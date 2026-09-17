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

import json
import os
import re
import subprocess
from typing import Any, Iterable, Iterator

from repology.logger import Logger
from repology.package import LinkType
from repology.packagemaker import NameType, PackageFactory, PackageMaker
from repology.parsers import Parser
from repology.parsers.maintainers import extract_maintainers
from repology.parsers.patches import add_patch_files
from repology.parsers.walk import walk_tree


_GIT_COMMIT_SUFFIX_RE = re.compile(r'^(.+)\.(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}$', re.IGNORECASE)


def read_version(path: str) -> str:
    with open(path) as fd:
        return fd.read().strip().split(None, 1)[0]


def normalize_sauzeros_version(version: str) -> str:
    if match := _GIT_COMMIT_SUFFIX_RE.fullmatch(version):
        return match[1]

    return version


def read_metadata(path: str) -> dict[str, Any]:
    """Read a package's metadata.json, or return nothing if it has none."""
    try:
        with open(path) as fd:
            data = json.load(fd)
    except FileNotFoundError:
        return {}

    return data if isinstance(data, dict) else {}


def iter_sources(path: str) -> Iterator[str]:
    with open(path) as fd:
        for line in fd:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            url = line.split()[0]

            if 'VERSION' in url and not any(filter(str.isnumeric, url)):  # type: ignore
                raise RuntimeError(f'substitution detected in url: "{url}", refusing to continue')

            if '://' in url:
                yield url


class SauzerosGitParser(Parser):
    _maintainer_from_git: bool

    def __init__(self, maintainer_from_git: bool = False):
        self._maintainer_from_git = maintainer_from_git

    def iter_parse(self, path: str, factory: PackageFactory) -> Iterable[PackageMaker]:
        for version_path_abs in walk_tree(path, name='version'):
            version_path_rel = os.path.relpath(version_path_abs, path)

            package_path_abs = os.path.dirname(version_path_abs)
            package_path_rel = os.path.relpath(package_path_abs, path)
            package_path_rel_comps = os.path.split(package_path_rel)

            sources_path_abs = os.path.join(package_path_abs, 'sources')
            patches_path_abs = os.path.join(package_path_abs, 'patches')

            with factory.begin(package_path_rel) as pkg:
                pkg.add_name(package_path_rel_comps[-1], NameType.KISS_NAME)
                pkg.set_version(normalize_sauzeros_version(read_version(version_path_abs)))

                if not os.path.exists(sources_path_abs):
                    pkg.log('skipping sourceless package', Logger.ERROR)
                    continue

                pkg.add_links(LinkType.UPSTREAM_DOWNLOAD, iter_sources(sources_path_abs))

                # The download URL alone is not enough to tell repology which
                # project a package belongs to. Short names such as ark and
                # cunit are shared by unrelated software, and repology's
                # split-ambiguity rules resolve them by looking at the homepage:
                #
                #   { name: ark,   wwwpart: apps.kde.org/ark/, setname: $0-archiver }
                #   { name: cunit, sourceforge: cunit,         setname: cunit-original }
                #   { name: ark,   addflag: unclassified }
                #
                # Without a homepage only the last rule can match and the
                # package lands in <name>-unclassified. metadata.json already
                # carries the URL, so publish it along with the rest of what it
                # knows.
                #
                # 'category' is deliberately not published: in this repository
                # it is the section the package lives in (core, extra), not an
                # upstream category, and feeding it to repology's categorypat
                # rules would only invite mismatches. The section is already
                # reported as the subrepo below.
                metadata = read_metadata(os.path.join(package_path_abs, 'metadata.json'))

                if homepage := metadata.get('url'):
                    pkg.add_links(LinkType.UPSTREAM_HOMEPAGE, homepage)
                if summary := metadata.get('description'):
                    pkg.set_summary(summary)
                if license_ := metadata.get('license'):
                    pkg.add_licenses(license_)

                pkg.set_extra_field('path', package_path_rel)
                pkg.set_subrepo(package_path_rel_comps[0])

                if self._maintainer_from_git:
                    command = ['git', 'log', '-1', '--format=tformat:%ae', version_path_rel]
                    with subprocess.Popen(command,
                                          stdout=subprocess.PIPE,
                                          encoding='utf-8',
                                          errors='ignore',
                                          cwd=path) as git:
                        lastauthor, _ = git.communicate()

                    pkg.add_maintainers(extract_maintainers(lastauthor))

                add_patch_files(pkg, patches_path_abs)

                yield pkg
