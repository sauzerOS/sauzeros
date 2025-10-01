set -gx CFLAGS "-march=native -O2 -pipe -fomit-frame-pointer"
set -gx CXXFLAGS $CFLAGS
set -gx MAKEFLAGS "-j$(nproc)"
set -gx XZ_OPT "-T0 -M 90%"
set -gx EDITOR nano
set -gx fish_user_paths /usr/local/bin /opt/cuda/bin $fish_user_paths
