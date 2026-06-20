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

import os
import re
import subprocess
from typing import Iterable, Iterator

from repology.logger import Logger
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

                pkg.add_downloads(iter_sources(sources_path_abs))

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
