#!/bin/bash
# check-zfs.sh — warn at login if main pool is not mounted

POOL="ironwolf"
REQUIRED_DATASETS=(
    "$POOL/nas"
    "$POOL/backups"
)

if ! zpool list -H "$POOL" >/dev/null 2>&1; then
    echo -e "\033[1;33m⚠️  ZFS pool '$POOL' is not imported.\033[0m"
    echo -e "   To unlock and import: \033[1mzfs load-key -a && zpool import -a\033[0m"
    echo
else
    missing=0
    not_mounted=0
    for dataset in "${REQUIRED_DATASETS[@]}"; do
        if ! zfs list -H -o name "$dataset" >/dev/null 2>&1; then
            missing=1
            continue
        fi
        mounted=$(zfs get -H -o value mounted "$dataset" 2>/dev/null || echo "no")
        if [ "$mounted" != "yes" ]; then
            not_mounted=1
        fi
    done

    if [ "$missing" -ne 0 ] || [ "$not_mounted" -ne 0 ]; then
        echo -e "\033[1;33m⚠️  ZFS datasets for '$POOL' are not mounted.\033[0m"
        echo -e "   Try: \033[1mzfs load-key -a && zfs mount -a\033[0m"
        echo
    fi
fi
