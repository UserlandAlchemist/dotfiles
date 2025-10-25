#!/bin/bash
#
# auto-shutdown.sh
#
# Shutdown the machine if:
#   - user session is idle for longer than IDLE_LIMIT_MIN
#   - CPU load is basically idle
#
# Notes:
# - This is intended to be called periodically by systemd (timer).
# - We assume a single active desktop user (you).
#
IDLE_LIMIT_MIN=15        # how long you must be idle before shutdown
CPU_IDLE_THRESHOLD=85    # percent idle CPU required to consider the box "inactive"
DESKTOP_USER="alchemist"


log() {
    logger -t auto-shutdown "$*"
}

# 0. Ensure the desktop user actually has a logind session
if ! loginctl show-user "$DESKTOP_USER" >/dev/null 2>&1; then
    log "no logind session for $DESKTOP_USER, skipping"
    exit 0
fi


# 1. Is the user idle?
idle_hint=$(loginctl show-user "$DESKTOP_USER" 2>/dev/null | awk -F= '/IdleHint=/{print $2}')
idle_since=$(loginctl show-user "$DESKTOP_USER" 2>/dev/null | awk -F= '/IdleSinceMonotonicUSec=/{print $2}')

if [ "$idle_hint" != "yes" ]; then
    log "user not idle (IdleHint=$idle_hint), skipping"
    exit 0
fi

# how long (µs) since user went idle?
now_usecs=$(awk '{printf "%0.f", $1 * 1000000}' /proc/uptime)
idle_usecs=$(( now_usecs - idle_since ))
idle_needed_usecs=$(( IDLE_LIMIT_MIN * 60 * 1000000 ))

if [ "$idle_usecs" -lt "$idle_needed_usecs" ]; then
    idle_m=$(("$idle_usecs" / 1000000 / 60))
    log "idle ${idle_m}m < ${IDLE_LIMIT_MIN}m, skipping"
    exit 0
fi


# 2. Is CPU mostly idle?
# We'll get aggregate CPU usage over a short sample.
read cpu1 user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 guest1 guestn1 < /proc/stat
sleep 1
read cpu2 user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 guest2 guestn2 < /proc/stat

total1=$((user1+nice1+system1+idle1+iowait1+irq1+softirq1+steal1))
total2=$((user2+nice2+system2+idle2+iowait2+irq2+softirq2+steal2))

total_delta=$((total2-total1))
idle_delta=$((idle2-idle1))

if [ "$total_delta" -le 0 ]; then
    log "weird CPU sample, skipping"
    # weird, but bail safely
    exit 0
fi

idle_pct=$(( 100 * idle_delta / total_delta ))

if [ "$idle_pct" -lt "$CPU_IDLE_THRESHOLD" ]; then
    log "CPU idle ${idle_pct}% < ${CPU_IDLE_THRESHOLD}%, skipping"
    # CPU not idle enough (maybe gaming, compiling, transcoding, etc.)
    exit 0
fi

if pgrep -x borg >/dev/null || pgrep -x rsync >/dev/null || pgrep -x zfs >/dev/null; then
    log "backup (borg) or other important process active, skipping"
    exit 0
fi

# If we got here:
# - You've been idle >= IDLE_LIMIT_MIN
# - CPU is mostly idle
# -> safe to power off
log "system idle >= ${IDLE_LIMIT_MIN}m and CPU idle ${idle_pct}%, powering off"
systemctl poweroff
