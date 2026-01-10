# Threat Model

Security assumptions, threat scope, and risk decisions for Project Shipshape.

**Note:** This document reflects current infrastructure with Artful inactive.
When Artful is deployed with public-facing services, threat scope and security
decisions will require re-evaluation.

---

## Assumptions

- Home environment with limited physical access
- Single-user administration with full privileges
- Flat /24 LAN with mixed-trust devices (workstation/NAS and IoT coexist)
- ISP is not trusted for privacy (metadata visibility assumed)
- External services can be compromised; data sent off-site may be exposed

---

## Goals

- Preserve data integrity and availability (local, off-site, and offline
  backups)
- Preserve privacy of personal and project data
- Enable rapid recovery without specialist intervention
- Minimize operational complexity and long-term maintenance burden

---

## In-Scope Threats

These threats are actively defended against with specific mitigations.

### Hardware Theft

Devices stolen or lost. Mitigated by full disk encryption (ZFS, LUKS),
encrypted backups (Borg), and offline secrets storage.

### Accidental Data Loss

Operational errors, hardware failure, or ransomware. Mitigated by layered
backups (local, off-site, offline), version control for configs, and tested
recovery procedures.

### Opportunistic Network Attacks

Internet-based scanning, exploitation attempts, credential stuffing. Mitigated
by no inbound services on home network, host firewalls, and strong
authentication for external services.

### Compromised IoT / LAN Devices

Malicious or compromised devices on the flat home network. Mitigated by
host-based firewalling, SSH key authentication between trusted hosts, and
treating IoT as untrusted.

### Supply Chain Attacks (Basic)

Compromised packages in standard repositories. Mitigated by preferring official
signed repos and minimizing manual builds.

### Mass Surveillance (Metadata)

ISP-level collection under UK legal frameworks. Mitigated by encrypted
transport (HTTPS, SSH) and VPN/encrypted DNS for sensitive activity.

---

## Out-of-Scope Threats

These threats are explicitly NOT defended against. Security decisions that seem
weak make sense in this context.

### Physical Coercion / Duress

Attacker forces disclosure of passphrases or access. No panic wipe codes, no
plausible deniability, no duress detection. Rationale: home environment, not
high-stakes target.

### Present Physical Attacker

Attacker with physical console access while system is running. No screen lock
enforcement, autologin enabled. Rationale: single-user home workstation with
disk encryption for theft scenarios.

### Sophisticated LAN Compromise

Advanced attacker with persistent LAN access. No 2FA on LAN SSH, plaintext
traffic acceptable for non-sensitive data. Rationale: trusted physical
environment, IoT treated as untrusted but not assumed sophisticated.

### Nation-State Targeted Attacks

Sophisticated adversary with significant resources targeting this specific
infrastructure. No extraordinary operational security measures. Rationale: not
a realistic threat profile for home lab.

### Advanced Supply Chain Attacks

Coordinated compromise of multiple upstream dependencies or signing keys. No
extensive source audits or builds from source. Rationale: impractical for home
infrastructure; rely on Debian's security process.

---

## Security Decisions

Specific choices explained in context of threat scope.

### Flat Network with IoT Devices

**Decision:** Accept risk.
**Context:** Compromised IoT is in-scope, but sophisticated LAN attacks are
out-of-scope.
**Mitigation:** Host-based firewalls and SSH key authentication sufficient for
in-scope threats.

### Autologin on Audacious

**Decision:** Accept risk.
**Context:** Present physical attacker is out-of-scope; hardware theft is
in-scope.
**Mitigation:** Disk encryption protects against theft; autologin acceptable for
single-user convenience.

### SSH Key-Only Authentication (LAN)

**Decision:** Accept risk.
**Context:** Sophisticated LAN compromise requiring 2FA is out-of-scope.
**Mitigation:** SSH keys with proper protection sufficient; 2FA adds friction
without meaningful benefit for threat model.

### Plaintext Traffic on Trusted LAN

**Decision:** Accept risk for non-sensitive traffic.
**Context:** Metadata leakage on LAN from sophisticated attacker is
out-of-scope.
**Mitigation:** Encryption for sensitive data (SSH, Borg); plaintext acceptable
for public package metadata and discovery protocols.

### UPnP Enabled

**Decision:** Accept risk with host firewall mitigation.
**Context:** Opportunistic network attacks are in-scope.
**Mitigation:** No services listening for inbound connections; host firewalls
provide defense even with accidental UPnP mappings.

### ISP Metadata Visibility

**Decision:** Accept baseline risk; mitigate for sensitive activity.
**Context:** Mass surveillance is in-scope; nation-state targeting is
out-of-scope.
**Mitigation:** HTTPS everywhere for normal activity; VPN and encrypted DNS
available when privacy requirements increase.

---

## Non-Negotiable Requirements

### Monitoring and Alerting

Backups and storage require monitoring to ensure recoverability. Gaps in
monitoring are not acceptable for in-scope data loss threats.

### Tested Recovery Procedures

Recovery from accidental data loss is in-scope and critical. Procedures must be
exercised periodically through drills and verification.

---
