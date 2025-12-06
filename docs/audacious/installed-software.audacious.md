# Installed Software (Structured List)

This document provides a machine-readable, script-friendly inventory of manually installed software.
Each section reflects installation *origin*, not function — making system state auditable and reproducible.

---

## Base System (installed via INSTALL.audacious.md)
- cryptsetup — LUKS encryption for ZFS unlock
- initramfs-tools — Initramfs generator (ZFS-reliable)
- zfs-initramfs — ZFS support during early boot
- linux-image-amd64 — main kernel image
- linux-headers-amd64 — build headers for modules
- systemd-boot — EFI bootloader for UKI
- systemd-ukify — UKI generation tooling
- systemd-zram-generator — swap-on-zram backend
- systemd-networkd — primary network management daemon
- systemd-resolved — DNS resolution
- openssh-client — SSH connectivity
- iproute2 — modern networking tools
- firmware-amd-graphics — AMD GPU firmware
- firmware-realtek — NIC firmware
- intel-microcode — CPU microcode patches

---

## Desktop Infrastructure (installed via INSTALL.audacious.md)

### Core session & UI
- sway — Wayland compositor
- swaybg — wallpaper management
- swayidle — power/idle controller
- swaylock — screen lock
- waybar — status bar
- wofi — application launcher
- mako-notifier — notification daemon
- xwayland — X11 compatibility
- grim — screenshot tool
- slurp — region selection tool
- wl-clipboard — clipboard manager
- xdg-desktop-portal — desktop portal services
- xdg-desktop-portal-wlr — Wayland portal implementation
- profile-sync-daemon — reduces browser write amplification

### Audio subsystem
- pipewire-audio — audio engine
- wireplumber — policy/session manager
- pavucontrol — graphical mixer

### Toolchain and environment applied at build time
- git — version control
- stow — dotfile deployment
- curl — transfer utility
- rsync — file/dir synchronisation
- tree — directory visualiser
- hdparm — drive tuning
- plymouth — graphical boot splash
- plymouth-themes — theme package
- desktop-base — Debian branding defaults

### Fonts installed at build time
- fonts-jetbrains-mono — primary UI font
- fonts-dejavu — general fallback set

---

## User Applications (installed post-build)

### Applications
- firefox-esr — web browser
- chromium — web browser (secondary / backup)
- discord — VoIP and community client
- zoom — video conferencing client
- heroic (local .deb) — Epic/GOG/Prime Gaming client
- steam-installer — Steam client (non-free)
- lutris — GOG/Epic game launcher
- openjdk-21-jdk — Java runtime for Minecraft
- transmission - torrenting client

### Document & media
- zathura — lightweight PDF/document viewer
- zathura-pdf-poppler — rendering backend
- poppler-utils — PDF extraction toolkit
- tesseract-ocr — OCR engine

### Music
- strawberry - music player
- mpd - music player daemon
- ncmpcpp - TUI client for mpd
- picard - tagging software


### Utilities
- lf — terminal file manager
- imv — Wayland-native image viewer
- jq — JSON processor
- sc — TUI spreadsheet
- nftables — firewall subsystem
- power-profiles-daemon — power profile control
- powertop — power optimisation diagnostics
- usbutils — USB inspection tools (`lsusb`)
- wakeonlan — WOL magic packet sender
- nano — minimal fallback editor
- sqv — OpenPGP signature verification utility
- kid3-cli - Music tagging cli utility

### Storage & backup
- borgbackup — encrypted backups
- autofs — automount service
- nfs-common — NFS client utilities

### Fonts installed later
- fonts-noto — multilingual family
- fonts-symbola — Unicode symbol/font fallback

---

## [meta]
- system: audacious (Debian 13 Trixie)
- origin-model: layered
- layers:
    - base-system: installed via INSTALL.audacious.md
    - desktop-infrastructure: installed via INSTALL.audacious.md
    - user-applications: post-build additions
- management: manual curation (origin-aware, not auto-generated)
- notes: Base + desktop layers are reproducible install-state; user layer reflects later additions.
- last-updated: 2025-11-30
- last-checked-for-drift: 2025-11-30
