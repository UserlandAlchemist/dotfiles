# SSH Key Setup Guide

Complete SSH key architecture and setup procedures for the Wolfpack.

**Purpose:** All SSH keys, their purposes, generation procedures, and deployment across Audacious, Astute, and remote services.

---

## Overview

The Wolfpack uses multiple SSH keys for different purposes to follow the principle of least privilege. Each key has a specific role and limited scope.

**Security principle:** Separate keys for separate purposes. If one key is compromised, damage is contained to that key's scope.

---

## Key Architecture

| Key Name | Purpose | Used By | Access To | Type |
|----------|---------|---------|-----------|------|
| `id_alchemist` | Main identity | Audacious, Astute | GitHub, Astute (full shell), Audacious (full shell) | ED25519 |
| `audacious-backup` | Borg backups | Audacious | Astute (borg user, restricted to borg serve) | ED25519 |
| `id_ed25519_astute_nas` | NAS control | Audacious | Astute (forced command: nas-inhibit control only) | ED25519 |

**Key locations:**

On Audacious:
- `~/.ssh/id_alchemist` — Main identity for git/GitHub and general SSH
- `~/.ssh/audacious-backup` — Borg client key
- `~/.ssh/id_ed25519_astute_nas` — NAS wake/inhibit control key

On Astute:
- `~/.ssh/id_alchemist` — Main identity for git operations
- `/srv/backups/.ssh/authorized_keys` — Borg public key (borg user)
- `~/.ssh/authorized_keys` — Main + NAS control public keys (alchemist user)

**Recovery location:** Encrypted Blue USB contains all private keys + passphrases.

---

## §1 Generate Main Identity (id_alchemist)

The primary SSH key for interactive access and git operations.

Steps:
1. Generate ED25519 key:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_alchemist -C "alchemist@userlandlab.org"
```

2. Set strong passphrase when prompted (store in password manager and Blue USB)

3. Verify key was created:

```sh
ls -l ~/.ssh/id_alchemist*
```

Should see:
```
-rw------- 1 alchemist alchemist  464 Dec 23 12:00 id_alchemist
-rw-r--r-- 1 alchemist alchemist  109 Dec 23 12:00 id_alchemist.pub
```

4. Extract public key for deployment:

```sh
cat ~/.ssh/id_alchemist.pub
```

Expected result: ED25519 public key ready for deployment to GitHub and Astute.

---

## §2 Generate Borg Backup Key (audacious-backup)

Dedicated key for Borg backups from Audacious to Astute. Restricted to `borg serve` command only.

Steps:
1. Generate ED25519 key **without passphrase** (used by automated systemd timers):

```sh
ssh-keygen -t ed25519 -f ~/.ssh/audacious-backup -C "audacious-backup" -N ""
```

**Why no passphrase:** Systemd timers run unattended. Key is restricted to `borg serve` via forced command.

2. Verify key:

```sh
ls -l ~/.ssh/audacious-backup*
```

3. Extract public key:

```sh
cat ~/.ssh/audacious-backup.pub
```

Expected result: Public key ready for deployment to Astute borg user.

---

## §3 Generate NAS Control Key (id_ed25519_astute_nas)

Dedicated key for NAS wake-on-demand and sleep inhibitor control. Restricted to forced command only.

Steps:
1. Generate ED25519 key **without passphrase** (used by interactive bash functions):

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_astute_nas -C "audacious-nas" -N ""
```

**Why no passphrase:** Used by `nas-open` and `nas-close` bash functions. Key is restricted to inhibitor control script via forced command.

2. Verify key:

```sh
ls -l ~/.ssh/id_ed25519_astute_nas*
```

3. Extract public key:

```sh
cat ~/.ssh/id_ed25519_astute_nas.pub
```

Expected result: Public key ready for deployment to Astute with forced command restriction.

---

## §4 Deploy Keys to GitHub

Configure GitHub to accept `id_alchemist` for git operations.

Steps:
1. Copy public key to clipboard:

```sh
cat ~/.ssh/id_alchemist.pub
```

