# Helper function to extract package names from HOKUTO_PATH repositories
function __hokuto_get_repo_packages
    set -l repo_paths
    
    # 1. Parse /etc/hokuto.conf if it exists
    if test -f /etc/hokuto.conf
        # Extract the line starting with HOKUTO_PATH=
        set -l config_line (grep "^HOKUTO_PATH=" /etc/hokuto.conf)
        
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
            find $path -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null
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
set -l hokuto_commands install i build b uninstall r update u list ls checksum c version new n edit e bootstrap chroot cleanup find f manifest m bump

for prog in $prog_names
    # 1. Disable default file completion
    complete -c $prog -f

    # 2. Autocomplete subcommands (only if no subcommand has been typed yet)
    complete -c $prog -n "not __fish_seen_subcommand_from $hokuto_commands" -a "$hokuto_commands"

    # 3. Logic for 'install' (and 'i')
    # Displays 'package.tar.zst (cross)' but inserts the full /var/cache/... path
    complete -c $prog -n "__fish_seen_subcommand_from install i" -a "(
        set -l cache_root '/var/cache/hokuto/bin/'
        for file in \$cache_root{,generic/,cross/}*.tar.zst
            if test -f \$file
                # Get just the filename
                set -l name (basename \$file)
                # Determine category for the description
                set -l desc 'Binary Cache'
                if string match -q '*/generic/*' \$file; set desc 'Generic'; end
                if string match -q '*/cross/*' \$file; set desc 'Cross'; end
                
                # Output 'Full_Path\tDescription'
                echo -e \"\$file\\t\$desc\"
            end
        end
    )"

    # 4. Logic for 'build' (and 'b')
    # Offers package names found in the repositories defined in /etc/hokuto.conf
    complete -c $prog -n "__fish_seen_subcommand_from build b" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"

    # 5. Logic for 'edit' (and 'e')
    # Offers package names found in the repositories defined in /etc/hokuto.conf
    complete -c $prog -n "__fish_seen_subcommand_from edit e" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"

    # 6. Logic for 'cd'
    # Offers package names found in the repositories defined in /etc/hokuto.conf
    complete -c $prog -n "__fish_seen_subcommand_from cd" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"

    # 7. Logic for 'uninstall' (and 'r')
    # Offers package names found in /var/db/hokuto/installed/
    complete -c $prog -n "__fish_seen_subcommand_from uninstall r" \
        -a "(__hokuto_get_installed_packages)" \
        -d "Installed Package"

    # 8. Logic for 'manifest' (and 'm')
    # Offers package names found in /var/db/hokuto/installed/
    complete -c $prog -n "__fish_seen_subcommand_from manifest m" \
        -a "(__hokuto_get_installed_packages)" \
        -d "Installed Package"

    # 9. Logic for 'bump'
    # Offers package names found in the repositories defined in /etc/hokuto.conf
    complete -c $prog -n "__fish_seen_subcommand_from bump" \
        -a "(__hokuto_get_repo_packages)" \
        -d "Repository Package"

end
