# Hosts Overview

This document lists all machines in the Wolfpack, their hardware specs, roles, and operating systems.

**The Wolfpack** is the fleet of machines managed by Project Shipshape (this dotfiles repository).

---

## Astute (server)

**Role:** Low-power NAS/backup server
**OS:** Debian 13 (Trixie)
**CPU:** Intel i5-7500
**RAM:** 8 GB
**GPU:** AMD Radeon RX 6600XT
**Storage:**
- NVMe root on ext4
- 2×3.6 TB IronWolf ZFS mirror at `/srv/nas` (encrypted)
- 32 GB encrypted swap

**Network:**
- 1 GbE at 192.168.1.154
- MAC: `60:45:cb:9b:ab:3b` (enp0s31f6)
- NFSv4 server for bulk storage
- Suspend-on-idle, Wake-on-LAN capable

**Remote Management:**
- GL.iNet Comet PoE (GL-RM1PE) for out-of-band KVM access
- 4K@30 HDMI capture, USB keyboard/mouse injection
- Tailscale connectivity
- OOB IP: 192.168.1.126

---

## Audacious (workstation, daily driver)

**Role:** Main development workstation and gaming system
**OS:** Debian 13 (Trixie)
**Motherboard:** Gigabyte Z690M DS3H DDR4
**CPU:** Intel i5-13600KF
**RAM:** 32 GB
**GPU:** AMD Radeon RX 7800XT
**Storage:**
- 2×1.8 TB NVMe in ZFS RAID1 (root filesystem, encrypted)
- 931 GB HDD for local backup staging

**Network:**
- 1 GbE at 192.168.1.147
- MAC: `d8:5e:d3:ac:e3:e7` (enp7s0)

**Desktop:**
- Autologin to Sway (Wayland)
- Minimal Amiga-inspired theme with Topaz fonts
- Keyboard-driven workflow

**Power policy:**
- Fast startup/shutdown, aggressive idle shutdown
- No suspend (both s2idle and s3 do not resume correctly on this hardware)

**Use cases:**
- Development (Python, Go, web)
- Retro coding projects (pyxel, BBC Micro BASIC conversions)
- Gaming (Steam, Heroic, Lutris, Prism Launcher)
- General desktop tasks
- Pro audio workstation (Ardour, sfizz, ZynAddSubFX)

**Displays:**
- MSI MAG274UPF — 3840×2160 @ up to 144 Hz, Adaptive Sync (primary, left, DP-1)
- LG Ultrawide — 2560×1080 @ 60 Hz (secondary, right, HDMI-A-1)

**Input:**
- 8BitDo Ultimate 2 BT controller with charging dock (2.4GHz mode)

---

## Artful (cloud)

**Role:** Public web services host
**Provider:** Hetzner CX22 instance
**OS:** Debian Stable
**Network:** IPv4, dynamic IP

**DNS/Domains:**
- private.example (personal)
- userlandlab.org (projects/general)
- Cloudflare free plan (DNS + proxy)

**Use cases:**
- Web services, reverse proxy, VPN
- Project demos and public-facing tools

**Status:** Available but not currently in active use

---

## Steam Deck

**Model:** 512GB OLED
**OS:** SteamOS
**Storage:** 512GB internal + 512GB MicroSD card
**Role:** Portable gaming and auxiliary system

**Dock:**
- Benazcap 7-in-1 aluminium dock
- HDMI 2.0 4K@60
- Gigabit Ethernet
- 3× USB-A 3.0 ports
- 100W USB-C PD passthrough

---
