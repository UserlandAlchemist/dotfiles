# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
Also read `AGENTS.md` for contributor guidelines.

## Repository Purpose

This is a personal dotfiles repository for "the Wolfpack" - a small ecosystem of independent Linux machines (audacious, astute, artful, steamdeck) managed using GNU Stow. All hosts run Debian 13 (Trixie) Stable except the Steam Deck. The repository follows a "repo-first" philosophy: plain text configuration, no wrappers or daemons, transparent and understandable systems designed for long-term maintainability and fast recovery.

## Architecture

### Directory Structure and Naming

The repository uses per-host stow packages with a specific naming convention:

**User-level packages** (deployed with `stow <package>`):
- Format: `<tool>-<hostname>/` (e.g., `bash-audacious/`, `sway-audacious/`)
- Install to: `$HOME`
- Examples: `bash-audacious/`, `bin-audacious/`, `emacs-audacious/`, `waybar-audacious/`

**System-level packages** (deployed with `sudo stow --target=/ <package>`):
- Format: `root-<concern>-<hostname>/` OR `root-<hostname>-<concern>/` (inconsistent - being standardized)
- Install to: `/` (system root)
- Examples: `root-power-audacious/`, `root-efisync-audacious/`, `root-backup-audacious/`

**Special cases:**
- `profile-common/` - Shared shell profile deployed first on all hosts
- `docs/<hostname>/` - Per-host documentation (INSTALL, RECOVERY, RESTORE guides)

**IMPORTANT**: There is known inconsistency in `root-*` package naming (some are `root-concern-host`, others are `root-host-concern`). This is acknowledged drift that needs standardization.

### Sudoers File Handling

Sudoers files **cannot** be managed directly via stow due to permissions requirements. Instead:

1. Sudoers rules live at `<package>/etc/sudoers.d/<name>.sudoers` (note `.sudoers` extension)
2. Each package with sudoers rules has an `install.sh` script that:
   - Runs `stow` for regular files
   - Uses `install -o root -g root -m 0440` to copy sudoers files to `/etc/sudoers.d/`
   - Runs `visudo -c` to validate
3. Examples: `root-sudoers-audacious/install.sh`, `root-power-astute/install.sh`

### The Machines

**Audacious** (primary workstation):
- i5-13600KF, 32GB RAM, 7800XT GPU
- ZFS RAID1 root (2×1.8TB NVMe)
- Sway (Wayland) with Amiga-inspired aesthetic
- systemd-boot with Unified Kernel Images (UKI)
- Dual EFI partitions with auto-sync via `efi-sync.path`
- **Power policy**: Fast startup/shutdown, aggressive idle shutdown (no suspend - unreliable on this hardware)
- IP: 192.168.1.147

**Astute** (low-power NAS/backup server):
- i5-7500, 8GB RAM, 6600XT GPU
- NVMe root (ext4) for unattended boots
- 2×3.6TB IronWolf ZFS mirror at `/srv/nas` (encrypted)
- NFS server for Audacious storage
- BorgBackup repository server
- **Power policy**: Suspend-on-idle, Wake-on-LAN wake-up
- IP: 192.168.1.154
- OOB management: GL.iNet Comet at 192.168.1.126

**Artful** (cloud):
- Hetzner CX22 instance
- Debian Stable
- Public web services, reverse proxy, VPN
- Domains: private.example, userlandlab.org

**Steam Deck**:
- SteamOS (not managed by this repo except for limited dotfiles)
- Portable gaming and auxiliary system

## Key Subsystems

### NAS Wake-on-Demand (Audacious ↔ Astute)

Multi-layer orchestration allowing Audacious to wake Astute for NAS access, then allow it to sleep when done.

**Audacious side** (`nas-audacious/`, `bash-audacious/.bashrc.d/30-astute.sh`):
- User service: `astute-nas.service` (systemd user)
  - Sends WOL magic packet to Astute
  - Waits for SSH reachability (30s timeout)
  - SSH to `astute-nas` host (restricted key) with command `start`
  - Mounts NFS via `sudo systemctl start srv-astute.mount`
- Bash functions:
  - `nas-open` → starts service, cd to `/srv/astute`
  - `nas-close` → stops service (unmounts, SSH stop command)
  - `ssh-astute` → WOL + SSH convenience wrapper

