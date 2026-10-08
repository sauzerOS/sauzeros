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

_hokuto_builder() {
  local -a commands
  commands=(
    'create:create the container (once)'
    'bump:hokuto bump --auto --build in the container'
    'build:build packages, then upload --sync'
    'rebuild:build and upload recipes ahead of the mirror'
    'cross-sync:hokuto cross-sync, then upload --sync'
    'cycle:one unattended bump, rebuild and cross-sync round'
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
    run)
      shift 2 words
      (( CURRENT -= 2 ))
      _normal
      ;;
  esac
}

_hokuto_builder "$@"
