# Dotfiles — audacious (Debian 13 "Trixie")

A reproducible desktop configuration for a Debian Trixie system running on ZFS.
Built to stay fast, understandable, and fixable.

---

## Overview

These dotfiles define the environment for the host **audacious**, using:

- **Debian 13 (Trixie)** with **ZFS**
- **sway** on **Wayland**
- **systemd-boot** with unified kernel images (UKI)
- **BorgBackup** for encrypted backups
- **GNU Stow** for configuration management
- **Amiga-style fonts and cursors**

Everything here is plain text, versioned, and mapped directly to where it belongs in the filesystem.
No external configuration managers, wrappers, or packaging systems.

---

## Philosophy

The system follows what I call the *Workbenchian* approach — influenced by the Amiga Workbench look and workflow, but designed for modern hardware and software.

- **Minimal dependencies:** standard Debian packages only. No Snaps, AppImages, or Flatpaks.
- **Keyboard-driven:** sway, lf, foot, and mako form the core workflow.
- **Low friction:** fast startup, low power draw, minimal background noise.
- **Dark and readable:** consistent palette for day-long use.
- **Retro, not nostalgic:** classic shapes and typefaces, but without dated cruft.
- **Directness over automation:** small scripts, no layers of abstraction.

The goal isn't to make Linux look like AmigaOS — it's to keep the same sense of immediacy and control.

---

## Integral Audio Stack (Manual Installs)

Some audio components are intentionally installed outside Debian packages and live under `/usr/local` or `/opt`. These are **not cruft** and are documented in `~/personal/audio-workstation-notes.md`.

- `/usr/local/lib/lv2/sfizz.lv2` and `libsfizz*` — sfizz (SFZ sampler)
- `/opt/zyn-fusion` — ZynAddSubFX Fusion
- `/opt/vcv-rack/rack-2.6.6` — VCV Rack (standalone learning tool)
- `/opt/integral` — sample library root and Integral metadata

Any change here must be recorded in the audio notes (version, source, install steps).

---

## Structure

### User-level packages (deploy to $HOME)
```
ardour-audacious/        → DAW configuration
bash-audacious/          → Shell configuration (.bashrc, .bash_profile, drop-ins)
bin-audacious/           → Personal scripts (~/.local/bin)
borg-user-audacious/     → Borg config and patterns
emacs-audacious/         → Editor configuration and custom theme
environment-audacious/   → Environment variables
fonts-audacious/         → Amiga + Nerd Fonts
foot-audacious/          → Terminal emulator config
git-audacious/           → Git configuration
icons-audacious/         → Amiga-style cursor theme
lf-audacious/            → Terminal file manager config
mako-audacious/          → Notification daemon config
mimeapps-audacious/      → Default application associations
nas-audacious/           → NAS wake-on-demand orchestration (user service)
ncmpcpp-audacious/       → Music player client config
picard-audacious/        → Music tagger config
pipewire-audacious/      → Audio routing and pro-audio latency config
psd-audacious/           → Profile-sync-daemon config
sway-audacious/          → Wayland compositor config
waybar-audacious/        → Status bar config
wofi-audacious/          → Application launcher config
```

### System-level packages (deploy to / with sudo)
```
root-backup-audacious/   → Borg systemd units and timers
root-cachyos-audacious/  → Kernel, sysctl, and I/O scheduler tuning
root-efisync-audacious/  → Dual ESP synchronization (efi-sync.path, efi-sync.service)
root-network-audacious/  → systemd-networkd wired ethernet config
root-power-audacious/    → Power management (powertop, USB autosuspend, SATA power)
root-proaudio-audacious/ → Real-time audio kernel tuning (rtprio limits)
root-sudoers-audacious/  → Passwordless sudo for NAS mount control
root-system-audacious/   → System configuration fixes for minimal Debian (journald override)
```

System-level packages (`root-*-audacious`) require `sudo stow --target=/` when deploying.

---

## Usage

Clone and deploy:

```bash
cd ~/dotfiles
stow bash-audacious bin-audacious emacs-audacious sway-audacious waybar-audacious wofi-audacious

# System packages use install scripts (deploy boot-critical configs as real files; stow any non-boot files if present)
sudo root-system-audacious/install.sh
sudo root-power-audacious/install.sh
sudo root-efisync-audacious/install.sh
sudo root-cachyos-audacious/install.sh
sudo root-backup-audacious/install.sh
sudo root-network-audacious/install.sh
sudo root-sudoers-audacious/install.sh
sudo root-proaudio-audacious/install.sh
```

Restow after changes or reinstalls:

```bash
stow --restow bash-audacious bin-audacious emacs-audacious sway-audacious waybar-audacious wofi-audacious

# For system packages, re-run install scripts
sudo root-system-audacious/install.sh
```

Remove a module:

```bash
stow -D sway-audacious waybar-audacious wofi-audacious
sudo stow -D --target=/ root-efisync-audacious
```

---

## System Services

Defined under `root-*-audacious` packages:

| Service | Description |
|----------|-------------|
| `efi-sync.path` / `.service` | Keeps dual EFI partitions mirrored |
| `powertop.service` | Applies power settings on boot |
| `usb-nosuspend.service` | Prevents input device autosuspend |
| `borg-backup.timer` | Runs regular Borg backups |
| `borg-check.timer` | Verifies backup integrity weekly |
| `borg-check-deep.timer` | Performs monthly deep verification |

Reload or enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service usb-nosuspend.service efi-sync.path
```

---

## Backups and Recovery

Backups are handled through Borg with systemd timers.

Trigger a manual run:

```bash
sudo systemctl start borg-backup.service
journalctl -u borg-backup.service -n 20
```

Documentation for setup and recovery:

- [`INSTALL.audacious.md`](INSTALL.audacious.md) — clean installation
- [`RECOVERY.audacious.md`](RECOVERY.audacious.md) — boot and ZFS repair
- [`RESTORE.audacious.md`](RESTORE.audacious.md) — Borg data restore

---

## Notes

- User: **alchemist**
- Host: **audacious**
- Filesystem: **ZFS**
- Bootloader: **systemd-boot (UKI)**
- OS: **Debian 13 (Trixie)**
- Kernel: **6.10+**

This system is meant to stay understandable years later — the fewer moving parts, the better.

---

## License

All original configuration and scripts © Userland Alchemist.
Shared under the MIT License unless otherwise stated.
