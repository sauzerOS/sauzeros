# Helper function to extract package names from HOKUTO_PATH repositories
function __hokuto_get_repo_packages
    set -l repo_paths

    if test -f /etc/hokuto/hokuto.conf
        set -l config_line (grep "^HOKUTO_PATH=" /etc/hokuto/hokuto.conf)

        if test -n "$config_line"
            set -l raw_path (string split -m1 "=" $config_line)[2]
            set raw_path (string trim -c '"\'' $raw_path)
            set repo_paths (string split ":" $raw_path)
        end
    end

    for path in $repo_paths
        if test -d $path
            find $path -mindepth 1 -maxdepth 1 -type d -not -name '.git' -printf "%f\n" 2>/dev/null
        end
    end
end

# Helper function to extract installed package names
function __hokuto_get_installed_packages
    set -l install_path "/var/db/hokuto/installed/"
    if test -d $install_path
        find $install_path -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null
    end
end

function __hokuto_get_install_packages
    set -l executable (commandline -opc)[1]
    # The current token is passed on: for pkg@ hokuto lists the versions the
    # mirror has.
    command $executable __complete install (commandline -ct) 2>/dev/null
end

function __hokuto_alt_needs_provider
    set -l tokens (commandline -opc)
    test (count $tokens) -gt 0; or return 1
    contains -- $tokens[-1] -ls --list
end

function __hokuto_alt_accepts_target
    not __hokuto_alt_needs_provider
end

function __hokuto_blacklisted
    set -l f /var/db/hokuto/build-ignore.json
    test -r $f; and string replace -rf '^\s*"package":\s*"([^"]*)".*' '$1' <$f | sort -u
end

function __hokuto_nobuild_listed
    set -l f /var/db/hokuto/nobuild.json
    test -r $f; and string replace -rf '^\s*"package":\s*"([^"]*)".*' '$1' <$f | sort -u
end

set -l prog_names hk hokuto
set -l hokuto_commands version --version log list ls checksum c build b bootstrap install i uninstall remove r update u manifest m size unmanaged find f new n cd edit e bump meta sync search s chroot cleanup python-rebuild alt info settings init-repos upload keys sign-file depends cross-sync check blacklist nobuild

