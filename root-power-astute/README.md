# root-power-astute - Astute Power Management

System-level power management policy and NAS orchestration support for Astute.

## Purpose

Astute is a low-power NAS/backup server designed to suspend on idle and wake on demand. This package provides:

1. **Idle suspend policy** - Automatic suspension after inactivity
2. **NAS sleep inhibitor** - Prevents suspension while NAS is in use by Audacious
3. **Power optimization** - Aggressive power savings via powertop
4. **Hardware blacklists** - Disable unnecessary modules (watchdog, GPU)

## Components

### NAS Wake-on-Demand Support

**This package (Astute side):**
- `nas-inhibit.service` - Systemd service that blocks sleep while NAS is in use
  - Runs: `systemd-inhibit --what=sleep --mode=block /usr/bin/sleep infinity`
  - Max runtime: 3600s (1 hour safety timeout)
- `astute-nas-inhibit.sh` - SSH forced command script
  - Accepts only `start` or `stop` via `SSH_ORIGINAL_COMMAND`
  - Calls `sudo systemctl start/stop nas-inhibit.service`
- `nas-inhibit.sudoers` - Allows `alchemist` to control nas-inhibit.service without password

**Remote (Audacious side) orchestration:**
- See `nas-audacious/README.md` for full workflow
- Audacious sends SSH commands to start/stop the inhibitor
- SSH key is restricted via authorized_keys forced command

### Idle Suspend Policy

- `astute-idle-suspend.timer` - Triggers idle check every 3 minutes
- `astute-idle-suspend.service` - Runs idle check script
- `astute-idle-check.sh` - Suspends system if all checks pass:
  - No active SSH sessions (interactive terminals)
  - No systemd inhibitors present
  - No recent NAS filesystem activity (10 minute window)
  - No active Jellyfin clients (20 minute window)

### Power Optimization

- `powertop.service` - One-shot service that applies powertop tunings on boot
  - Runs: `powertop --auto-tune`
  - Aggressive power savings for all devices

### Hardware Configuration

- `blacklist-watchdog.conf` - Disables watchdog modules (iTCO_wdt, iTCO_vendor_support)
- `blacklist-gpu.conf` - Disables AMD GPU drivers (amdgpu, radeon) on headless server

## How It Works

### NAS Inhibitor Lifecycle

1. Audacious user runs `nas-open`
2. Audacious SSH to `astute-nas` host with command `start`
3. SSH forced command runs: `/usr/local/libexec/astute-nas-inhibit.sh`
4. Script validates command, runs: `sudo systemctl start nas-inhibit.service`
5. Service asserts sleep inhibitor, preventing suspension
6. After `nas-close` on Audacious, service stops and inhibitor releases
7. Safety timeout (1 hour) ensures orphaned inhibitors eventually expire

### Idle Suspend Workflow

**Automatic (timer-based):**
1. Timer triggers every 3 minutes
2. `astute-idle-check.sh` runs checks:
   - `w -h` - Any interactive SSH or local console sessions (pts/ or tty)?
   - `systemd-inhibit --list` - Any sleep inhibitors?
   - `find /srv/nas -maxdepth 4 -mmin -10` - Recent NAS file activity?
   - Jellyfin API - Any active clients in last 20 minutes?
3. If all clear: `systemctl suspend`
4. Wake-on-LAN from Audacious brings system back

**Manual (Waybar click):**
1. User clicks Astute status indicator in Waybar
2. If Astute is down: Send WOL packet
3. If Astute is up: Trigger `systemctl start astute-idle-suspend.service` via SSH
4. Display mako notification with result:
   - "Going to Sleep" - System was idle, now suspending
   - "Staying Awake - [reason]" - System has active inhibitor/sessions/activity

## Waybar Integration

**Status indicator** (`bin-audacious/.local/bin/astute-status.sh`):
- Displays Astute server status in Waybar
- **SRV UP** (yellow) - Server is awake and responsive
- **SRV WAKING** (white) - WOL packet sent, waiting for boot
- **SRV ZZZ** (blue) - Server is asleep

**Click behavior:**
- When asleep: Send WOL packet to wake server
- When awake: Trigger idle-check to test if server can sleep

**Notifications** (via mako):
- Low urgency (gray, 8s): Status updates
  - "Idle Check - Checking if Astute can sleep..."
  - "Wake on LAN - Sending magic packet to wake Astute..."
- Normal urgency (blue, 10s): Results
  - "Staying Awake - SSH session active"
  - "Staying Awake - sleep inhibitor active"
  - "Staying Awake - recent NAS activity"
  - "Staying Awake - Jellyfin client active"
  - "Going to Sleep - Astute is idle and suspending now"

See `mako-audacious/README.md` for notification styling details.

---

## Security Model

**SSH key restriction** (on Audacious):
- Dedicated key `id_ed25519_astute_nas` (no passphrase, for automation)
- Authorized_keys forced command: only allows `start` or `stop`
- No shell access, no port forwarding, no agent forwarding

**Sudo restriction** (on Astute):
- User `alchemist` can only:
  - Start/stop nas-inhibit.service
  - Trigger astute-idle-suspend.service
  - Read astute-idle-suspend.service logs via journalctl
- No other sudo privileges for NAS operations

## Edge Cases

**Ungraceful shutdown:**
- If Audacious crashes or network fails, remote inhibitor stays active
- Mitigation: RuntimeMaxSec=3600 (1-hour timeout)
- Manual cleanup: `ssh astute sudo systemctl stop nas-inhibit.service`

**Inhibitor leak detection:**
```sh
# Check for orphaned inhibitors
systemd-inhibit --list --mode=block
```

## Installation

```sh
cd ~/dotfiles
sudo ./root-power-astute/install.sh
```

This script:
1. Stows systemd units and scripts to `/`
2. Installs sudoers file with correct ownership (root:root) and mode (0440)
3. Runs `systemctl daemon-reload`
4. Validates sudoers syntax with `visudo -c`

**Note:** Sudoers files cannot be stowed directly (symlinks violate security requirements). The install.sh script uses `install -o root -g root -m 0440` to copy the file with correct permissions.

## Testing

```sh
# Test NAS inhibitor (from Audacious)
nas-open
ssh astute systemctl status nas-inhibit.service  # should be active
nas-close
ssh astute systemctl status nas-inhibit.service  # should be inactive

# Test idle suspend policy
ssh astute
# Wait 5+ minutes with no activity
# System should suspend

# Test inhibitor prevents suspend
nas-open  # from Audacious
# Astute should NOT suspend while inhibitor is active

# Verify no inhibitor leaks
nas-open && nas-close && nas-open && nas-close
ssh astute 'systemd-inhibit --list --mode=block | grep sleep | wc -l'  # should be 0
```

## See Also

- `nas-audacious/README.md` - Client-side NAS orchestration (Audacious)
- `ssh-audacious/.ssh/config` - SSH host configuration for `astute-nas`
- `root-sudoers-audacious/` - Audacious sudo policy for NFS mount control
- install.audacious.md §17 - NAS integration setup
