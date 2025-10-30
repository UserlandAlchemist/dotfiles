#!/bin/bash
# check-zfs.sh — warn at login if main pool is not mounted

POOL="ironwolf"

if ! zpool list -H "$POOL" >/dev/null 2>&1; then
    echo -e "\033[1;33m⚠️  ZFS pool '$POOL' is not imported.\033[0m"
    echo -e "   To unlock and import: \033[1mzfs load-key -a && zpool import -a\033[0m"
    echo
elif ! zfs list -H -o name | grep -q "^${POOL}/"; then
    echo -e "\033[1;33m⚠️  ZFS pool '$POOL' imported but datasets not mounted.\033[0m"
    echo -e "   Try: \033[1mzfs mount -a\033[0m"
    echo
fi
