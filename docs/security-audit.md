# Security Audit - Project Shipshape

**Date:** 2026-01-07
**Scope:** Audacious (workstation) + Astute (NAS/server)
**Status:** Phase 1 security fixes deployed, comprehensive audit complete

---

## Executive Summary

**Overall Security Posture:** GOOD

Phase 1 critical security fixes (SSH hardening, host firewall) successfully deployed and operational. Both hosts are fully patched, firewalls actively blocking unwanted traffic, and no suspicious activity detected. Minor improvements recommended for automation and key management.

**Critical Findings:** None (all P0 issues resolved)

**High Priority Recommendations:**
1. Enable unattended-upgrades on Audacious (Astute already configured)
2. Clean up duplicate SSH keys on Audacious
3. Document or restrict Astute services listening on 0.0.0.0

---

## 1. Network Services Inventory

### Audacious (Workstation)

**Listening TCP Services:**
- `127.0.0.53:53` - systemd-resolved (local DNS)
- `127.0.0.54:53` - systemd-resolved (local DNS, secondary)
- `0.0.0.0:111` - rpcbind (NFS client support)
- `0.0.0.0:4713` - pipewire-pulse (PulseAudio compatibility)
- `0.0.0.0:5355` - systemd-resolved (LLMNR)
- `192.168.122.1:53` - libvirt dnsmasq (VM networking)
- Steam/Discord/Wine - various localhost ports (gaming/desktop apps)

**Status:** ✓ No SSH server (client-only, correct)
**Status:** ✓ Firewall active, blocking inbound connections
**Dropped packets:** 8,171+ (IoT devices, mDNS, broadcasts)

### Astute (NAS/Server)

**Listening TCP Services:**
- `192.168.1.154:22` - SSH (LAN-only, hardened) ✓
- `0.0.0.0:2049` - NFSv4 server
- `0.0.0.0:111` - rpcbind (NFS support)
- `0.0.0.0:3142` - apt-cacher-ng (package proxy)
- `0.0.0.0:6600` - MPD (Music Player Daemon)
- `0.0.0.0:8096` - Jellyfin Media Server
- Various ephemeral NFS ports (39243, 52627, 54177, etc.)

**Status:** ✓ SSH restricted to LAN IP only
**Status:** ✓ Firewall active, restricting access to Audacious IP only
**Dropped packets:** 328+ (IoT devices, DHCPv6, broadcasts)

**NOTE:** Jellyfin (8096) and MPD (6600) listening on 0.0.0.0 but protected by firewall (only Audacious can connect).

---

## 2. Running Services Analysis

### Audacious Services

**System:**
- accounts-daemon, dbus, cron
- avahi-daemon (mDNS service discovery)
- libvirtd (VM management - inactive VMs)
- nfs-blkmap, rpcbind (NFS client)
- polkit, rtkit-daemon, power-profiles-daemon
- udisks2, upower (hardware management)
- zfs-zed (ZFS event monitoring)

**Status:** ✓ No unexpected services
**Status:** ✓ No unnecessary daemons

### Astute Services

**System:**
- apt-cacher-ng (package proxy for LAN)
- jellyfin (media server)
- mpd (music player daemon)
- nas-inhibit (custom sleep inhibitor)
- nfs-mountd, nfs-idmapd, nfs-blkmap, nfsdcld, rpc-statd (NFSv4 server stack)
- smartmontools (disk health monitoring)
- ssh (OpenSSH server)
- zfs-zed (ZFS event monitoring)

**Status:** ✓ All services expected and documented
**Status:** ✓ smartmontools active (good - disk health monitoring)

---

## 3. Authentication & Access Control

### SSH Configuration

**Audacious:**
- No SSH server installed ✓
- SSH client only (connects to Astute)

**Astute:**
- ListenAddress: 192.168.1.154 (LAN-only) ✓
- PasswordAuthentication: no ✓
- KbdInteractiveAuthentication: no ✓
- PermitRootLogin: no ✓
- Key-based auth only ✓

**Status:** ✓ SSH properly hardened

### Sudoers Configuration

