# root-ssh-astute

SSH server hardening.

Locks SSH to LAN-only access to reduce exposure if router settings change or
UPnP opens ports.

## Components

- `etc/ssh/sshd_config.d/10-listenaddress.conf`
   - Sets `ListenAddress 192.168.1.154`
   - Keeps SSH bound to the Astute LAN IP only
   - Disables password auth and root login

- `etc/systemd/system/ssh.service.d/wait-for-network.conf`
   - Makes SSH wait for network-online.target before starting
   - Ensures 192.168.1.154 is assigned via DHCP before SSH tries to bind
   - Prevents "Cannot assign requested address" failures on boot

## Install

```sh
sudo ./root-ssh-astute/install.sh
```

## Verify

```sh
ss -tlnp | grep :22
```

Expected result:

- SSH listens on `192.168.1.154:22` only (no `0.0.0.0:22`)
- Password authentication is disabled

## Notes

- Restarting `ssh` should not terminate existing SSH sessions.
- No Tailscale/VPN listen address is configured (LAN-only by design).
