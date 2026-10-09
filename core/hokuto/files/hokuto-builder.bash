# bash completion for hokuto-builder

_hokuto_builder_repo_packages()
{
    local config=${HOKUTO_CONFIG:-/etc/hokuto/hokuto.conf} raw_path=${HOKUTO_PATH-} line path

    if [[ -z $raw_path && -f $config ]]; then
        while IFS= read -r line; do
            [[ $line == HOKUTO_PATH=* ]] || continue
            raw_path=${line#HOKUTO_PATH=}
            raw_path=${raw_path//\"/}
            raw_path=${raw_path//\'/}
        done < "$config"
    fi
    [[ -n $raw_path ]] || return 0

    local IFS=:
    for path in $raw_path; do
        [[ -d $path ]] || continue
        find "$path" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%f\n' 2>/dev/null
    done
}

# The packages on the build blacklists (native and generic container).
_hokuto_builder_blacklisted()
{
    local f
    for f in /var/db/hokuto/build-ignore.json /var/db/hokuto/build-ignore-generic.json; do
        [[ -r $f ]] && sed -n 's/^ *"package": *"\([^"]*\)".*/\1/p' "$f"
    done | sort -u
}

_hokuto_builder()
{
    local cur prev words cword
    # bash-completion is optional, as for hokuto's own completion.
    if declare -F _init_completion >/dev/null; then
        _init_completion || return
    else
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
        cur=${COMP_WORDS[COMP_CWORD]}
        prev=${COMP_WORDS[COMP_CWORD-1]}
    fi

    local commands="create bump build rebuild cross-sync cycle blacklist run shell update destroy help"

    if (( cword == 1 )); then
        COMPREPLY=($(compgen -W "$commands -h --help" -- "$cur"))
        return
    fi

    case ${words[1]} in
        bump)
            COMPREPLY=($(compgen -W "-y" -- "$cur"))
            ;;
        build)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W "--no-upload -j --parallel -v --verbose" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$(_hokuto_builder_repo_packages)" -- "$cur"))
            fi
            ;;
        rebuild)
            COMPREPLY=($(compgen -W "-y --no-upload -j --parallel -v --verbose" -- "$cur"))
            ;;
        cross-sync)
            COMPREPLY=($(compgen -W "-system -y --no-upload -j" -- "$cur"))
            ;;
        blacklist)
            if (( cword == 2 )); then
                COMPREPLY=($(compgen -W "list remove clear" -- "$cur"))
            elif [[ ${words[2]} == remove ]]; then
                if [[ $prev == -arch ]]; then
                    COMPREPLY=($(compgen -W "native aarch64" -- "$cur"))
                elif [[ $cur == -* ]]; then
                    COMPREPLY=($(compgen -W "-arch" -- "$cur"))
                else
                    COMPREPLY=($(compgen -W "$(_hokuto_builder_blacklisted)" -- "$cur"))
                fi
            fi
            ;;
        run)
            # The command to run inside the container, then its arguments.
            if (( cword == 2 )); then
                COMPREPLY=($(compgen -c -- "$cur"))
            else
                COMPREPLY=($(compgen -f -- "$cur"))
            fi
            ;;
    esac
}

complete -F _hokuto_builder hokuto-builder
