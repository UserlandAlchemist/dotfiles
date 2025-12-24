# Userland Dotfiles

Configuration management for "the Wolfpack" — a small ecosystem of independent Linux systems managed using GNU Stow. Designed for clarity, reproducibility, and fast recovery.

---

## What is this?

This repository contains all configuration for multiple Debian-based hosts:
- **audacious** — Main workstation (ZFS root, Sway, development + gaming)
- **astute** — Low-power NAS/backup server (suspend-on-idle, Wake-on-LAN)
- **artful** — Cloud instance (Hetzner, currently inactive)
- **steamdeck** — Portable system (limited dotfiles)

Everything is plain text, version controlled, and deployable via GNU Stow. No configuration managers, no wrappers, no abstractions — just files that map directly to their target locations.

---

## Architecture

### Package Organization

Configuration is split into **per-host stow packages** using a consistent naming convention:

**User-level packages** (deploy to `$HOME`):
```
<tool>-<hostname>/
```
Examples: `bash-audacious/`, `sway-audacious/`, `emacs-audacious/`

**System-level packages** (deploy to `/`):
```
root-<concern>-<hostname>/
```
Examples: `root-power-audacious/`, `root-backup-audacious/`, `root-efisync-audacious/`

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
- **Fast deployment:** Stow only the packages needed for the current host

---

## Quick Start

### Deploy user configuration

```bash
cd ~/dotfiles
stow bash-audacious bin-audacious sway-audacious waybar-audacious
```

### Deploy system configuration

```bash
sudo stow --target=/ root-power-audacious root-efisync-audacious
sudo systemctl daemon-reload
```

### Restow after edits

```bash
stow --restow bash-audacious bin-audacious
sudo stow --restow --target=/ root-power-audacious
```

### Remove packages

```bash
stow -D sway-audacious waybar-audacious
sudo stow -D --target=/ root-power-audacious
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
- [`docs/audacious/README.audacious.md`](docs/audacious/README.audacious.md) — Overview
- [`docs/audacious/INSTALL.audacious.md`](docs/audacious/INSTALL.audacious.md) — Full installation from scratch
- [`docs/audacious/RECOVERY.audacious.md`](docs/audacious/RECOVERY.audacious.md) — Boot and ZFS recovery
- [`docs/audacious/RESTORE.audacious.md`](docs/audacious/RESTORE.audacious.md) — Borg data restoration
- [`docs/audacious/VANILLA-DIVERGENCE.md`](docs/audacious/VANILLA-DIVERGENCE.md) — Divergence from stock Debian
- [`docs/audacious/DRIFT-CHECK.md`](docs/audacious/DRIFT-CHECK.md) — Package drift detection procedure
- [`docs/audacious/installed-software.audacious.md`](docs/audacious/installed-software.audacious.md) — Complete package inventory

**Astute:**
- [`docs/astute/INSTALL.astute.md`](docs/astute/INSTALL.astute.md) — Full installation from scratch
- [`docs/astute/installed-software.astute.md`](docs/astute/installed-software.astute.md) — Complete package inventory

### System Reference
- [`docs/hosts-overview.md`](docs/hosts-overview.md) — Hardware specs for all hosts
- [`docs/network-overview.md`](docs/network-overview.md) — Network topology and addressing
- [`docs/SUBSYSTEMS.md`](docs/SUBSYSTEMS.md) — Critical subsystems reference (for emergencies)

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

## The Wolfpack

Hostnames follow Royal Navy submarine names. "Wolfpack" describes the architecture: independent, low-maintenance machines with clearly defined roles that cooperate without tight coupling.

**Audacious** is the central workstation — powerful, fast-booting, aggressively powered off when idle. **Astute** provides storage and backups while sleeping whenever possible. **Artful** offers lightweight cloud presence. The **Steam Deck** acts as a portable companion.

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
