# root-journald-audacious

General system configuration fixes for Audacious (minimal Debian install).

## Purpose

This package contains system-level configuration overrides that don't fit into more specific packages. These are fixes for Debian defaults that assume a full install but break in minimal debootstrap environments.

## Contents

### journald configuration (persistent storage retry)

**File**: `etc/systemd/journald.conf.d/syslog.conf`

**Purpose**: Fix syslog forwarding + restore persistent storage at boot.

**Background**:
1. Debian's default enables `ForwardToSyslog=yes` which assumes rsyslog is installed. In our minimal debootstrap, rsyslog is not present, causing journald wedging.
2. Persistent storage previously failed at boot when `/var` was not mounted yet (ZFS datasets mount later) and `/var/log/journal` was not ready. Journald silently failed to create the system journal and captured zero system logs until manually restarted.

**Fix**: Order journald after ZFS mounts and require the `/var` mount path
via `RequiresMountsFor=/var`. This avoids a hard dependency on a nonexistent
`var.mount` unit and ensures journald attaches to the persistent journal.

**Status**: Working. Persistent logs restored. Root cause was a hard
`Requires=var.mount` on journald: ZFS mounts do not create `var.mount`, so
the journald socket failed to start at boot. Replaced with
`RequiresMountsFor=/var` and directory preparation.

### journald /var mount dependency + preparation

**File**: `etc/systemd/system/systemd-journald.service.d/wait-for-var.conf`

**Purpose**: Ensure journald waits for `/var` and ZFS mounts.

**Background**: `/var` is on separate ZFS dataset (`rpool/VAR`). Hypothesis was journald started before `/var` ready.

**Result**: New approach adds a prepare unit to create the directory before journald starts.

## Deploy

Run the install script as root:

```bash
sudo /home/alchemist/dotfiles/root-journald-audacious/install.sh
```

The script will:
1. Install systemd configs as real files (avoiding /home symlink issues at boot)
2. Stow remaining package files (if any)
3. Reload systemd daemon
4. Prompt to restart journald

## Related Issues

- Journald wedging after boot (40min journal blackout from ForwardToSyslog)
- Journald failing to capture system logs when /var on separate ZFS dataset
- System units symlinking to /home failing to load before /home mounts
- Debian expecting rsyslog in standard server installs

## Related packages

- `root-backup-audacious` — Backup systemd units
- `root-efisync-audacious` — EFI sync systemd units
- `root-power-audacious` — Power management systemd units
- `root-network-audacious` — Network configuration
