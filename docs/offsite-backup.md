# Offsite Backup

Document the BorgBase offsite backup flow and recovery steps.

---

## Overview

- Provider: BorgBase (EU)
- Transport: SSH + BorgBackup
- Encryption: client-side (repokey-blake2)
- Schedule: daily at 14:00 from Astute

---

## Repositories

- `audacious-home` (j6i5cke1) — **append-only**; contains the Audacious Borg repository directory from Astute
- `astute-critical` (y7pc8k07) — **append-only**; contains `/srv/nas/lucii` and `/srv/nas/bitwarden-exports`

Both repositories use append-only mode for ransomware protection. Retention must be managed manually via BorgBase web UI.

---

## Credentials

1. SSH key on Astute:
   - Private key: `/root/.ssh/borgbase_offsite`
   - Public key uploaded to BorgBase
2. Passphrases stored in password manager.
3. Root-only passphrase files on Astute:
   - `/root/.config/borg-offsite/audacious-home.passphrase`
   - `/root/.config/borg-offsite/astute-critical.passphrase`
4. Blue USB key exports (stored on Audacious):
   - `/mnt/keyusb/borg/audacious-home-key.txt`
   - `/mnt/keyusb/borg/astute-critical-key.txt`

---

## Repo initialization

Run once per repo (as root). Force the root SSH key:

```bash
sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg init -e repokey-blake2 \
  ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg init -e repokey-blake2 \
  ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

---

## Backup flow

1. Audacious backs up to Astute (Borg 1.x) multiple times per day.
2. Astute pushes offsite daily at 14:00:
   - `audacious-home`: snapshot of `/srv/backups/audacious-borg`
   - `astute-critical`: snapshot of critical datasets
3. Monthly check verifies repo integrity.

---

## Restore: Audacious (from offsite)

This is a two-step restore (repo restore, then data restore).

1. Restore the Borg repo directory from BorgBase:

```bash
sudo borg extract \
  ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo::audacious-home-YYYY-MM-DD \
  srv/backups/audacious-borg
```

2. Restore data from the recovered repo:

```bash
export BORG_REPO=/srv/backups/audacious-borg
export BORG_PASSCOMMAND="cat /root/.config/borg/passphrase"

borg list "$BORG_REPO"

borg extract "$BORG_REPO"::audacious-YYYY-MM-DD \
  home/alchemist
```

**Note:** Step 2 uses the LOCAL Borg repo passphrase (`/root/.config/borg/passphrase`), NOT the off-site passphrase. The off-site passphrase is only for accessing BorgBase repositories.

---

## Restore: Astute critical data

1. List archives:

```bash
sudo borg list ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

2. Extract to a staging path, then move into place:

```bash
sudo borg extract \
  ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo::astute-critical-YYYY-MM-DD \
  srv/nas/lucii \
  srv/nas/bitwarden-exports
```

---

## Health checks

1. **Verify append-only mode (BOTH repos):**

   - audacious-home (j6i5cke1): Settings → Append-only mode: **ENABLED**
   - astute-critical (y7pc8k07): Settings → Append-only mode: **ENABLED**

   **CRITICAL:** Without append-only on both repos, ransomware can delete off-site backups, defeating the entire purpose.

2. Timers:

```bash
systemctl list-timers | grep borg-offsite
```

3. Recent logs:

```bash
journalctl -u borg-offsite-audacious.service --since "1 week ago"
journalctl -u borg-offsite-astute-critical.service --since "1 week ago"
```

4. Monthly checks:

```bash
journalctl -u borg-offsite-check.service --since "2 months ago"
```

5. List archives (force root SSH key):

```bash
sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg list ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg list ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```
