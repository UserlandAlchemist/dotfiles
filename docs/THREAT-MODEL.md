# Threat Model

Security assumptions, attack surfaces, acceptable risks, and defensive posture for Project Shipshape.

**Scope:** The Wolfpack (Audacious, Astute, Artful, Steam Deck, mobile devices)
**Last Updated:** 2026-01-05
**Status:** Initial threat model for security architecture decisions

---

## Threat Actors

### 1. External Network Attackers (Internet)

**Profile:** Opportunistic or targeted attackers from the public internet.

**Capabilities:**
- Network scanning and service enumeration
- Exploitation of internet-facing services
- DDoS and resource exhaustion attacks
- Credential stuffing and brute force

**Motivation:** Data theft, botnet recruitment, ransomware, cryptocurrency mining

**Current Exposure:**
- Router with UPnP enabled (potential automatic port forwarding)
- Artful VPS when active (public-facing services)
- Outbound connections from workstation (browser, applications)
- Dynamic WAN IP with no inbound firewall rules currently configured

**Risk Level:** Medium-High (increasing with any internet-facing services)

### 2. Local Network Attackers (LAN)

**Profile:** Compromised IoT devices, malicious guests, or lateral movement from breached devices.

**Capabilities:**
- Access to flat /24 network (no segmentation)
- Service discovery and exploitation on LAN
- Traffic sniffing on unencrypted protocols
- ARP spoofing and man-in-the-middle attacks

**Motivation:** Lateral movement, data exfiltration, persistent access

**Current Exposure:**
- Flat network: IoT devices (cameras, smart plugs, Echo Dot) share network with workstation/NAS
- NFSv4 without Kerberos (plaintext on LAN)
- No network segmentation or firewall between devices
- Multiple WiFi IoT devices with varying security postures

**Risk Level:** Medium (IoT devices are potential entry points)

### 3. Physical Access Attackers

**Profile:** Physical access to hardware (theft, "evil maid" attacks, unauthorized access).

**Capabilities:**
- Direct hardware access (USB, boot manipulation)
- Theft of devices or storage media
- Cold boot attacks on unencrypted RAM
- Firmware/BIOS manipulation

**Motivation:** Data theft, persistent backdoors, sabotage

**Current Exposure:**
- Home environment (limited to household members and guests)
- Blue USB key with secrets (physical security critical)
- Cold storage LUKS drive (physical security critical)
- No BIOS passwords documented
- Physical console access possible (keyboard/monitor)

**Risk Level:** Low (home environment) to Medium (if portable devices lost/stolen)

### 4. Supply Chain Attackers

**Profile:** Compromised software packages, malicious firmware updates, typosquatted packages.

**Capabilities:**
- Malicious packages in upstream repositories
- Compromised package signing keys
- Firmware backdoors
- Man-in-the-middle on package downloads

**Motivation:** Widespread compromise, espionage, data theft

**Current Exposure:**
- Debian package repositories (official sources, signed)
- Manual builds from source (sfizz, ZynAddSubFX, VCV Rack)
- Rust toolchain via rustup (community infrastructure)
- Firmware updates (CPU microcode, AMD GPU firmware)
- No package integrity monitoring beyond apt verification

**Risk Level:** Low-Medium (mitigated by using official repos and signatures)

### 5. Insider Threats (Operational Error)

**Profile:** Accidental misconfiguration, data loss, or exposure by authorized users.

**Capabilities:**
- Full administrative access to all systems
- Ability to modify or delete data
- Deployment of insecure configurations
- Accidental exposure of secrets

**Motivation:** Not malicious - human error, fatigue, lack of knowledge

**Current Exposure:**
- Single-user environment (no segregation of duties)
- Sudo access for system changes
- Manual secret management (Blue USB, not automated)
- No automated configuration drift detection (manual DRIFT-CHECK.md)
- Untested recovery procedures (disaster recovery drill pending)

**Risk Level:** Medium (most likely threat to realize)

---

## Attack Surfaces

### Network Attack Surface

**External (WAN):**
- Router with UPnP enabled (risk: automatic port forwarding by malicious apps)
- Dynamic external IP (no current inbound services documented)
- Artful VPS when active (SSH, web services - not currently deployed)
- Outbound connections from workstation (browser, package updates, git)

