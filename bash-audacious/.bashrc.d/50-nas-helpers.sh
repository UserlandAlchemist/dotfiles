# NAS mount/unmount helpers
# Provides commands for managing the Astute NAS mount

nas-open() {
    systemctl --user start astute-nas.service || return 1
    cd /srv/astute || return 1
}

nas-close() {
    # Ensure we are not inside the mount
    if pwd -P | grep -q '^/srv/astute'; then
        cd ~ || return 1
    fi

    systemctl --user stop astute-nas.service
}
