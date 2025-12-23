# Userland Dotfiles

Declarative, host-specific configuration for Linux systems, designed for clarity, reproducibility, and long-term maintainability across a small ecosystem of independent machines (“the Wolfpack”).

---

## Philosophy

These dotfiles follow a few core principles:

- **Understandable systems** — everything is plain text, transparent, and easy to reason about.
- **Repo-first** — prefer software provided by the system’s native package manager; avoid Snap, AppImage, and Flatpak layers to keep systems predictable and easy to recover.
- **No wrappers or daemons** — configuration is managed directly through GNU Stow and standard tools.
- **Per-host modularity** — each machine has its own isolated tree of configs and documentation.
- **Fast recovery** — every host can be rebuilt entirely from its install docs, recovery notes, and stow packages.
- **Sustainable design** — hardware is reused and cascaded between machines where possible, and systems sleep or shut down aggressively to reduce waste.

---

## The Wolfpack

Hostnames are named after Royal Navy submarines, and “Wolfpack” describes both the naming and the architecture: a group of independent, low-maintenance machines with clearly defined roles that cooperate without being tightly coupled.

At the centre is **Audacious**, a full Linux workstation for development and general computing that also behaves like a console when gaming—fast to boot, minimal overhead, and powered off aggressively when not in use. Supporting it is **Astute**, a low-power server that provides storage, backups, and GPU fallback while sleeping whenever possible. **Artful** offers a lightweight cloud presence, and the **Steam Deck** acts as a portable companion system.

Together these hosts form a small, efficient ecosystem: one powerful workstation supported by lean, purpose-built infrastructure, with no unnecessary overlap or complexity. It is a “workstation × homelab” hybrid rather than a traditional multi-server lab, prioritising clarity, sustainability, and low waste.

---

## Distro choice

All hosts (except the SteamDeck) currently run **Debian 13 (Trixie)** as a practical baseline. Debian Stable offers excellent ZFS-on-root support, predictable behaviour for long-term systems, and is widely available on cloud providers such as Hetzner. Using the same distro across all machines reduces context switching and simplifies recovery. This is a pragmatic choice rather than a permanent requirement; the repo-first design of these dotfiles keeps them portable.

---

## Layout

Each directory ending in `-<hostname>` defines configuration for a specific system.  
The `docs/<hostname>/` directory contains its complete install, recovery, and restore guides.

---

## How it works

All configuration is linked into place using **GNU Stow**, ensuring each package can be safely applied or removed.

Example:

```bash
cd ~/dotfiles
stow bash-audacious bin-audacious sway-audacious waybar-audacious
sudo stow --target=/ root-power-audacious root-efisync-audacious
```

To restow after edits:

```bash
stow --restow bash-audacious bin-audacious
sudo stow --restow --target=/ root-power-audacious
```

To remove:

```bash
stow -D sway-audacious waybar-audacious
sudo stow -D --target=/ root-power-audacious
```

---

## Current Hosts

| Host        | OS                       | Role |
|-------------|---------------------------|------|
| **audacious** | Debian 13 (Trixie)        | Main workstation (development + console-like gaming, ZFS root, Sway) |
| **astute**    | Debian 13 (Trixie)        | Low-power server (NAS, backups, GPU fallback, suspend-on-idle) |
| **artful**    | Debian Stable (Hetzner)   | Lightweight public cloud node (reverse proxy, demos, access) |
| **steamdeck** | SteamOS                   | Portable auxiliary system and companion device |


## Documentation

Each host’s documentation lives under its own folder:

- [`docs/audacious/README.audacious.md`](docs/audacious/README.audacious.md) — Overview for Audacious  
- [`docs/audacious/INSTALL.audacious.md`](docs/audacious/INSTALL.audacious.md) — Full install guide  
- [`docs/audacious/RECOVERY.audacious.md`](docs/audacious/RECOVERY.audacious.md) — Boot and ZFS recovery  
- [`docs/audacious/RESTORE.audacious.md`](docs/audacious/RESTORE.audacious.md) — Borg restore procedure  

Global reference:
- [`docs/hosts-overview.md`](docs/hosts-overview.md)

---

## License

All original configuration, scripts, and documentation © Userland Alchemist.  
Shared under the **MIT License** unless otherwise noted.

---
