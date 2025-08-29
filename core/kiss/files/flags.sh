export CFLAGS="-march=native -mtune=native -O2 -pipe -fomit-frame-pointer"
export CXXFLAGS=$CFLAGS
export MAKEFLAGS="-j$(($(nproc)+2))"
export KISS_SU=sudo
export KISS_TMPDIR=/tmp
export KISS_COMPRESS=zst
export XZ_OPT="-T0 -M 90%"
export $(cat /etc/locale.conf)
export EDITOR=nano
export KISS_STRIP=0
alias ls='ls --color'
alias grep='grep --color=auto'
