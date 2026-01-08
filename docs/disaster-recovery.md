# Disaster Recovery Strategy

Complete procedures for recovering from catastrophic loss scenarios.

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

For detailed procedures on verifying, updating, and maintaining recovery kits (Secrets USB, Google Drive bundle, Trusted Person USB), see docs/secrets-recovery.md.

---

## Recovery Procedures

### Catastrophic Loss (Fire/Flood) - All On-Premises Destroyed

**What you have:**
- New/borrowed computer
- Google Drive account access OR trusted person USB
- GPG passphrase (memorized or in wallet) OR LUKS passphrase

**Steps:**

1. **Acquire temporary computer** (laptop, friend's machine, library)

2. **Install BorgBackup:**
   ```bash
   sudo apt update && sudo apt install borgbackup gpg
   ```

3. **Retrieve recovery bundle:**

   Option A: Google Drive
   ```bash
   # Download borgbase-recovery-bundle-YYYYMMDD.tar.gz.gpg from Google Drive
   gpg -d borgbase-recovery-bundle-YYYYMMDD.tar.gz.gpg | tar xzf -
   cd recovery-bundle/
   ```

   Option B: Trusted person USB
   ```bash
   sudo cryptsetup luksOpen /dev/sdX keyusb
   sudo mount /dev/mapper/keyusb /mnt/keyusb
   cd /mnt/keyusb
   ```

4. **Follow RECOVERY-INSTRUCTIONS.md** in the bundle (or Secrets USB)

5. **Restore critical data first:**
   - Bitwarden exports (from astute-critical)
   - SSH keys (from audacious-home)
   - lucii archive (from astute-critical)

6. **Restore full home directory:**
   - Two-step restore from audacious-home
   - Rebuild Audacious workstation

7. **Rebuild Astute:**
   - Restore critical data from astute-critical
   - Restore Borg repo from audacious-home
   - Follow docs/astute/install.astute.md

### Single System Loss (Hardware Failure)

**Audacious Lost:**

1. Acquire replacement hardware
2. Follow docs/audacious/install.audacious.md
3. Restore from Borg on Astute:
   ```bash
   export BORG_REPO=borg@astute:/srv/backups/audacious-borg
   borg list
   borg extract ::audacious-YYYY-MM-DD home/alchemist
   ```
4. RPO: 6 hours (last local backup)

**Astute Lost:**

1. Acquire replacement hardware
2. Follow docs/astute/install.astute.md
3. Restore from BorgBase:
   ```bash
   # Restore audacious-borg repo from BorgBase
   # Restore critical data from astute-critical
   ```
4. RPO: 24 hours (last off-site backup)

### Ransomware Attack

**DO NOT PAY RANSOM** - Backups make this unnecessary.

1. **Disconnect infected systems from network immediately**
2. **Do NOT restart** encrypted systems (preserves forensics)
3. **Determine infection extent:**
   - Which systems encrypted?
   - When did encryption occur?
   - Which backups are pre-infection?

4. **Restore from clean backup:**
   - BorgBase (append-only, ransomware cannot delete)
   - Secrets USB (offline, cannot be encrypted remotely)
   - Cold storage (offline, 30-day old but guaranteed clean)

5. **Rebuild from known-good state:**
   - Fresh OS install recommended
   - Restore data from pre-infection backup
   - Verify no persistence mechanisms

6. **Identify and patch vulnerability**
7. **Monitor for re-infection**

---

## Testing Recovery Procedures

### Annual Recovery Drill (Recommended)

Test recovery capabilities without actual disaster:

1. **Preparation:**
   - Download Google Drive bundle to temporary location
   - Do NOT decrypt on production systems (use VM or test machine)

2. **Test Decryption:**
   ```bash
   gpg -d borgbase-recovery-bundle-YYYYMMDD.tar.gz.gpg > /tmp/test.tar.gz
   tar tzf /tmp/test.tar.gz  # List contents
   rm /tmp/test.tar.gz       # Clean up
   ```

3. **Test BorgBase Access:**
   ```bash
   # On test VM, verify can list archives
   borg list ssh://j6i5cke1@...
   ```

4. **Test Partial Restore:**
   - Extract single file from astute-critical
   - Verify file integrity
   - Do NOT restore entire system (time-consuming)

5. **Document:**
   - Time taken for each step
   - Any issues encountered
   - Updates needed to procedures
   - Update RTO/RPO estimates

### Quarterly Verification (Minimal)

1. Run `scripts/verify-secrets-usb.sh`
2. List BorgBase archives (verify append-only backups running)
3. Verify Google Drive bundle exists and is recent
4. Verify GPG passphrase still remembered

---
