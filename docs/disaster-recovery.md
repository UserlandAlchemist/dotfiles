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

### Verify Secrets USB (Monthly)

```bash
cd ~/dotfiles
sudo scripts/verify-secrets-usb.sh
```

This checks that all required files exist. If checksums have been saved (see below), it also verifies file integrity.

If verification fails, populate missing files per docs/secrets-recovery.md §2.

**After initial population or any updates:**
```bash
sudo scripts/verify-secrets-usb.sh --save-checksums
```

This computes SHA256 checksums of all files and saves them to `.checksums.txt` on the USB. Subsequent runs will verify files haven't been corrupted or tampered with.

### Create Google Drive Bundle (Quarterly or When Secrets Change)

```bash
cd ~/dotfiles
scripts/create-gdrive-recovery-bundle.sh
```

This creates: `~/borgbase-recovery-bundle-YYYYMMDD.tar.gz.gpg`

Upload to Google Drive → Disaster Recovery folder, then delete local copy.

**When to update:**
- BorgBase SSH key rotated
- BorgBase passphrases changed
- Local Borg passphrase changed
- After any disaster recovery test
- Minimum: quarterly

**After adding/updating any secrets on Secrets USB:**
```bash
sudo scripts/verify-secrets-usb.sh --save-checksums
```

### Update Trusted Person USB (Semi-Annually)

When trusted person visits (~6 months):

1. Verify Secrets USB is current:
   ```bash
   cd ~/dotfiles
   sudo scripts/verify-secrets-usb.sh
   ```

2. Create/update encrypted clone:
   ```bash
   cd ~/dotfiles
   sudo scripts/clone-secrets-usb.sh
   ```

   This script will:
   - Wipe and encrypt the target USB (LUKS with same passphrase as Secrets USB)
   - Copy all files from Secrets USB
   - Verify copy with SHA256 checksums
   - Report success/failure

3. Label the USB: "Secrets USB Backup - Updated YYYY-MM-DD"
4. Hand off to trusted person for off-site storage
5. Document handoff date in maintenance log

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

## Passphrase Management

### GPG Passphrase (Google Drive Bundle)

**Requirements:**
- Must be memorable WITHOUT password manager
- Must be strong (6-8 random words)
- Must survive stress (disaster scenario)

**Storage:**
- **Primary:** Memorized
- **Backup:** Written on paper in wallet (kept on person, not in house)
- **DO NOT:** Store in Bitwarden, Secrets USB, or any on-premises location

**Recommendation:** Use diceware to generate 6-8 word passphrase:
```bash
# Example only - generate your own!
correct-horse-battery-staple-purple-monkey-dishwasher
```

### LUKS Passphrase (Secrets USB)

**Requirements:**
- Strong enough to protect all secrets
- Must be memorable or stored securely

**Storage:**
- Bitwarden (survives house fire)
- Written backup in safe deposit box (optional)

---

## Recovery Kit Contents Reference

### Secrets USB (Complete Backup)

```
/mnt/keyusb/
├── ssh-backup/
│   ├── id_alchemist (main SSH key)
│   ├── audacious-backup (Borg SSH key)
│   ├── id_ed25519_astute_nas (NAS control key)
│   └── borgbase_offsite (BorgBase SSH key)
├── borg/
│   ├── passphrase (local Borg repo)
│   ├── repo-key-export.txt (local Borg repo key)
│   ├── audacious-home-key.txt (BorgBase repo key)
│   ├── audacious-home.passphrase (BorgBase repo passphrase)
│   ├── astute-critical-key.txt (BorgBase repo key)
│   ├── astute-critical.passphrase (BorgBase repo passphrase)
│   └── REPOSITORY-INFO.txt (metadata)
├── pgp/ (PGP key exports)
└── docs/
    └── secrets-recovery.md (procedures)
```

### Google Drive Bundle (Minimal for BorgBase Access)

```
recovery-bundle/
├── RECOVERY-INSTRUCTIONS.md (this is the key file!)
├── METADATA.txt
├── borgbase_offsite (SSH private key)
├── audacious-home.passphrase
├── astute-critical.passphrase
├── audacious-home-key.txt
├── astute-critical-key.txt
└── local-borg-passphrase.txt
```

---

## RTO/RPO Estimates

### Recovery Time Objective (RTO)

Time to restore operations after disaster:

- **Catastrophic loss:** 1-3 days
  - Acquire hardware: 1 day
  - Restore critical data: 4-8 hours
  - Full rebuild: 2-3 days
- **Single system:** 4-8 hours
  - Hardware available: immediate
  - Restore from backup: 4-8 hours
- **Ransomware:** 4-8 hours
  - Identify clean backup: 1-2 hours
  - Rebuild and restore: 4-6 hours

### Recovery Point Objective (RPO)

Maximum acceptable data loss:

- **Local backups:** 6 hours (last Audacious → Astute backup)
- **Off-site backups:** 24 hours (last BorgBase backup)
- **Offline backups:** 30 days (cold storage monthly)

---

## Maintenance Schedule

- **Weekly:** Verify Borg backups running (automatic timers)
- **Monthly:** Verify Secrets USB complete
- **Quarterly:** Update Google Drive bundle
- **Semi-annually:** Update trusted person USB
- **Annually:** Full recovery drill

---

## Emergency Contacts

- **BorgBase Support:** support@borgbase.com
- **Trusted Person:** [Name/Phone - add to paper copy only]
- **This Document:** Available on Google Drive if all else lost