**Internal (LAN - 192.168.1.0/24):**
- Audacious (192.168.1.147):
  - No listening services exposed to LAN (pipewire-pulse local only in practice)
  - NFS client (connects to Astute)
  - SSH client (for Astute management)

- Astute (192.168.1.154):
  - NFSv4 server (port 2049, plaintext)
  - SSH server (port 22, key-based auth)
  - apt-cacher-ng (port 3142, HTTP cache)
  - Wake-on-LAN (broadcasts on LAN)

- GL.iNet Comet KVM (192.168.1.126):
  - Web interface for KVM access
  - Tailscale connectivity (potentially exposes to VPN network)
  - HDMI capture and USB injection capabilities

- IoT Devices (WiFi):
  - Tapo H200 hub, C200 camera (cloud-connected, unknown ports)
  - Echo Dot (cloud-connected Amazon services)
  - Philips Hue bridge (local control, cloud sync)
  - Various Tapo smart plugs

**Broadcast/Multicast:**
- Avahi/mDNS (service discovery)
- LLMNR (name resolution)
- DHCP (untrusted responses possible)

### Physical Attack Surface

**Direct Hardware Access:**
- Audacious: Desktop case with standard ATX access
- Astute: Server case (accessible via GL.iNet Comet KVM remotely)
- Steam Deck: Portable device (high theft risk)
- Mobile phone: Personal device (high loss/theft risk)

**Removable Media:**
- Blue USB key (secrets: SSH keys, Borg passphrases)
- Cold storage LUKS drive (monthly backup snapshots)
- SD cards (Steam Deck storage)

**Console Access:**
- Physical keyboard/mouse/monitor on Audacious
- GL.iNet Comet provides KVM access to Astute (network-based console)

### Authentication Attack Surface

**SSH:**
- Key-based authentication (good)
- SSH keys stored on Blue USB and deployed systems
- Forced commands for nas-inhibit (good - restricted)
- No 2FA on SSH (acceptable for home LAN)

**Local Login:**
- Audacious: Autologin to Sway (no password prompt)
- Astute: Console login via password or SSH keys
- Physical access = full system access on Audacious

**External Services:**
- GitHub: Code repository access (2FA unknown from docs)
- Bitwarden: Password vault access
- ChatGPT Plus: AI service access
- Cloudflare: DNS management

### Data at Rest

**Encrypted:**
- Audacious ZFS root (encrypted)
- Astute ZFS nas pool (encrypted)
- Astute swap (encrypted)
- Cold storage LUKS drive (encrypted)
- Borg backup repository (encrypted)

**Plaintext:**
- Astute ext4 root (not encrypted - lower value data)
- Logs and journals (may contain sensitive info)
- Configuration files in dotfiles repo (no secrets, but structure visible)

### Data in Transit

**Encrypted:**
- SSH (Audacious ↔ Astute management)
- HTTPS (browser, package downloads)
- Borg backups over SSH

**Plaintext:**
- NFSv4 (Audacious ↔ Astute, LAN-only, no Kerberos)
- apt-cacher-ng HTTP proxy (package content, LAN-only)
- Local network discovery (Avahi, mDNS)

---

## Trust Zones and Security Boundaries

### Zone 1: Trusted Core (High Trust)

**Scope:**
- Audacious workstation
- Astute NAS/server
- LAN network segment connecting them

**Trust Assumptions:**
- Physical security: Home environment, limited household access
- Network security: Direct wired connection, no untrusted devices inline
- Administrative control: Full control over all devices in zone
- Data sensitivity: Personal/project data, SSH keys, development work

**Security Requirements:**
- Encryption at rest for all sensitive data
- SSH key-based authentication between hosts
- Encrypted backups
- Version-controlled configuration

**Current Posture:** Strong (encryption, SSH hardening, good backup practices)

### Zone 2: Semi-Trusted Peripherals (Medium Trust)

**Scope:**
- GL.iNet Comet KVM (OOB management)
- Steam Deck (portable workstation)
- Mobile phone (2FA, remote access)

**Trust Assumptions:**
- Comet KVM: Trusted but network-exposed (Tailscale)
- Steam Deck: Trusted but portable (theft/loss risk)
- Mobile: Trusted but highest loss/theft risk

**Security Requirements:**
- Comet: Strong authentication, monitor for unauthorized access
- Steam Deck: Minimal secrets, can be wiped remotely if possible
- Mobile: 2FA app (Aegis) encrypted, screen lock enabled

