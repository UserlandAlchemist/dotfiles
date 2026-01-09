# root-cachyos-audacious

Gaming and desktop performance optimizations derived from CachyOS kernel tuning.

System-level performance tweaks optimized for high-performance desktop with
gaming workloads: desktop productivity + gaming (MTGA, MMOs) + media streaming (Twitch).

## Hardware assumptions

- **CPU**: Modern multi-core x86_64 with intel_pstate driver
- **RAM**: 32GB with zram compressed swap
- **Storage**: NVMe SSDs (primary), with some SATA devices
- **Workload**: Mixed desktop, gaming, and media streaming

## Contents

### Kernel and memory tuning

**File**: `etc/sysctl.d/99-gaming-desktop-settings.conf`

**Memory management:**
- `vm.swappiness=150` — Aggressively use zram compression (cheap) over evicting file cache (expensive)
- `vm.vfs_cache_pressure=50` — Reduce VFS cache eviction pressure, keeping directory/inode cache in memory
- `vm.page-cluster=0` — Disable swap readahead (zram is RAM, not disk)
- `vm.dirty_bytes=268435456` (256MB) — Larger dirty page threshold before forcing writeout
- `vm.dirty_background_bytes=67108864` (64MB) — Background flusher starts at 64MB dirty
- `vm.dirty_writeback_centisecs=1500` (15s) — Reduce flusher wakeup frequency

**Kernel behavior:**
- `kernel.nmi_watchdog=0` — Disable NMI watchdog (reduces overhead, faster boot/shutdown)
- `kernel.unprivileged_userns_clone=1` — Allow unprivileged containers (needed for some games/tools)
- `kernel.printk=3 3 3 3` — Hide low-priority kernel messages from console
- `kernel.kptr_restrict=2` — Hide kernel pointers from all users (security hardening)
- `kernel.kexec_load_disabled=1` — Disable kexec (security hardening)

**Network:**
- `net.core.netdev_max_backlog=4096` — Increase receive queue to prevent packet loss under load

**Filesystem:**
- `fs.file-max=2097152` — Increase file handle limit (needed for some game launchers)

### I/O scheduler optimization

**File**: `etc/udev/rules.d/60-ioschedulers.rules`

Automatically sets optimal I/O schedulers based on device type:
- **NVMe**: `none` (no scheduler, direct submission to hardware)
- **SSD**: `mq-deadline` (latency-optimized, deadline scheduler)
- **HDD**: `bfq` (fairness scheduler for rotational media)

### Zram swap management

**File**: `etc/udev/rules.d/30-zram.rules`

When zram0 initializes:
- Disables zswap (conflicts with zram accounting)
- Swappiness set via sysctl.d (see above)

**Current setup**: 32GB zram device providing compressed swap in RAM.

### Low-latency audio access

**Files**:
- `etc/udev/rules.d/40-hpet-permissions.rules` — HPET and RTC accessible to `audio` group
- `etc/udev/rules.d/99-cpu-dma-latency.rules` — CPU DMA latency control accessible to `audio` group

**Purpose**: Allows low-latency audio applications (games, VOIP, streaming) to control CPU sleep states and timer precision without root privileges. User must be in `audio` group.

### Transparent hugepage tuning

**File**: `etc/tmpfiles.d/thp.conf`

Sets THP defrag mode to `defer+madvise`:
- Applications using tcmalloc (e.g., some games, Chrome) can request hugepages
- Kernel won't aggressively defragment memory unless requested
- Reduces background memory compaction overhead

### Systemd tweaks

**Files**:
- `etc/systemd/user.conf.d/limits.conf` — User services: max 1M open files (for game launchers)
- `etc/systemd/system.conf.d/limits.conf` — System services: max 1M open files
- `etc/systemd/system.conf.d/00-timeout.conf` — Fast service timeouts (15s start, 10s stop)

### Module configuration

**File**: `etc/modprobe.d/blacklist.conf`

Blacklists modules that aren't needed and add overhead:
- `iTCO_wdt` — Intel watchdog timer
- `sp5100_tco` — AMD watchdog timer

**File**: `etc/modprobe.d/20-audio-pm.conf`

Disables power management for audio hardware (prevents pops/clicks).

### Disabled udev rules

These rules exist but are disabled (`.disabled` suffix):
- `20-audio-pm.rules.disabled` — Alternative audio PM method
- `50-sata.rules.disabled` — SATA link power management
- `69-hdparam.rules.disabled` — HDD power management tuning

If you need aggressive power saving, remove `.disabled` suffix.

## Installation

```bash
cd ~/dotfiles
sudo root-cachyos-audacious/install.sh
```

The install script:
1. Deploys systemd configs as real files (not symlinks to /home)
2. Stows remaining configs
3. Reloads systemd daemon

## Verification

```bash
# Check swappiness
cat /proc/sys/vm/swappiness  # should be 150

# Check NVMe scheduler
cat /sys/block/nvme0n1/queue/scheduler  # should be [none]

# Check zswap is disabled
cat /sys/module/zswap/parameters/enabled  # should be N

# Check file limits
ulimit -n  # should be high (1048576)

# Check user is in audio group
groups | grep audio  # should include audio
```

## Gaming workflow integration

**With Steam/Lutris/Heroic:**
- Gamemode automatically applies nice priority (-10) to game processes
- Use `game-performance` wrapper for performance power profile + inhibit suspend

**Example**:
```bash
game-performance steam
game-performance lutris
```

## Performance vs battery life

This configuration prioritizes **performance and responsiveness** over power efficiency:
- No aggressive CPU/disk power management
- Higher memory usage (keeps more in cache)
- Faster I/O (no conservative scheduling)

If running on battery, consider:
- Using `powerprofilesctl set power-saver` manually
- Re-enabling `.disabled` udev rules for SATA/HDD power management

## Maintenance

When updating this package:
1. Edit configs in `~/dotfiles/root-cachyos-audacious/`
2. Re-run install script: `sudo root-cachyos-audacious/install.sh`
3. For sysctl changes: `sudo sysctl --system` or reboot
4. For udev changes: `sudo udevadm control --reload-rules && sudo udevadm trigger`

## References

- [CachyOS kernel tweaks](https://github.com/CachyOS/CachyOS-Settings)
- [Linux kernel zram documentation](https://www.kernel.org/doc/html/latest/admin-guide/blockdev/zram.html)
- [tcmalloc system optimizations](https://github.com/google/tcmalloc/blob/master/docs/tuning.md)
