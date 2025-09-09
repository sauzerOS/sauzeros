export CFLAGS="-march=native -mtune=native -O2 -pipe -fomit-frame-pointer"
export CXXFLAGS=$CFLAGS
export MAKEFLAGS="-j$(($(nproc)+2))"
export XZ_OPT="-T0 -M 90%"
export $(cat /etc/locale.conf)
export EDITOR=nano
alias ls='ls --color'
alias grep='grep --color=auto'
export KISS_PATH=/repo/no_updates:/repo/sauzeros/core:/repo/sauzeros/extra
