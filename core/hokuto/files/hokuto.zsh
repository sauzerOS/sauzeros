#compdef hokuto hk

_hokuto_installed_packages() {
  local -a packages
  packages=(/var/db/hokuto/installed/*(/N:t))
  _describe 'installed package' packages
}

_hokuto_repository_packages() {
  local -a packages roots
  roots=(${(s.:.)HOKUTO_PATH})
  (( ${#roots} )) || roots=(/repo/*)
  packages=(${^roots}/*(/N:t))
  _describe 'package' packages
}

_hokuto() {
  local context state line command
  typeset -A opt_args

  _arguments -C \
    '1:command:->command' \
    '*::argument:->args'

  case $state in
    command)
      local -a commands
      commands=(
        'version:Show version information'
        'log:Show build logs'
        'list:List installed packages'
        'ls:List installed packages'
        'checksum:Generate package checksums'
        'c:Generate package checksums'
        'build:Build packages'
        'b:Build packages'
        'install:Install packages'
        'i:Install packages'
        'uninstall:Uninstall packages'
        'remove:Uninstall packages'
        'r:Uninstall packages'
        'update:Update installed packages'
        'u:Update installed packages'
        'manifest:Show an installed package manifest'
        'm:Show an installed package manifest'
        'size:Show installed package size'
        'unmanaged:Find unmanaged files'
        'find:Find package ownership'
        'f:Find package ownership'
        'new:Create a package recipe'
        'n:Create a package recipe'
        'edit:Edit a package recipe'
        'e:Edit a package recipe'
        'bump:Bump package versions'
        'cleanup:Clean caches and temporary files'
        'upload:Upload local binaries to the remote mirror'
        'check:Check whether a package is installed'
      )
      _describe 'command' commands
      ;;
    args)
      command=${line[1]}
      case $command in
        list|ls)
          _arguments \
            '--remote[List packages from the remote repository]' \
            '--check-integrity[Check installed manifests for missing files]' \
            '*:installed package:_hokuto_installed_packages'
          ;;
		cleanup)
          _arguments \
            '--sources[Remove cached sources]' \
            '--bins[Remove built binary packages]' \
            '--orphans[Check and remove orphan packages]' \
            '--tmp[Remove temporary build files]' \
			'--all[Clean sources, binaries, temporary files, and orphans]'
			;;
		update|u)
			_arguments \
			  '(-i --idle)'{-i,--idle}'[Use idle build priority]' \
			  '(-ii --superidle)'{-ii,--superidle}'[Use super-idle build priority]' \
			  '(-v --verbose)'{-v,--verbose}'[Enable verbose output]' \
			  '(-j --parallel)'{-j,--parallel}'[Number of parallel jobs]:jobs:' \
			  '--remote[Check the remote binary mirror only]' \
			  '--build-missing-binaries[Build repository packages missing current binaries]' \
			  '(-y --yes)'{-y,--yes}'[Assume yes]'
			;;
		upload)
			_arguments \
			  '--cleanup[Prompt to remove older versions on remote]' \
			  '--cleanup-all[Remove all older versions on remote without prompting]' \
			  '--reindex[Regenerate the remote index]' \
			  '--sync[Upload all missing local files without prompting]' \
			  '--prompt[Prompt for each missing local file]' \
			  '--syncdb[Upload only the global package database]' \
			  '--delete=-[Delete remote files]:package name:' \
			  '--copy-from-r2[Copy all files from Cloudflare R2]'
			;;
        uninstall|remove|r)
          _arguments \
            '(-f --force)'{-f,--force}'[Force uninstallation]' \
            '(-y --yes)'{-y,--yes}'[Assume yes]' \
            '--list[Select installed packages interactively]' \
            '*:installed package:_hokuto_installed_packages'
          ;;
        manifest|m|size)
          _hokuto_installed_packages
          ;;
        build|b|checksum|c|install|i|edit|e|bump|check)
          _hokuto_repository_packages
          ;;
      esac
      ;;
  esac
}

_hokuto "$@"
