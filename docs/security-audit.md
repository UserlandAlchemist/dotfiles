# Security Audit - Project Shipshape

**Date:** 2026-01-07
**Scope:** Audacious (workstation) + Astute (NAS/server)

---

## Summary

**Overall posture:** Good

No critical findings. Core controls (host firewalls, SSH hardening, patching) are in place. Minor operational improvements remain.

---

## Open Findings

**P1 - High**
- Enable unattended-upgrades on Audacious (security-only, delayed, no auto-reboot).

---

## Control Snapshot

**Network exposure**
- Audacious: no SSH server; firewall active; inbound blocked.
- Astute: SSH LAN-only; firewall restricts access to Audacious; NFS/apt-cacher-ng/MPD/Jellyfin are LAN-only.

**Authentication**
- SSH keys only; root login disabled; no password auth on Astute.
- Sudoers rules are scoped to NAS mount/inhibit controls.

**Patching**
- Both hosts fully patched at time of audit.
- Unattended upgrades active on Astute only.

**Monitoring**
- No suspicious activity observed in recent logs.

---

## Key Evidence (abbreviated)

- Listening services align with documented roles.
- Host firewalls active and dropping unsolicited traffic.
- SSH restricted to LAN IP on Astute.
- smartmontools active on Astute.

---

## Method

Commands used during audit included:
- `ss -tulpen`
- `systemctl list-units --type=service --state=running`
- `nft list ruleset`
- `journalctl --since "7 days ago"`
- `apt list --upgradable`

---

## Notes

Operational posture and remediation tracking live in this document. Design-time threat assumptions and acceptable risks live in `docs/threat-model.md`.
