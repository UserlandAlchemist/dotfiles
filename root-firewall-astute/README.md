# root-firewall-astute

Host firewall using nftables.

Default-deny inbound rules to protect the NAS from LAN lateral movement while
allowing only Audacious to reach core services.

## Rules Summary

- Default policy: drop inbound and forward, allow outbound
- Allow established/related connections
- Allow loopback
- Allow ICMP from LAN (ping)
- Allow DHCP replies (UDP 67 -> 68) from LAN
- Allow from Audacious only:
  - SSH (22/tcp)
  - NFSv4 (2049/tcp)
  - RPC bind (111/tcp, 111/udp)
  - apt-cacher-ng (3142/tcp)
- Log and drop other inbound traffic (rate-limited)

## Install

```sh
sudo ./root-firewall-astute/install.sh
```

## Verify

```sh
sudo nft list ruleset
ss -tlnp
```

Expected result:
- `nftables` service active
- Only Audacious can reach SSH/NFS/RPC/apt-cacher-ng

## Notes

- If NFS fails, confirm ports in use on Astute and adjust rules as needed.
- If Audacious IP changes, update `audacious_ip` in nftables.conf.
