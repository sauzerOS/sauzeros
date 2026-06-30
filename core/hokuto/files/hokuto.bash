# bash completion for hokuto/hk

_hokuto_get_repo_packages()
{
    local config_line raw_path path
    if [[ -f /etc/hokuto/hokuto.conf ]]; then
        config_line=$(grep '^HOKUTO_PATH=' /etc/hokuto/hokuto.conf 2>/dev/null)
        raw_path=${config_line#HOKUTO_PATH=}
        raw_path=${raw_path%\"}
        raw_path=${raw_path#\"}
        raw_path=${raw_path%\'}
        raw_path=${raw_path#\'}
        IFS=: read -ra _hokuto_repo_paths <<< "$raw_path"
        for path in "${_hokuto_repo_paths[@]}"; do
            [[ -d $path ]] || continue
            find "$path" -mindepth 1 -maxdepth 1 -type d -not -name .git -printf '%f\n' 2>/dev/null
        done
    fi
}

_hokuto_get_installed_packages()
{
    local install_path=/var/db/hokuto/installed
    [[ -d $install_path ]] || return 0
    find "$install_path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
}

_hokuto_get_cached_tarballs()
{
    local file
    for file in /var/cache/hokuto/bin/*.tar.zst; do
        [[ -f $file ]] && printf '%s\n' "$file"
    done
}

_hokuto_complete()
{
    local cur prev cmd words cword
    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}

    local commands="version --version log list ls checksum c build b bootstrap install i uninstall remove r update u manifest m size unmanaged find f new n cd edit e bump meta sync search s chroot cleanup python-rebuild alt settings init-repos upload keys sign-file depends cross-sync check"

    if (( COMP_CWORD == 1 )); then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi

    cmd=${COMP_WORDS[1]}
    case "$cmd" in
        install|i)
            case "$cur" in
                -*) COMPREPLY=( $(compgen -W "-y --yes --force --no-deps --generic -g --arm64 --x86_64 --multi --remote --no-remote --fast" -- "$cur") ) ;;
                *) COMPREPLY=( $(compgen -W "$(_hokuto_get_cached_tarballs) $(_hokuto_get_repo_packages)" -- "$cur") ) ;;
            esac
            ;;
        build|b)
            case "$cur" in
                -*) COMPREPLY=( $(compgen -W "-a -i --idle -ii --superidle -v --verbose --alldeps -r --rebuilds --ordered --generic --cross --no-deps --no-devel --no-remote --wget-no-check-certificate -j --parallel --index" -- "$cur") ) ;;
                *) COMPREPLY=( $(compgen -W "$(_hokuto_get_repo_packages)" -- "$cur") ) ;;
            esac
            ;;
        uninstall|remove|r)
            case "$cur" in
                -*) COMPREPLY=( $(compgen -W "-f --force -y --yes" -- "$cur") ) ;;
                *) COMPREPLY=( $(compgen -W "$(_hokuto_get_installed_packages)" -- "$cur") ) ;;
            esac
            ;;
        update|u)
            COMPREPLY=( $(compgen -W "-i --idle -ii --superidle -v --verbose -j --parallel --remote -y --yes" -- "$cur") )
            ;;
        list|ls)
            case "$cur" in
                -*) COMPREPLY=( $(compgen -W "--remote" -- "$cur") ) ;;
                *) COMPREPLY=( $(compgen -W "$(_hokuto_get_installed_packages)" -- "$cur") ) ;;
            esac
            ;;
        checksum|c)
            case "$cur" in
                -*) COMPREPLY=( $(compgen -W "-f --unpack" -- "$cur") ) ;;
                *) COMPREPLY=( $(compgen -W "$(_hokuto_get_repo_packages)" -- "$cur") ) ;;
            esac
            ;;
        new|n)
            COMPREPLY=( $(compgen -W "--here --from-arch --from-aur" -- "$cur") )
            ;;
        edit|e|cd|bump|alt|check|meta|depends)
            case "$cur" in
                -*) COMPREPLY=( $(compgen -W "-a --auto --build --set -y --yes -e -db -r --reverse" -- "$cur") ) ;;
                *) COMPREPLY=( $(compgen -W "$(_hokuto_get_repo_packages)" -- "$cur") ) ;;
            esac
            ;;
        manifest|m|size)
            COMPREPLY=( $(compgen -W "$(_hokuto_get_installed_packages)" -- "$cur") )
            ;;
        unmanaged)
            COMPREPLY=( $(compgen -W "--checksums --backup --restore --add" -- "$cur") )
            ;;
        cleanup)
            COMPREPLY=( $(compgen -W "--sources --bins --orphans --all" -- "$cur") )
            ;;
        upload)
            COMPREPLY=( $(compgen -W "--cleanup --reindex --sync --prompt --syncdb --delete --copy-from-r2" -- "$cur") )
            ;;
        search|s)
            COMPREPLY=( $(compgen -W "--tag --strict" -- "$cur") )
            ;;
        cross-sync)
            COMPREPLY=( $(compgen -W "--native -j -i" -- "$cur") )
            ;;
        keys)
            COMPREPLY=( $(compgen -W "--sync" -- "$cur") )
            ;;
        sign-file)
            COMPREPLY=( $(compgen -f -- "$cur") )
            ;;
        bootstrap|chroot)
            COMPREPLY=( $(compgen -d -- "$cur") )
            ;;
    esac
}

complete -F _hokuto_complete hokuto
complete -F _hokuto_complete hk
