# Dotfiles — audacious (Debian 13 “Trixie”)

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

The goal isn’t to make Linux look like AmigaOS — it’s to keep the same sense of immediacy and control.

---

## Structure

```
bash-audacious/          → Shell configuration (.bashrc, .bash_profile)
bin-audacious/           → Personal scripts (~/.local/bin)
borg-user-audacious/     → Borg config and patterns
backup-systemd-audacious/→ Borg systemd units and timers
emacs-audacious/         → Editor configuration and custom theme
etc-cachyos-audacious/   → Kernel, sysctl, and audio tuning
etc-power-audacious/     → Power and udev rules, powertop setup
etc-systemd-audacious/   → Core systemd units (EFI sync, boot)
fonts-audacious/         → Amiga + Nerd Fonts
icons-audacious/         → Amiga-style cursor theme
sway-audacious/, waybar-audacious/, wofi-audacious/ → Wayland desktop configuration
```

System-level trees (`etc-*-audacious`, `backup-systemd-audacious`) require `sudo` when stowing.

---

## Usage

Clone and deploy:

```bash
cd ~/dotfiles
stow bash-audacious bin-audacious emacs-audacious sway-audacious waybar-audacious wofi-audacious
sudo stow --target=/ etc-systemd-audacious etc-power-audacious
```

Restow after changes or reinstalls:

```bash
stow --restow bash-audacious bin-audacious emacs-audacious sway-audacious waybar-audacious wofi-audacious
sudo stow --restow --target=/ etc-systemd-audacious etc-power-audacious
```

Remove a module:

```bash
stow -D sway-audacious waybar-audacious wofi-audacious
sudo stow -D --target=/ etc-systemd-audacious
```

---

## System Services

Defined under `etc-systemd-audacious` and `etc-power-audacious`:

| Service | Description |
|----------|-------------|
| `efi-sync.path` / `.service` | Keeps EFI partitions mirrored |
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
