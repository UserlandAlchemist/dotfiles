# root-offsite-astute

Off-site BorgBackup push from Astute to BorgBase.

This package backs up:
- Audacious Borg repo directory: `/srv/backups/audacious-borg` → `audacious-home` repo
- Critical datasets: `/srv/nas/lucii` and `/srv/nas/bitwarden-exports` → `astute-critical` repo

The `astute-critical` repository must be **append-only** in BorgBase.

---

## Prerequisites

1. BorgBackup installed (borg 1.x).
2. BorgBase SSH key installed on Astute:
   - Private key: `/root/.ssh/borgbase_offsite`
   - Public key uploaded to BorgBase.
3. Passphrase files created (root-only):
   - `/root/.config/borg-offsite/audacious-home.passphrase`
   - `/root/.config/borg-offsite/astute-critical.passphrase`
4. BorgBase repos created:
   - audacious-home (normal)
   - astute-critical (append-only)

---

## Repo initialization

Initialize the BorgBase repos (run once per repo). Force the root SSH key:

```bash
sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg init --encryption=repokey-blake2 \
  ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg init --encryption=repokey-blake2 \
  ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

Store both passphrases in the password manager. Do not paste them here.

---

## Deploy

Install systemd units as real files:

```bash
sudo /home/alchemist/dotfiles/root-offsite-astute/install.sh
```

Enable timers:

```bash
sudo systemctl enable --now \
  borg-offsite-audacious.timer \
  borg-offsite-astute-critical.timer \
  borg-offsite-check.timer
```

---

## Schedules

- `borg-offsite-audacious.timer` — daily at 14:00 (Persistent + WakeSystem)
- `borg-offsite-astute-critical.timer` — daily at 14:00 (Persistent + WakeSystem)
- `borg-offsite-check.timer` — monthly (Persistent + WakeSystem)

---

## Sanity checks

List off-site archives:

```bash
sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg list ssh://j6i5cke1@j6i5cke1.repo.borgbase.com/./repo

sudo BORG_RSH="ssh -i /root/.ssh/borgbase_offsite -T -o IdentitiesOnly=yes" \
  borg list ssh://y7pc8k07@y7pc8k07.repo.borgbase.com/./repo
```

Check service status:

```bash
systemctl status borg-offsite-audacious.service
systemctl status borg-offsite-astute-critical.service
systemctl status borg-offsite-check.service
```

---

## Notes

- `audacious-home` contains the Borg repo directory from Astute. Restores are two-step.
- `astute-critical` is append-only; do not prune or compact.
- Logs: `journalctl -u borg-offsite-*.service`
