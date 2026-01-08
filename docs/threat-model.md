# Threat Model

Security assumptions, threat actors, attack surfaces, and acceptable risks for Project Shipshape.

**Scope:** The Wolfpack (Audacious, Astute, Artful, Steam Deck, mobile devices)
**Operational posture and audit findings:** tracked in `TODO.md` session notes.

---

## Purpose

Define the threats this system is designed to withstand, make tradeoffs explicit, and keep risk acceptance consistent across engineering decisions.

---

## Assumptions

- Home environment with limited physical access.
- Single-user administration with full privileges.
- Flat LAN with mixed-trust devices (workstation/NAS and IoT coexist).
- ISP is not trusted for privacy (metadata visibility assumed).
- External services can be compromised; data sent off-site may be exposed.
- Recoverability is a core requirement, not a best-effort goal.

---

## Assets and Goals

- Preserve data integrity and availability (local, off-site, and offline backups).
- Preserve privacy of personal and project data.
- Enable rapid recovery without specialist intervention.
- Minimize operational complexity and long-term maintenance burden.

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

**Design Response:** No inbound services exposed on the home network; rely on outbound-only access, host firewalls, and strong authentication for any external services.

**Risk Level:** Medium (public internet is hostile; exposure is intentionally minimized)

### 2. Local Network Attackers (LAN)

**Profile:** Compromised IoT devices, malicious guests, or lateral movement from breached devices.

**Capabilities:**
- Access to flat /24 network (no segmentation)
- Service discovery and exploitation on LAN
- Traffic sniffing on unencrypted protocols
- ARP spoofing and man-in-the-middle attacks

**Motivation:** Lateral movement, data exfiltration, persistent access

**Design Response:** Assume IoT is untrusted; prioritize host-based firewalling and strong auth between trusted hosts.

**Risk Level:** Medium

### 3. Physical Access Attackers

**Profile:** Physical access to hardware (theft, "evil maid" attacks, unauthorized access).

**Capabilities:**
- Direct hardware access (USB, boot manipulation)
- Theft of devices or storage media
- Cold boot attacks on unencrypted RAM
- Firmware/BIOS manipulation

**Motivation:** Data theft, persistent backdoors, sabotage

**Design Response:** Disk encryption, offline secrets storage, and offline backups.

**Risk Level:** Low to Medium (depends on device portability)

### 4. Supply Chain Attackers

**Profile:** Compromised software packages, malicious firmware updates, typosquatted packages.

**Capabilities:**
- Malicious packages in upstream repositories
- Compromised package signing keys
- Firmware backdoors
- Man-in-the-middle on package downloads

**Motivation:** Widespread compromise, espionage, data theft

**Design Response:** Prefer official signed repositories and minimize manual builds.

**Risk Level:** Low to Medium

### 5. Insider Threats (Operational Error)

**Profile:** Accidental misconfiguration, data loss, or exposure by authorized users.

**Capabilities:**
- Full administrative access to all systems
- Ability to modify or delete data
- Deployment of insecure configurations
- Accidental exposure of secrets

**Motivation:** Not malicious - human error, fatigue, lack of knowledge

**Design Response:** Version control for configuration, documented procedures, and layered backups.

**Risk Level:** Medium

### 6. State-Level Mass Surveillance (UK)

**Profile:** ISP-level collection under UK legal frameworks.

**Capabilities:**
- DNS query logging and metadata collection
- Visibility into unencrypted traffic
- Bulk interception warrants

**Motivation:** Mass surveillance, not targeted action at baseline threat level

**Design Response:** Use encrypted transport where possible; consider VPN and encrypted DNS for sensitive activity.

**Risk Level:** High for privacy, Low for direct system compromise

---

## Attack Surfaces

### Network Attack Surface

**External (WAN):**
- Router and ISP edge
- UPnP (automatic port forwarding risk)
- External services (GitHub, Bitwarden, ChatGPT, Cloudflare)
- Artful VPS when active

**Internal (LAN):**
- NFSv4 traffic (plaintext on LAN)
- SSH management between hosts
- apt-cacher-ng traffic (plaintext on LAN)
- Service discovery (mDNS, LLMNR, DHCP)
- IoT devices with unknown security posture

### Physical Attack Surface

- Desktop workstation and NAS hardware
- Portable devices (Steam Deck, mobile)
- Secrets USB and cold storage drive

### Authentication Attack Surface

- SSH keys and forced commands
- Local autologin and physical console access
- External service accounts and 2FA posture

### Data at Rest

- Encrypted: ZFS pools, LUKS cold storage, Borg repositories
- Plaintext: system logs and some configuration files

### Data in Transit

- Encrypted: SSH, HTTPS, Borg over SSH
- Plaintext on LAN: NFSv4, apt-cacher-ng, discovery protocols

---

## Trust Zones and Security Boundaries

### Zone 1: Trusted Core (High Trust)

**Scope:** Audacious, Astute, and the wired LAN.

**Requirements:**
- Encryption at rest for sensitive data
- SSH key-based authentication between hosts
- Host-based firewalling
- Version-controlled configuration

### Zone 2: Semi-Trusted Peripherals (Medium Trust)

**Scope:** GL.iNet Comet KVM, Steam Deck, mobile phone.

**Requirements:**
- Strong authentication
- Minimal secrets stored
- Ability to wipe or revoke access

### Zone 3: Untrusted IoT (Low Trust)

**Scope:** Tapo devices, Hue bridge, Echo Dot, other IoT.

**Requirements:**
- No access to sensitive data
- Treat as compromise-prone

### Zone 4: Internet (Untrusted)

**Scope:** Public internet and external services.

**Requirements:**
- No unnecessary inbound exposure
- Strong authentication
- Assume data sent off-site may be exposed

---

## Acceptable Risks and Tradeoffs

### Risk: Flat Network with IoT Devices

**Decision:** Accept risk.
**Rationale:** Segmentation adds complexity and hardware cost; mitigations rely on host firewalls and least-privilege access.

### Risk: NFSv4 Plaintext on LAN

**Decision:** Accept risk.
**Rationale:** Trusted physical environment; Kerberos adds operational overhead for marginal gain.

### Risk: UPnP Enabled

**Decision:** Accept risk with host firewall mitigation.
**Rationale:** Required for gaming convenience; host firewalls reduce exposure from unintended port mappings.

### Risk: Autologin on Audacious

**Decision:** Accept risk.
**Rationale:** Single-user home workstation; disk encryption protects data at rest.

### Risk: SSH Key-Only Authentication

**Decision:** Accept risk.
**Rationale:** LAN-only SSH access and key protection provide sufficient security for the threat model; 2FA adds friction without meaningful benefit for local-only access.

### Risk: ISP Metadata Visibility

**Decision:** Accept baseline risk; mitigate for sensitive activity.
**Rationale:** Use HTTPS everywhere; use VPN and encrypted DNS when privacy requirements increase.

### Risk: Monitoring and Alerting Gaps

**Decision:** Do not accept risk.
**Rationale:** Backups and storage require monitoring to ensure recoverability.

### Risk: Untested Recovery Procedures

**Decision:** Do not accept risk.
**Rationale:** Recovery is a core requirement; procedures must be exercised periodically.

---

## Out of Scope

- Nation-state targeted compromise beyond mass surveillance.
- Physical coercion and advanced hardware tampering.
- Supply chain compromise of all upstream dependencies simultaneously.

---

## Maintenance

Review this document after major infrastructure changes and during periodic recovery drills. Track operational posture and audit findings in `TODO.md` session notes.