**Audacious:**
```
/etc/sudoers.d/nas-mount.sudoers
- alchemist can start/stop srv-astute.mount (NAS mounting)
- NOPASSWD for mount control only
```

**Astute:**
```
/etc/sudoers.d/nas-inhibit.sudoers
- alchemist (from Audacious) can control nas-inhibit service
- alchemist (from Audacious) can trigger astute-idle-suspend
- alchemist (from Audacious) can read idle-suspend logs
- NOPASSWD for specific systemctl/journalctl commands only
```

**Status:** ✓ Sudoers rules minimal and specific
**Status:** ✓ No passwordless root access
**Status:** ✓ Principle of least privilege applied

---

## 4. Cryptographic Key Inventory

### SSH Keys - Audacious

Located in `/home/alchemist/.ssh/`:
- `audacious-backup` / `audacious-backup.pub` - Borg backup to Astute
- `id_alchemist` / `id_alchemist.pub` - General purpose key
- `id_astute_nas` / `id_astute_nas.pub` - NFS/NAS access (current)
- `id_ed25519_astute_nas` / `id_ed25519_astute_nas.pub` - Old NAS key (duplicate?)

**Finding:** Two similar keys for Astute NAS access (id_astute_nas and id_ed25519_astute_nas)

**Recommendation:** Identify which key is active, remove the unused one

### SSH Keys - Astute

Located in `/home/alchemist/.ssh/`:
- `authorized_keys` - Contains public keys for Audacious access
- `known_hosts` - SSH host fingerprints

**Status:** ✓ No private keys on Astute (correct - server-only)
**Status:** ✓ No root SSH directory (root login disabled)

### GPG Keys

**Audacious:**
- Debian CD signing keys only (package verification)
- No personal GPG keys

**Astute:**
- No GPG keys configured
- Fresh GnuPG directory

**Status:** ✓ No unused personal GPG keys to clean up
**Note:** GPG not currently used for encryption/signing

---

## 5. Update & Patch Management

### Audacious

- **Patch Status:** Fully updated (0 pending updates)
- **Unattended Upgrades:** NOT INSTALLED
- **Apt List Changes:** Installed (notification tool)

**Recommendation:** Install and configure unattended-upgrades for security patches

### Astute

- **Patch Status:** Fully updated (0 pending updates)
- **Unattended Upgrades:** ✓ INSTALLED AND ACTIVE
- **Apt List Changes:** Installed (notification tool)

**Status:** ✓ Astute has automated security updates configured

---

## 6. Firewall Analysis

### Audacious Firewall (nftables)

**Ruleset:** Default-deny inbound, allow outbound
**Active:** ✓ Yes (since 2026-01-07 13:13:29)

**Allowed Inbound:**
- Established/related connections
- Loopback
- ICMP from LAN (192.168.1.0/24)
- DHCPv6 replies (UDP 67→68 from LAN)

**Dropped Packets (8,171+):**
- 192.168.1.210 - mDNS broadcasts (port 5353)
- 192.168.1.68 - Unknown broadcasts (port 6667)
- 192.168.1.94 - Unknown broadcasts (port 20002)

**Status:** ✓ Firewall working correctly, blocking unwanted traffic

### Astute Firewall (nftables)

**Ruleset:** Default-deny inbound, restrict to Audacious IP only
**Active:** ✓ Yes (since 2026-01-06 17:07:45)

**Allowed Inbound (from 192.168.1.147 only):**
- SSH (22/tcp)
- NFSv4 (2049/tcp)
- RPC bind (111/tcp, 111/udp)
- apt-cacher-ng (3142/tcp)
- ICMP from LAN
- DHCPv6 replies from LAN

**Dropped Packets (328+):**
- 192.168.1.68 - Unknown broadcasts (port 6667)
- 192.168.1.94 - Unknown broadcasts (port 20002)
- 8c:83:94:94:b8:e9 - DHCPv6 traffic from unknown device

**Status:** ✓ Firewall working correctly
**Status:** ✓ IoT lateral movement blocked

---

## 7. Log Analysis (Past 7 Days)

### Audacious Logs

**Reviewed:** journalctl -p warning -S "1 week ago"

