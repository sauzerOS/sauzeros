# Helper function to extract package names from HOKUTO_PATH repositories
function __hokuto_get_repo_packages
    set -l repo_paths
    
    # 1. Parse /etc/hokuto/hokuto.conf if it exists
    if test -f /etc/hokuto/hokuto.conf
        # Extract the line starting with HOKUTO_PATH=
        set -l config_line (grep "^HOKUTO_PATH=" /etc/hokuto/hokuto.conf)
        
        if test -n "$config_line"
            # Split by '=' to get the value, then trim quotes, then split by ':'
            set -l raw_path (string split -m1 "=" $config_line)[2]
            set raw_path (string trim -c '"\'' $raw_path)
            set repo_paths (string split ":" $raw_path)
        end
    end

    # 2. Iterate through paths and list subdirectories (packages)
    for path in $repo_paths
        if test -d $path
            # Find directories, max depth 1, print only the name
            find $path -mindepth 1 -maxdepth 1 -type d -not -name '.git' -printf "%f\n" 2>/dev/null
        end
    end
end

# NEW: Helper function to extract installed package names
function __hokuto_get_installed_packages
    set -l install_path "/var/db/hokuto/installed/"
    if test -d $install_path
        # Find directories, max depth 1, print only the name
        find $install_path -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null
    end
end

# Define the list of binaries to apply completion to
set -l prog_names hk hokuto

# Define main subcommands
set -l hokuto_commands install i build b uninstall remove r update u list ls checksum c version new n edit e bootstrap chroot cleanup find f manifest m bump meta log python-rebuild alt settings init-repos upload depends search sync cross-sync cd keys

