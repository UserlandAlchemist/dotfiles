# Task for Codex: Extend Borg Retention

**Priority:** P2 (from BACKUP-AUDIT.md)
**Difficulty:** Simple
**Risk:** Low

---

## Objective

Change Borg backup retention from 2 archives to 7 daily archives.

**Why:** Provides 7-day recovery window for deleted files and ransomware protection.

**Impact:** Repository grows from 4.44 GB to ~9 GB (well within Astute's 3.6 TB capacity).

---

## Implementation

**File to edit:** `root-backup-audacious/usr/local/lib/borg/run-backup.sh`

**Change line 52-55 from:**
```bash
echo "Pruning old archives..."
borg prune --list \
  --keep-last 2 \
  "$REPO"
```

**To:**
```bash
echo "Pruning old archives..."
borg prune --list \
  --keep-daily 7 \
  "$REPO"
```

---

## Deployment

```bash
sudo /home/alchemist/dotfiles/root-backup-audacious/install.sh
```

---

## Verification

**After 7 days of backups:**

```bash
source ~/.config/borg/env
export BORG_BASE_DIR=/tmp/borg-verify
export BORG_CACHE_DIR=/tmp/borg-verify/cache
borg list "$BORG_REPO"
```

Should show 7 archives (or number of days since change if <7 days).

**Current (before change):** 2 archives
**Expected (after 7 days):** 7 archives

---

## Testing

**Optional immediate test:**
```bash
# Manual backup
sudo systemctl start borg-backup.service

# Check logs
journalctl -u borg-backup.service -n 50

# Verify prune output mentions "--keep-daily 7"
```

---

## Commit Message

```
backups: extend Borg retention to 7 daily archives

Change retention policy from --keep-last 2 to --keep-daily 7 to provide
7-day recovery window for deleted files and ransomware protection.

Space impact: ~4.44 GB → ~9 GB repository (acceptable, Astute has 3.2 TB free).

Recommendation from docs/BACKUP-AUDIT.md (P2).
```

---

## Notes

- Service runs as root (uses sudo install script)
- Next backup will apply new retention policy automatically
- Old archives beyond 7 days will be pruned on next backup
- Repository will grow gradually over 7 days to full size