**Findings:**
- Only firewall drops logged (expected behavior)
- No authentication failures
- No service crashes
- No kernel panics or errors
- No suspicious connection attempts

**Status:** ✓ Clean logs, no security concerns

### Astute Logs

**Reviewed:** journalctl -p warning -S "1 week ago"

**Findings:**
- Only firewall drops logged (expected behavior)
- No authentication failures
- No SSH brute-force attempts
- No service crashes
- No ZFS errors
- No disk SMART warnings

**Status:** ✓ Clean logs, no security concerns

---

## 8. IoT Device Identification

**Devices Probing Network:**

1. **192.168.1.210** (ec:b5:fa:22:e0:8f)
   - Activity: mDNS service discovery (port 5353)
   - Frequency: Constant
   - Status: Being blocked by firewall ✓

2. **192.168.1.68** (d8:d6:68:b7:1f:d8)
   - Activity: Broadcast to port 6667
   - Frequency: Every 5 seconds
   - Status: Being blocked by firewall ✓

3. **192.168.1.94** (8c:86:dd:9f:c7:bb)
   - Activity: Broadcast to port 20002
   - Frequency: Bursts
   - Status: Being blocked by firewall ✓

4. **Unknown** (8c:83:94:94:b8:e9)
   - Activity: DHCPv6 client (targeting Astute specifically)
   - Frequency: Regular intervals
   - Status: Being blocked by firewall ✓

**Recommendation:** Document what these devices are for inventory purposes (see threat model section on IoT lateral movement)

---

## 9. Comparison with Threat Model

### Security Gaps Previously Identified (2026-01-06)

1. **Router firewall disabled** → ✓ FIXED (set to Default)
2. **SSH on 0.0.0.0** → ✓ FIXED (locked to 192.168.1.154)
3. **No host firewall** → ✓ FIXED (nftables active on both hosts)
4. **UPnP enabled with Extended Security** → ACCEPTED RISK (host firewall mitigates)
5. **No SSH server on Audacious** → ✓ CORRECT (verified)
6. **No port forwarding rules** → ✓ VERIFIED (still none)
7. **DMZ disabled** → ✓ VERIFIED (still disabled)

**Status:** All critical gaps from initial audit RESOLVED ✓

### Current Risk Assessment

**External Network Attackers:**
- Previous: Medium-High (no firewall, UPnP)
- Current: **Low** (host firewall + router firewall active)

**Local Network Attackers (IoT):**
- Previous: Medium (flat network, no filtering)
- Current: **Low-Medium** (host firewall blocks lateral movement)

**Physical Access Attackers:**
- Status: **Low-Medium** (encryption at rest, autologin accepted)

**Supply Chain Attackers:**
- Status: **Low-Medium** (official repos, signed packages)

**Insider Threats (Operational Error):**
- Status: **Medium** (single user, most likely to realize)

---

## 10. Recommendations

### P1 - High Priority

**1. Enable Unattended Upgrades on Audacious**
- Package: unattended-upgrades
- Reason: Astute already configured, Audacious needs parity
- Config: Security updates only, exclude kernel (ZFS compatibility)
- Timeline: This week

**2. Clean Up Duplicate SSH Keys (Audacious)**
- Keys: id_astute_nas vs id_ed25519_astute_nas
- Action: Identify active key via authorized_keys on Astute
- Action: Remove unused key from Audacious
- Action: Update secrets-recovery.md if key references change

**3. Document IoT Device Inventory**
- Devices: 192.168.1.210, 192.168.1.68, 192.168.1.94, unknown DHCPv6
- Action: Identify what these devices are
- Action: Update network topology documentation
- Reason: IoT compromise is accepted risk in threat model, should know what's on network

### P2 - Medium Priority

**4. Review Astute Service Exposure**
- Services: Jellyfin (8096), MPD (6600) listening on 0.0.0.0
- Current: Protected by firewall (Audacious-only access)
- Consider: Bind to LAN IP (192.168.1.154) instead
- Benefit: Defense-in-depth (service + firewall restriction)

**5. Document Service Inventory**
- Create: docs/SERVICE-INVENTORY.md
- Content: All listening services, ports, purpose, access control
- Baseline for future audits

