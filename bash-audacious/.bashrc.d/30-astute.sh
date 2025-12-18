# astute helpers
# - ssh-astute: wake astute and connect via SSH
# - nas-open: wake astute and enter NAS mount
# - nas-close: unmount the NAS and release the sleep-inhibit lock
_is_astute_nas_mounted() {
    local mount="/srv/astute"
    local want_src="astute:/srv/nas"
    local got

    got="$(findmnt -rn -T "$mount" -o FSTYPE,SOURCE 2>/dev/null || true)"
    # Expect exactly: "nfs4 astute:/srv/nas" (or "nfs astute:/srv/nas" on some systems)
    echo "$got" | grep -Eq '^(nfs4?|nfs)\s+'"${want_src//\//\\/}"'$'
}

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
    local host="astute"
    local mac="60:45:cb:9b:ab:3b"
    local mount="/srv/astute"

    if _is_astute_nas_mounted; then
       echo "NAS already mounted (astute:/srv/nas)"
       cd /srv/astute || return 1
       return 0
    fi
    
    logger -t nas-open "Sending WOL to ${host}"
    wakeonlan "${mac}"

    echo "Waiting for ${host}... to become reachable..."
    for _ in $(seq 1 30); do
        ping -c1 -W1 "${host}" >/dev/null 2>&1 && break
        sleep 1
    done

    if ! ping -c1 -W1 "${host}" >/dev/null 2>&1; then
        echo "Error: ${host} did not become reachable"
        return 1
    fi

    echo "Enabling NAS sleep inhibit on ${host}"
    if ! ssh "${host}" sudo systemctl start nas-inhibit.service; then
        echo "Error: failed to enable inhibit on ${host}"
        return 1
    fi

    echo "Mounting NAS..."
    if ! sudo systemctl start srv-astute.mount; then
        echo "Error: mount failed"
        ssh "${host}" sudo systemctl stop nas-inhibit.service
        return 1
    fi

    if ! mountpoint -q "${mount}"; then
        echo "Error: mount did not become active"
        ssh "${host}" sudo systemctl stop nas-inhibit.service
        return 1
    fi

    cd "${mount}" || return 1
}

nas-close() {
    local host="astute"
    local mount="/srv/astute"

    if mountpoint -q "${mount}"; then
        echo "Unmounting NAS..."
        sudo systemctl stop srv-astute.mount || return 1
    fi

    echo "Releasing NAS sleep inhibit on ${host}"
    ssh "${host}" sudo systemctl stop nas-inhibit.service
}
