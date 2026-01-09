# Offsite Backup

BorgBase offsite backup setup and operations.

---

## Overview

- **Provider:** BorgBase (EU)
- **Transport:** SSH + BorgBackup
- **Encryption:** client-side (repokey-blake2)
- **Schedule:**
  - Audacious: daily at 14:00
  - Astute: weekly on Sunday at 15:00
- **Retention:** Managed manually via BorgBase web UI or offline full-access key

---

## Repositories

### audacious-home (j31cxd2v)
- **Access:** Append-only SSH key
- **Content:** Audacious home data
- **Backup frequency:** Daily at 14:00

### astute-critical (y7pc8k07)
- **Access:** Append-only SSH key
- **Content:** `/srv/nas/lucii` and `/srv/nas/bitwarden-exports`
- **Backup frequency:** Weekly on Sunday at 15:00

Both repositories use append-only SSH keys for ransomware protection. Keys must be assigned as "Append-Only Access" in BorgBase (not repo-level setting).

---

## Setup

### SSH Key Generation

Generate separate SSH keys on each host with no passphrase (required for automated backups).

Audacious (as root):

```sh
sudo install -d -m 0700 /root/.ssh
sudo ssh-keygen -t ed25519 -a 100 -f /root/.ssh/borgbase-offsite-audacious -C "audacious borgbase offsite" -N ""
sudo chmod 600 /root/.ssh/borgbase-offsite-audacious
```

Astute (as root):

```sh
sudo install -d -m 0700 /root/.ssh
sudo ssh-keygen -t ed25519 -a 100 -f /root/.ssh/borgbase-offsite-astute -C "astute borgbase offsite" -N ""
sudo chmod 600 /root/.ssh/borgbase-offsite-astute
```

Upload public keys to BorgBase and assign each key as "Append-Only Access" for its repository:
- Audacious: `/root/.ssh/borgbase-offsite-audacious.pub` → audacious-home
- Astute: `/root/.ssh/borgbase-offsite-astute.pub` → astute-critical

### Repository Initialization

Run once per repo (as root):

```sh
sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-audacious -T -o IdentitiesOnly=yes" \
  borg init -e repokey-blake2 \
  ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-astute -T -o IdentitiesOnly=yes" \
  borg init -e repokey-blake2 \
  ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

After initialization, export repo keys and credentials to the Secrets USB. See `docs/recovery-kit-maintenance.md` for procedures.

---

## Health Checks

### Verify Append-Only Access

For each repository in BorgBase web UI:
- audacious-home (j31cxd2v): Edit Repository → ACCESS → SSH key under "Append-Only Access"
- astute-critical (y7pc8k07): Edit Repository → ACCESS → SSH key under "Append-Only Access"

**CRITICAL:** BorgBase implements append-only via SSH key assignment. Each repo must have its SSH key assigned as "Append-Only Access". Without this, ransomware can delete off-site backups.

### Verify Timers

```sh
systemctl list-timers | grep borg-offsite
```

### Check Recent Logs

```sh
journalctl -u borg-offsite-audacious.service --since "1 week ago"
journalctl -u borg-offsite-astute-critical.service --since "1 week ago"
```

### Monthly Integrity Checks

```sh
journalctl -u borg-offsite-check.service --since "2 months ago"
```

### List Archives

```sh
sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-audacious -T -o IdentitiesOnly=yes" \
  borg list ssh://j31cxd2v@j31cxd2v.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase-offsite-astute -T -o IdentitiesOnly=yes" \
  borg list ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

---

## Restore

All restore procedures are in `docs/disaster-recovery.md` (§4).

---