**Current Posture:** Moderate (Comet has Tailscale exposure, portable devices not documented)

### Zone 3: Untrusted IoT (Low Trust)

**Scope:**
- Tapo cameras, smart plugs, sensors
- Philips Hue bridge
- Echo Dot

**Trust Assumptions:**
- Assume devices can be compromised
- Cloud connectivity is unknown/untrusted
- Firmware security unknown
- May have unpatched vulnerabilities

**Security Requirements:**
- Network isolation from trusted core (IDEAL, not current)
- No access to sensitive data or systems
- Monitor for unusual traffic patterns
- Consider expendable if compromised

**Current Posture:** Weak (flat network, no isolation, shares network with workstation/NAS)

### Zone 4: Internet (Untrusted)

**Scope:**
- Public internet
- External services (GitHub, Bitwarden, ChatGPT, Cloudflare)
- Artful VPS when active

**Trust Assumptions:**
- Hostile environment
- Active scanning and exploitation attempts
- External services may be compromised or experience breaches

**Security Requirements:**
- Firewall with default-deny on WAN interface
- No unnecessary inbound services
- Strong authentication for all external services
- Encryption for all external communication
- Assume data sent to external services may be exposed

**Current Posture:** Weak (no firewall, UPnP enabled, Artful security posture unknown)

---

## Acceptable Risks and Mitigations

### Risk: Compromised IoT Device Lateral Movement

**Scenario:** Tapo camera or Echo Dot compromised, attacker pivots to workstation/NAS on flat network.

**Current State:** No network segmentation, all devices on 192.168.1.0/24

**Options:**
1. **Accept Risk (Low effort):**
   - Rationale: Home environment, limited exposure
   - Mitigation: Monitor for unusual traffic, keep IoT firmware updated where possible
   - Residual risk: Medium (data exfiltration, ransomware possible)

2. **Implement Network Segmentation (High effort):**
   - Separate VLAN for IoT devices
   - Firewall rules between VLANs
   - Requires managed switch and router configuration
   - Residual risk: Low

**Decision:** **Accept risk with monitoring** (Phase 1). IoT segmentation is future enhancement after core security (firewall, monitoring) in place. Home environment risk is lower than enterprise.

### Risk: NFSv4 Plaintext Traffic on LAN

**Scenario:** Attacker on LAN (compromised IoT or malicious guest) sniffs NFS traffic, reads file content.

**Current State:** NFSv4 without Kerberos, plaintext on trusted LAN

**Options:**
1. **Accept Risk (Low effort):**
   - Rationale: LAN is trusted, physical home environment
   - Mitigation: Keep LAN physically secure, monitor for rogue devices
   - Residual risk: Low-Medium (requires LAN access first)

2. **Implement NFS with Kerberos (High effort):**
   - Deploy Kerberos KDC
   - Configure NFSv4 with sec=krb5p
   - Operational complexity increase
   - Residual risk: Very Low

**Decision:** **Accept risk** (indefinite). Home LAN is physically controlled environment. NFS traffic between workstation and NAS is trusted. Encryption at rest provides protection if storage compromised. Kerberos adds significant operational overhead for marginal security gain in this threat model.

### Risk: No Firewall on Audacious/Astute

**Scenario:** Service vulnerability exposed to LAN (or WAN via UPnP), remote exploitation.

**Current State:** nftables installed but inactive, no host-based firewall

**Options:**
1. **Accept Risk (Low effort):**
   - NOT acceptable - this is a known critical gap

2. **Implement Host-Based Firewall (Medium effort):**
   - Configure nftables on both hosts
   - Default-deny, allow specific services (SSH, NFS, apt-cacher-ng)
   - Block unexpected outbound connections
   - Residual risk: Low

**Decision:** **MUST IMPLEMENT** (Phase 3, priority P1-High already in queue). This is prerequisite security control. Not negotiable.

### Risk: UPnP Enabled on Router

**Scenario:** Malicious application on workstation opens port via UPnP, exposes service to internet.

**Current State:** UPnP enabled for gaming/Steam Deck convenience

**Options:**
1. **Disable UPnP (Low effort):**
   - Breaks automatic port forwarding for games
   - Requires manual port forwarding when needed
   - Residual risk: Very Low

2. **Keep UPnP Enabled (Current):**
   - Convenience for gaming
   - Risk: Malware could open ports
   - Mitigation: Host-based firewall (blocks inbound even if port forwarded)
   - Residual risk: Low (with host firewall)

