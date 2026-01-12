# shellcheck shell=bash
debian_chroot=${debian_chroot:-}
PS1='${debian_chroot:+($debian_chroot)}\[\033[1;36m\]\u@\[\033[1;31m\]\h\[\033[00m\]:\[\033[1;34m\]\w\[\033[00m\]\$ '

case "$TERM" in
xterm* | rxvt* | foot*)
	PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
	;;
esac
