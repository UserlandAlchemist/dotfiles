#!/bin/bash
set -euo pipefail

CPU_THRESHOLD=80          # % busy across all cores
NET_WINDOW_SEC=5          # how long we sample RX
NET_RATE_LIMIT_Bps=5120   # ~5 KB/s
RECHECK_INTERVAL_SEC=300  # 5 minutes between retries

log() {
    logger -t idle-shutdown "$1"
}

audio_active_alsa() {
    # return 0 if any PCM device is currently RUNNING (i.e. actually playing)
    # return 1 otherwise
    if grep -q "state: RUNNING" /proc/asound/card*/pcm*/sub*/status 2>/dev/null; then
        return 0
    fi
    return 1
}


network_rx_rate_busy() {
    # returns 0 if network is "busy enough that we shouldn't power off"
    # returns 1 if network is quiet

    read_rx_bytes_all() {
        # Sum RX bytes for all non-lo interfaces
        awk -F'[: ]+' '
            NR>2 && $1 != "lo" {
                sum += $(NF-7)
            }
            END { print sum+0 }
        ' /proc/net/dev
    }

    local start end delta rate
    start=$(read_rx_bytes_all)
    sleep "$NET_WINDOW_SEC"
    end=$(read_rx_bytes_all)

    delta=$(( end - start ))
    rate=$(( delta / NET_WINDOW_SEC ))

    if (( rate >= NET_RATE_LIMIT_Bps )); then
        return 0  # busy
    else
        return 1  # quiet
    fi
}

cpu_busy() {
    # returns 0 if CPU is busy (>= threshold), 1 otherwise

    # read two snapshots of /proc/stat 1s apart
    local cpu1 cpu2
    cpu1=$(grep '^cpu ' /proc/stat)
    sleep 1
    cpu2=$(grep '^cpu ' /proc/stat)

    # fields: cpu user nice system idle iowait irq softirq steal ...
    # shellcheck disable=SC2206
    local a1=($cpu1)
    # shellcheck disable=SC2206
    local a2=($cpu2)

    # strip leading "cpu"
    local u1 n1 s1 i1 w1 q1 sq1 st1
    local u2 n2 s2 i2 w2 q2 sq2 st2
    read u1 n1 s1 i1 w1 q1 sq1 st1 <<<"${a1[@]:1:8}"
    read u2 n2 s2 i2 w2 q2 sq2 st2 <<<"${a2[@]:1:8}"

    local total1=$((u1+n1+s1+i1+w1+q1+sq1+st1))
    local total2=$((u2+n2+s2+i2+w2+q2+sq2+st2))
    local idle1=$((i1+w1))
    local idle2=$((i2+w2))

    local dtotal=$((total2-total1))
    local didle=$((idle2-idle1))
    local dbusy=$((dtotal-didle))

    # avoid divide-by-zero
    if (( dtotal == 0 )); then
        return 1
    fi

    local busy_pct=$(( 100 * dbusy / dtotal ))

    if (( busy_pct >= CPU_THRESHOLD )); then
        return 0  # busy
    else
        return 1  # not busy
    fi
}

user_is_back() {
    # Heuristic: if any active output has DPMS on again, assume the user woke the machine.
    # Requires jq.
    if swaymsg -t get_outputs \
        | jq -e 'map(select(.active == true and .dpms == true)) | length > 0' >/dev/null 2>&1
    then
        return 0  # user is back / screens on
    else
        return 1  # still idle / screens dark
    fi
}

safe_to_poweroff_now() {
    # 1. user returned?
    if user_is_back; then
        log "ABORT: user is back (outputs are on)"
        return 1
    fi

    # 2. backups (borg) etc.
    if pgrep -fa borg >/dev/null; then
        log "ABORT: borg running"
        return 1
    fi

    # 3. audio playing?
    if audio_active_alsa; then
        log "ABORT: audio active"
        return 1
    fi

    # 4. long-running jobs?
    if pgrep -faE 'rsync|wget|curl|aria2c|dd|apt|dpkg|make|gcc|clang|qemu|virt|zfs' >/dev/null; then
        log "ABORT: long-running job found"
        return 1
    fi

    # 5. remote/pts sessions?
    if who | grep -q 'pts/'; then
        log "ABORT: remote session detected"
        return 1
    fi

    # 6. network busy?
    if network_rx_rate_busy; then
        log "ABORT: network busy"
        return 1
    fi

    # 7. cpu busy?
    if cpu_busy; then
        log "ABORT: CPU busy"
        return 1
    fi

    return 0
}

main() {
    while true; do
        if safe_to_poweroff_now; then
            log "OK: powering off due to sustained idle"
            systemctl poweroff
            exit 0
        fi

        # Not safe yet, sleep and try again.
        sleep "$RECHECK_INTERVAL_SEC"
    done
}

main
