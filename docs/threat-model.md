# Threat Model

Security assumptions, attack surfaces, acceptable risks, and defensive posture for Project Shipshape.

**Scope:** The Wolfpack (Audacious, Astute, Artful, Steam Deck, mobile devices)
**Last Updated:** 2026-01-06
**Status:** Updated after security audit - router firewall disabled, SSH exposure found

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
- **CRITICAL FINDING (2026-01-06):** Router firewall was completely disabled until audit
- Router firewall now set to Default (block unsolicited inbound, allow outbound)
- UPnP enabled (potential automatic port forwarding, Extended UPnP Security ON)
- SSH on Astute listening on 0.0.0.0 (all interfaces), not restricted to LAN IP
- No host-based firewall active (nftables installed but inactive)
- Artful VPS when active (public-facing services, currently inactive)
- Outbound connections from workstation (browser, applications)
- Dynamic WAN IP with no inbound firewall rules currently configured

**Risk Level:** Critical (recently mitigated to Medium-High) - router firewall disabled meant zero perimeter protection, SSH potentially exposed via UPnP

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
- Secrets USB key with secrets (physical security critical)
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
- Manual secret management (Secrets USB, not automated)
- No automated configuration drift detection (manual drift-check.md)
- Untested recovery procedures (disaster recovery drill pending)

**Risk Level:** Medium (most likely threat to realize)

### 6. State-Level Mass Surveillance (UK)

**Profile:** UK government mass surveillance via ISP under legal frameworks (Investigatory Powers Act 2016, Online Safety Act 2023).

**Capabilities:**
- Full visibility of unencrypted traffic at ISP level
- DNS query logging (what domains accessed, when)
- Connection metadata collection (who, when, how much data, where)
- Deep packet inspection on unencrypted traffic
- Legal compulsion of service providers to retain data
- Bulk interception warrants (mass, not targeted)

**Motivation:** Mass surveillance for national security and law enforcement purposes, not targeted individual surveillance (at current threat level)

**Current Exposure:**
- ISP considered compromised (legal obligation to cooperate with surveillance)
- All DNS queries visible to ISP (no encrypted DNS)
- HTTPS metadata visible (destination IPs, timing, volume)
- Unencrypted HTTP completely visible
- No VPN currently deployed (all traffic routes through ISP)
- External service usage traceable (GitHub, Bitwarden, ChatGPT)

**Risk Level:** High (for privacy and metadata exposure), Low (for targeted action at current threat level)

**Mitigations Needed:**
- VPN for sensitive browsing (encrypts traffic from local → VPN endpoint)
- Encrypted DNS (DNS-over-HTTPS or DNS-over-TLS)
- HTTPS everywhere (already mostly in place)
- Consider Tor for highest-sensitivity activities (if threat level escalates)

---

## Attack Surfaces

### Network Attack Surface

**External (WAN):**
- BT Smart Hub 2 router (firewall now on Default - was completely disabled until 2026-01-06)
- UPnP enabled with Extended UPnP Security ON (risk: automatic port forwarding by malicious apps)
- No manual port forwarding rules configured
- DMZ disabled
- Dynamic external IP (no current inbound services documented)
- Artful VPS when active (SSH, web services - not currently deployed)
- Outbound connections from workstation (browser, package updates, git)
- ISP considered compromised (UK legal interception obligations)

**Internal (LAN - 192.168.1.0/24):**
- Audacious (192.168.1.147):
  - No listening services exposed to LAN (pipewire-pulse local only in practice)
  - NFS client (connects to Astute)
  - SSH client (for Astute management)

- Astute (192.168.1.154):
  - NFSv4 server (port 2049, plaintext)
  - SSH server (port 22, key-based auth)
    - **SECURITY GAP:** Listening on 0.0.0.0 (all interfaces), not restricted to LAN IP
    - Should be: ListenAddress 192.168.1.154 (LAN-only)
    - Current config: No ListenAddress restriction in sshd_config
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
- Secrets USB key (secrets: SSH keys, Borg passphrases)
- Cold storage LUKS drive (monthly backup snapshots)
- SD cards (Steam Deck storage)

**Console Access:**
- Physical keyboard/mouse/monitor on Audacious
- GL.iNet Comet provides KVM access to Astute (network-based console)

