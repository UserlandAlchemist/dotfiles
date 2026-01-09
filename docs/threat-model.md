# Threat Model

Security assumptions, threat actors, attack surfaces, and acceptable risks for Project Shipshape.

---

## Assumptions

- Home environment with limited physical access
- Single-user administration with full privileges
- Flat /24 LAN with mixed-trust devices (workstation/NAS and IoT coexist)
- ISP is not trusted for privacy (metadata visibility assumed)
- External services can be compromised; data sent off-site may be exposed
- Recoverability is a core requirement, not a best-effort goal

---

## Assets and Goals

- Preserve data integrity and availability (local, off-site, and offline backups)
- Preserve privacy of personal and project data
- Enable rapid recovery without specialist intervention
- Minimize operational complexity and long-term maintenance burden

---

## Threat Actors

### External Network Attackers (Medium Risk)
Opportunistic or targeted attackers from the public internet. No inbound services exposed on the home network; rely on outbound-only access, host firewalls, and strong authentication for any external services.

### Local Network Attackers (Medium Risk)
Compromised IoT devices or malicious guests on the flat /24 LAN. Assume IoT is untrusted; prioritize host-based firewalling and strong auth between trusted hosts.

### Physical Access Attackers (Low to Medium Risk)
Theft, "evil maid" attacks, or unauthorized physical access. Mitigated by disk encryption, offline secrets storage, and offline backups.

### Supply Chain Attackers (Low to Medium Risk)
Compromised software packages or malicious firmware updates. Prefer official signed repositories and minimize manual builds.

### Insider Threats / Operational Error (Medium Risk)
Accidental misconfiguration or data loss by authorized users. Mitigated by version control, documented procedures, and layered backups.

### State-Level Mass Surveillance (High Privacy Risk, Low Compromise Risk)
ISP-level collection under UK legal frameworks. Use encrypted transport where possible; consider VPN and encrypted DNS for sensitive activity.

---

## Attack Surfaces

### External (WAN)
- Router and ISP edge
- UPnP (automatic port forwarding risk)
- External services (GitHub, Bitwarden, ChatGPT, Cloudflare)
- Artful VPS when active

### Internal (LAN)
- SSH management between hosts
- apt-cacher-ng traffic (plaintext HTTP)
- Service discovery protocols (mDNS, LLMNR, DHCP)
- IoT devices with unknown security posture
- NFSv4 traffic (plaintext when implemented)

### Physical
- Desktop workstation and NAS hardware
- Portable devices (Steam Deck, mobile)
- Secrets USB and cold storage drive

### Authentication
- SSH keys and forced commands
- Local autologin and physical console access
- External service accounts and 2FA posture

### Data at Rest
- Encrypted: ZFS pools, LUKS cold storage, Borg repositories
- Plaintext: system logs and configuration files

### Data in Transit
- Encrypted: SSH, HTTPS, Borg over SSH
- Plaintext on LAN: apt-cacher-ng, discovery protocols, NFSv4 (when implemented)

---

## Acceptable Risks

### Flat Network with IoT Devices
**Decision:** Accept risk.
**Rationale:** Segmentation adds complexity and hardware cost; mitigations rely on host firewalls and least-privilege access.

### Plaintext Traffic on Trusted LAN
**Decision:** Accept risk for non-sensitive traffic (package downloads, discovery protocols).
**Rationale:** Trusted physical environment; encryption overhead not justified for public package metadata.

### UPnP Enabled
**Decision:** Accept risk with host firewall mitigation.
**Rationale:** Required for gaming convenience; host firewalls reduce exposure from unintended port mappings.

### Autologin on Audacious
**Decision:** Accept risk.
**Rationale:** Single-user home workstation; disk encryption protects data at rest.

### SSH Key-Only Authentication (LAN)
**Decision:** Accept risk.
**Rationale:** LAN-only SSH access and key protection provide sufficient security; 2FA adds friction without meaningful benefit for local-only access.

### ISP Metadata Visibility
**Decision:** Accept baseline risk; mitigate for sensitive activity.
**Rationale:** Use HTTPS everywhere; use VPN and encrypted DNS when privacy requirements increase.

---

## Non-Negotiable Requirements

### Monitoring and Alerting
Backups and storage require monitoring to ensure recoverability. Gaps in monitoring are not acceptable.

### Tested Recovery Procedures
Recovery is a core requirement; procedures must be exercised periodically through drills and verification.

---
