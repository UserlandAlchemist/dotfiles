# shellcheck shell=bash
PROMPT_COMMAND='history -a; history -c; history -r'

# shellcheck source=/dev/null
. "$HOME/.local/bin/env"

export SSH_ASKPASS_REQUIRE=never
export GIT_TERMINAL_PROMPT=1
unset SSH_ASKPASS
unset GIT_ASKPASS

case "$TERM" in
*foot*)
	debian_chroot=${debian_chroot:-}
	PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
	PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
	;;
esac
