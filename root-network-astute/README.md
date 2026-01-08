# root-network-astute

Network configuration for Astute using systemd-networkd with DHCP.

## Purpose

Configures wired ethernet networking using systemd-networkd for proper network-online.target signaling. This ensures services that depend on network connectivity (especially offsite backups) wait until DNS resolution is working.

## Contents

### systemd-networkd configuration

**Files**:
- `etc/systemd/network/10-wired.link` — Matches enp0s31f6 interface by name
- `etc/systemd/network/20-wired.network` — Configures DHCP on enp0s31f6

**Why systemd-networkd + systemd-resolved?**
- Proper network-online.target signaling for backup timers with WakeSystem
- Direct integration with systemd
- Consistent with Audacious configuration (both use networkd + resolved)
- systemd-resolved provides local DNS caching and robust DNS management
- Fixes DNS resolution failures after system wake

**Interface naming:**
The interface name `enp0s31f6` is hardware-specific (predictable network interface name based on PCI topology). If the hardware changes, this name may change and will need updating.

**DHCP reservation:**
Astute uses DHCP with a router-side reservation. The BT Smart Hub 2 is configured to always assign 192.168.1.154 to Astute's MAC address (60:45:cb:9b:ab:3b). No static IP configuration needed on Astute.

## Installation

See docs/astute/install-astute.md §7 for migration procedure.

## Verification

```bash
# Check systemd-networkd status
systemctl status systemd-networkd

# Check interface status
networkctl status enp0s31f6

# Verify IP address
ip addr show enp0s31f6  # Should show 192.168.1.154

# Test DNS resolution
host borgbase.com

# Test offsite backup
sudo systemctl start borg-offsite-audacious.service
journalctl -u borg-offsite-audacious.service -n 30
```

## Troubleshooting

**Network not coming up:**
- Check interface name: `ip link show`
- If different from `enp0s31f6`, update both `.link` and `.network` files
- Restart networkd: `sudo systemctl restart systemd-networkd`

**DHCP not assigning address:**
- Check router DHCP server status
- Verify DHCP reservation for MAC 60:45:cb:9b:ab:3b
- Check networkd logs: `journalctl -u systemd-networkd`
- Try manual renewal: `sudo networkctl renew enp0s31f6`

**DNS not working:**
- Check resolv.conf: `cat /etc/resolv.conf`
- Should be symlink to `/run/systemd/resolve/stub-resolv.conf`
- Check systemd-resolved status: `resolvectl status`
- Check systemd-resolved service: `systemctl status systemd-resolved`
- Verify DNS servers: `resolvectl` (should show DHCP-provided DNS)
