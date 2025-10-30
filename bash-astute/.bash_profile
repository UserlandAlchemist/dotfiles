# ~/.bash_profile — ensures ssh-agent is running but adds no keys

# Source .bashrc if interactive
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# ZFS login check (absolute path so SSH logins always see it)
if [ -x "$HOME/.local/bin/check-zfs.sh" ]; then
    "$HOME/.local/bin/check-zfs.sh"
fi
