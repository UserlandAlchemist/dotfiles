# Network Overview

This document describes the home network fabric, core devices, addressing, and WAN configuration for the Wolfpack.

See `README.md` for Project Shipshape naming conventions.

---

## Router

- **Model:** BT Smart Hub 2
- **Role:** Primary router, DHCP server, Wi-Fi AP
- **LAN Gateway:** 192.168.1.254
- **FTTP Profile:** 1000 Mbps downstream / 1000 Mbps upstream
- **Public Wi-Fi:** Disabled
- **UPnP:** Enabled (suitable for gaming, Steam Deck, and IoT)
- **DNS:** Per-device (router does not allow DNS override)

---

## Switch

- **Model:** TP-Link LS1008G (unmanaged, 8-port Gigabit)
- **Uplink:** Connected to BT Smart Hub 2
- **PoE:** Not supported (Comet powered via USB-C)

**Connected devices:**
- Wolfpack hosts (see `docs/hosts-overview.md` for details)
- glkvm (GL.iNet Comet - OOB KVM)
- hue-bridge (Philips Hue Zigbee hub)
- Steam Deck dock (when powered and docked)

---

## DHCP Reservations

Wolfpack host IPs and MACs live in `docs/hosts-overview.md`. This section only tracks infra devices.

| Device         | IP Address    | MAC Address       | Notes                   |
|----------------|---------------|-------------------|-------------------------|
| **glkvm**      | 192.168.1.126 | 94:83:c4:be:77:9e | GL.iNet Comet (OOB KVM) |
| **hue-bridge** | 192.168.1.210 | ec:b5:fa:22:e0:8f | Philips Hue Zigbee hub  |

---

## Wireless Devices (Summary)

Most IoT devices are connected via 2.4 GHz Wi-Fi.

Notable devices:
- **Tapo H200 hub**
- **Tapo C200 camera**
- **Echo Dot** (dual-band, currently on 5 GHz)
- Additional Tapo smart plugs/sensors

A detailed per-device accounting is not required for core Wolfpack documentation.

---

## WAN Information

- **Provider:** BT (FTTP)
- **Authentication:** PPPoE username `bthomehub@btbroadband.com` (no password required)
- **External IP:** Dynamic; changes periodically
- **DNS:** Cloudflare (1.1.1.1 / 1.0.0.1) used per-device

---

## APT Proxy (apt-cacher-ng)

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
- Installed via `root-network-audacious/install.sh` (real files in `/etc` and `/usr/local`)

---

## Notes

- LAN operates as a simple **192.168.1.0/24** flat network.
- The Comet KVM remains reachable when hosts are powered off, but video requires host power.
- No VLANs or managed switching currently in use.

---
