# ~/.bash_profile — ensures ssh-agent is running but adds no keys

# Source .bashrc if interactive
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Check ZFS pool state at login
if command -v ~/.local/bin/check-zfs.sh >/dev/null 2>&1; then
    check-zfs.sh
fi
