# SSH connectivity helpers
# Provides smart wake-on-demand SSH functions for remote hosts

ssh-astute() {
    local host="astute"
    local mac="60:45:cb:9b:ab:3b"

    # Quick check if already reachable (short timeout for speed)
    if ssh -o BatchMode=yes -o ConnectTimeout=2 "${host}" true 2>/dev/null; then
        logger -t astute-ssh "${host} already reachable, connecting"
        ssh -A "${host}"
        return
    fi

    # Host is down, send WOL
    logger -t astute-ssh "Sending WOL to ${host}"
    wakeonlan "${mac}"

    echo "Waiting for ${host} to wake up..."

    # Wait loop with longer timeout (host is waking from suspend)
    for i in $(seq 1 30); do
        # Use 3-second timeout after WOL (SSH might be slower to start)
        if ssh -o BatchMode=yes -o ConnectTimeout=3 "${host}" true 2>/dev/null; then
            echo "${host} is up after ${i} seconds"
            logger -t astute-ssh "${host} responded after ${i}s"
            ssh -A "${host}"
            return
        fi
        sleep 1
    done

    echo "Warning: ${host} did not respond within 30 seconds"
    logger -t astute-ssh "WARNING: ${host} timeout after WOL"

    # One final attempt with full timeout
    echo "Attempting connection anyway..."
    ssh -A "${host}"
}
