# nas-audacious - NAS Wake-on-Demand Orchestration

User-level systemd service that orchestrates wake-on-demand access to the Astute NAS server.

## Purpose

Allows Audacious to wake Astute from suspend, mount the NFS share, and prevent Astute from sleeping while the NAS is in use.

## Components

**This package:**
- `astute-nas.service` - User systemd service controlling the full lifecycle
- `astute-nas.env` - Environment variables (NAS_PROVIDER_HOST, NAS_PROVIDER_MAC)

**Dependencies (cross-package orchestration):**
1. `bash-audacious/.bashrc.d/50-nas-helpers.sh` - Provides `nas-open` and `nas-close` functions
2. `ssh-audacious/.ssh/config` - Defines `astute-nas` SSH host (restricted key, forced command)
3. `root-sudoers-audacious/` - Allows passwordless sudo for srv-astute.mount control
4. **Remote (Astute):**
   - `root-power-astute/usr/local/libexec/astute-nas-inhibit.sh` - SSH forced command script
   - `root-power-astute/etc/systemd/system/nas-inhibit.service` - Sleep inhibitor service
   - `root-power-astute/etc/sudoers.d/nas-inhibit.sudoers` - Allows alchemist to control nas-inhibit.service

**System dependencies (not in repo):**
- `/etc/fstab` entry: `astute:/srv/nas  /srv/astute  nfs4  _netdev,noatime,noauto  0  0`
- `/srv/astute` mount point
- Astute NFS server running and exporting `/srv/nas`
- SSH key: `~/.ssh/id_ed25519_astute_nas` (secret, not in repo)
- Astute authorized_keys entry with forced command restriction

## How It Works

### Opening (nas-open)

1. User runs `nas-open` (bash function)
2. Bash function calls `systemctl --user start astute-nas.service`
3. Service checks if Astute is reachable via ping
   - If already up: skips WOL, proceeds to step 5
   - If down: continues to step 4
4. Service sends Wake-on-LAN magic packet and waits up to 30s for SSH
5. Service SSHes to `astute-nas` host with command `start`
6. SSH forced command on Astute runs: `sudo systemctl start nas-inhibit.service`
7. Service mounts NFS: `sudo systemctl start srv-astute.mount`
8. Bash function changes directory to `/srv/astute`

**Result:** Astute is awake, NAS is mounted, sleep inhibitor prevents suspension.

### Closing (nas-close)

1. User runs `nas-close` (bash function)
2. Bash function ensures not inside mount point (cd ~)
3. Bash function calls `systemctl --user stop astute-nas.service`
4. Service unmounts: `sudo systemctl stop srv-astute.mount`
5. Service SSHes to `astute-nas` host with command `stop`
6. SSH forced command on Astute runs: `sudo systemctl stop nas-inhibit.service`

**Result:** NAS unmounted, sleep inhibitor released, Astute can suspend on idle.

## Security Model

**SSH key restriction:**
- Dedicated key `id_ed25519_astute_nas` (no passphrase, for automation)
- Authorized_keys forced command: only allows `start` or `stop` via SSH_ORIGINAL_COMMAND
- No shell access, no port forwarding, no agent forwarding

**Sudo restrictions:**
- Audacious: Can only start/stop srv-astute.mount (NAS mount)
- Astute: Can only start/stop nas-inhibit.service (sleep inhibitor)

## Edge Cases

**Ungraceful service termination:**
- If `systemctl --user kill astute-nas.service` happens, remote inhibitor stays active
- Mitigation: nas-inhibit.service has 1-hour RuntimeMaxSec timeout (auto-cleanup)
- Manual cleanup: `ssh astute sudo systemctl stop nas-inhibit.service`

**Astute already awake:**
- Service checks reachability before WOL
- Skips wake, proceeds directly to mount
- Saves ~15 seconds

**Network unreachable:**
- Service fails after 30-second timeout
- No mount occurs, safe failure

## Deployment

```sh
stow nas-audacious
systemctl --user daemon-reload
```

No explicit enable needed - controlled via `nas-open`/`nas-close` functions.

## Testing

```sh
# Full cycle
nas-open
ls /srv/astute       # should show NAS contents
nas-close

# Verify inhibitor on Astute
ssh astute systemctl status nas-inhibit.service  # should be inactive after close

# Verify rapid cycles don't leak inhibitors
nas-open && nas-close && nas-open && nas-close
ssh astute 'systemd-inhibit --list --mode=block' | wc -l  # should be 0
```

## See Also

- `bash-audacious/.bashrc.d/50-nas-helpers.sh` - User-facing functions
- `root-sudoers-audacious/nas-mount.sudoers` - Sudo policy (Audacious side)
- `root-power-astute/README.md` - Server-side configuration (Astute)
- install-audacious.md §17 - NAS integration setup
