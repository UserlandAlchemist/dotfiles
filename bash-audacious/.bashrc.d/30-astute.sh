# astute helpers
# - ssh-astute: wake astute and connect via SSH
# - nas-open: wake astute and enter NAS mount
# - nas-close: unmount the NAS and release the sleep-inhibit lock
ssh-astute() {
    local host="astute"
    local mac="60:45:cb:9b:ab:3b"

    logger -t astute-ssh "Sending WOL to ${host}"
    wakeonlan "${mac}"

    echo "Waiting for ${host} to accept SSH..."
    for _ in $(seq 1 30); do
        if ssh -o BatchMode=yes -o ConnectTimeout=1 "${host}" true 2>/dev/null; then
            exec ssh -A "${host}"
        fi
        sleep 1
    done

    echo "Warning: ${host} did not respond within timeout; attempting SSH anyway"
    exec ssh -A "${host}"
}

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
