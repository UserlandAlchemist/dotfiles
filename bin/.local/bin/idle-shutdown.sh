#!/bin/bash
set -euo pipefail

CPU_THRESHOLD=80          # % busy across all cores
NET_WINDOW_SEC=5          # how long we sample RX
NET_RATE_LIMIT_Bps=5120   # ~5 KB/s

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

# 1. borg running?
if pgrep -fa borg >/dev/null 2>&1; then
    log "abort: borg activity detected"
    exit 0
fi

# 2. audio playing?
if audio_active_alsa; then
    log "abort: audio playback active (ALSA RUNNING)"
    exit 0
fi

# 3. obvious long-running jobs?
if pgrep -faE 'rsync|wget|curl|aria2c|dd|apt|dpkg|make|gcc|clang|qemu|virt|zfs' >/dev/null 2>&1; then
    log "abort: long-running job detected"
    exit 0
fi

# 4. remote interactive sessions?
if who | grep -q 'pts/'; then
    log "abort: remote session active"
    exit 0
fi

# 5. network activity test (download in progress?)
read_rx_bytes_all() {
    # Sum RX across ALL non-loopback interfaces from /proc/net/dev
    # Field layout in /proc/net/dev:
    # Inter-|   Receive                                                | Transmit
    #  face | bytes packets errs drop fifo frame compressed multicast | bytes ...
    #
    # We want Receive bytes (1st number after the interface name).
    #
    # We'll:
    #   - trim interface name colon
    #   - skip "lo"
    #   - sum all RX bytes
    awk -F'[: ]+' '
        $1 != "" && $1 != "lo" {
            # After splitting by colon/space:
            # $1 = iface name
            # $2 = RX bytes
            rx_total += $2
        }
        END { print rx_total+0 }
    ' /proc/net/dev
}

rx_start=$(read_rx_bytes_all)
sleep "$NET_WINDOW_SEC"
rx_end=$(read_rx_bytes_all)

rx_delta=$(( rx_end - rx_start ))
rx_rate=$(( rx_delta / NET_WINDOW_SEC ))   # bytes/sec

log "net: rx_rate=${rx_rate}Bps (threshold ${NET_RATE_LIMIT_Bps}Bps)"
if [ "$rx_rate" -ge "$NET_RATE_LIMIT_Bps" ]; then
    log "abort: network busy (probable download)"
    exit 0
fi

# 6. CPU busy?
read _ u1 n1 s1 i1 io1 irq1 siq1 st1 _ < /proc/stat
sleep 1
read _ u2 n2 s2 i2 io2 irq2 siq2 st2 _ < /proc/stat

t1=$((u1+n1+s1+i1+io1+irq1+siq1+st1))
t2=$((u2+n2+s2+i2+io2+irq2+siq2+st2))

delta_total=$((t2 - t1))
delta_idle=$(((i2+io2) - (i1+io1)))

if [ "$delta_total" -le 0 ]; then
    log "abort: delta_total <= 0 (weird CPU sample)"
    exit 0
fi

busy_pct=$((100 * (delta_total - delta_idle) / delta_total))
log "cpu: busy_pct=${busy_pct}% (threshold ${CPU_THRESHOLD}%)"
if [ "$busy_pct" -ge "$CPU_THRESHOLD" ]; then
    log "abort: CPU busy (${busy_pct}%)"
    exit 0
fi

# 7. all checks passed, shut down
log "OK: powering off due to idle timeout"
systemctl poweroff
