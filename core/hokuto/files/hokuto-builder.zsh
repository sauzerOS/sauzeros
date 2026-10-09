#compdef hokuto-builder

_hokuto_builder_repo_packages() {
  local -a packages roots
  local raw_path=$HOKUTO_PATH
  if [[ -z $raw_path && -f /etc/hokuto/hokuto.conf ]]; then
    raw_path=${${(M)${(f)"$(</etc/hokuto/hokuto.conf)"}:#HOKUTO_PATH=*}#HOKUTO_PATH=}
    raw_path=${${raw_path//\"/}//\'/}
  fi
  roots=(${(s.:.)raw_path})
  packages=(${^roots}/*(/N:t))
  _describe 'package' packages
}

_hokuto_builder_blacklisted() {
  local -a packages
  local f
  for f in /var/db/hokuto/build-ignore.json /var/db/hokuto/build-ignore-generic.json; do
    [[ -r $f ]] && packages+=(${(f)"$(sed -n 's/^ *"package": *"\([^"]*\)".*/\1/p' $f)"})
  done
  _describe 'blacklisted package' packages
}

_hokuto_builder() {
  local -a commands
  commands=(
    'create:create the container (once)'
    'bump:hokuto bump --auto --build in the container'
    'build:build packages, then upload --sync'
    'rebuild:build and upload recipes ahead of the mirror'
    'cross-sync:hokuto cross-sync, then upload --sync'
    'cycle:one unattended bump, rebuild and cross-sync round'
    'blacklist:list or edit the build blacklist'
    'run:run a command in the container'
    'shell:interactive shell in the container'
    "update:update the container's own packages"
    'destroy:delete the container'
    'help:show usage'
  )

  if (( CURRENT == 2 )); then
    _describe 'command' commands
    return
  fi

  case $words[2] in
    bump)
      _arguments '-y[bump and build everything unattended]'
      ;;
    build)
      _arguments \
        '--no-upload[skip upload --sync]' \
        '(-j --parallel)'{-j,--parallel}'[parallel build jobs]:jobs:' \
        '(-v --verbose)'{-v,--verbose}'[verbose build output]' \
        '*:package:_hokuto_builder_repo_packages'
      ;;
    rebuild)
      _arguments \
        '-y[build without asking]' \
        '--no-upload[skip upload --sync]' \
        '(-j --parallel)'{-j,--parallel}'[parallel build jobs]:jobs:' \
        '(-v --verbose)'{-v,--verbose}'[verbose build output]'
      ;;
    cross-sync)
      _arguments \
        '-system[sync the aarch64-* cross-system packages]' \
        '-y[build every missing package without asking]' \
        '--no-upload[skip upload --sync]' \
        '-j[parallel build jobs]:jobs:'
      ;;
    blacklist)
      if (( CURRENT == 3 )); then
        local -a subcommands
        subcommands=(
          'list:list the blacklisted packages'
          'remove:let packages build again'
          'clear:empty the blacklist'
        )
        _describe 'blacklist command' subcommands
      elif [[ $words[3] == remove ]]; then
        shift 2 words
        (( CURRENT -= 2 ))
        _arguments \
          "-arch[only this architecture's entry]:arch:(native aarch64)" \
          '*:package:_hokuto_builder_blacklisted'
      fi
      ;;
    run)
      shift 2 words
      (( CURRENT -= 2 ))
      _normal
      ;;
  esac
}

_hokuto_builder "$@"
