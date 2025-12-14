# astute helpers
# - astute-ssh: wake astute and connect via SSH
# - astute-nas: wake astute and enter NAS mount

astute-ssh() {
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

astute-nas() {
    local host="astute"
    local mac="60:45:cb:9b:ab:3b"
    local mount="/srv/astute"
    local ready=0

    logger -t astute-nas "Sending WOL to ${host}"
    wakeonlan "${mac}"

    echo "Waiting for ${host} to advertise NAS exports..."
    for _ in {1..30}; do
        if /usr/sbin/showmount -e "${host}" >/dev/null 2>&1; then
            ready=1
            break
        fi
        sleep 1
    done

    if [ "$ready" -ne 1 ]; then
        echo "Error: ${host} did not advertise NAS exports within timeout"
        echo "Astute may still be waking; try again shortly."
        return 1
    fi

    # Trigger systemd automount explicitly
    if ! ls "${mount}" >/dev/null 2>&1; then
        echo "Error: NAS export is advertised but mount is not yet reachable"
        return 1
    fi

    cd "${mount}" || return 1
}
