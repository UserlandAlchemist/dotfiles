if [ "$(hostname)" = "audacious" ] && [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland
    systemctl --user import-environment XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
    exec sway
fi
