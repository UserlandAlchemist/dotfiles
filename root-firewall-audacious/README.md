# root-firewall-audacious

Host firewall using nftables.

Default-deny inbound rules to reduce LAN lateral movement and accidental exposure.

## Rules Summary

- Default policy: drop inbound and forward, allow outbound
- Allow established/related connections
- Allow loopback
- Allow ICMP from LAN (ping)
- Allow DHCP replies (UDP 67 -> 68) from LAN
- Log and drop other inbound traffic (rate-limited)

## Install

```sh
sudo ./root-firewall-audacious/install.sh
```

## Verify

```sh
sudo nft list ruleset
ss -tlnp
```

Expected result:
- `nftables` service active
- No unexpected inbound listeners are reachable from LAN

## Notes

- DHCP is enabled on Audacious; inbound DHCP replies are allowed.
- If you need inbound services later, add explicit allow rules.
