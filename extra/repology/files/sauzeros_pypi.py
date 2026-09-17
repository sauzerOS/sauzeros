# Copyright (C) 2026 Repology contributors
#
# This file is part of repology
#
# repology is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# repology is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with repology.  If not, see <http://www.gnu.org/licenses/>.

"""Build a PyPI dataset covering only the python packages this distribution
actually ships.

repology.org consumes pypicache.repology.org, a rebuilt copy of all 893k PyPI
projects. That exists because repology tracks every distribution and so needs
every project, and because one shared crawler is kinder to PyPI than each
instance crawling it. Neither reason applies to a single-distribution instance:
the pypi repository is declared `shadow`, so a PyPI project that no real
repository ships never becomes visible anyway. What it is actually for is
answering "is our python-foo behind PyPI", and that only needs the projects we
package -- under two hundred rather than nearly a million.

Fetching them directly also removes the dependency on repology.org being
reachable, which is what prompted this: the domain went to a registrar hold and
every pypi fetch failed.
"""

import json
import os
import re
import shutil
import subprocess
import tempfile
import time
from typing import Any, Iterable
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from repology.atomic_fs import AtomicFile
from repology.fetchers import PersistentData, ScratchFileFetcher
from repology.logger import Logger


# The name PyPI knows a package by, as spelled in a source URL. Both the
# pythonhosted and the pypi.org spellings appear in our sources files.
_PYPI_SOURCE_URL_RE = re.compile(
    r'https://(?:files\.pythonhosted\.org|pypi\.org|pypi\.io)/packages/source/[^/]+/([^/]+)/'
)

_PACKAGE_PREFIX = 'python-'

_USER_AGENT = 'sauzeros-repology-updater (+https://github.com/sauzerOS/sauzeros)'


def _candidate_pypi_names(package_name: str, sources_text: str) -> list[str]:
    """Names to try for a package, best first.

    The source URL wins when there is one: it is what upstream actually
    publishes under. Otherwise strip our python- prefix, which is right for the
    large majority, and finally try the package name unchanged -- python-dateutil
    really is called python-dateutil on PyPI.

    PyPI normalises case and -/_/. in names, so no variants of those are needed.
    """
    candidates = []

    if match := _PYPI_SOURCE_URL_RE.search(sources_text):
        candidates.append(match.group(1))

    if package_name.startswith(_PACKAGE_PREFIX):
        candidates.append(package_name[len(_PACKAGE_PREFIX):])

    candidates.append(package_name)

    seen = set()
    return [c for c in candidates if not (c.lower() in seen or seen.add(c.lower()))]


def _iter_python_packages(checkout: str) -> Iterable[tuple[str, str]]:
    """Yield (package name, contents of its sources file) for python packages."""
    for dirpath, _, filenames in os.walk(checkout):
        if 'sources' not in filenames:
            continue
        name = os.path.basename(dirpath)
        if not name.startswith(_PACKAGE_PREFIX):
            continue
        try:
            with open(os.path.join(dirpath, 'sources'), encoding='utf-8', errors='ignore') as fd:
                yield name, fd.read()
        except OSError:
            continue


class SauzerosPyPiFetcher(ScratchFileFetcher):
    _repositories: list[str]
    _fetch_timeout: int
    _fetch_delay: float

    def __init__(self, repositories: list[str], fetch_timeout: int = 20, fetch_delay: float = 0.5) -> None:
        super().__init__(binary=False)
        self._repositories = list(repositories)
        self._fetch_timeout = fetch_timeout
        self._fetch_delay = fetch_delay

    def _clone(self, url: str, target: str, logger: Logger) -> None:
        # Only the sources files are needed, so avoid pulling blobs for the rest
        # of the tree. This mirrors how the sauzeros sources themselves are
        # fetched.
        subprocess.run(
            ['git', 'clone', '--quiet', '--depth', '1', '--filter=blob:none', '--sparse', url, target],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
        )
        subprocess.run(
            ['git', 'sparse-checkout', 'set', '--no-cone', '**/sources'],
            cwd=target, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
        )

    def _collect_names(self, logger: Logger) -> dict[str, list[str]]:
        """Map each packaged python module to the PyPI names worth trying."""
        wanted: dict[str, list[str]] = {}
        workdir = tempfile.mkdtemp(prefix='sauzeros-pypi-')
        try:
            for index, url in enumerate(self._repositories):
                target = os.path.join(workdir, str(index))
                try:
                    self._clone(url, target, logger)
                except subprocess.CalledProcessError as e:
                    stderr = e.stderr.decode('utf-8', 'ignore').strip() if e.stderr else ''
                    raise RuntimeError(f'cannot clone {url}: {stderr}') from e

                for package_name, sources_text in _iter_python_packages(target):
                    wanted.setdefault(package_name, _candidate_pypi_names(package_name, sources_text))
        finally:
            shutil.rmtree(workdir, ignore_errors=True)

        return wanted

    def _fetch_project(self, name: str) -> dict[str, Any] | None:
        request = Request(f'https://pypi.org/pypi/{name}/json', headers={'User-Agent': _USER_AGENT})
        try:
            with urlopen(request, timeout=self._fetch_timeout) as response:
                return json.load(response)
        except HTTPError as e:
            if e.code == 404:
                return None
            raise
        except URLError as e:
            raise RuntimeError(f'cannot fetch PyPI project {name}: {e}') from e

    def _do_fetch(self, statefile: AtomicFile, persdata: PersistentData, logger: Logger) -> bool:
        wanted = self._collect_names(logger)
        logger.log(f'{len(wanted)} packaged python modules to look up on PyPI')

        projects = []
        missing = []

        for package_name in sorted(wanted):
            for candidate in wanted[package_name]:
                data = self._fetch_project(candidate)
                if self._fetch_delay:
                    time.sleep(self._fetch_delay)
                if data is not None:
                    projects.append(data)
                    break
            else:
                # Not every python package we ship is distributed on PyPI:
                # antlr4 publishes as antlr4-python3-runtime, pkg_resources is
                # part of setuptools, distutils-extra only exists on Launchpad.
                missing.append(package_name)

        if missing:
            logger.log('no PyPI project found for: ' + ', '.join(missing), severity=Logger.WARNING)

        logger.log(f'{len(projects)} PyPI projects fetched')

        json.dump(projects, statefile.get_file())

        return True