for prog in $prog_names
    complete -c $prog -f
    complete -c $prog -n "not __fish_seen_subcommand_from $hokuto_commands" -a "$hokuto_commands"

    complete -c $prog -n "__fish_seen_subcommand_from log" -a "(command $prog __complete log 2>/dev/null)" -d "Available Package Log"

    complete -c $prog -n "__fish_seen_subcommand_from install i" -s y -l yes -d "Assume yes to all prompts"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l force -d "Install even if already installed"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l no-deps -d "Ignore dependencies"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l generic -d "Install generic variant"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -s g -d "Install generic variant"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l arm64 -d "Install arm64 version"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l x86_64 -d "Install x86_64 version"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l multi -d "Install multilib variants"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l remote -d "Install from remote mirror"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l no-remote -d "Use local package sources and cached files only"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l ask -d "Show the install plan and ask before installing"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l debug -d "Enable debug output and detailed install mode"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -a '(
        set -l cache_root "/var/cache/hokuto/bin/"
        for file in $cache_root*.tar.zst
            if test -f $file
                echo -e "$file\tBinary Cache"
            end
        end
    )'
    complete -c $prog -n "__fish_seen_subcommand_from install i" -a "(__hokuto_get_install_packages)" -d "Available Package"

    complete -c $prog -n "__fish_seen_subcommand_from build b" -s a -d "Automatically install after build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s i -d "Idle build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l idle -d "Idle build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -o ii -d "Super-idle build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l superidle -d "Super-idle build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s v -l verbose -d "Enable verbose output"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l debug -d "Enable debug output"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l alldeps -d "Force rebuild of all dependencies"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s r -l rebuilds -d "Enable post-build rebuilds"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l ordered -d "Force ordered build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l generic -d "Build generic variant"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l cross -d "Cross-compile for target arch"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l no-deps -d "Skip dependency check"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l no-devel -d "Skip automatic base-devel dependency installation"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l no-remote -d "Do not use the remote binary mirror"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l wget-no-check-certificate -d "Pass --no-check-certificate to wget fallback"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s j -l parallel -d "Number of parallel jobs"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l index -d "Update github.io status table"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    complete -c $prog -n "__fish_seen_subcommand_from uninstall remove r; and not __fish_seen_subcommand_from blacklist nobuild" -s f -l force -d "Force uninstallation"
    complete -c $prog -n "__fish_seen_subcommand_from uninstall remove r; and not __fish_seen_subcommand_from blacklist nobuild" -s y -l yes -d "Assume yes"
    complete -c $prog -n "__fish_seen_subcommand_from uninstall remove r; and not __fish_seen_subcommand_from blacklist nobuild" -s p -l purge -d "Also remove the orphans the removal leaves"
    complete -c $prog -n "__fish_seen_subcommand_from uninstall remove r; and not __fish_seen_subcommand_from blacklist nobuild" -a "(__hokuto_get_installed_packages)" -d "Installed Package"

    complete -c $prog -n "__fish_seen_subcommand_from update u" -s i -l idle -d "Idle build during update"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -o ii -l superidle -d "Super-idle build during update"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -s v -l verbose -d "Enable verbose output"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -s j -l parallel -d "Number of parallel jobs"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -l remote -d "Check remote mirror only"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -l build-missing-binaries -d "Build repository packages missing current binaries"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -s y -l yes -d "Assume yes"

    complete -c $prog -n "__fish_seen_subcommand_from list ls; and not __fish_seen_subcommand_from blacklist nobuild" -l remote -d "List remote packages"
    complete -c $prog -n "__fish_seen_subcommand_from list ls; and not __fish_seen_subcommand_from blacklist nobuild" -l size -d "Sort packages by size, largest first"
    complete -c $prog -n "__fish_seen_subcommand_from list ls; and not __fish_seen_subcommand_from blacklist nobuild" -l check-integrity -d "Check installed manifests for missing files"
    complete -c $prog -n "__fish_seen_subcommand_from list ls; and not __fish_seen_subcommand_from blacklist nobuild" -s f -l force -d "Start the list in force uninstall mode"
    complete -c $prog -n "__fish_seen_subcommand_from list ls; and not __fish_seen_subcommand_from blacklist nobuild" -a "(__hokuto_get_installed_packages)" -d "Installed Package"

    complete -c $prog -n "__fish_seen_subcommand_from checksum c" -s f -d "Force sources download"
    complete -c $prog -n "__fish_seen_subcommand_from checksum c" -l unpack -d "Unpack sources in build dir"
    complete -c $prog -n "__fish_seen_subcommand_from checksum c" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    complete -c $prog -n "__fish_seen_subcommand_from new n" -l here -d "Create package in current directory"
    complete -c $prog -n "__fish_seen_subcommand_from new n" -l from-arch -d "Import from Arch Linux official repos"
    complete -c $prog -n "__fish_seen_subcommand_from new n" -l from-aur -d "Import from AUR"

    complete -c $prog -n "__fish_seen_subcommand_from edit e" -s a -d "Open all build files"
    complete -c $prog -n "__fish_seen_subcommand_from edit e cd bump check" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    complete -c $prog -n "__fish_seen_subcommand_from alt; and __hokuto_alt_accepts_target" -a "discard-unmanaged" -d "Remove unmanaged alternatives"
    complete -c $prog -n "__fish_seen_subcommand_from alt; and __hokuto_alt_accepts_target" -s h -l help -d "Show alternatives help"
    complete -c $prog -n "__fish_seen_subcommand_from alt; and __hokuto_alt_accepts_target" -o ls -l list -d "List files provided by an owner"
    complete -c $prog -n "__fish_seen_subcommand_from alt; and __hokuto_alt_accepts_target" -a "(__hokuto_get_installed_packages)" -d "Alternative Package"
    complete -c $prog -n "__fish_seen_subcommand_from alt; and __hokuto_alt_needs_provider" -a "unmanaged (__hokuto_get_installed_packages)" -d "Alternative Owner"

    complete -c $prog -n "__fish_seen_subcommand_from manifest m size" -a "(__hokuto_get_installed_packages)" -d "Installed Package"

    complete -c $prog -n "__fish_seen_subcommand_from unmanaged" -l checksums -d "Also check installed manifest checksums"
    complete -c $prog -n "__fish_seen_subcommand_from unmanaged" -l backup -d "Create a tar.zst backup from selected files"
    complete -c $prog -n "__fish_seen_subcommand_from unmanaged" -l restore -d "Restore selected files from a tar.zst backup"
    complete -c $prog -n "__fish_seen_subcommand_from unmanaged" -l add -d "Add a file or directory to backup selection"

    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l sources -d "Remove cached sources"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l bins -d "Remove built binary packages"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l orphans -d "Check and remove orphans"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l kernel -d "Remove old kernels and related modules"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l tmp -d "Remove temporary build files"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l all -d "Clean sources, bins and orphans"

    complete -c $prog -n "__fish_seen_subcommand_from upload" -l cleanup -d "Remove older versions on remote"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l cleanup-all -d "Remove all older versions on remote without prompting"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l reindex -d "Regenerate remote index"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l sync -d "Upload all missing local files"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l prompt -d "Prompt for each file"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l syncdb -d "Upload global package database"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l delete -d "Delete remote files"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l copy-from-r2 -d "Migrate from Cloudflare R2"

    complete -c $prog -n "__fish_seen_subcommand_from depends" -s r -l reverse -d "Show reverse dependencies"
    complete -c $prog -n "__fish_seen_subcommand_from depends" -a "(__hokuto_get_install_packages)" -d "Available Package"

    complete -c $prog -n "__fish_seen_subcommand_from meta" -s e -d "Edit metadata"
    complete -c $prog -n "__fish_seen_subcommand_from meta" -o db -d "Generate global package database"
    complete -c $prog -n "__fish_seen_subcommand_from meta" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    complete -c $prog -n "__fish_seen_subcommand_from search s" -l tag -d "Search by package tag"
    complete -c $prog -n "__fish_seen_subcommand_from search s" -l strict -d "Search exact package names"

    complete -c $prog -n "__fish_seen_subcommand_from cross-sync" -l native -d "Identify missing native packages"
    complete -c $prog -n "__fish_seen_subcommand_from cross-sync" -s j -d "Number of parallel jobs"
    complete -c $prog -n "__fish_seen_subcommand_from cross-sync" -s i -d "Install after build"

    set -l blacklist_commands list remove clear
    complete -c $prog -n "__fish_seen_subcommand_from blacklist; and not __fish_seen_subcommand_from $blacklist_commands" -a list -d "List the blacklisted packages"
    complete -c $prog -n "__fish_seen_subcommand_from blacklist; and not __fish_seen_subcommand_from $blacklist_commands" -a remove -d "Let packages build again"
    complete -c $prog -n "__fish_seen_subcommand_from blacklist; and not __fish_seen_subcommand_from $blacklist_commands" -a clear -d "Empty the blacklist"
    complete -c $prog -n "__fish_seen_subcommand_from blacklist; and __fish_seen_subcommand_from remove" -a "(__hokuto_blacklisted)" -d Blacklisted
    complete -c $prog -n "__fish_seen_subcommand_from blacklist; and __fish_seen_subcommand_from remove" -o arch -x -a "native aarch64" -d "Only this architecture's entry"

    set -l python_rebuild_commands status list check confirm cancel
    complete -c $prog -n "__fish_seen_subcommand_from python-rebuild; and not __fish_seen_subcommand_from $python_rebuild_commands" -a status -d "Show the held upgrade and the last check"
    complete -c $prog -n "__fish_seen_subcommand_from python-rebuild; and not __fish_seen_subcommand_from $python_rebuild_commands" -a list -d "List the packages the upgrade rebuilds"
    complete -c $prog -n "__fish_seen_subcommand_from python-rebuild; and not __fish_seen_subcommand_from $python_rebuild_commands" -a check -d "Test-build them against the new python"
    complete -c $prog -n "__fish_seen_subcommand_from python-rebuild; and not __fish_seen_subcommand_from $python_rebuild_commands" -a confirm -d "Bump them and release python"
    complete -c $prog -n "__fish_seen_subcommand_from python-rebuild; and not __fish_seen_subcommand_from $python_rebuild_commands" -a cancel -d "Drop the hold"
    complete -c $prog -n "__fish_seen_subcommand_from python-rebuild; and __fish_seen_subcommand_from confirm" -l force -d "Confirm without a passed check"

    set -l nobuild_commands list add remove clear
    complete -c $prog -n "__fish_seen_subcommand_from nobuild; and not __fish_seen_subcommand_from $nobuild_commands" -a list -d "List the no-build list"
    complete -c $prog -n "__fish_seen_subcommand_from nobuild; and not __fish_seen_subcommand_from $nobuild_commands" -a add -d "Never build these packages"
    complete -c $prog -n "__fish_seen_subcommand_from nobuild; and not __fish_seen_subcommand_from $nobuild_commands" -a remove -d "Build these packages again"
    complete -c $prog -n "__fish_seen_subcommand_from nobuild; and not __fish_seen_subcommand_from $nobuild_commands" -a clear -d "Empty the no-build list"
    complete -c $prog -n "__fish_seen_subcommand_from nobuild" -o cross -d "Cross builds (cross-sync)"
    complete -c $prog -n "__fish_seen_subcommand_from nobuild" -o native -d "Native builds (bump, rebuild)"
    complete -c $prog -n "__fish_seen_subcommand_from nobuild; and __fish_seen_subcommand_from remove" -a "(__hokuto_nobuild_listed)" -d "On the no-build list"
    complete -c $prog -n "__fish_seen_subcommand_from nobuild; and __fish_seen_subcommand_from add" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    complete -c $prog -n "__fish_seen_subcommand_from keys" -l sync -d "Update remote keyring from local"
    complete -c $prog -n "__fish_seen_subcommand_from sign-file" -a "(__fish_complete_path)" -d "File to sign"
    complete -c $prog -n "__fish_seen_subcommand_from find f" -d "Search query"
    complete -c $prog -n "__fish_seen_subcommand_from chroot bootstrap" -a "(__fish_complete_directories)"
end
