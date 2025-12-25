# root-system-audacious

General system configuration fixes for Audacious (minimal Debian install).

## Purpose

This package contains system-level configuration overrides that don't fit into more specific packages. These are fixes for Debian defaults that assume a full install but break in minimal debootstrap environments.

## Contents

### journald configuration

**File**: `etc/systemd/journald.conf.d/10-no-syslog-forward.conf`

**Purpose**: Disable `ForwardToSyslog` to prevent journald from wedging.

**Background**: Debian's default systemd configuration enables `ForwardToSyslog=yes` (from `/usr/lib/systemd/journald.conf.d/syslog.conf`), which assumes rsyslog is installed. In our minimal debootstrap install, rsyslog is not present. This causes journald to repeatedly try forwarding logs to a non-existent socket, eventually wedging after boot and stopping all journal output for 30-40 minutes until manually restarted.

**Fix**: Override `ForwardToSyslog=no` since we rely solely on journald (no traditional syslog daemon).

## Deploy

Run the install script as root:

```bash
sudo /home/alchemist/dotfiles/root-system-audacious/install.sh
```

The script will:
1. Install systemd configs as real files (avoiding /home symlink issues at boot)
2. Stow remaining package files (if any)
3. Reload systemd daemon
4. Prompt to restart journald

## Related Issues

- Journald wedging after boot (40min journal blackout)
- System units symlinking to /home failing to load before /home mounts
- Debian expecting rsyslog in standard server installs

## Related packages

- `root-backup-audacious` — Backup systemd units
- `root-efisync-audacious` — EFI sync systemd units
- `root-power-audacious` — Power management systemd units
- `root-network-audacious` — Network configuration
