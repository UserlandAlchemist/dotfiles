# Disaster Recovery Strategy

Scenario map for catastrophic loss. Detailed steps live in `docs/data-restore.md`, `docs/secrets-recovery.md`, and per-host install/recovery docs.

**Last Updated:** 2026-01-07

**Current Hardware:** The Secrets USB is currently a blue SanDisk 32GB USB drive. The Trusted Copy is maintained by a trusted person off-site.

---

## Threat Scenarios

### Scenario 1: House Fire / Flood
- **Lost:** Audacious, Astute, Secrets USB, cold storage HDD
- **Survives:** BorgBase off-site, trusted person's USB copy, Google Drive bundle
- **RTO:** 1-3 days
- **RPO:** 24 hours (last BorgBase backup)

### Scenario 2: Single System Failure
- **Lost:** Audacious OR Astute (hardware failure, theft)
- **Survives:** Other system, local Borg backups, Secrets USB
- **RTO:** 4-8 hours
- **RPO:** 6 hours (last local Borg backup)

### Scenario 3: Ransomware
- **Encrypted:** Audacious and/or Astute filesystems
- **Survives:** BorgBase off-site (append-only), Secrets USB (offline), cold storage (offline)
- **RTO:** 4-8 hours (restore from BorgBase)
- **RPO:** 24 hours (last BorgBase backup)

---

## Recovery Kit Locations

### Primary: Secrets USB (On-Site, Encrypted)
- **Location:** Home, with cold storage drive
- **Encryption:** LUKS (AES256)
- **Update Frequency:** As secrets change
- **Access:** cryptsetup + mount
- **Risk:** Destroyed in same disaster as Audacious/Astute

### Secondary: Trusted Person USB (Off-Site, Encrypted)
- **Location:** Trusted person, visits every ~6 months
- **Content:** Full copy of Secrets USB
- **Update Frequency:** Every 6 months during visit
- **Risk:** 6-month staleness, relies on trusted person

### Tertiary: Google Drive Bundle (Cloud, Encrypted)
- **Location:** Google Drive (external provider)
- **Encryption:** GPG AES256 symmetric
- **Update Frequency:** When secrets change, minimum quarterly
- **Access:** GPG passphrase (memorized or in wallet)
- **Risk:** Only as secure as GPG passphrase

### Quaternary: Bitwarden (Optional)
- **Location:** Bitwarden cloud (external provider)
- **Content:** Individual secrets as secure notes
- **Access:** Bitwarden master password
- **Risk:** Single point of failure if Bitwarden account lost

---

## Recovery Kit Maintenance

For detailed procedures on verifying, updating, and maintaining recovery kits (Secrets USB, Google Drive bundle, Trusted Person USB), see `docs/secrets-maintenance.md`.

---

## Recovery Procedures

Use `docs/data-restore.md` for all data recovery steps. Use per-host install/recovery docs for OS and infrastructure repair.

### Catastrophic Loss (Fire/Flood)

Primary path:
1. Restore secrets (`docs/secrets-recovery.md`)
2. Rebuild Astute (`docs/astute/install-astute.md`)
3. Restore data from BorgBase (`docs/data-restore.md`)
4. Rebuild Audacious (`docs/audacious/install-audacious.md`)
5. Restore data from Astute (`docs/data-restore.md`)

### Single System Loss (Hardware Failure)

Audacious lost:
1. Reinstall Audacious (`docs/audacious/install-audacious.md`)
2. Restore data from Astute (`docs/data-restore.md`)

Astute lost:
1. Rebuild Astute (`docs/astute/install-astute.md`)
2. Restore data from BorgBase (`docs/data-restore.md`)

### Ransomware Attack

Immediate actions:
1. Disconnect systems from the network
2. Preserve evidence (do not reboot)
3. Identify pre-infection backups

Recovery path:
1. Rebuild from clean install
2. Restore data from clean backups (`docs/data-restore.md`)
3. Rotate credentials and re-issue keys (`docs/secrets-recovery.md`)

---

## Testing Recovery Procedures

### Annual Recovery Drill

1. Restore secrets on a test machine (`docs/secrets-recovery.md`).
2. Verify BorgBase access and list archives (`docs/data-restore.md`).
3. Perform a small restore and verify integrity.
4. Record time taken and update RTO/RPO estimates.

### Quarterly Verification

1. Run `scripts/verify-secrets-usb.sh`.
2. Verify BorgBase archives exist and are append-only.
3. Verify Google Drive bundle is present and recent.
4. Confirm GPG passphrase recall.

---
