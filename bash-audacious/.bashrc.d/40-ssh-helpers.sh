# SSH connectivity helpers
# Provides smart wake-on-demand SSH functions for remote hosts

ssh-astute() {
    local host="astute"
    local mac="60:45:cb:9b:ab:3b"

    # Check if already reachable before sending WOL
    if ssh -o BatchMode=yes -o ConnectTimeout=1 "${host}" true 2>/dev/null; then
        logger -t astute-ssh "${host} already reachable, connecting"
        ssh -A "${host}"
        return
    fi

    # Host is down, send WOL
    logger -t astute-ssh "Sending WOL to ${host}"
    wakeonlan "${mac}"

    echo "Waiting for ${host} to accept SSH..."
    for _ in $(seq 1 30); do
        if ssh -o BatchMode=yes -o ConnectTimeout=1 "${host}" true 2>/dev/null; then
            ssh -A "${host}"
            return
        fi
        sleep 1
    done

    echo "Warning: ${host} did not respond within timeout; attempting SSH anyway"
    ssh -A "${host}"
}
