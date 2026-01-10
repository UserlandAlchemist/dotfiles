# Infrastructure Overview

Complete hardware and network reference for the Wolfpack.

---

## Network Infrastructure

### Router

- **Model:** BT Smart Hub 2
- **Role:** Primary router, DHCP server, Wi-Fi AP
- **LAN Gateway:** 192.168.1.254
- **FTTP Profile:** 1000 Mbps downstream / 1000 Mbps upstream
- **Public Wi-Fi:** Disabled
- **UPnP:** Enabled (suitable for gaming, Steam Deck, and IoT)
- **DNS:** Per-device (router does not allow DNS override)

### Switch

- **Model:** TP-Link LS1008G (unmanaged, 8-port Gigabit)
- **Uplink:** Connected to BT Smart Hub 2
- **PoE:** Not supported (Comet powered via USB-C)

**Connected devices:**

- Wolfpack hosts (Astute, Audacious)
- glkvm (GL.iNet Comet - OOB KVM)
- hue-bridge (Philips Hue Zigbee hub)
- Steam Deck dock (when powered and docked)

### DHCP Reservations

Wolfpack host IPs/MACs documented in Hosts section below.

| Device         | IP Address    | MAC Address       | Notes                   |
|----------------|---------------|-------------------|-------------------------|
| **glkvm**      | 192.168.1.126 | 94:83:c4:be:77:9e | GL.iNet Comet (OOB KVM) |
| **hue-bridge** | 192.168.1.210 | ec:b5:fa:22:e0:8f | Philips Hue Zigbee hub  |

### WAN Information

- **Provider:** BT (FTTP)
- **Authentication:** PPPoE username `bthomehub@btbroadband.com` (no password
  required)
- **External IP:** Dynamic; changes periodically
- **DNS:** Cloudflare (1.1.1.1 / 1.0.0.1) used per-device

### APT Proxy (apt-cacher-ng)

- **Service:** apt-cacher-ng on astute:3142
- **Clients:** audacious (automatic failover)

**Architecture:**

- Astute caches Debian packages via apt-cacher-ng
- Audacious uses `Acquire::http::ProxyAutoDetect` for proxy selection
- Detection script pings astute with a 1s timeout
- Falls back to DIRECT if astute is unavailable

**Configuration:**

- `/etc/apt/apt.conf.d/01proxy` - ProxyAutoDetect configuration
- `/usr/local/bin/apt-proxy-detect.sh` - Reachability detection script
- Installed via `root-network-audacious/install.sh` (real files in `/etc` and
  `/usr/local`)

### Wireless Devices

Most IoT devices are connected via 2.4 GHz Wi-Fi.

Notable devices:

- **Tapo H200 hub**
- **Tapo C200 camera**
- **Echo Dot** (dual-band, currently on 5 GHz)
- Additional Tapo smart plugs/sensors

A detailed per-device accounting is not required for core Wolfpack documentation.

### Network Notes

- LAN operates as a simple **192.168.1.0/24** flat network
- The Comet KVM remains reachable when hosts are powered off, but video
  requires host power
- No VLANs or managed switching currently in use

---

## Hosts

### Audacious (workstation, daily driver)

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

- MSI MAG274UPF — 3840×2160 @ up to 144 Hz, Adaptive Sync (primary, left,
  DP-1)
- LG Ultrawide — 2560×1080 @ 60 Hz (secondary, right, HDMI-A-1)

**Input:**

- 8BitDo Ultimate 2 BT controller with charging dock (2.4GHz mode)

---

### Astute (server)

**Role:** Low-power NAS/backup server
**OS:** Debian 13 (Trixie)
**CPU:** Intel i5-7500
**RAM:** 8 GB
**GPU:** AMD Radeon RX 6600/6600 XT/6600M (Navi 23)
**Storage:**

- NVMe root on ext4
- 2×3.6 TB IronWolf ZFS mirror at `/srv/nas` (encrypted)
- 32 GB encrypted swap

**Network:**

- 1 GbE at 192.168.1.154
- MAC: `60:45:cb:9b:ab:3b` (enp0s31f6)
- NFSv4 server for bulk storage
- Suspend-on-idle, Wake-on-LAN capable
- OOB KVM: GL.iNet Comet PoE (GL-RM1PE) at 192.168.1.126 - 4K@30 HDMI capture,
  USB keyboard/mouse injection, Tailscale connectivity

---

### Artful (cloud)

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

### Steam Deck

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

### Mobile Devices

**Primary:** Samsung Galaxy A53 (Android)
**Use cases:**

- 2FA (Aegis)
- Remote access to self-hosted services

---
