# root-network-audacious

Network configuration using systemd-networkd with APT proxy auto-detection.

Configures wired ethernet and automatic APT proxy detection for faster package
downloads when the Astute NAS is available.

## Contents

### systemd-networkd configuration

**Files**:

- `etc/systemd/network/10-wired.link` — Matches enp7s0 interface by name
- `etc/systemd/network/20-wired.network` — Configures DHCP on enp7s0

**Why systemd-networkd?**

- Faster boot than NetworkManager
- Minimal dependencies
- Direct integration with systemd
- Explicit configuration (no GUI required)

**Interface naming:**
The interface name `enp7s0` is hardware-specific:

- `en` — Ethernet
- `p7` — PCI bus 7
- `s0` — Slot 0

This is a predictable network interface name based on
hardware topology, not a MAC-based name. If the
motherboard or PCIe slot changes, this name may change and
will need updating.

### APT proxy auto-detection

**Files**:

- `etc/apt/apt.conf.d/01proxy` — Configures APT to use proxy auto-detection script
- `usr/local/bin/apt-proxy-detect.sh` — Detects if apt-cacher-ng on Astute is available

**How it works:**

1. APT calls `apt-proxy-detect.sh` before each package download
2. Script checks if Astute (192.168.1.154:3142) is
   reachable via ping or TCP connection
3. If available: Returns proxy URL (`http://192.168.1.154:3142`)
4. If unavailable: Returns `DIRECT` (download directly from mirrors)

**HTTPS behavior:**
The config explicitly disables proxying for HTTPS
(`Acquire::https::Proxy "false"`). This is correct
because:

- apt-cacher-ng cannot cache encrypted HTTPS traffic
- Main Debian repos use HTTP + GPG signatures (transport
  encryption unnecessary)
- Third-party repos (Jellyfin, PrismLauncher) use HTTPS
  and download directly
- Package authenticity is verified via GPG regardless of HTTP vs HTTPS

**Benefits:**

- Fast package downloads for Debian repos when Astute is
  awake (cached packages)
- Automatic fallback to direct downloads when Astute is suspended
- No manual proxy switching required
- Majority of packages (Debian official repos) benefit from caching

**Astute setup required:**
This assumes apt-cacher-ng is installed and running on
Astute at port 3142. See `docs/astute/install-astute.md`
for setup instructions.

## Installation

```bash
cd ~/dotfiles
sudo root-network-audacious/install.sh
```

The install script:

1. Deploys systemd-networkd configs as real files (not symlinks)
2. Deploys APT proxy config and detection script
3. Stows remaining files

**Manual activation required:**

```bash
# Enable and start systemd-networkd
sudo systemctl enable --now systemd-networkd

# Disable NetworkManager if present
sudo systemctl disable --now NetworkManager

# Test network connectivity
ping -c3 8.8.8.8

# Test APT proxy detection
/usr/local/bin/apt-proxy-detect.sh
# Should return: http://192.168.1.154:3142 (if Astute is awake)
# Should return: DIRECT (if Astute is suspended)
```

## Verification

```bash
# Check systemd-networkd status
systemctl status systemd-networkd

# Check interface status
networkctl status enp7s0

# Test APT proxy
sudo apt update  # Should use proxy if Astute is available
```

## Troubleshooting

**Network not coming up:**

- Check interface name: `ip link show`
- If different from `enp7s0`, update both `.link` and `.network` files
- Restart networkd: `sudo systemctl restart systemd-networkd`

**APT proxy not working:**

- Test script manually: `/usr/local/bin/apt-proxy-detect.sh`
- Check Astute reachability: `ping 192.168.1.154`
- Check apt-cacher-ng on Astute: `ssh astute systemctl status apt-cacher-ng`

**DHCP not assigning address:**

- Check router DHCP server status
- Check networkd logs: `journalctl -u systemd-networkd`
- Try manual renewal: `sudo networkctl renew enp7s0`

## See Also

- `docs/audacious/install-audacious.md` §9 — Network configuration during install
- `docs/astute/install-astute.md` — apt-cacher-ng setup on Astute