### Authentication Attack Surface

**SSH:**
- Key-based authentication (good)
- SSH keys stored on Secrets USB and deployed systems
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

**Visible to ISP (Mass Surveillance Risk):**
- All DNS queries (plaintext to ISP DNS servers)
- HTTPS connection metadata (destination IPs, timing, volume)
- Unencrypted HTTP (full content visible)
- No VPN currently deployed (all traffic routes through ISP)
- External service connections traceable (GitHub, Bitwarden, ChatGPT, etc.)

---

## Specific Attack Scenarios

### Ransomware Attack

**Threat Profile:** Opportunistic or targeted ransomware that encrypts data and demands payment for decryption keys.

**Attack Vectors:**
- Browser exploit (compromised website, malicious ad)
- Supply chain compromise (malicious package update)
- Phishing/social engineering (malicious download)
- Vulnerability exploitation in internet-facing service
- Lateral movement from compromised IoT device

**Capabilities if Successful:**
- File encryption across accessible filesystems
- Backup deletion to prevent recovery
- Data exfiltration before encryption (double extortion)
- Persistence mechanisms for re-infection
- Network propagation to other systems

**Current Protections:**

✓ **Implemented:**
- Router firewall blocks unsolicited inbound (prevents direct exploitation)
- Host firewalls on Audacious and Astute (limits lateral movement)
- SSH hardened to LAN-only (prevents remote access path)
- Borg backups with encryption (6-hourly to Astute, 7-day retention)
- Off-site backups to BorgBase (append-only, daily)
- ZFS snapshots (read-only, cannot be encrypted by unprivileged malware)
- Disk encryption (LUKS) protects data at rest
- Cold storage offline backups (monthly, physically disconnected)
- Secrets USB offline key backup (LUKS encrypted)

