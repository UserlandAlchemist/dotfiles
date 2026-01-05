# Project Shipshape

Configuration management for "the Wolfpack" — a small ecosystem of independent Linux systems. User-level configs deployed with GNU Stow; system-level configs via install scripts. Designed for clarity, reproducibility, and fast recovery.

---

## What is this?

This repository contains all configuration for multiple Debian-based hosts:
- **audacious** — Main workstation (ZFS root, Sway, development + gaming)
- **astute** — Low-power NAS/backup server (suspend-on-idle, Wake-on-LAN)
- **artful** — Cloud instance (Hetzner, currently inactive)
- **steamdeck** — Portable system (limited dotfiles)

Everything is plain text, version controlled, and deployed using two methods: GNU Stow for user configs, install scripts for system configs. No configuration managers, no complex abstractions — just files that map directly to their target locations.

---

## Architecture

### Package Organization

Configuration is split into **per-host stow packages** using a consistent naming convention:

**User-level packages** (deploy to `$HOME`):
```
<tool>-<hostname>/
```
Examples: `bash-audacious/`, `sway-audacious/`, `emacs-audacious/`

**System-level packages** (deploy to `/` via install scripts):
```
root-<concern>-<hostname>/
```
Examples: `root-power-audacious/`, `root-backup-audacious/`, `root-efisync-audacious/`

System packages include `install.sh` scripts that copy files to /etc and other system locations as real files (not symlinks). This ensures configs are available before /home mounts during boot.

**Shared configuration:**
```
profile-common/
```
Shell profile sourced first on all hosts.

**Documentation:**
```
docs/<hostname>/
```
Per-host install guides, recovery procedures, and restore documentation.

### Why Per-Host Packages?

- **Independent recovery:** Each host can be rebuilt from its own packages without touching others
- **No shared config drift:** Changes to one host never affect another
- **Clear ownership:** Every file belongs to exactly one host
- **Fast deployment:** Deploy only the packages needed for the current host
- **Safe boot-time configs:** System packages use install scripts, not symlinks, so configs load before /home mounts

---

## Quick Start

### Deploy user configuration

```bash
cd ~/dotfiles
stow bash-audacious bin-audacious sway-audacious waybar-audacious
```

### Deploy system configuration

```bash
cd ~/dotfiles
sudo root-power-audacious/install.sh
sudo root-efisync-audacious/install.sh
sudo systemctl daemon-reload
```

**Note:** System packages (root-*) use install scripts that copy files to /etc and other system locations. This ensures configs are real files, not symlinks, so they're available before /home mounts at boot.

### Restow user packages after edits

```bash
stow --restow bash-audacious bin-audacious
```

### Update system packages after edits

```bash
sudo root-power-audacious/install.sh
```

### Remove packages

```bash
# User packages
stow -D sway-audacious waybar-audacious

# System packages (manual removal required - see package README)
```

---

## Key Subsystems

### NAS Wake-on-Demand (Audacious ↔ Astute)
Multi-layer orchestration allowing Audacious to wake Astute from suspend, mount NFS storage, and prevent Astute from sleeping while in use.

- User service: `astute-nas.service` (WOL + SSH + mount)
- Bash helpers: `nas-open`, `nas-close`
- Remote inhibitor: `nas-inhibit.service` on Astute
- SSH forced commands for security

See: `nas-audacious/README.md`, `root-power-astute/README.md`

### Intelligent Idle Shutdown (Audacious)
Script triggered by `swayidle` after 20 minutes of inactivity. Checks for media playback, remote streaming, and systemd inhibitors before shutting down. Allows unattended work up to 90 minutes.

See: `bin-audacious/.local/bin/idle-shutdown.sh`

### Encrypted Backups (Audacious → Astute)
Automated BorgBackup with systemd timers. Multiple daily backups, weekly integrity checks, monthly deep verification. SSH key authentication, encrypted repository.

See: `borg-user-audacious/README.md`, `root-backup-audacious/README.md`

### Cold Storage Snapshots (Audacious)
Monthly snapshots to the LUKS cold-storage drive with a reminder timer. Keeps 12 months of history.

See: `cold-storage-audacious/README.md`

