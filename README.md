# Userland Dotfiles

Declarative, host-specific configuration for Linux systems, designed for clarity, reproducibility, and long-term maintainability.

---

## 🧠 Philosophy

These dotfiles are built around a few simple ideas:

- **Understandable systems** — everything is plain text and transparent.  
- **Debian-native** — uses only standard Debian or upstream packages.  
- **No wrappers or daemons** — configuration is managed directly through GNU Stow.  
- **Per-host modularity** — each machine has its own isolated tree of configs.  
- **Minimal dependencies** — no Snap, AppImage, or Flatpak layers.  
- **Fast recovery** — every host can be rebuilt entirely from its docs and stow sets.

---

## 🗂 Layout

```
dotfiles/
├── backup-systemd-audacious/   → systemd units for Borg backup timers
├── bash-audacious/             → bash configuration for audacious
├── bin-audacious/              → personal scripts (~/.local/bin)
├── borg-user-audacious/        → user-level Borg settings
├── docs/
│   ├── audacious/
│   │   ├── INSTALL.audacious.md
│   │   ├── RECOVERY.audacious.md
│   │   ├── RESTORE.audacious.md
│   │   └── README.audacious.md
│   └── hosts-overview.md
└── ...
```

Each directory ending in `-<hostname>` defines configuration for a specific system.  
The `docs/<hostname>/` directory contains its complete install, recovery, and restore guides.

---

## 🧩 How it works

All configuration is linked into place using **GNU Stow**, ensuring each package can be safely applied or removed.

Example:

```bash
cd ~/dotfiles
stow bash-audacious bin-audacious sway-audacious waybar-audacious
sudo stow --target=/ etc-systemd-audacious etc-power-audacious
```

To restow after edits:

```bash
stow --restow bash-audacious bin-audacious
```

To remove:

```bash
stow -D sway-audacious waybar-audacious
```

---

## 💻 Current Hosts

| Host | OS | Notes |
|------|----|-------|
| **audacious** | Debian 13 (Trixie) | Main workstation, ZFS root, sway desktop |

Future hosts (for example, `astute`, `perceptive`, etc.) will follow the same pattern with their own `*-hostname` directories and docs.

---

## 🛠 Dependencies

Core tools used across all hosts:

- `stow`
- `git`
- `rsync`
- `systemd`
- `borgbackup`
- `zfsutils-linux`
- `curl`, `tree`, `hdparm`
- (optional) `emacs`, `uv` (Python toolchain manager)

---

## 📚 Documentation

Each host’s documentation lives under its own folder:

- [`docs/audacious/README.audacious.md`](docs/audacious/README.audacious.md) — Overview for Audacious  
- [`docs/audacious/INSTALL.audacious.md`](docs/audacious/INSTALL.audacious.md) — Full install guide  
- [`docs/audacious/RECOVERY.audacious.md`](docs/audacious/RECOVERY.audacious.md) — Boot and ZFS recovery  
- [`docs/audacious/RESTORE.audacious.md`](docs/audacious/RESTORE.audacious.md) — Borg restore procedure  

Global reference:
- [`docs/hosts-overview.md`](docs/hosts-overview.md)

---

## 🧾 License

All original configuration, scripts, and documentation © Userland Alchemist.  
Shared under the **MIT License** unless otherwise noted.

---