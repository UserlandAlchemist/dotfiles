# ~/.bash_profile — ensures ssh-agent is running but adds no keys

# Source .bashrc if interactive
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Start ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)" >/dev/null
fi
