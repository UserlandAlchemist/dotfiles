# SSH Key Inventory and Analysis

**Date:** 2026-01-07
**Scope:** Audacious, Astute
**Status:** Comprehensive audit complete

---

## Executive Summary

**Total keys on Audacious:** 3 key pairs (6 files)
**Active keys:** 3 key pairs
**Unused keys:** 0 (id_astute_nas deleted 2026-01-07)
**Scoping status:** Good - all active keys properly scoped with restrictions
**Security posture:** Good - forced commands, IP restrictions, no agent forwarding where appropriate

---

## Key Inventory

### 1. id_alchemist (Main Identity Key)

**Type:** ED25519
**Fingerprint:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCWy7Ue1pd4CBBINMocHUozJ5qq54fXoJVfHcxwcWhF`
**Comment:** alchemist@userlandlab.org
**Location:** ~/.ssh/id_alchemist (Audacious)

**Used for:**
- SSH to Astute (full shell access)
- GitHub access (git operations)

**Authorized on:**
- Astute: `~/.ssh/authorized_keys` (full access, no restrictions)
- GitHub: (configured in account settings)

**SSH config entries:**
- `Host astute` → Full shell access
- `Host github.com` → Git operations

**Scoping:** Appropriate - main identity key for interactive work
**Status:** ✓ Active, properly configured
**Backup coverage:** Borg to Astute, should be on Blue USB

---

### 2. audacious-backup (Borg Backup Key)

**Type:** ED25519
**Fingerprint:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLtERwjC4P/QCoGqhy2s1LhKjHfarurz+ompZ/SxfzJ`
**Comment:** alchemist@audacious
**Location:** ~/.ssh/audacious-backup (Audacious)

**Used for:**
- Borg backup from Audacious to Astute

**Authorized on:**
- Astute: `/srv/backups/.ssh/authorized_keys` (borg user)
  - Forced command: `borg serve --restrict-to-path /srv/backups`
  - `restrict` flag applied (disables agent forwarding, port forwarding, PTY, X11, etc.)

**SSH config entries:**
- `Host astute-borg` → Borg backup operations

**Scoping:** ✓ Excellent - heavily restricted
- Cannot run arbitrary commands (forced command)
- Cannot access anything outside /srv/backups
- Cannot forward ports or agents
- Cannot allocate PTY

**Status:** ✓ Active, properly restricted
**Backup coverage:** Borg to Astute, should be on Blue USB

---

### 3. id_ed25519_astute_nas (NAS Automation Key) - ACTIVE

**Type:** ED25519
**Fingerprint:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOL7TwXpgVk3zJ8tEbPTVuVIjpX8hbqVVd9+K2y9KCY7`
**Comment:** audacious → astute NAS inhibit
**Location:** ~/.ssh/id_ed25519_astute_nas (Audacious)

**Used for:**
- NAS automation (sleep inhibitor control, idle checks)
- Triggered by Waybar clicks, systemd units

**Authorized on:**
- Astute: `~/.ssh/authorized_keys`
  - Source IP restriction: `from="192.168.1.147"` (Audacious only)
  - Forced command: `/usr/local/libexec/astute-nas-inhibit.sh`
  - Disabled: agent forwarding, port forwarding, X11 forwarding, PTY allocation

**SSH config entries:**
- `Host astute-nas` → NAS automation only
  - `IdentityAgent none` (no agent access)
  - `ForwardAgent no` (explicit disable)

**Scoping:** ✓ Excellent - highly restricted
- Cannot run arbitrary commands (forced command to specific script)
- Cannot access from any IP except Audacious (192.168.1.147)
- Cannot forward agents or ports
- Cannot allocate PTY
- No access to agent (IdentityAgent none)

**Status:** ✓ Active, properly restricted
**Backup coverage:** Borg to Astute, should be on Blue USB

---

### 4. id_astute_nas (OLD NAS Key) - DELETED

**Type:** ED25519
**Fingerprint:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOErGyh5opRYMlmjtV6Q3oSrSx1t3Vj5lK8jTxNJNja`
**Comment:** audacious→astute nas automation
**Location:** ~~/.ssh/id_astute_nas (Audacious)~~ DELETED

**Status:** ✓ DELETED 2026-01-07

**Analysis:**
This was a duplicate/unused key created Dec 21 2025, likely an attempted replacement for `id_ed25519_astute_nas` that was never deployed. The older key (Dec 18) remained the active one.

Since this key was never added to any authorized_keys files or SSH config, it was safely deleted with no impact on system functionality.

---

## Key Usage Matrix