**Decision:** **Keep UPnP enabled, mitigate with host firewall**. Gaming/Steam Deck convenience is valuable. Host-based firewall on Audacious will prevent exploitation even if UPnP opens ports. Monitor router for unexpected forwarding rules periodically.

### Risk: Autologin on Audacious

**Scenario:** Physical access to workstation = immediate full access without password.

**Current State:** Audacious autologins to Sway, no password prompt

**Options:**
1. **Require Password Login (Low effort):**
   - Prompts for password on boot
   - Protects against casual physical access
   - Residual risk: Low (for casual access)

2. **Keep Autologin (Current):**
   - Convenience for single-user home workstation
   - Physical security is home environment
   - Disk encryption protects data if hardware stolen
   - Residual risk: Medium (for physical access attacks)

**Decision:** **Keep autologin** (current). Home environment with household-only access. Disk encryption protects against theft (attacker gets encrypted drive, not running system). Convenience outweighs risk for this use case. Re-evaluate if threat model changes (shared living space, etc.).

### Risk: No 2FA on SSH

**Scenario:** SSH key compromised, attacker gains access without second factor.

**Current State:** SSH key-based auth only, no 2FA

**Options:**
1. **Implement SSH 2FA (Medium effort):**
   - TOTP or hardware key (Yubikey)
   - Protects against key theft
   - Operational overhead for every SSH session
   - Residual risk: Very Low

2. **Keep Key-Only Auth (Current):**
   - Keys stored securely (Blue USB for offline, deployed for convenience)
   - LAN-only SSH access (not internet-facing)
   - Residual risk: Low (requires key compromise + LAN access)

