# bash completion for hokuto/hk

_hokuto_config_value()
{
    local key=$1 config=${HOKUTO_CONFIG:-/etc/hokuto/hokuto.conf}
    local line value

    value=${!key-}
    if [[ -n $value ]]; then
        printf '%s\n' "$value"
        return 0
    fi

    [[ -f $config ]] || return 0
    while IFS= read -r line; do
        line=${line%%#*}
        line=${line#"${line%%[![:space:]]*}"}
        line=${line%"${line##*[![:space:]]}"}
        [[ $line == "$key="* ]] || continue
        value=${line#*=}
        value=${value#"${value%%[![:space:]]*}"}
        value=${value%"${value##*[![:space:]]}"}
        value=${value%\"}
        value=${value#\"}
        value=${value%\'}
        value=${value#\'}
        printf '%s\n' "$value"
        return 0
    done < "$config"
}

_hokuto_get_repo_packages()
{
    local raw_path path
    raw_path=$(_hokuto_config_value HOKUTO_PATH)
    [[ -n $raw_path ]] || return 0

    local IFS=:
    for path in $raw_path; do
        [[ -d $path ]] || continue
        find "$path" -mindepth 1 -maxdepth 1 -type d -not -name .git -printf '%f\n' 2>/dev/null
    done
}

_hokuto_get_installed_packages()
{
    local root cache_dir install_path
    root=$(_hokuto_config_value HOKUTO_ROOT)
    [[ -n $root ]] || root=/
    install_path=${root%/}/var/db/hokuto/installed
    [[ -d $install_path ]] || return 0
    find "$install_path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
}

_hokuto_get_cached_tarballs()
{
    local cache_dir file
    cache_dir=$(_hokuto_config_value HOKUTO_CACHE_DIR)
    [[ -n $cache_dir ]] || cache_dir=/var/cache/hokuto
    for file in "$cache_dir"/bin/*.tar.zst; do
        [[ -f $file ]] && printf '%s\n' "$file"
    done
}

_hokuto_comp_words()
{
    if declare -F _init_completion >/dev/null; then
        _init_completion -n : || return
    else
        cur=${COMP_WORDS[COMP_CWORD]}
        prev=${COMP_WORDS[COMP_CWORD-1]}
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi
}

_hokuto_compgen_words()
{
    local -a choices
    mapfile -t choices
    COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
}

_hokuto_complete_packages()
{
    local -a choices
    mapfile -t choices < <(_hokuto_get_repo_packages)
    COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
}

_hokuto_complete_installed()
{
    local -a choices
    mapfile -t choices < <(_hokuto_get_installed_packages)
    COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
}

_hokuto_complete_install_targets()
{
    local -a choices
    mapfile -t choices < <(_hokuto_get_cached_tarballs; command "${COMP_WORDS[0]}" __complete install 2>/dev/null)
    COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
}

_hokuto_complete_available_packages()
{
    local -a choices
    mapfile -t choices < <(command "${COMP_WORDS[0]}" __complete install 2>/dev/null)
    COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
}

_hokuto_first_command()
{
    local i word commands="version --version log list ls checksum c build b bootstrap install i uninstall remove r update u manifest m size unmanaged find f new n cd edit e bump meta sync search s chroot cleanup python-rebuild alt info settings init-repos upload keys sign-file depends cross-sync check"
    for ((i = 1; i < cword; i++)); do
        word=${words[i]}
        if [[ " $commands " == *" $word "* ]]; then
            printf '%s\n' "$word"
            return 0
        fi
    done
    return 1
}

_hokuto_complete()
{
    local cur prev words cword cmd
    COMPREPLY=()
    _hokuto_comp_words

    local commands="version --version log list ls checksum c build b bootstrap install i uninstall remove r update u manifest m size unmanaged find f new n cd edit e bump meta sync search s chroot cleanup python-rebuild alt info settings init-repos upload keys sign-file depends cross-sync check"

    cmd=$(_hokuto_first_command)
    if [[ -z $cmd ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return 0
    fi

    case "$cmd" in
        log)
            local -a choices
            mapfile -t choices < <(command "${COMP_WORDS[0]}" __complete log 2>/dev/null)
            COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
            ;;
        install|i)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "-y --yes --force --no-deps --generic -g --arm64 --x86_64 --multi --remote --no-remote --ask --debug" -- "$cur")) ;;
                *) _hokuto_complete_install_targets ;;
            esac
            ;;
        build|b)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "-a -i --idle -ii --superidle -v --verbose --debug --alldeps -r --rebuilds --ordered --generic --cross --no-deps --no-devel --no-remote --wget-no-check-certificate -j --parallel --index" -- "$cur")) ;;
                *) _hokuto_complete_packages ;;
            esac
            ;;
        uninstall|remove|r)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "-f --force -y --yes --list" -- "$cur")) ;;
                *) _hokuto_complete_installed ;;
            esac
            ;;
		update|u)
			COMPREPLY=($(compgen -W "-i --idle -ii --superidle -v --verbose -j --parallel --remote --build-missing-binaries -y --yes" -- "$cur"))
            ;;
		list|ls)
			case "$cur" in
				-*) COMPREPLY=($(compgen -W "--remote --size --check-integrity" -- "$cur")) ;;
                *) _hokuto_complete_installed ;;
            esac
            ;;
        checksum|c)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "-f --unpack" -- "$cur")) ;;
                *) _hokuto_complete_packages ;;
            esac
            ;;
        new|n)
            COMPREPLY=($(compgen -W "--here --from-arch --from-aur" -- "$cur"))
            ;;
        edit|e)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "-a" -- "$cur")) ;;
                *) _hokuto_complete_packages ;;
            esac
            ;;
        cd|bump|check)
            _hokuto_complete_packages
            ;;
        alt)
            case "$prev" in
                -ls|--list)
                    local -a choices
                    mapfile -t choices < <(printf '%s\n' unmanaged; _hokuto_get_installed_packages)
                    COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
                    ;;
                *)
                    case "$cur" in
                        -*) COMPREPLY=($(compgen -W "-h --help -ls --list" -- "$cur")) ;;
                        *)
                            local -a choices
                            mapfile -t choices < <(printf '%s\n' discard-unmanaged; _hokuto_get_installed_packages)
                            COMPREPLY=($(compgen -W "${choices[*]}" -- "$cur"))
                            ;;
                    esac
                    ;;
            esac
            ;;
        meta)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "-e -db" -- "$cur")) ;;
                *) _hokuto_complete_packages ;;
            esac
            ;;
        depends)
            case "$cur" in
                -*) COMPREPLY=($(compgen -W "-r --reverse" -- "$cur")) ;;
                *) _hokuto_complete_available_packages ;;
            esac
            ;;
        manifest|m|size)
            _hokuto_complete_installed
            ;;
        unmanaged)
            COMPREPLY=($(compgen -W "--checksums --backup --restore --add" -- "$cur"))
            ;;
		cleanup)
			COMPREPLY=($(compgen -W "--sources --bins --orphans --tmp --all" -- "$cur"))
            ;;
        upload)
            COMPREPLY=($(compgen -W "--cleanup --cleanup-all --reindex --sync --prompt --syncdb --delete --copy-from-r2" -- "$cur"))
            ;;
        search|s)
            COMPREPLY=($(compgen -W "--tag --strict" -- "$cur"))
            ;;
        cross-sync)
            COMPREPLY=($(compgen -W "--native -j -i" -- "$cur"))
            ;;
        keys)
            COMPREPLY=($(compgen -W "--sync" -- "$cur"))
            ;;
        sign-file)
            COMPREPLY=($(compgen -f -- "$cur"))
            ;;
        bootstrap|chroot)
            COMPREPLY=($(compgen -d -- "$cur"))
            ;;
    esac
}

complete -o default -o bashdefault -F _hokuto_complete hokuto
complete -o default -o bashdefault -F _hokuto_complete hk
