#!/bin/sh

# Hold a timed systemd sleep inhibitor for NAS usage
# Default: 30 minutes (1800 seconds)

DURATION="${1:-1800}"

exec systemd-inhibit \
    --what=sleep \
    --who="astute-nas" \
    --why="User actively using NAS" \
    sleep "${DURATION}"