**Astute side** (`root-power-astute/`):
- SSH forced command: `/usr/local/libexec/astute-nas-inhibit.sh`
  - Accepts only `start` or `stop` via `SSH_ORIGINAL_COMMAND`
  - Calls `sudo systemctl start/stop nas-inhibit.service`
- System service: `nas-inhibit.service`
  - Runs: `systemd-inhibit --what=sleep --mode=block /usr/bin/sleep infinity`
  - Prevents system sleep while NAS is in use
  - Max runtime: 3600s (1 hour)
- Sudoers rule: `/etc/sudoers.d/nas-inhibit`
  - Allows `alchemist` to control `nas-inhibit.service` without password

**SSH config** (`ssh-audacious/.ssh/config`):
```
Host astute-nas
    HostName astute
    User alchemist
    IdentityFile ~/.ssh/id_ed25519_astute_nas
    IdentitiesOnly yes
    IdentityAgent none
    ForwardAgent no
```

**Authorized keys on Astute** (NOT in repo - in `/home/alchemist/.ssh/authorized_keys`):
```
command="/usr/local/libexec/astute-nas-inhibit.sh",restrict ssh-ed25519 AAAA... audacious-nas
```

### Intelligent Idle Shutdown (Audacious)

Script: `bin-audacious/.local/bin/idle-shutdown.sh`

Triggered by `swayidle` after 20 minutes of no user input. Multi-phase policy:

1. **Immediate abort if**:
   - MPRIS media playing (via `playerctl`)
   - Jellyfin remote playback detected (fail-open if unreachable)
   - systemd shutdown inhibitor active

2. **Idle phase** (first 20-30 min):
   - True idle → shutdown

3. **Unattended work phase** (up to 90 min):
   - CPU/network activity detected → allow to continue
   - After 90 min total → force shutdown

Design: Fail-open for remote checks; critical jobs must use `systemd-inhibit`.

### BorgBackup (Audacious → Astute)

**Audacious** (`borg-user-audacious/`, `root-backup-audacious/`):
- User config: `~/.config/borg/patterns` (inclusion/exclusion patterns)
- User secret: `~/.config/borg/passphrase` (NOT in repo)
- Systemd timers:
  - `borg-backup.timer` → multiple times daily
  - `borg-check.timer` → daily integrity checks
  - `borg-check-deep.timer` → monthly deep verification
- SSH host: `astute-borg` (restricted key: `~/.ssh/audacious-backup`)

**Astute**:
- Dedicated `borg` system user with restricted shell
- Repository: `/srv/backups/audacious-borg`
- SSH authorized_keys with forced command: `borg serve --restrict-to-path /srv/backups`
- Stored on encrypted ZFS mirror

### Dual EFI Auto-Sync (Audacious)

**Package**: `root-efisync-audacious/`

- `efi-sync.path` - Watches `/boot/efi/EFI/Linux/` for UKI updates
- `efi-sync.service` - Uses `rsync` to mirror primary ESP to backup ESP
- Purpose: Both NVMe drives can boot with identical EFI content

### Power Management

**Audacious** (`root-power-audacious/`):
- `powertop.service` - Aggressive power savings on boot
- `usb-nosuspend.service` - Prevents input device autosuspend
- udev rules to keep keyboard/mouse/webcam fully powered
- SATA power policies via `hdparm`
- Note: Suspend is disabled (unreliable on this hardware)

**Astute** (`root-power-astute/`):
- `astute-idle-suspend.timer` + `.service`
- Suspends on idle, WOL wakes

## Common Workflows

### Deploying Configuration

**User-level** (from `~/dotfiles`):
```bash
stow profile-common bash-audacious bin-audacious emacs-audacious sway-audacious waybar-audacious
```

**System-level**:
```bash
sudo stow --target=/ root-power-audacious root-backup-audacious
sudo systemctl daemon-reload
```

**Packages with sudoers** (use install.sh):
```bash
cd root-sudoers-audacious
sudo ./install.sh
```

**Restow after edits**:
```bash
stow --restow bash-audacious bin-audacious
sudo stow --restow --target=/ root-power-audacious
```

**Remove**:
```bash
stow -D sway-audacious
sudo stow -D --target=/ root-power-audacious
```

### Testing Changes

After modifying systemd units:
```bash
sudo systemctl daemon-reload
sudo systemctl restart <service>
journalctl -u <service> -n 50
```