for prog in $prog_names
    # 1. Disable default file completion
    complete -c $prog -f

    # 2. Autocomplete subcommands (only if no subcommand has been typed yet)
    complete -c $prog -n "not __fish_seen_subcommand_from $hokuto_commands" -a "$hokuto_commands"

    # 3. Logic for 'install' (and 'i')
    complete -c $prog -n "__fish_seen_subcommand_from install i" -s y -l yes -d "Assume yes to all prompts"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l force -d "Install even if already installed"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l nodeps -d "Ignore dependencies"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -s g -l generic -d "Install generic variant"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l arm64 -d "Install arm64 version"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l x86_64 -d "Install x86_64 version"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l multi -d "Install multilib variants"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l remote -d "Install from remote mirror"
    complete -c $prog -n "__fish_seen_subcommand_from install i" -l fast -d "Enable fast install mode"
    
    # Displays 'package.tar.zst (cross)' but inserts the full /var/cache/... path
    complete -c $prog -n "__fish_seen_subcommand_from install i" -a '(
        set -l cache_root "/var/cache/hokuto/bin/"
        for file in $cache_root*.tar.zst
            if test -f $file
                set -l name (basename $file)
                echo -e "$file\tBinary Cache"
            end
        end
    )'

    # Extension: also offer repository packages
    complete -c $prog -n "__fish_seen_subcommand_from install i" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"

    # 4. Logic for 'build' (and 'b')
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s a -d "Automatically install after build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s i -d "Idle build (half cores)"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -o ii -d "Super-idle build (one core)"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s v -l verbose -d "Enable verbose output"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l alldeps -d "Force rebuild of all dependencies"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s r -l rebuilds -d "Enable post-build rebuilds"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l ordered -d "Force ordered build"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l generic -d "Build generic variant"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l cross -d "Cross-compile for target arch"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -l nodeps -d "Skip dependency check"
    complete -c $prog -n "__fish_seen_subcommand_from build b" -s j -l parallel -d "Number of parallel jobs"
    
    complete -c $prog -n "__fish_seen_subcommand_from build b" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"

    # 5. Logic for 'uninstall' (and 'remove' 'r')
    complete -c $prog -n "__fish_seen_subcommand_from uninstall remove r" -s f -l force -d "Force uninstallation"
    complete -c $prog -n "__fish_seen_subcommand_from uninstall remove r" -s y -l yes -d "Assume yes"
    complete -c $prog -n "__fish_seen_subcommand_from uninstall remove r" \
        -a "(__hokuto_get_installed_packages)" \
        -d "Installed Package"

    # 6. Logic for 'update' (and 'u')
    complete -c $prog -n "__fish_seen_subcommand_from update u" -s i -l idle -d "Idle build during update"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -o ii -l superidle -d "Super-idle build during update"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -s v -l verbose -d "Enable verbose output"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -s j -l parallel -d "Number of parallel jobs"
    complete -c $prog -n "__fish_seen_subcommand_from update u" -l remote -d "Check remote mirror only"

    # 7. Logic for 'list' (and 'ls')
    complete -c $prog -n "__fish_seen_subcommand_from list ls" -l remote -d "List remote packages"
    complete -c $prog -n "__fish_seen_subcommand_from list ls" -a "(__hokuto_get_installed_packages)" -d "Installed Package"

    # 8. Logic for 'checksum' (and 'c')
    complete -c $prog -n "__fish_seen_subcommand_from checksum c" -s f -d "Force sources download"
    complete -c $prog -n "__fish_seen_subcommand_from checksum c" -l unpack -d "Unpack sources in build dir"
    complete -c $prog -n "__fish_seen_subcommand_from checksum c" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    # 9. Logic for 'edit' (and 'e')
    complete -c $prog -n "__fish_seen_subcommand_from edit e" -s a -d "Open all build files (sources, build, depends)"
    complete -c $prog -n "__fish_seen_subcommand_from edit e" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"

    # 10. Logic for 'manifest' (and 'm')
    complete -c $prog -n "__fish_seen_subcommand_from manifest m" \
        -a "(__hokuto_get_installed_packages)" \
        -d "Installed Package"

    # 11. Logic for 'cleanup'
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l sources -d "Remove cached sources"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l bins -d "Remove built binary packages"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l orphans -d "Check and remove orphans"
    complete -c $prog -n "__fish_seen_subcommand_from cleanup" -l all -d "Clean sources, bins and orphans"

    # 12. Logic for 'upload'
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l cleanup -d "Remove older versions on remote"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l reindex -d "Regenerate remote index"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l sync -d "Upload all missing local files"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l prompt -d "Prompt for each file"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l syncdb -d "Upload global package database"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l delete -d "Delete package variants from remote"
    complete -c $prog -n "__fish_seen_subcommand_from upload" -l copy-from-r2 -d "Migrate from Cloudflare R2"

    # 13. Logic for 'depends'
    complete -c $prog -n "__fish_seen_subcommand_from depends" -s r -l reverse -d "Show reverse dependencies"
    complete -c $prog -n "__fish_seen_subcommand_from depends" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    # 14. Logic for 'meta'
    complete -c $prog -n "__fish_seen_subcommand_from meta" -s e -d "Edit metadata"
    complete -c $prog -n "__fish_seen_subcommand_from meta" -o db -d "Generate global package database"
    complete -c $prog -n "__fish_seen_subcommand_from meta" -a "(__hokuto_get_repo_packages)" -d "Repository Package"

    # 15. Logic for 'search'
    complete -c $prog -n "__fish_seen_subcommand_from search" -l tag -d "Search by package tag"

    # 16. Logic for 'cross-sync'
    complete -c $prog -n "__fish_seen_subcommand_from cross-sync" -l native -d "Sync native aarch64 packages"

    # 17. Logic for 'keys'
    complete -c $prog -n "__fish_seen_subcommand_from keys" -l sync -d "Update remote keyring from local"

    # 18. Logic for other package-based commands
    complete -c $prog -n "__fish_seen_subcommand_from cd bump alt" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"
    
    complete -c $prog -n "__fish_seen_subcommand_from find f" -d "Search query"
end