✗ **Gaps:**
- No real-time backup monitoring/alerting (Task #9, P1-High)
- Recovery procedures untested (Task #8, P1-High)
- No application sandboxing (AppArmor disabled)
- Browser runs with full user privileges (no isolation)
- No automated integrity checking (AIDE/Tripwire not deployed)

**Risk Level:** Medium

**Residual Risk After All Protections:** Low-Medium
- Local backups provide 6-hour RPO (Recovery Point Objective)
- Off-site append-only backups survive root compromise
- Offline backups (cold storage, Secrets USB) provide last resort
- Multiple backup layers make complete data loss unlikely

**Likelihood:** Medium (browser exploits, supply chain attacks possible)
**Impact if No Backups:** Critical (total data loss, productivity loss)
**Impact with Current Backups:** Low (restore from off-site, <24hr data loss)

**Recovery Plan:**
1. Disconnect infected system from network immediately
2. Identify infection extent and affected systems
3. Do NOT pay ransom (backups eliminate need)
4. Restore from most recent clean backup:
   - Primary: Borg backup from Astute (6-hour RPO)
   - Secondary: Off-site BorgBase (24-hour RPO)
   - Tertiary: Cold storage (30-day RPO)
5. Analyze infection vector and patch vulnerability
6. Monitor for re-infection

**Decision:** **Accept residual risk** with strong backup strategy. Defense-in-depth backup approach (local + off-site append-only + offline) makes ransomware ineffective. Focus on backup integrity and tested recovery over prevention-only strategies.

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

**CRITICAL FINDING (2026-01-06):** Router firewall was completely disabled (now fixed - set to Default). Combined with SSH on 0.0.0.0 and UPnP enabled, potential for SSH to be internet-exposed via UPnP port forward. Actual exposure unknown (no evidence of UPnP port 22 mapping, but can't rule out historical exposure).

**Options:**
1. **Accept Risk (Low effort):**
   - NOT acceptable - this is a known critical gap, made worse by router firewall being disabled

2. **Implement Host-Based Firewall (Medium effort):**
   - Configure nftables on both hosts
   - Default-deny, allow specific services (SSH, NFS, apt-cacher-ng)
   - Astute: Only allow connections from Audacious (192.168.1.147)
   - Block unexpected outbound connections
   - Residual risk: Low

**Decision:** **MUST IMPLEMENT IMMEDIATELY** (escalated to P0-Critical). Router firewall disabled + SSH on 0.0.0.0 + UPnP = potential internet exposure. Defense-in-depth requires host firewall regardless of router config.

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
   - Keys stored securely (Secrets USB for offline, deployed for convenience)
   - LAN-only SSH access (not internet-facing)
   - Residual risk: Low (requires key compromise + LAN access)

**Decision:** **Keep key-only auth** (current). SSH is LAN-only, not internet-facing. Key compromise requires either physical access (Secrets USB theft) or system compromise (in which case 2FA wouldn't help). Re-evaluate if SSH becomes internet-facing or if keys stored on less-secure devices.

### Risk: Untested Disaster Recovery

**Scenario:** Disaster strikes, recovery procedures fail due to untested assumptions.

**Current State:** Comprehensive recovery documentation, but never tested in practice

**Options:**
1. **Accept Risk (Low effort):**
   - NOT acceptable - recovery is critical

2. **Execute Disaster Recovery Drill (High effort):**
   - Test install.audacious.md in VM
   - Test Borg restore procedures
   - Verify Secrets USB secret recovery
   - Identify gaps and fix documentation
   - Residual risk: Very Low

**Decision:** **MUST IMPLEMENT** (Phase 2, task #7 already in queue). Recovery documentation is only theoretical until tested. VM testing environment (task #5) is prerequisite. High priority for Principle 3 (Resilience).

### Risk: SSH Listening on All Interfaces (Astute)

**Scenario:** SSH bound to 0.0.0.0 instead of LAN IP, potentially exposed via UPnP or port forwarding.

**Current State:** SSH listening on 0.0.0.0:22 (all interfaces), no ListenAddress restriction

**FINDING (2026-01-06):** Combined with router firewall disabled + UPnP enabled, SSH could have been internet-exposed. Router firewall now enabled (Default), but SSH still not restricted to LAN IP.

**Options:**
1. **Accept Risk (Low effort):**
   - NOT acceptable - SSH should be LAN-only, no need for WAN access

2. **Restrict SSH to LAN IP (Low effort):**
   - Add `ListenAddress 192.168.1.154` to sshd_config
   - SSH only accessible from LAN, even if router port forwarding configured
   - Version-control in dotfiles (ssh-server-astute package)
   - Residual risk: Very Low

**Decision:** **MUST IMPLEMENT IMMEDIATELY** (P0-Critical). Simple fix, critical security gap. Create ssh-server-astute package to version-control hardening.

### Risk: ISP Mass Surveillance (No VPN/Encrypted DNS)

**Scenario:** UK government bulk surveillance via ISP under IPA 2016 / Online Safety Act 2023. ISP logs DNS queries, connection metadata, and has DPI capability.

**Current State:**
- No VPN deployed (all traffic via ISP)
- DNS queries plaintext to ISP DNS servers
- HTTPS metadata visible (destination IPs, timing, volume)
- External service usage fully traceable

**Threat Assessment:** Mass surveillance (not targeted at individual). Privacy concern, not immediate security threat. Escalation to targeted surveillance requires changed threat model (activism, journalism, etc.).

**Options:**
1. **Accept Risk (Low effort):**
   - Acceptable for general browsing
   - HTTPS protects content (but not metadata)
   - Residual risk: Medium (privacy), Low (security)

2. **Implement VPN + Encrypted DNS (Medium effort):**
   - VPN encrypts all traffic from local → VPN endpoint
   - Encrypted DNS (DoH/DoT) hides DNS queries from ISP
   - ISP sees: encrypted tunnel to VPN provider, volume/timing only
   - VPN provider sees: actual traffic (trust shift from ISP to VPN)
   - Residual risk: Low (privacy), Very Low (security)

**Decision:** **IMPLEMENT VPN + ENCRYPTED DNS** (P1-High). UK political situation warrants privacy protection. Use case: on-demand for sensitive activities (not always-on for all traffic). VPN provider selection: prioritize privacy policy, jurisdiction, no-logs verification.

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
- Secrets stored offline (Secrets USB)

**Resilience:**
- Multiple backup layers (Borg, cold storage)
- Comprehensive recovery documentation
- Version-controlled configuration

**Isolation:**
- Per-host package isolation
- Open standards (portable, swappable)

### Critical Gaps

**Router Firewall (FIXED 2026-01-06):**
- Status: Was completely disabled, now set to Default
- Impact: Had zero perimeter protection, potential SSH internet exposure
- Priority: MITIGATED (but highlights need for defense-in-depth)

**SSH Hardening (Astute):**
- Status: Listening on 0.0.0.0 (all interfaces), not restricted to LAN IP
- Impact: Potential internet exposure via UPnP or port forwarding
- Priority: P0-Critical (MUST FIX IMMEDIATELY)

**Host Firewall:**
- Status: Implemented (packages ready, install pending)
- Impact: Services exposed to LAN without filtering, no defense-in-depth
- Priority: P0-Critical (MUST FIX IMMEDIATELY) - escalated from P1-High

**Network Segmentation:**
- Status: Flat /24 network, IoT shares with workstation/NAS
- Impact: Compromised IoT can pivot to sensitive systems
- Priority: P2-Medium (ACCEPT RISK for now, mitigate with host firewall + monitoring)

**ISP Surveillance (VPN/Encrypted DNS):**
- Status: No VPN, plaintext DNS, all traffic via ISP
- Impact: Mass surveillance visibility, metadata collection
- Priority: P1-High (privacy concern, UK political situation)

**Monitoring:**
- Status: No automated monitoring or alerting
- Impact: Silent failures go undetected, potential IoT compromise unnoticed
- Priority: P1-High (MUST FIX) - critical for IoT compromise detection

**Recovery Testing:**
- Status: Documentation untested
- Impact: Recovery may fail when needed
- Priority: P1-High (MUST TEST)

### Defense-in-Depth Strategy

**Layer 0: ISP/Network Privacy (TO BE IMPLEMENTED)**
- VPN for sensitive traffic (on-demand, not always-on)
- Encrypted DNS (DoH/DoT) to hide queries from ISP
- Reduces mass surveillance visibility

**Layer 1: Network Perimeter**
- Router (BT Smart Hub 2) - firewall on Default (fixed 2026-01-06, was disabled)
- Blocks unsolicited inbound, allows outbound
- UPnP enabled with Extended UPnP Security (accepted risk with host firewall mitigation)
- No manual port forwarding rules
- No DMZ
- No inbound services currently (Artful inactive)

**Layer 2: Host-Based Firewall (IMPLEMENTED - deploy pending)**
- nftables on Audacious and Astute (root-firewall-* packages)
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
- Offline backups (Secrets USB, cold storage)
- Comprehensive documentation
- Testing (to be executed)

---

## Guidance for Implementation

### Firewall Implementation (Task #6)

Based on this threat model:

**Packages:**
- `root-firewall-audacious`
- `root-firewall-astute`

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

### SSH Hardening Implementation (Task - NEW P0-Critical)

Based on security audit findings:

**Package:** root-ssh-astute

**Critical Changes:**
- Restrict SSH to LAN IP: `ListenAddress 192.168.1.154`
- Verify key-based auth only: `PasswordAuthentication no`
- Disable root login: `PermitRootLogin no`
- Optional: additional hardening (X11Forwarding, AllowAgentForwarding, etc.)

**Deploy:** Install script copies config to /etc/ssh/sshd_config.d/, validates, restarts sshd

**Verify:** `ss -tlnp | grep :22` shows 192.168.1.154:22 (not 0.0.0.0:22)

### Monitoring Implementation (Task #9)

Based on this threat model, monitor:

**Critical Priorities:**
- Borg backup success/failure (daily)
- ZFS scrub errors or pool degradation (weekly)
- Systemd service failures for critical services
- Disk SMART failures
- **NEW:** Unexpected connections to Astute (IoT compromise detection)
- **NEW:** Firewall dropped packets (attempted lateral movement)

**Medium Priorities:**
- Unusual network connections (non-LAN destinations from Astute)
- Failed SSH attempts
- Sudo usage (audit log)
- Package installation/removal

**Low Priorities:**
- System resource usage trends
- Temperature monitoring (Astute headless)

### VPN + Encrypted DNS Implementation (Task - NEW P1-High)

Based on UK mass surveillance concerns and performance requirements:

**Use Case:** On-demand VPN for sensitive activities (not always-on, not for gaming)

**Design Constraints:**
- Must NOT slow down general browsing (VPN off by default)
- Must NOT interfere with gaming (direct connection for low latency)
- Enable VPN manually for sensitive activities only

**VPN Options:**
1. **Commercial VPN (Recommended for simplicity):**
   - Providers: Mullvad, IVPN, Proton VPN (privacy-focused, no-logs)
   - Easy on-demand toggle (systemd service or NetworkManager integration)
   - Exit node selection (choose low-latency endpoints)
   - Split tunneling possible (route only specific apps through VPN)

2. **Self-Hosted Wireguard on Artful (Future):**
   - Full control, but limited to Artful's jurisdiction/provider
   - Requires Artful deployment and hardening first
   - Still shifts trust from ISP to VPS provider

**Encrypted DNS:**
- DNS-over-HTTPS (DoH) to Cloudflare (1.1.1.1) or Quad9 (9.9.9.9)
- OR DNS-over-TLS (DoT) to same providers
- Always-on (minimal performance impact)
- Prevents ISP DNS query logging

**Implementation Approach:**
- Encrypted DNS: Always-on (systemd-resolved or stubby)
- VPN: Manual activation via script/systemd (e.g., `vpn-on`, `vpn-off` commands)
- Browser profile: "Sensitive browsing" profile activates VPN automatically
- Gaming: Never use VPN (direct connection, UPnP works)

**Decision Needed:**
- VPN provider selection (commercial vs future self-hosted)
- Encrypted DNS method (DoH vs DoT)

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

### Artful VPS Security Hardening (Task - NEW P1-High)

Prerequisites for deploying Artful as internet-facing VPS:

**SSH Hardening:**
- Key-based auth only (no password auth)
- Non-standard SSH port (reduce automated scans)
- fail2ban for brute-force protection
- Rate limiting on SSH connections

**Host Firewall:**
- Default-deny on all interfaces
- Minimal services exposed (SSH, HTTP/HTTPS if needed)
- Explicit allow rules only
- Log all dropped packets

**Automated Updates:**
- Unattended security updates enabled
- Kernel/critical package updates tested before production
- Email/monitoring alerts for failed updates

**Monitoring:**
- Intrusion detection (fail2ban logs, unusual connections)
- Service health monitoring
- Disk space and resource usage
- Security update status

**Hardening:**
- Disable unnecessary services
- Remove unused packages
- Kernel hardening (sysctl tuning)
- AppArmor or SELinux if supported by VPS

**Dependencies:** Artful not currently deployed - hardening must be completed before any internet-facing deployment

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
- UK legal landscape changes (Online Safety Act enforcement, new surveillance powers)
- Escalation from mass surveillance to targeted surveillance

**Document Updates:**
- Keep aligned with actual implementation (not aspirational)
- Update acceptable risk decisions as mitigations are implemented
- Track residual risk over time
- Document security audit findings and remediation

---

## Audit History

### 2026-01-06: Security Audit - Router Firewall + SSH Exposure

**Findings:**
1. Router firewall completely disabled (CRITICAL) - now fixed (set to Default)
2. SSH on Astute listening on 0.0.0.0, not restricted to LAN IP (CRITICAL)
3. UPnP enabled with Extended UPnP Security ON (acceptable with mitigation)
4. No manual port forwarding rules (good)
5. DMZ disabled (good)
6. Audacious has no SSH server (correct - client-only)

**Remediation:**
- Router firewall enabled (Default) - COMPLETE
- SSH hardening (root-ssh-astute package) - IMPLEMENTED (install pending)
- Host firewall (nftables) escalated to P0-Critical - IMPLEMENTED (install pending)
- VPN + encrypted DNS added as P1-High task - PENDING
- Artful security hardening prerequisites documented - PENDING

**Impact:**
- Potential historical SSH internet exposure (unknown duration, no evidence of compromise)
- Zero perimeter protection until router firewall enabled
- Defense-in-depth insufficient (no host firewall)

**Risk Level Change:**
- External Network Attackers: Critical → Medium-High (after router fix, pending host firewall)
- New threat actor added: UK State-Level Mass Surveillance (High privacy risk)

---

**Last Updated:** 2026-01-06
**Next Review:** 2027-01-06 or upon triggering event
