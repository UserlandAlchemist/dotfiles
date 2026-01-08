# Offsite Backup

Document the BorgBase offsite backup flow and recovery materials.

---

## Overview

- Provider: BorgBase (EU)
- Transport: SSH + BorgBackup
- Encryption: client-side (repokey-blake2)
- Schedule: daily at 14:00 from Audacious; weekly on Sunday at 15:00 from Astute

---

## Repositories

- `audacious-home` (j31cxd2v) — **append-only access**; contains Audacious home data
- `astute-critical` (y7pc8k07) — **append-only access**; contains `/srv/nas/lucii` and `/srv/nas/bitwarden-exports`

Both repositories are accessed via append-only SSH keys for ransomware protection (keys assigned as "Append-Only Access" in BorgBase). Retention must be managed manually via BorgBase web UI or offline full-access key.

---

## Credentials

1. SSH keys (separate keys per host recommended, passphrase may be shared):
   - Audacious: `/root/.ssh/borgbase-offsite-audacious`
   - Astute: `/root/.ssh/borgbase-offsite-astute`
   - Public keys uploaded to BorgBase
2. Passphrases stored in password manager.
3. Root-only passphrase files:
   - Audacious: `/root/.config/borg-offsite/audacious-home.passphrase`
   - Astute: `/root/.config/borg-offsite/astute-critical.passphrase`
4. Secrets USB key exports (stored on Audacious):
   - `/mnt/keyusb/borg/audacious-home-key.txt`
   - `/mnt/keyusb/borg/astute-critical-key.txt`
   - `/mnt/keyusb/ssh-backup/borgbase-offsite-audacious`
   - `/mnt/keyusb/ssh-backup/borgbase-offsite-astute`

---

## BorgBase SSH key generation

Generate separate SSH keys on each host (passphrase may be shared).

Audacious (as root):

```sh
sudo install -d -m 0700 /root/.ssh
sudo ssh-keygen -t ed25519 -a 100 -f /root/.ssh/borgbase-offsite-audacious -C "audacious borgbase offsite"
sudo chmod 600 /root/.ssh/borgbase-offsite-audacious
```

Astute (as root):

```sh
sudo install -d -m 0700 /root/.ssh
sudo ssh-keygen -t ed25519 -a 100 -f /root/.ssh/borgbase-offsite-astute -C "astute borgbase offsite"
sudo chmod 600 /root/.ssh/borgbase-offsite-astute
```

Upload public keys to BorgBase:
- Audacious: `/root/.ssh/borgbase-offsite-audacious.pub`
- Astute: `/root/.ssh/borgbase-offsite-astute.pub`

Assign each key as "Append-Only Access" for its repo in BorgBase.

---

## Secrets USB recovery materials

Export BorgBase repo keys and credentials to the Secrets USB. Do this after repo init or any credential rotation.

Steps:
1. Export BorgBase repo keys:

Audacious (as root):

```sh
install -d -m 0700 /root/tmp-borg-keys

BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-audacious -T -o IdentitiesOnly=yes" \
BORG_PASSCOMMAND="cat /root/.config/borg-offsite/audacious-home.passphrase" \
  borg key export ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo \
  /root/tmp-borg-keys/audacious-home-key.txt
```

Astute (as root):

```sh
install -d -m 0700 /root/tmp-borg-keys

BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-astute -T -o IdentitiesOnly=yes" \
BORG_PASSCOMMAND="cat /root/.config/borg-offsite/astute-critical.passphrase" \
  borg key export ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo \
  /root/tmp-borg-keys/astute-critical-key.txt
```

2. Copy repo keys to the Secrets USB:

Audacious (as root):

```sh
cp /root/tmp-borg-keys/audacious-home-key.txt /mnt/keyusb/borg/
rm /root/tmp-borg-keys/audacious-home-key.txt
rm -rf /root/tmp-borg-keys
```

Astute (as root), then on Audacious:

```sh
scp /root/tmp-borg-keys/astute-critical-key.txt alchemist@audacious:~/
rm -rf /root/tmp-borg-keys

cp ~/astute-critical-key.txt /mnt/keyusb/borg/
rm ~/astute-critical-key.txt
```

3. Copy BorgBase SSH key and passphrases to the Secrets USB:

Audacious (as root):

```sh
cp /root/.ssh/borgbase-offsite-audacious /mnt/keyusb/ssh-backup/borgbase-offsite-audacious
cp /root/.config/borg-offsite/audacious-home.passphrase /mnt/keyusb/borg/
chmod 600 /mnt/keyusb/ssh-backup/borgbase-offsite-audacious
chmod 600 /mnt/keyusb/borg/audacious-home.passphrase
```

Astute (as root), then on Audacious:

```sh
install -d -m 0700 /root/tmp-borgbase-creds
cp /root/.ssh/borgbase-offsite-astute /root/tmp-borgbase-creds/
cp /root/.config/borg-offsite/astute-critical.passphrase /root/tmp-borgbase-creds/
chmod 600 /root/tmp-borgbase-creds/*

scp /root/tmp-borgbase-creds/* alchemist@audacious:~/
rm -rf /root/tmp-borgbase-creds

cp ~/borgbase-offsite-astute /mnt/keyusb/ssh-backup/borgbase-offsite-astute
cp ~/astute-critical.passphrase /mnt/keyusb/borg/
chmod 600 /mnt/keyusb/ssh-backup/borgbase-offsite-astute
chmod 600 /mnt/keyusb/borg/astute-critical.passphrase
rm ~/borgbase-offsite-astute ~/astute-critical.passphrase
```

Expected result: Secrets USB contains BorgBase repo keys, SSH key, and passphrases.

---

## Repo initialization

Run once per repo (as root). Force the root SSH key:

If switching `audacious-home` from Astute to Audacious, delete the existing BorgBase repo first and recreate it with the same name, then re-run the init from Audacious.

```bash
sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-audacious -T -o IdentitiesOnly=yes" \
  borg init -e repokey-blake2 \
  ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-astute -T -o IdentitiesOnly=yes" \
  borg init -e repokey-blake2 \
  ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

---

## Backup flow

1. Audacious backs up to Astute (Borg 1.x) multiple times per day.
2. Audacious pushes offsite daily at 14:00:
   - `audacious-home`: snapshot of Audacious home data
3. Astute pushes offsite weekly on Sunday at 15:00:
   - `astute-critical`: snapshot of critical datasets
4. Monthly checks verify repo integrity.

---

## Restore

All restore procedures are centralized in `docs/data-restore.md`. Use that guide for:
- Audacious data restore from BorgBase.
- Astute critical data restore from BorgBase.
- Full-loss recovery flow.

## Health checks

1. **Verify append-only access (BOTH repos):**

   For each repository in BorgBase web UI:
   - audacious-home (j31cxd2v): Edit Repository → ACCESS → SSH key under "Append-Only Access"
   - astute-critical (y7pc8k07): Edit Repository → ACCESS → SSH key under "Append-Only Access"

   **CRITICAL:** BorgBase implements append-only via SSH key assignment (not repo-level setting). Each repo must have its SSH key assigned as "Append-Only Access". Without this, ransomware can delete off-site backups.

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
sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-audacious -T -o IdentitiesOnly=yes" \
  borg list ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-astute -T -o IdentitiesOnly=yes" \
  borg list ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```
