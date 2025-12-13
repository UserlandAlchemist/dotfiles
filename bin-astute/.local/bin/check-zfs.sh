#!/bin/bash
# check-zfs.sh — warn at login if main pool is not ready (imported + encrypted datasets unlocked + mounted)

POOL="ironwolf"

warn() {
    echo -e "\033[1;33m⚠️  $1\033[0m"
    [ -n "$2" ] && echo -e "   $2"
    echo
}

# 0) If the ZFS userspace tools aren't installed, we cannot check anything
command -v zpool >/dev/null 2>&1 || { warn "ZFS tools not available (zfsutils-linux not installed?)" ""; exit 0; }

# 1) ZFS kernel module present?
if ! lsmod | awk '{print $1}' | grep -qx "zfs"; then
    warn "ZFS kernel module is not loaded." \
         "Likely kernel upgrade without zfs-dkms build for: \033[1m$(uname -r)\033[0m
   Remedy (typical): \033[1msudo apt install linux-headers-$(uname -r) zfs-dkms && sudo dkms autoinstall\033[0m"
    exit 0
fi

# 2) Pool imported?
if ! zpool list -H "$POOL" >/dev/null 2>&1; then
    warn "ZFS pool '$POOL' is not imported." \
         "Bring online with: \033[1msudo zpool import -a && sudo zfs load-key -a && sudo zfs mount -a\033[0m"
    exit 0
fi

# 3) Encrypted datasets unlocked?
# Check only datasets under this pool where encryption is enabled.
LOCKED=$(
    zfs get -H -o name,value encryption,keystatus -r "$POOL" 2>/dev/null \
    | awk '
        NR%2==1 { name=$1; enc=$2 }
        NR%2==0 { ks=$2; if (enc != "off" && ks != "available") print name }
    '
)

if [ -n "$LOCKED" ]; then
    warn "Encrypted datasets are locked (expected after power loss)." \
         "Unlock and mount with: \033[1msudo zfs load-key -a && sudo zfs mount -a\033[0m
   Locked:
$(echo "$LOCKED" | sed 's/^/     - /')"
    exit 0
fi

# 4) Ensure datasets are mounted (keys may be loaded but mounts can still be missing)
UNMOUNTED=$(
    zfs get -H -o name,value mounted -r "$POOL" 2>/dev/null \
    | awk '$2 == "no" { print $1 }'
)

# Only warn if any unmounted datasets exist under the pool (excluding the pool itself which will be "yes")
if echo "$UNMOUNTED" | grep -q "^${POOL}/"; then
    warn "Some datasets are not mounted." \
         "Try: \033[1msudo zfs mount -a\033[0m
   Unmounted:
$(echo "$UNMOUNTED" | grep "^${POOL}/" | sed 's/^/     - /')"
fi

