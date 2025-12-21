#!/bin/sh
set -eu

case "${SSH_ORIGINAL_COMMAND:-}" in
  start)
    systemctl start nas-inhibit.service
    ;;
  stop)
    systemctl stop nas-inhibit.service
    ;;
  *)
    logger -t astute-nas-inhibit "Rejected command: ${SSH_ORIGINAL_COMMAND:-<none>}"
    exit 1
    ;;
esac

