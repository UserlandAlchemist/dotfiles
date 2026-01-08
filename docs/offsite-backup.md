# Offsite Backup

Document the BorgBase offsite backup flow and recovery materials.

---

## Overview

- Provider: BorgBase (EU)
- Transport: SSH + BorgBackup
- Encryption: client-side (repokey-blake2)
- Schedule: daily at 14:00 from Astute

---

## Repositories

- `audacious-home` (j6i5cke1) — **append-only access**; contains the Audacious Borg repository directory from Astute
- `astute-critical` (y7pc8k07) — **append-only access**; contains `/srv/nas/lucii` and `/srv/nas/bitwarden-exports`

Both repositories are accessed via an append-only SSH key for ransomware protection (key assigned as "Append-Only Access" in BorgBase). Retention must be managed manually via BorgBase web UI or offline full-access key.

---

## Credentials

1. SSH key on Astute:
   - Private key: `/root/.ssh/borgbase_offsite`
   - Public key uploaded to BorgBase
2. Passphrases stored in password manager.
3. Root-only passphrase files on Astute:
   - `/root/.config/borg-offsite/audacious-home.passphrase`
   - `/root/.config/borg-offsite/astute-critical.passphrase`
4. Secrets USB key exports (stored on Audacious):
   - `/mnt/keyusb/borg/audacious-home-key.txt`
   - `/mnt/keyusb/borg/astute-critical-key.txt`

---

## Secrets USB recovery materials

Export BorgBase repo keys and credentials to the Secrets USB. Do this after repo init or any credential rotation.

Steps:
1. Export BorgBase repo keys on Astute (as root):

```sh
install -d -m 0700 /root/tmp-borg-keys

BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
BORG_PASSCOMMAND="cat /root/.config/borg-offsite/audacious-home.passphrase" \
  borg key export ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo \
  /root/tmp-borg-keys/audacious-home-key.txt

BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
BORG_PASSCOMMAND="cat /root/.config/borg-offsite/astute-critical.passphrase" \
  borg key export ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo \
  /root/tmp-borg-keys/astute-critical-key.txt
```

2. Copy repo keys to Audacious, then to the Secrets USB:

```sh
scp /root/tmp-borg-keys/*.txt alchemist@audacious:~/

cp ~/audacious-home-key.txt /mnt/keyusb/borg/
cp ~/astute-critical-key.txt /mnt/keyusb/borg/
rm ~/audacious-home-key.txt ~/astute-critical-key.txt

rm -rf /root/tmp-borg-keys
```

3. Copy BorgBase SSH key and passphrases to the Secrets USB:

```sh
install -d -m 0700 /root/tmp-borgbase-creds
cp /root/.ssh/borgbase_offsite /root/tmp-borgbase-creds/
cp /root/.config/borg-offsite/audacious-home.passphrase /root/tmp-borgbase-creds/
cp /root/.config/borg-offsite/astute-critical.passphrase /root/tmp-borgbase-creds/
chmod 600 /root/tmp-borgbase-creds/*

scp /root/tmp-borgbase-creds/* alchemist@audacious:~/

cp ~/borgbase_offsite /mnt/keyusb/ssh-backup/
cp ~/audacious-home.passphrase /mnt/keyusb/borg/
cp ~/astute-critical.passphrase /mnt/keyusb/borg/
chmod 600 /mnt/keyusb/ssh-backup/borgbase_offsite
chmod 600 /mnt/keyusb/borg/*.passphrase
rm ~/borgbase_offsite ~/audacious-home.passphrase ~/astute-critical.passphrase

rm -rf /root/tmp-borgbase-creds
```

Expected result: Secrets USB contains BorgBase repo keys, SSH key, and passphrases.

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

## Restore

All restore procedures are centralized in `docs/data-restore.md`. Use that guide for:
- Audacious data restore from BorgBase.
- Astute critical data restore from BorgBase.
- Full-loss recovery flow.

## Health checks

1. **Verify append-only access (BOTH repos):**

   For each repository in BorgBase web UI:
   - audacious-home (j6i5cke1): Edit Repository → ACCESS → SSH key under "Append-Only Access"
   - astute-critical (y7pc8k07): Edit Repository → ACCESS → SSH key under "Append-Only Access"

   **CRITICAL:** BorgBase implements append-only via SSH key assignment (not repo-level setting). The `astute-borgbase` key must be assigned as "Append-Only Access" to both repos. Without this, ransomware can delete off-site backups.

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
