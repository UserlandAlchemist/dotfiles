# root-sudoers-audacious

Sudo permissions for NAS mount control without password prompts.

## Purpose

This package grants the `alchemist` user passwordless sudo access to mount and unmount the Astute NAS. This is required for the NAS wake-on-demand orchestration system.

## Contents

### Sudoers configuration

**File**: `etc/sudoers.d/nas-mount.sudoers`

**Permissions granted:**
```
alchemist ALL=(root) NOPASSWD: /usr/bin/systemctl start srv-astute.mount
alchemist ALL=(root) NOPASSWD: /usr/bin/systemctl stop srv-astute.mount
```

**What this allows:**
- User `alchemist` can run these specific systemctl commands as root without entering a password
- Commands are restricted to exactly these paths (no other systemctl operations)
- Only affects the `srv-astute.mount` unit (NFS mount for Astute NAS)

## Why passwordless sudo?

The NAS orchestration system (`nas-audacious/` package) provides `nas-open` and `nas-close` bash functions that:
1. Wake Astute from suspend (Wake-on-LAN)
2. Mount the NFS share to `/srv/astute`
3. Start a remote inhibitor to prevent Astute from sleeping

This workflow must be **seamless and non-interactive**:
- User runs `nas-open` → NAS becomes available instantly
- No password prompt interrupting the workflow
- Allows scripting and automation (e.g., in dotfile deploy scripts)

## Security model

**Why this is safe:**
1. **Restricted command scope**: Only these two specific systemctl operations, nothing else
2. **Explicit path**: Uses full path `/usr/bin/systemctl` (prevents PATH hijacking)
3. **No wildcards**: No `*` or `?` in the command specification
4. **Single user**: Only `alchemist` has this privilege
5. **Limited blast radius**: Worst case is NAS mount/unmount disruption (no system compromise)

**Attack surface:**
- Attacker with access to `alchemist` account could:
  - Mount the NAS (exposes NAS contents - but read-only for user data)
  - Unmount the NAS (causes disruption but no data loss)
- Attacker **cannot**:
  - Gain root shell
  - Execute arbitrary commands as root
  - Modify system files
  - Access other systemctl operations

**Alternative considered:**
Using `systemctl --user` would avoid sudo entirely, but systemd mounts require root privileges by design. User-level mounts via FUSE were considered but rejected due to performance and compatibility concerns.

## Installation

This package uses a custom install script to ensure proper file ownership and permissions.

```bash
cd ~/dotfiles
sudo root-sudoers-audacious/install.sh
```

**Why install.sh?**
Sudoers files must have:
- Owner: `root:root`
- Permissions: `0440` (read-only, not writable even by root)
- Syntax validation before deployment

The install script:
1. Validates sudoers syntax with `visudo -c`
2. Sets correct ownership (`root:root`)
3. Sets correct permissions (`0440`)
4. Backs up any existing conflicting file

Plain `stow` cannot set ownership to root or ensure proper permissions.

## Verification

Test the configuration:

```bash
# This should work WITHOUT password prompt
sudo systemctl status srv-astute.mount

# This should REQUIRE password (not in sudoers)
sudo systemctl status sshd.service
```

Check file permissions:

```bash
ls -l /etc/sudoers.d/nas-mount.sudoers
# Should show: -r--r----- 1 root root ... nas-mount.sudoers
```

## Integration with NAS orchestration

This package is part of the multi-layer NAS wake-on-demand system:

**Local (Audacious):**
1. `bash-audacious/.bashrc.d/50-nas-helpers.sh` — Provides `nas-open`/`nas-close` functions
2. `nas-audacious/.config/systemd/user/astute-nas.service` — User service orchestrating wake/mount
3. **`root-sudoers-audacious`** (this package) — Allows passwordless mount control
4. `/etc/fstab` — Defines NFS mount point (not in repo, manual setup)

**Remote (Astute):**
1. `root-power-astute/usr/local/libexec/astute-nas-inhibit.sh` — SSH forced command script
2. `root-power-astute/etc/systemd/system/nas-inhibit.service` — Sleep inhibitor
3. `root-power-astute/etc/sudoers.d/nas-inhibit.sudoers` — Allows remote service control

## Troubleshooting

**Password still prompted:**
- Check file ownership: `ls -l /etc/sudoers.d/nas-mount.sudoers` (should be `root:root`)
- Check file permissions: Should be `0440` (read-only)
- Check syntax: `sudo visudo -cf /etc/sudoers.d/nas-mount.sudoers`
- Check username matches: Entry must use exact username `alchemist`

**"sudo: unable to open ... : Permission denied"**
- File permissions are wrong, should be `0440`
- Re-run install script: `sudo root-sudoers-audacious/install.sh`

**Sudoers syntax error:**
- Never edit sudoers files directly
- Always use `visudo` or the install script
- Syntax errors can lock you out of sudo entirely
- If locked out, boot to single-user mode and fix `/etc/sudoers`

## Manual fstab entry

This package does **not** create the `/etc/fstab` entry. That must be added manually:

```bash
# /etc/fstab
astute:/srv/nas  /srv/astute  nfs4  _netdev,noatime,noauto  0  0
```

**Flags explained:**
- `_netdev` — Wait for network before attempting mount
- `noatime` — Don't update access times (performance optimization)
- `noauto` — Don't mount at boot (mount on-demand via nas-open)

See `docs/audacious/install.audacious.md` §17 for complete NAS integration setup.

## See Also

- `nas-audacious/README.md` — Complete NAS orchestration system documentation
- `root-power-astute/README.md` — Server-side sleep inhibitor configuration
- `docs/audacious/install.audacious.md` §17 — NAS integration setup guide
