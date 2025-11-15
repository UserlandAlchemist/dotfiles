# Network Overview

This document describes the home network fabric, core devices, addressing, and WAN configuration. It supports fast recovery, clarity, and long-term maintainability within the Wolfpack architecture.

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

**Ports in use (7/8):**
- Port 1: audacious, astute, glkvm (Comet), hue-bridge (wired connections via patch panel / hub connection)
- Additional connected devices via Ethernet: Steam Deck dock (when powered)

---

## Core Wired Devices (DHCP Reservations)
| Device          | IP Address       | MAC Address          | Notes                      |
|-----------------|------------------|------------------------|-----------------------------|
| **audacious**    | 192.168.1.147    | D8:5E:D3:AC:E3:E7     | Main workstation            |
| **astute**       | 192.168.1.154    | 60:45:CB:9B:AB:3B     | Server / NAS                |
| **glkvm**        | 192.168.1.126    | 94:83:C4:BE:77:9E     | GL.iNet Comet (OOB KVM)     |
| **hue-bridge**   | 192.168.1.210    | EC:B5:FA:22:E0:8F     | Philips Hue Zigbee bridge   |
| **steamdeck-dock** (when powered) | (varies) | (Realtek prefix) | Benazcap 7-in-1 dock |

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

## Notes
- LAN operates as a simple **192.168.1.0/24** flat network.
- The Comet KVM remains reachable when hosts are powered off, but video requires host power.
- No VLANs or managed switching currently in use.

---