**Decision:** **Keep key-only auth** (current). SSH is LAN-only, not internet-facing. Key compromise requires either physical access (Blue USB theft) or system compromise (in which case 2FA wouldn't help). Re-evaluate if SSH becomes internet-facing or if keys stored on less-secure devices.

### Risk: Untested Disaster Recovery

**Scenario:** Disaster strikes, recovery procedures fail due to untested assumptions.

**Current State:** Comprehensive recovery documentation, but never tested in practice

**Options:**
1. **Accept Risk (Low effort):**
   - NOT acceptable - recovery is critical

2. **Execute Disaster Recovery Drill (High effort):**
   - Test INSTALL.audacious.md in VM
   - Test Borg restore procedures
   - Verify Blue USB secret recovery
   - Identify gaps and fix documentation
   - Residual risk: Very Low

**Decision:** **MUST IMPLEMENT** (Phase 2, task #7 already in queue). Recovery documentation is only theoretical until tested. VM testing environment (task #5) is prerequisite. High priority for Principle 3 (Resilience).

### Risk: No Monitoring or Alerting

**Scenario:** Silent failures (backup failure, disk errors, service crashes) go unnoticed for days/weeks.

**Current State:** No automated monitoring, manual checks only

**Options:**
1. **Accept Risk (Low effort):**
   - NOT acceptable for critical systems (backups, ZFS)

2. **Implement Basic Monitoring (Medium effort):**
   - Systemd OnFailure handlers for critical services
   - ZFS scrub status checks
   - SMART monitoring for disks
   - Backup success/failure notifications
   - Residual risk: Low

**Decision:** **MUST IMPLEMENT** (Phase 3, task #9 already in queue). Astute runs headless and suspends frequently - silent failures are high risk. Backups are critical and must be monitored. Basic monitoring is non-negotiable for reliable infrastructure.

---

## Security Posture Summary

### Current Strengths

**Encryption:**
- Strong encryption at rest (ZFS, LUKS)
- Encrypted backups (Borg)
- SSH for remote management

**Authentication:**
- SSH key-based auth (better than passwords)
- Forced commands for restricted operations
- Secrets stored offline (Blue USB)

**Resilience:**
- Multiple backup layers (Borg, cold storage)
- Comprehensive recovery documentation
- Version-controlled configuration

**Isolation:**
- Per-host package isolation
- Open standards (portable, swappable)

### Critical Gaps

**Host Firewall:**
- Status: Missing (nftables inactive)
- Impact: Services exposed to LAN without filtering
- Priority: P1-High (MUST FIX)

**Network Segmentation:**
- Status: Flat /24 network, IoT shares with workstation/NAS
- Impact: Compromised IoT can pivot to sensitive systems
- Priority: P2-Medium (ACCEPT RISK for now, future improvement)

**Monitoring:**
- Status: No automated monitoring or alerting
- Impact: Silent failures go undetected
- Priority: P1-High (MUST FIX)

**Recovery Testing:**
- Status: Documentation untested
- Impact: Recovery may fail when needed
- Priority: P1-High (MUST TEST)

### Defense-in-Depth Strategy

**Layer 1: Network Perimeter**
- Router (BT Smart Hub 2) - basic NAT/firewall
- UPnP enabled (accepted risk with mitigation)
- No inbound services currently (Artful inactive)

**Layer 2: Host-Based Firewall (TO BE IMPLEMENTED)**
- nftables on Audacious and Astute
- Default-deny, explicit allows
- Blocks lateral movement even on flat network

**Layer 3: Application Hardening**
- SSH key-based auth, forced commands
- Sudo configurations for least privilege
- Service-specific restrictions

**Layer 4: Encryption**
- Data at rest (ZFS, LUKS)
- Data in transit (SSH, HTTPS)
- Backups (Borg encryption)

**Layer 5: Monitoring and Response (TO BE IMPLEMENTED)**
- Automated alerts for failures
- Regular integrity checks
- Backup validation

**Layer 6: Recovery**
- Offline backups (Blue USB, cold storage)
- Comprehensive documentation
- Testing (to be executed)

---

## Guidance for Implementation

### Firewall Implementation (Task #10)

Based on this threat model:

**Default Policy:** DENY all inbound, DENY all forwarding, ALLOW outbound (with logging)

**Audacious Inbound Allow:**
- None required (workstation, client-only)
- Consider: ICMP (ping) from LAN for diagnostics
- Consider: SSH from LAN for remote administration (if needed)

**Astute Inbound Allow:**
- SSH (port 22) from Audacious only (192.168.1.147)
- NFSv4 (port 2049) from Audacious only
- RPC (port 111) from Audacious only
- apt-cacher-ng (port 3142) from Audacious only
- ICMP (ping) from LAN

**Outbound Restrictions:**
- Log unexpected outbound connections for monitoring
- Allow: SSH, HTTP, HTTPS, DNS, NTP
- Consider blocking: Unexpected protocols (flag for investigation)

**Inter-Zone Rules:**
- Trusted Core ↔ Trusted Core: Permissive
- Trusted Core ← IoT: DENY (IoT cannot initiate to core)
- Trusted Core → IoT: ALLOW (core can manage IoT if needed)

### Monitoring Implementation (Task #9)

Based on this threat model, monitor:

**Critical Priorities:**
- Borg backup success/failure (daily)
- ZFS scrub errors or pool degradation (weekly)
- Systemd service failures for critical services
- Disk SMART failures

**Medium Priorities:**
- Unusual network connections
- Failed SSH attempts
- Sudo usage (audit log)
- Package installation/removal

**Low Priorities:**
- System resource usage trends
- Temperature monitoring (Astute headless)

### Network Segmentation (Future)

If threat model changes (e.g., untrusted guests, increased IoT attack frequency):

1. Acquire managed switch with VLAN support
2. Create VLANs:
   - VLAN 10: Trusted Core (Audacious, Astute)
   - VLAN 20: Peripherals (Comet KVM, Steam Deck when docked)
   - VLAN 30: IoT (cameras, smart plugs, Hue, Echo)
   - VLAN 99: Guest (if needed)
3. Implement firewall rules between VLANs
4. Test thoroughly before production deployment

---

## Threat Model Maintenance

**Review Cadence:**
- Annual review (same time as disaster recovery drill)
- After major infrastructure changes (new services, network changes)
- After security incidents (real or near-miss)
- When adding new device types (e.g., NAS, servers, IoT categories)

**Triggers for Re-evaluation:**
- Internet-facing services deployed (Artful activation)
- Living situation changes (shared housing, guests)
- New attack vectors discovered in infrastructure
- External service compromises (GitHub, Bitwarden, etc.)
- UK legal landscape changes affecting email hosting

**Document Updates:**
- Keep aligned with actual implementation (not aspirational)
- Update acceptable risk decisions as mitigations are implemented
- Track residual risk over time

---

**Last Updated:** 2026-01-05
**Next Review:** 2027-01-05 or upon triggering event