2. Navigate to GitHub Settings:
   - Visit: https://github.com/settings/keys
   - Click "New SSH key"
   - Title: "Audacious main identity" (or hostname)
   - Key type: Authentication key
   - Paste public key
   - Click "Add SSH key"

3. Test GitHub connection:

```sh
ssh -T git@github.com
```

Expected output:
```
Hi UserlandAlchemist! You've successfully authenticated, but GitHub does not provide shell access.
```

Expected result: Git operations work over SSH.

---

## §5 Deploy Keys to Astute

Configure Astute to accept keys from Audacious with appropriate restrictions.

### §5.1 Deploy Main Identity (Full Access)

Allow interactive SSH to Astute with full shell access.

Steps:
1. From Audacious, copy public key:

```sh
cat ~/.ssh/id_alchemist.pub
```

2. On Astute, add to authorized_keys:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys <<EOF
ssh-ed25519 AAAA...PASTE_PUBLIC_KEY... alchemist@userlandlab.org
EOF
chmod 600 ~/.ssh/authorized_keys
```

3. Test from Audacious:

```sh
ssh -i ~/.ssh/id_alchemist astute
```

Expected result: Shell access to Astute.

---

### §5.2 Deploy Borg Key (Restricted to borg serve)

Allow Borg client to access repository server with command restriction.

Steps:
1. On Astute, create borg system user (if not exists):

```sh
sudo adduser --system --home /srv/backups --shell /bin/sh --group borg
```

2. Set up SSH directory:

```sh
sudo mkdir -p /srv/backups/.ssh
sudo chmod 700 /srv/backups/.ssh
```

3. From Audacious, copy Borg public key:

```sh
cat ~/.ssh/audacious-backup.pub
```

4. On Astute, add with forced command restriction:

```sh
sudo tee /srv/backups/.ssh/authorized_keys >/dev/null <<'EOF'
command="borg serve --restrict-to-path /srv/backups",restrict ssh-ed25519 AAAA...PASTE_PUBLIC_KEY... audacious-backup
EOF
sudo chown borg:borg /srv/backups/.ssh/authorized_keys
sudo chmod 600 /srv/backups/.ssh/authorized_keys
```

**Security:** `restrict` disables port forwarding, X11, agent forwarding. `command=` forces only `borg serve`.

5. Test from Audacious:

```sh
ssh -i ~/.ssh/audacious-backup borg@astute
```

Should see:
```
Remote: borg serve --restrict-to-path /srv/backups
```

Then disconnect (key can only run borg serve, not shell).

6. Test Borg access:

```sh
borg list borg@astute:/srv/backups/audacious-borg
```

Expected result: Borg repository accessible, but key cannot get shell.

---

### §5.3 Deploy NAS Control Key (Restricted to Inhibitor Script)

Allow NAS wake functions to control sleep inhibitor with command restriction.

Steps:
1. From Audacious, copy NAS public key:

```sh
cat ~/.ssh/id_ed25519_astute_nas.pub
```

2. On Astute, add to alchemist user's authorized_keys with forced command:

```sh
cat >> ~/.ssh/authorized_keys <<'EOF'
command="/usr/local/libexec/astute-nas-inhibit.sh",restrict ssh-ed25519 AAAA...PASTE_PUBLIC_KEY... audacious-nas
EOF
```

**Security:** Key can only run `/usr/local/libexec/astute-nas-inhibit.sh`, which accepts `start` or `stop` commands.

3. Ensure inhibitor script exists (deployed via `root-power-astute/`):

```sh
ls -l /usr/local/libexec/astute-nas-inhibit.sh
```

4. Ensure sudoers rule allows alchemist to control nas-inhibit.service:

```sh
sudo cat /etc/sudoers.d/nas-inhibit.sudoers
```

Should contain:
```
alchemist ALL=(ALL) NOPASSWD: /bin/systemctl start nas-inhibit.service
alchemist ALL=(ALL) NOPASSWD: /bin/systemctl stop nas-inhibit.service
```

5. Test from Audacious:

```sh
ssh -i ~/.ssh/id_ed25519_astute_nas astute start
```

Should start nas-inhibit.service on Astute.

6. Verify inhibitor active:

```sh
ssh -i ~/.ssh/id_alchemist astute 'systemctl status nas-inhibit.service'
```

7. Stop inhibitor:

```sh
ssh -i ~/.ssh/id_ed25519_astute_nas astute stop
```

8. Test nas-open/nas-close functions:

```sh
source ~/.bashrc
nas-open
ls /srv/astute
nas-close
```

Expected result: NAS control works, key cannot get shell or run other commands.

---

## §6 SSH Client Configuration (Audacious)

Configure SSH client to use correct keys for each host.

Location: `~/.ssh/config` (deployed via `ssh-audacious/`)

Configuration:
```
Host github.com
    User git
    IdentityFile ~/.ssh/id_alchemist
    IdentitiesOnly yes