After modifying timers:
```bash
sudo systemctl daemon-reload
systemctl list-timers
```

After modifying bash functions:
```bash
source ~/.bashrc
# Or log out and back in
```

### Checking System Status

**NAS status**:
```bash
~/bin/astute-status.sh  # Custom helper
systemctl --user status astute-nas.service
```

**Backup status**:
```bash
systemctl status borg-backup.service
journalctl -u borg-backup.service -n 50
systemctl list-timers | grep borg
```

**Power/inhibitors**:
```bash
systemd-inhibit --list
loginctl show-session $(loginctl | grep alchemist | awk '{print $1}') -p IdleHint,IdleSinceHint
```

### Recovery Documentation

Each host has complete rebuild documentation in `docs/<hostname>/`:

- `INSTALL.<hostname>.md` - Full installation from scratch
- `RECOVERY.<hostname>.md` - Boot/ZFS recovery procedures
- `RESTORE.<hostname>.md` - Borg data restoration

Recovery docs are mechanically tested and versioned alongside config.

## Secrets Management

**NEVER committed to git**:
- SSH keys: `ssh-*/.ssh/id_*`
- Borg passphrases: `borg-user-*/.config/borg/passphrase`
- SSH known_hosts: `ssh-*/.ssh/known_hosts`
- Jellyfin tokens: `.config/jellyfin/api.token`

**Recovery location**: Encrypted USB key (blue) contains:
- SSH keys (`audacious-backup`, `id_alchemist`, `id_ed25519_astute_nas`)
- SSH config and known_hosts
- Borg passphrase
- Borg repository key export
- Recovery documentation

## Design Principles

When modifying this repository:

1. **No wrappers**: Use GNU Stow directly, standard systemd units, plain bash scripts
2. **Per-host isolation**: Never create shared config that breaks single-host recovery
3. **Documentation first**: Changes that affect recovery must update INSTALL/RECOVERY/RESTORE docs
4. **Vanilla Debian preference**: Minimize divergence from stock Debian packages and config files
5. **Fail-open for remote checks**: Don't block local operations on remote service availability
6. **Explicit over clever**: Direct scripts and clear dependencies over abstraction layers
7. **Secrets never committed**: Use .gitignore and external encrypted storage

## Known Issues and Drift

As of 2025-12-23, the following are acknowledged:

1. **Documentation drift**: Some features (NAS inhibitor SSH key setup) are implemented but not documented

Note: The following issues were recently resolved:
- ✅ Naming inconsistency standardized: all packages now follow `root-<concern>-<host>` pattern
- ✅ Package organization fixed: NAS inhibitor consolidated into `root-power-astute/`
- ✅ Vanilla Trixie divergence resolved: `.bashrc` now uses wrapper + drop-in pattern

## Testing Requirements

Before committing changes that affect:

**Boot/system services**: Test with `systemctl daemon-reload && systemctl restart <service> && journalctl -u <service> -n 50`

**NAS wake**: Test both `nas-open` and `nas-close` from Audacious, verify:
- Astute wakes from suspend
- `/srv/astute` mounts successfully
- `systemd-inhibit --list` shows nas-inhibit on Astute
- `nas-close` releases inhibitor and allows Astute to suspend

**Idle shutdown**: Trigger manually with `~/bin/idle-shutdown.sh` and monitor via `journalctl -t idle-shutdown -f`

**Borg backups**: Test with `sudo systemctl start borg-backup.service && journalctl -u borg-backup.service -f`

**Sudoers changes**: Always validate with `visudo -c` before deployment

## Git Workflow

Standard workflow:
```bash
cd ~/dotfiles
git status
git add <files>
git commit -m "description"
git push
```

Commit message style (from git log):
- Use imperative mood
- Focus on "why" rather than "what"
- Reference affected host in prefix when relevant
- **NEVER** reference AI tools (Claude Code, LLMs, etc.) in commit messages
- Opportunistically remove previous AI references when editing commits
- Exception: LLM-specific documentation (AGENTS.md, HANDOFF.md, etc.) may reference AI tools

SSH requirements for remote operations:
- Pushing to astute or GitHub from astute requires ssh-agent with id_alchemist identity unlocked
- Before SSH operations to astute, verify agent is running and key is loaded
