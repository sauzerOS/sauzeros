# fish completion for hokuto-builder

function __hokuto_builder_repo_packages
    set -l raw_path $HOKUTO_PATH
    if test -z "$raw_path"; and test -f /etc/hokuto/hokuto.conf
        set -l config_line (grep "^HOKUTO_PATH=" /etc/hokuto/hokuto.conf)
        if test -n "$config_line"
            set raw_path (string trim -c '"\'' (string split -m1 "=" $config_line)[2])
        end
    end
    for path in (string split ":" -- $raw_path)
        if test -d $path
            find $path -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf "%f\n" 2>/dev/null
        end
    end
end

set -l commands create bump build rebuild cross-sync cycle run shell update destroy help

complete -c hokuto-builder -f
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a create -d "Create the container (once)"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a bump -d "hokuto bump --auto --build in the container"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a build -d "Build packages, then upload --sync"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a rebuild -d "Build and upload recipes ahead of the mirror"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a cross-sync -d "hokuto cross-sync, then upload --sync"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a cycle -d "One unattended bump, rebuild and cross-sync round"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a run -d "Run a command in the container"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a shell -d "Interactive shell in the container"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a update -d "Update the container's own packages"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a destroy -d "Delete the container"
complete -c hokuto-builder -n "not __fish_seen_subcommand_from $commands" -a help -d "Show usage"

complete -c hokuto-builder -n "__fish_seen_subcommand_from bump" -o y -d "Bump and build everything unattended"

complete -c hokuto-builder -n "__fish_seen_subcommand_from build" -a "(__hokuto_builder_repo_packages)" -d Package
complete -c hokuto-builder -n "__fish_seen_subcommand_from build rebuild cross-sync" -l no-upload -d "Skip upload --sync"
complete -c hokuto-builder -n "__fish_seen_subcommand_from build rebuild" -s j -l parallel -x -d "Parallel build jobs"
complete -c hokuto-builder -n "__fish_seen_subcommand_from build rebuild" -s v -l verbose -d "Verbose build output"
complete -c hokuto-builder -n "__fish_seen_subcommand_from cross-sync" -o system -d "Sync the aarch64-* cross-system packages"
complete -c hokuto-builder -n "__fish_seen_subcommand_from rebuild cross-sync" -s y -d "Build without asking"
complete -c hokuto-builder -n "__fish_seen_subcommand_from cross-sync" -s j -x -d "Parallel build jobs"

complete -c hokuto-builder -n "__fish_seen_subcommand_from run" -F -a "(__fish_complete_subcommand --fcs-skip=2)"
