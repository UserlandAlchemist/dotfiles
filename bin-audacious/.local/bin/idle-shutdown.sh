#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# idle-shutdown (final, run-tagged)
#
# Triggered ONLY by swayidle after 20 minutes of no user input.
#
# Policy:
# - Media playback (MPRIS or confirmed Jellyfin playback) => abort immediately
# - systemd shutdown inhibitor => abort immediately
# - True idle => shutdown after ~20–30 minutes total
# - CPU/network activity (unattended work) => allow up to 90 minutes, then force shutdown
#
# Design assumptions:
# - Audacious is a Jellyfin CLIENT
# - Jellyfin server is on Astute
# - Remote Jellyfin check is FAIL-OPEN
# - Long critical jobs must use systemd-inhibit
# -------------------------------------------------------------------

CHECK_INTERVAL_SEC=180        # 3 minutes
MEDIA_WINDOW_SEC=1200         # 20 minutes
BUSY_WINDOW_SEC=5400          # 90 minutes
NET_RATE_LIMIT_BPS=100000     # 100 KB/s RX threshold

# Remote Jellyfin (optional, fail-open)
: "${JELLYFIN_CHECK_REMOTE:=1}"
: "${JELLYFIN_SERVER_URL:=http://astute:8096}"
: "${JELLYFIN_TOKEN_FILE:=$HOME/.config/jellyfin/api.token}"

# -------------------------------------------------------------------
# Run identification & logging
# -------------------------------------------------------------------

RUN_ID="$(date +%Y%m%dT%H%M%S)-$$"

log() {
  logger -t idle-shutdown "run=${RUN_ID} $1"
}

decision() {
  # decision "<action>" "<reason>"
  # action: abort | shutdown
  log "DECISION: ${1} (${2})"
}

# -------------------------------------------------------------------
# Inhibitors and activity signals
# -------------------------------------------------------------------

shutdown_inhibited() {
  systemd-inhibit --list 2>/dev/null | grep -qi shutdown
}

borg_backup_running() {
  systemctl is-active --quiet borg-backup.service || \
  systemctl is-active --quiet borg-check.service || \
  systemctl is-active --quiet borg-check-deep.service || \
  systemctl is-active --quiet borg-offsite-audacious.service || \
  systemctl is-active --quiet borg-offsite-check.service || \
  systemctl show -p ActiveState borg-backup.service | grep -q "activating" || \
  systemctl show -p ActiveState borg-check.service | grep -q "activating" || \
  systemctl show -p ActiveState borg-check-deep.service | grep -q "activating" || \
  systemctl show -p ActiveState borg-offsite-audacious.service | grep -q "activating" || \
  systemctl show -p ActiveState borg-offsite-check.service | grep -q "activating"
}

mpris_playing() {
  command -v playerctl >/dev/null || return 1
  playerctl -a status 2>/dev/null | grep -qx Playing
}

jellyfin_remote_playing() {
  [[ "${JELLYFIN_CHECK_REMOTE}" = "1" ]] || return 1
  [[ -r "${JELLYFIN_TOKEN_FILE}" ]] || return 1

  curl -fsS --max-time 2 \
    -H "X-Emby-Token: $(cat "${JELLYFIN_TOKEN_FILE}")" \
    "${JELLYFIN_SERVER_URL}/Sessions" \
  | jq -e '.[]? | select(.NowPlayingItem != null)' >/dev/null
}

cpu_busy() {
  local a b
  read -r _ a < <(grep '^cpu ' /proc/stat)
  sleep 1
  read -r _ b < <(grep '^cpu ' /proc/stat)
  (( ${b%% *} - ${a%% *} > 20 ))
}

network_busy() {
  local start end rate
  start=$(awk -F'[: ]+' 'NR>2 && $1!="lo"{s+=$(NF-7)} END{print s}' /proc/net/dev)
  sleep 1
  end=$(awk -F'[: ]+' 'NR>2 && $1!="lo"{s+=$(NF-7)} END{print s}' /proc/net/dev)
  rate=$(( end - start ))
  log "METRIC: net_rx_bps=${rate}"
  (( rate >= NET_RATE_LIMIT_BPS ))
}

cpu_or_network_busy() {
  cpu_busy || network_busy
}

# -------------------------------------------------------------------
# Phase A — Media / inhibitor window (20 min)
# -------------------------------------------------------------------

phase_media_window() {
  local elapsed=0
  log "PHASE A: media/inhibitor window started"

  while (( elapsed < MEDIA_WINDOW_SEC )); do
    if shutdown_inhibited; then
      decision "abort" "inhibitor"
      exit 0
    fi

    if borg_backup_running; then
      decision "abort" "borg-backup-active"
      exit 0
    fi

    if mpris_playing; then
      decision "abort" "media:mpris"
      exit 0
    fi

    if jellyfin_remote_playing; then
      decision "abort" "media:jellyfin-remote"
      exit 0
    fi

    sleep "${CHECK_INTERVAL_SEC}"
    elapsed=$((elapsed + CHECK_INTERVAL_SEC))
  done
}

# -------------------------------------------------------------------
# Phase B — Unattended work window (90 min)
# -------------------------------------------------------------------

phase_busy_window() {
  local elapsed=0
  log "PHASE B: unattended work window started"

  while (( elapsed < BUSY_WINDOW_SEC )); do
    if shutdown_inhibited; then
      decision "abort" "inhibitor"
      exit 0
    fi

    if borg_backup_running; then
      decision "abort" "borg-backup-active"
      exit 0
    fi

    if mpris_playing; then
      decision "abort" "media:mpris"
      exit 0
    fi

    if jellyfin_remote_playing; then
      decision "abort" "media:jellyfin-remote"
      exit 0
    fi

    if ! cpu_or_network_busy; then
      decision "shutdown" "busy-cleared"
      systemctl poweroff
      exit 0
    fi

    sleep "${CHECK_INTERVAL_SEC}"
    elapsed=$((elapsed + CHECK_INTERVAL_SEC))
  done

  decision "shutdown" "busy-timeout"
  systemctl poweroff
  exit 0
}

# -------------------------------------------------------------------
# Entry point (called by swayidle)
# -------------------------------------------------------------------

main() {
  log "START: idle-shutdown fired by swayidle"

  phase_media_window

  if cpu_or_network_busy; then
    phase_busy_window
  fi

  decision "shutdown" "idle"
  systemctl poweroff
}

main
