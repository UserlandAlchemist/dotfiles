# root-system-audacious

General system configuration fixes for Audacious (minimal Debian install).

## Purpose

This package contains system-level configuration overrides that don't fit into more specific packages. These are fixes for Debian defaults that assume a full install but break in minimal debootstrap environments.

## Contents

### journald configuration workaround

**File**: `etc/systemd/journald.conf.d/syslog.conf`

**Purpose**: Fix syslog forwarding + work around persistent storage failure.

**Background**:
1. Debian's default enables `ForwardToSyslog=yes` which assumes rsyslog is installed. In our minimal debootstrap, rsyslog is not present, causing journald wedging.
2. More critically: persistent storage (`Storage=auto` or `Storage=persistent`) **silently fails** at boot - journald creates no system journal in `/var/log/journal/` and captures zero system-level logs until manually restarted. Even with `After=var.mount`, persistent mode fails.

**Workaround**: Use `Storage=volatile` to write logs to `/run/log/journal/` (RAM). This works perfectly and provides complete boot logs with debug output. Logs are lost on reboot, but this is better than having NO system logs at all.

**Status**: Temporary workaround. Root cause of persistent storage failure under investigation (possibly filesystem permissions, ZFS ACLs, or deeper issues with `/var` writes at boot time).

### journald /var mount dependency (unsuccessful)

**File**: `etc/systemd/system/systemd-journald.service.d/wait-for-var.conf`

**Purpose**: Attempted fix - ensure journald waits for `/var` mount before starting.

**Background**: `/var` is on separate ZFS dataset (`rpool/VAR`). Hypothesis was journald started before `/var` ready.

**Result**: Adding `After=var.mount` did not fix persistent storage failure. Journald still creates no system journal even when starting after `/var` is mounted. Issue runs deeper than timing/dependencies.

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

- Journald wedging after boot (40min journal blackout from ForwardToSyslog)
- Journald failing to capture system logs when /var on separate ZFS dataset
- System units symlinking to /home failing to load before /home mounts
- Debian expecting rsyslog in standard server installs

## Related packages

- `root-backup-audacious` — Backup systemd units
- `root-efisync-audacious` — EFI sync systemd units
- `root-power-audacious` — Power management systemd units
- `root-network-audacious` — Network configuration
