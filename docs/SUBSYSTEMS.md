# Key Subsystems Reference

Quick reference for critical subsystems. For stressed situations (hardware failures, recovery), this document provides essential architecture knowledge in one place.

---

## Sudoers File Handling

Sudoers files **cannot** be managed via stow due to permissions requirements.

**Process:**
1. Rules live at `<package>/etc/sudoers.d/<name>.sudoers` (note `.sudoers` extension)
2. Each package with sudoers has `install.sh` that:
   - Installs system-scope files as real files in `/etc` or `/usr/local`
   - Uses `install -o root -g root -m 0440` to copy sudoers files to `/etc/sudoers.d/`
   - Runs `visudo -c` to validate
3. Examples: `root-sudoers-audacious/install.sh`, `root-power-astute/install.sh`

---

## NAS Wake-on-Demand (Audacious ↔ Astute)

Multi-layer orchestration allowing Audacious to wake Astute for NAS access, then allow sleep when done.

### Audacious Side

**Packages:** `nas-audacious/`, `bash-audacious/.bashrc.d/50-nas-helpers.sh`

**User service:** `astute-nas.service`
- Sends WOL magic packet to Astute
- Waits for SSH reachability (60s timeout)
- SSH to `astute-nas` host (restricted key) with command `start`
- Mounts NFS via `sudo systemctl start srv-astute.mount`

**Bash functions:**
- `nas-open` → starts service, cd to `/srv/astute`
- `nas-close` → stops service (unmounts, SSH stop command)
- `ssh-astute` → WOL + SSH convenience wrapper

**SSH config:** `ssh-audacious/.ssh/config`
```
Host astute-nas
    HostName astute
    User alchemist
    IdentityFile ~/.ssh/id_ed25519_astute_nas
    IdentitiesOnly yes
    IdentityAgent none
    ForwardAgent no
```

### Astute Side

**Package:** `root-power-astute/`

**SSH forced command:** `/usr/local/libexec/astute-nas-inhibit.sh`
- Accepts only `start` or `stop` via `SSH_ORIGINAL_COMMAND`
- Calls `sudo systemctl start/stop nas-inhibit.service`

**System service:** `nas-inhibit.service`
- Runs: `systemd-inhibit --what=sleep --mode=block /usr/bin/sleep infinity`
- Prevents system sleep while NAS is in use
- Max runtime: 3600s (1 hour)

**Sudoers rule:** `/etc/sudoers.d/nas-inhibit.sudoers`
- Allows `alchemist` to control `nas-inhibit.service` without password

**Authorized keys:** `/home/alchemist/.ssh/authorized_keys` (NOT in repo)
```
command="/usr/local/libexec/astute-nas-inhibit.sh",restrict ssh-ed25519 AAAA... audacious-nas
```

---

## Intelligent Idle Shutdown (Audacious)

**Script:** `bin-audacious/.local/bin/idle-shutdown.sh`

Triggered by `swayidle` after 20 minutes of no user input. Multi-phase policy:

**Immediate abort if:**
- MPRIS media playing (via `playerctl`)
- Jellyfin remote playback detected (fail-open if unreachable)
- systemd shutdown inhibitor active

**Idle phase** (first 20-30 min):
- True idle → shutdown

**Unattended work phase** (up to 90 min):
- CPU/network activity detected → allow to continue
- After 90 min total → force shutdown

**Design philosophy:** Fail-open for remote checks; critical jobs must use `systemd-inhibit`.

---

## BorgBackup (Audacious → Astute)

### Audacious

**Packages:** `borg-user-audacious/`, `root-backup-audacious/`

**Configuration:**
- User config: `~/.config/borg/patterns` (inclusion/exclusion patterns)
- User secret: `~/.config/borg/passphrase` (NOT in repo)

**Systemd timers:**
- `borg-backup.timer` → multiple times daily
- `borg-check.timer` → daily integrity checks
- `borg-check-deep.timer` → monthly deep verification

**SSH host:** `astute-borg` (restricted key: `~/.ssh/audacious-backup`)

### Astute

**Setup:**
- Dedicated `borg` system user with restricted shell
- Repository: `/srv/backups/audacious-borg`
- SSH authorized_keys with forced command: `borg serve --restrict-to-path /srv/backups`
- Stored on encrypted ZFS mirror

---

## Dual EFI Auto-Sync (Audacious)

**Package:** `root-efisync-audacious/`

**Components:**
- `efi-sync.path` - Watches `/boot/efi/EFI/Linux/` for UKI updates
- `efi-sync.service` - Uses `rsync` to mirror primary ESP to backup ESP

**Purpose:** Both NVMe drives can boot with identical EFI content.

---

## Power Management

### Audacious

**Package:** `root-power-audacious/`

**Services:**
- `powertop.service` - Aggressive power savings on boot
- `usb-nosuspend.service` - Prevents input device autosuspend

**Configuration:**
- udev rules to keep keyboard/mouse/webcam fully powered
- SATA power policies via `hdparm`

**Note:** Suspend is disabled (unreliable on this hardware - neither s2idle nor s3 resume correctly).

### Astute

**Package:** `root-power-astute/`

**Services:**
- `astute-idle-suspend.timer` + `.service`
- Suspends on idle, WOL wakes

---

## Quick Recovery Commands

### Deploy user configuration
```bash
cd ~/dotfiles
stow profile-common bash-audacious bin-audacious emacs-audacious sway-audacious waybar-audacious
```

### Deploy system configuration
```bash
sudo root-power-audacious/install.sh
sudo root-backup-audacious/install.sh
```

### Packages with sudoers (use install.sh)
```bash
cd root-sudoers-audacious
sudo ./install.sh
```

---

## Emergency Contacts

See `docs/SSH-KEY-SETUP.md` for SSH key recovery procedures.
See `docs/SECRETS-RECOVERY.md` for Blue USB backup procedures.
See host-specific `docs/<hostname>/RECOVERY.md` for full recovery workflows.
