# bash completion for sauzeros-live-vm

_sauzeros_live_vm()
{
    local cur prev words cword
    COMPREPLY=()
    # bash-completion is optional, as for hokuto's own completion.
    if declare -F _init_completion >/dev/null; then
        _init_completion || return
    else
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
        cur=${COMP_WORDS[COMP_CWORD]}
        prev=${COMP_WORDS[COMP_CWORD-1]}
    fi

    case $prev in
        -r|--rootfs)
            COMPREPLY=($(compgen -d -- "$cur"))
            return ;;
        -i|--image|-k|--kernel|--disk|--create-img)
            COMPREPLY=($(compgen -f -- "$cur"))
            return ;;
        --iso)
            COMPREPLY=($(compgen -f -X '!*.[iI][sS][oO]' -- "$cur") $(compgen -d -- "$cur"))
            return ;;
        --display)
            COMPREPLY=($(compgen -W "gtk sdl spice" -- "$cur"))
            return ;;
        --arch)
            COMPREPLY=($(compgen -W "x86_64 aarch64" -- "$cur"))
            return ;;
        --bridge)
            local bridges=(/sys/class/net/*/bridge)
            bridges=("${bridges[@]%/bridge}")
            COMPREPLY=($(compgen -W "${bridges[*]##*/}" -- "$cur"))
            return ;;
        -m|--memory|-c|--cpus|-s|--free|-a|--append)
            return ;;
    esac

    local opts="-r --rootfs -i --image -m --memory -c --cpus -s --free
        -k --kernel -a --append --reuse --fresh --gl --no-gl --venus
        --relative-mouse --uefi --display --iso --disk --create-img --arch --bridge -h --help"
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

complete -F _sauzeros_live_vm sauzeros-live-vm