**6. Backup Key Coverage Verification**
- Location: Blue USB secret recovery
- Verify: All active SSH keys backed up
- Verify: authorized_keys file backed up
- Update: secrets-recovery.md with current key paths

### P3 - Low Priority

**7. Consider GPG Key Setup**
- Use case: Sign git commits
- Use case: Encrypt sensitive notes
- Status: Optional (not currently needed)

**8. Monitor Firewall Drop Rates**
- Current: ~8K drops on Audacious, ~300 on Astute
- Action: Track over time for anomaly detection
- Integration: Could add to monitoring/alerting (Phase 5, Task #14)

---

## 11. Compliance with Best Practices

**PASS:**
- ✓ Principle of least privilege (sudoers, SSH)
- ✓ Defense-in-depth (router + host firewall)
- ✓ Encryption at rest (ZFS native encryption)
- ✓ Encryption in transit (SSH for remote access, NFSv4 over LAN)
- ✓ Regular patching (both hosts fully updated)
- ✓ Service minimization (only necessary daemons running)
- ✓ Logging enabled (journald, firewall drops)
- ✓ Key-based authentication (no passwords)
- ✓ Root login disabled (SSH)

**PARTIAL:**
- ~ Automated updates (Astute yes, Audacious no)
- ~ Service binding (some services on 0.0.0.0, others on specific IPs)

**NOT APPLICABLE:**
- N/A Multi-factor authentication (LAN-only SSH, not needed per threat model)
- N/A Network segmentation (flat network, accepted risk)
- N/A Intrusion detection system (deferred to Phase 5)

---

## 12. Audit Methodology

**Tools Used:**
- ss (network socket inspection)
- systemctl (service enumeration)
- journalctl (log analysis)
- nft (firewall rule inspection)
- dpkg/apt (package inventory)
- file system inspection (SSH keys, GPG, sudoers)

**Coverage:**
- ✓ Network services
- ✓ Running processes
- ✓ Authentication configuration
- ✓ Cryptographic keys
- ✓ Patch status
- ✓ Firewall rules
- ✓ Security logs
- ✓ Threat model alignment

**Limitations:**
- Did not perform penetration testing
- Did not audit application-level security (Jellyfin, MPD configs)
- Did not review router configuration in detail (user verified)
- Did not audit ZFS pool permissions/ACLs

---

## 13. Conclusion

**Overall Assessment:** STRONG

Phase 1 critical security fixes successfully addressed all high-risk gaps identified in the 2026-01-06 partial audit. Both hosts now have:
- Hardened SSH configuration (LAN-only, key-based)
- Active host-based firewalls (nftables, default-deny)
- Current security patches
- Minimal attack surface
- Clean security logs

The security posture has improved from **Medium-High risk** to **Low risk** for external/network threats. Remaining risks are documented in the threat model and accepted as trade-offs for usability and operational simplicity.

Recommended next steps:
1. Implement P1 recommendations (unattended-upgrades, key cleanup, IoT inventory)
2. Proceed with Phase 3 tasks (off-site backup, install library, VM testing)
3. Revisit security audit annually or after major infrastructure changes

**Audit Status:** COMPLETE
**Next Audit:** 2027-01-07 (annual) or after major changes

---

## Appendix: Service Port Reference

**Common Ports Observed:**
- 22/tcp - SSH
- 53/tcp+udp - DNS
- 67/udp - DHCP server
- 68/udp - DHCP client
- 111/tcp+udp - RPC bind (NFS)
- 546/udp - DHCPv6 client
- 547/udp - DHCPv6 server
- 2049/tcp - NFSv4
- 3142/tcp - apt-cacher-ng
- 4713/tcp - PulseAudio/Pipewire
- 5353/udp - mDNS (multicast DNS)
- 5355/udp - LLMNR (Link-Local Multicast Name Resolution)
- 6600/tcp - MPD (Music Player Daemon)
- 6667/tcp - IRC (but observed as unknown broadcast)
- 8096/tcp - Jellyfin
- 20002/udp - Unknown (device-specific)