Host astute
    HostName 192.168.1.154
    User alchemist
    IdentityFile ~/.ssh/id_alchemist
    IdentitiesOnly yes

Host astute-nas
    HostName astute
    User alchemist
    IdentityFile ~/.ssh/id_ed25519_astute_nas
    IdentitiesOnly yes
    IdentityAgent none
    ForwardAgent no

Host astute-borg
    HostName astute
    User borg
    IdentityFile ~/.ssh/audacious-backup
    IdentitiesOnly yes
    IdentityAgent none
    ForwardAgent no
```

**Why IdentitiesOnly yes:** Prevents SSH from trying all keys in agent. Only use specified key.

**Why IdentityAgent none for restricted keys:** Prevents agent forwarding for automated keys.

---

## §7 Extract Keys for Blue USB (Recovery)

Backup all private keys and passphrases to encrypted USB for disaster recovery.

Prerequisites:
- Blue USB formatted with LUKS encryption (see `SECRETS-RECOVERY.md`)
- USB mounted at `/mnt/keyusb`

Steps:
1. Mount Blue USB:

```sh
sudo cryptsetup luksOpen /dev/sdX1 keyusb
sudo mount /dev/mapper/keyusb /mnt/keyusb
```

2. Create SSH keys directory:

```sh
sudo mkdir -p /mnt/keyusb/ssh-keys
```

3. Copy private keys:

```sh
sudo cp ~/.ssh/id_alchemist /mnt/keyusb/ssh-keys/
sudo cp ~/.ssh/audacious-backup /mnt/keyusb/ssh-keys/
sudo cp ~/.ssh/id_ed25519_astute_nas /mnt/keyusb/ssh-keys/
```

4. Copy public keys (for reference):

```sh
sudo cp ~/.ssh/id_alchemist.pub /mnt/keyusb/ssh-keys/
sudo cp ~/.ssh/audacious-backup.pub /mnt/keyusb/ssh-keys/
sudo cp ~/.ssh/id_ed25519_astute_nas.pub /mnt/keyusb/ssh-keys/
```

5. Save SSH config:

```sh
sudo cp ~/.ssh/config /mnt/keyusb/ssh-keys/
```

6. Create passphrase file:

```sh
sudo tee /mnt/keyusb/ssh-keys/PASSPHRASES.txt >/dev/null <<EOF
id_alchemist passphrase: [ENTER PASSPHRASE HERE]
Date created: $(date +%Y-%m-%d)
EOF
```

7. Set restrictive permissions:

```sh
sudo chmod 600 /mnt/keyusb/ssh-keys/*
```

8. Sync and unmount:

```sh
sync
sudo umount /mnt/keyusb
sudo cryptsetup luksClose keyusb
```

Expected result: All SSH keys backed up to encrypted USB.

---

## §8 Restore Keys from Blue USB

Restore SSH keys after system reinstall or hardware replacement.

Use `/home/alchemist/dotfiles/docs/SECRETS-RECOVERY.md` §4.2 for the full SSH-only recovery procedure.

---

## §9 Key Rotation and Maintenance

### When to Rotate Keys

Rotate keys if:
- Private key compromised or suspected compromise
- Leaving system unattended in untrusted location
- After security incident
- Regularly (every 1-2 years as best practice)

### How to Rotate Keys

1. Generate new key (§1, §2, or §3 depending on which key)
2. Deploy new public key to all targets (GitHub, Astute)
3. Test new key works
4. Remove old public key from authorized_keys
5. Delete old private key
6. Update Blue USB backup (§7)

### Auditing Key Usage

Check which keys are deployed where:

On Audacious:
```sh
ls -l ~/.ssh/id_* ~/.ssh/audacious-backup*
```

On Astute:
```sh
cat ~/.ssh/authorized_keys
sudo cat /srv/backups/.ssh/authorized_keys
```

On GitHub:
- Visit: https://github.com/settings/keys
- Review SSH keys and last used dates

---

## §10 Troubleshooting

### "Permission denied (publickey)"

**Cause:** SSH key not accepted.

**Fix:**
1. Verify key exists:
   ```sh
   ls -l ~/.ssh/id_alchemist
   ```

2. Check SSH config uses correct key:
   ```sh
   cat ~/.ssh/config
   ```

3. Test with verbose mode:
   ```sh
   ssh -v -i ~/.ssh/id_alchemist astute
   ```

4. Verify public key is in authorized_keys on target:
   ```sh
   ssh user@host 'cat ~/.ssh/authorized_keys'
   ```

5. Check permissions:
   - Private key: 600
   - ~/.ssh directory: 700
   - authorized_keys: 600

---

### "Could not open a connection to your authentication agent"

**Cause:** SSH agent not running.

**Fix:**
```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_alchemist
```

---

### Borg backups fail with "Repository access aborted"

**Cause:** Borg key rejected or forced command incorrect.

**Fix:**
1. Test Borg SSH access:
   ```sh
   ssh -i ~/.ssh/audacious-backup borg@astute
   ```

2. Verify forced command in authorized_keys:
   ```sh
   sudo cat /srv/backups/.ssh/authorized_keys
   ```

   Should contain:
   ```
   command="borg serve --restrict-to-path /srv/backups",restrict ssh-ed25519 ...
   ```

3. Check borg user home permissions:
   ```sh
   sudo ls -ld /srv/backups
   sudo ls -ld /srv/backups/.ssh
   ```

---

### NAS control functions fail

**Cause:** NAS control key rejected or forced command script missing.

**Fix:**
1. Test NAS SSH access:
   ```sh
   ssh -i ~/.ssh/id_ed25519_astute_nas astute start
   ```

2. Verify forced command in authorized_keys:
   ```sh
   ssh astute 'cat ~/.ssh/authorized_keys | grep audacious-nas'
   ```

3. Check inhibitor script exists:
   ```sh
   ssh astute 'ls -l /usr/local/libexec/astute-nas-inhibit.sh'
   ```

4. Verify sudoers rule:
   ```sh
   ssh astute 'sudo cat /etc/sudoers.d/nas-inhibit.sudoers'
   ```

---

## Appendix A: Security Considerations

**Why ED25519 keys:**
- Modern, secure, fast
- Shorter key length than RSA (256-bit vs 3072-bit)
- Better resistance to timing attacks

**Why separate keys:**
- Principle of least privilege
- Compromise of one key doesn't affect others
- Different keys can have different lifetimes
- Easier to audit access per-service

**Why forced commands:**
- Restricts key to single operation
- Prevents shell access even if key is compromised
- Combined with `restrict` option for maximum security

**Why some keys have no passphrase:**
- Automated operations (systemd timers) can't enter passphrases
- Mitigated by forced commands and restricted scope
- Risk: If audacious root is compromised, attacker can run borg/nas commands
- Acceptable: Main identity key has passphrase for interactive use

---

## Appendix B: Cross-References

**Related documentation:**
- `SECRETS-RECOVERY.md` — Blue USB creation and maintenance
- `docs/audacious/INSTALL.audacious.md` §17 — NAS integration
- `docs/astute/INSTALL.astute.md` §11 — Borg server setup
- `docs/astute/INSTALL.astute.md` §12 — Dotfiles deployment (nas-inhibit service)
- `root-power-astute/README.md` — NAS inhibitor implementation
- `nas-audacious/README.md` — NAS wake-on-demand service

---