| Key Name | SSH Access | Borg Backup | GitHub | NAS Automation |
|----------|-----------|-------------|---------|----------------|
| id_alchemist | ✓ Astute | - | ✓ | - |
| audacious-backup | - | ✓ Astute | - | - |
| id_ed25519_astute_nas | - | - | - | ✓ Astute |
| id_astute_nas | ✗ UNUSED | ✗ | ✗ | ✗ |

---

## Security Analysis

### Scoping Assessment

**Excellent practices:**
1. Separate keys for separate purposes (identity, backup, automation)
2. Forced commands for restricted access (borg, NAS automation)
3. IP restrictions on automation keys (from="192.168.1.147")
4. Agent forwarding disabled for automation keys
5. Borg key restricted to specific path only

**Good practices:**
1. All keys use ED25519 (modern, secure algorithm)
2. Main identity key has ForwardAgent enabled (allows GitHub access from Astute)
3. IdentitiesOnly used where appropriate (prevents key confusion)

**No issues found** - all active keys properly scoped for their purpose.

---

## Backup Coverage

**Keys backed up to Astute (Borg):** All (full /home/alchemist including ~/.ssh/)
- Last backup: Check `borg list ssh://borg@astute/srv/backups`

**Keys should be on Blue USB:**
- id_alchemist (private + public)
- audacious-backup (private + public)
- id_ed25519_astute_nas (private + public)

**Verify Blue USB coverage:** (when available)
```bash
# Mount Blue USB first (see secrets-recovery.md §3)
ls -la /mnt/keyusb/ssh-keys/
```

---

## Recommendations

### P1 - High Priority

**1. ~~Delete unused key pair (id_astute_nas)~~** ✓ COMPLETE 2026-01-07

Unused duplicate key successfully deleted with no impact.

---

### P2 - Medium Priority

**2. Verify Blue USB backup coverage**

When Blue USB is available, verify all active keys are backed up:
- [ ] id_alchemist (private + public)
- [ ] audacious-backup (private + public)
- [ ] id_ed25519_astute_nas (private + public)

**3. Document key rotation procedure**

Create procedure for rotating keys if compromised:
- How to generate new keys
- How to deploy to Astute authorized_keys
- How to update SSH config
- How to update Blue USB backup
- How to verify new keys work before removing old

---

### P3 - Low Priority

**4. Consider key rotation schedule**

No specific rotation schedule needed for SSH keys in home environment, but consider:
- Rotate after any suspected compromise
- Rotate when team members change (N/A - single user)
- Rotate annually as best practice (optional)

**5. Add key fingerprints to authorized_keys comments**

For easier auditing, add fingerprints to Astute authorized_keys:

```bash
# ssh-ed25519 AAAAC3N... alchemist@userlandlab.org (id_alchemist)
# Fingerprint: SHA256:xxxxx
```

---

## GPG Keys

**Status:** No GPG keys configured on either host.

**Audacious:** Debian CD signing keys only (package verification)
**Astute:** Fresh GnuPG directory (no keys)

**Recommendation:** No action needed unless GPG signing required for:
- Git commit signing
- Email encryption
- Document signing

If needed in future, create GPG key and document in this inventory.

---

## Authorized Keys on Astute

### alchemist@astute:~/.ssh/authorized_keys

```
# Full shell access (main identity)
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCWy7Ue1pd4CBBINMocHUozJ5qq54fXoJVfHcxwcWhF alchemist@userlandlab.org

# NAS automation (restricted)
from="192.168.1.147",command="/usr/local/libexec/astute-nas-inhibit.sh",no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOL7TwXpgVk3zJ8tEbPTVuVIjpX8hbqVVd9+K2y9KCY7 audacious to astute NAS inhibit
```

### borg@astute:/srv/backups/.ssh/authorized_keys

```
# Borg backup (heavily restricted)
command="borg serve --restrict-to-path /srv/backups",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLtERwjC4P/QCoGqhy2s1LhKjHfarurz+ompZ/SxfzJ alchemist@audacious
```

---

## Key Generation Commands (Reference)

For future key generation or rotation:

**Main identity key:**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_alchemist -C "alchemist@userlandlab.org"
```

**Backup key (passwordless for automation):**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/audacious-backup -C "audacious-backup" -N ""
```

**NAS automation key (passwordless for automation):**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_astute_nas -C "audacious-nas" -N ""
```

---

## Appendix: Key Types and Algorithms

**All keys use ED25519:**
- Modern elliptic curve algorithm
- Faster than RSA
- Smaller key size (256-bit security)
- Resistant to timing attacks
- Recommended over RSA 4096 or ECDSA

**No legacy keys found** (no RSA, DSA, or ECDSA).

---

**Last updated:** 2026-01-07
**Next review:** 2027-01-07 (annual) or after key rotation
