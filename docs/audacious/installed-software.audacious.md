# Installed Software (Structured List)

This document provides a machine-readable, script-friendly inventory of manually installed software.  
Each section contains categorized software entries in a consistent key-value format.

---

## [desktop]
- steam-installer: Steam client (non-free) — gaming platform
- discord: Chat and VoIP client for communities
- zoom: Video conferencing client
- lutris: Client for gog and epic games
- heroic (local .deb): Game launcher for Epic/GOG/Prime Gaming. Installed manually via .deb into /opt/Heroic (no system binary). Package recommends Fluidsynth - this has been removed post install.

---

## [file-management]
- zathura: Lightweight document viewer
- zathura-pdf-poppler: Poppler backend for PDF rendering
- lf: Terminal file manager
- imv: Lightweight Wayland image viewer (integrates with lf)

---

## [fonts]
- fonts-symbola: Unicode fallback font
- fonts-noto: Comprehensive multilingual typeface family

---

## [storage]
- cryptsetup: LUKS encryption utility for unlocking encrypted drives

---

## [networking]
- wakeonlan: Utility to send Wake-on-LAN packets
- nfs-common: NFS client utilities for network shares
- autofs: Automount service for network shares
- systemd-resolved:  for DNS resolution
---

## [power]
- powertop: Power consumption optimizer and diagnostic tool
- power-profiles-daemon: System service for managing power modes

---

## [utilities]
- usbutils: Provides the `lsusb` command for USB device inspection
- jq: Command-line JSON processor (used in `idle-shutdown.sh`)

---

## [development]
- golang-go: Go toolchain (used for Boot.dev learning client)
- python3-pip: python package manager
---

## [meta]
- source: post-install
- managed-by: manual
- system: audacious (Debian 13 Trixie)
- notes: Core system and Sway desktop components installed via INSTALL.md and managed under dotfiles.