### Dual EFI Synchronization (Audacious)
Automatic mirroring of primary ESP to backup ESP whenever kernel images update. Both NVMe drives can boot independently.

See: `root-efisync-audacious/README.md`

### Boot Stack (Audacious)
systemd-boot with Unified Kernel Images (UKI) instead of GRUB. ZFS root filesystem on encrypted RAID1.

See: `docs/audacious/INSTALL.audacious.md`

---

## Documentation Map

### Per-Host Guides
Each host has complete rebuild documentation:

**Audacious:**
- [`docs/audacious/INSTALL.audacious.md`](docs/audacious/INSTALL.audacious.md) — Full installation from scratch
- [`docs/audacious/RECOVERY.audacious.md`](docs/audacious/RECOVERY.audacious.md) — Boot and ZFS recovery
- [`docs/audacious/RESTORE.audacious.md`](docs/audacious/RESTORE.audacious.md) — Borg data restoration
- [`docs/audacious/DRIFT-CHECK.md`](docs/audacious/DRIFT-CHECK.md) — Package drift detection procedure
- [`docs/audacious/installed-software.audacious.md`](docs/audacious/installed-software.audacious.md) — Complete package inventory

**Astute:**
- [`docs/astute/INSTALL.astute.md`](docs/astute/INSTALL.astute.md) — Full installation from scratch
- [`docs/astute/RECOVERY.astute.md`](docs/astute/RECOVERY.astute.md) — Boot and ZFS recovery
- [`docs/astute/installed-software.astute.md`](docs/astute/installed-software.astute.md) — Complete package inventory

### System Reference
- [`docs/hosts-overview.md`](docs/hosts-overview.md) — Hardware specs for all hosts
- [`docs/network-overview.md`](docs/network-overview.md) — Network topology and addressing
- [`docs/principles.md`](docs/principles.md) — Project principles guiding Shipshape
- [`docs/THREAT-MODEL.md`](docs/THREAT-MODEL.md) — Security threat model and acceptable risks

---

## Design Principles

### Repo-First Philosophy
- **Plain text configuration:** Everything versioned, transparent, understandable
- **Standard Debian packages:** No Snaps, AppImages, or Flatpaks
- **No wrappers or daemons:** Direct use of GNU Stow and systemd
- **Explicit over clever:** Clear scripts and dependencies over abstraction

### Per-Host Isolation
- **Single-host recovery:** Each machine can be rebuilt independently
- **No shared files:** Avoid config that blocks single-host recovery
- **Documented divergence:** Track how systems differ from vanilla Debian

### Secrets Management
Never committed to git:
- SSH keys (`ssh-*/.ssh/id_*`)
- Borg passphrases (`borg-user-*/.config/borg/passphrase`)
- API tokens (`.config/*/api.token`)
- SSH known_hosts

Recovery location: Encrypted USB key (blue) contains all secrets.

---

## Project Naming

**Project Shipshape** refers to this dotfiles repository and configuration management implementation — everything in order, maintainable, and ready for deployment or disaster recovery.

**The Wolfpack** refers to the fleet of machines managed by this repository:
- **Audacious** — Main workstation (powerful, fast-booting, aggressively idle-shutdown)
- **Astute** — Low-power NAS/backup server (suspend-on-idle, Wake-on-LAN)
- **Artful** — Cloud instance on Hetzner (currently inactive)
- **Steam Deck** — Portable gaming companion

Hostnames follow Royal Navy submarine names. "Wolfpack" describes the architecture: independent, low-maintenance machines with clearly defined roles that cooperate without tight coupling.

Together they form a "workstation × homelab" hybrid rather than a traditional multi-server lab, prioritizing clarity, sustainability, and low waste.

---

## Distro Choice

All hosts (except Steam Deck) run **Debian 13 (Trixie) Stable**. This provides:
- Excellent ZFS-on-root support
- Predictable long-term behavior
- Wide cloud provider availability (Hetzner)
- Reduced context switching across machines

This is a pragmatic choice, not a permanent requirement. The repo-first design keeps dotfiles portable.

---

## License

All original configuration, scripts, and documentation © Userland Alchemist.
Shared under the **MIT License** unless otherwise noted.

---
