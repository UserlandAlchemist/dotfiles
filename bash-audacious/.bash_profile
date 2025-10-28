# ~/.bash_profile — ensures ssh-agent is running but adds no keys

# Source .bashrc if interactive
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Start ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)" >/dev/null
fi

# Auto-start sway on the first virtual terminal (tty1) if we're not already
# in a Wayland or X session. This is what makes autologin drop us straight
# into the compositor.
if [ "$(hostname)" = "audacious" ] && [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
