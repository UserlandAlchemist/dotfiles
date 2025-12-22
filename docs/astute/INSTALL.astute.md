# Debian 13 (Trixie) — Astute Install Guide

This guide prepares Astute, a headless Debian server providing encrypted ZFS storage,
network backups, and low-power operation.

Astute uses:
- Unencrypted NVMe root (ext4) for unattended boots
- SATA SSD for swap and ZFS cache/log
- Encrypted ZFS mirror (IronWolf drives) mounted at /srv/nas
- Headless operation via SSH, Wake-on-LAN, and suspend/resume

Host configuration:
- Hostname: astute
- Admin user: alchemist
- NVMe system disk: /dev/nvme0n1
- SATA SSD: /dev/sda
- IronWolf disks: /dev/sdb and /dev/sdc

---

## 1) Boot the installer

1. Boot the Debian 13.1 (Trixie) netinst USB stick.
2. Choose "Install" (standard mode).
3. Configure locale, keyboard, and network as normal.
4. When asked, choose "Manual" partitioning.

---

## 2) Partitioning

### /dev/nvme0n1 (system)
- 512 MB EFI System Partition, FAT32, mountpoint /boot/efi
- remaining space, ext4, mountpoint /

### /dev/sda (SATA SSD)
- 32 GB swap (or to preference)
- remainder unformatted (for ZFS cache/log)

### /dev/sdb and /dev/sdc (IronWolf HDDs)
Leave unused during install. Do not create partitions or filesystems.

Finish partitioning, write changes, and install GRUB to /dev/nvme0n1.

---

## 3) Software selection

At the "Software selection" screen:
- Select: standard system utilities
- Select: SSH server
- Do NOT select a desktop environment

Continue installation and reboot into Debian 13.1.

---

## 4) First boot

Log in locally and become root:

    su -

Install base packages:

    apt update
    apt install -y sudo cryptsetup sudo

Add the admin user to the sudo group:

    usermod -aG sudo alchemist

---

## 5) SSH key setup

Unlock your encrypted USB (if used for SSH keys):

     lsblk
     cryptsetup luksOpen /dev/sdX1 keyusb
     mkdir -p /mnt/keyusb
     mount /dev/mapper/keyusb /mnt/keyusb

Install your admin key:

     mkdir -p /home/alchemist/.ssh
     cat /mnt/keyusb/id-alchemist.pub >> /home/alchemist/.ssh/authorized_keys
     chmod 700 /home/alchemist/.ssh
     chmod 600 /home/alchemist/.ssh/authorized_keys
     chown -R alchemist:alchemist /home/alchemist/.ssh

Unmount and close USB:

    umount /mnt/keyusb
    cryptsetup luksClose keyusb

Enable SSH:

    systemctl enable --now ssh

---

## 6) Verify SSH access

From another system:

    ssh -i ~/.ssh/id_alchemist alchemist@<astute-ip>

---

## 7) Base packages

Enable the "contrib" component required for ZFS packages:

    sudo sed -i 's/main non-free-firmware/main contrib non-free-firmware/' /etc/apt/sources.list
    sudo apt update

Install the core packages needed for Astute’s configuration:

    sudo apt install zfs-dkms zfsutils-linux borgbackup nfs-kernel-server powertop git stow ethtool vim htop lm-sensors cpufrequtils

Install kernel headers and build ZFS for the running kernel:

    sudo apt install linux-headers-$(uname -r)
    sudo dkms autoinstall

Confirm ZFS tools are available:

    sudo modprobe zfs
    zfs version
    zpool version

## 8) Import existing ZFS pool

List available pools to confirm detection:

    sudo zpool import

If the expected pool appears (for example `ironwolf`), import it, overriding the
"last accessed by another system" warning:

    sudo zpool import -f -N ironwolf

Check pool status:

    sudo zpool status ironwolf

If the pool is encrypted, load the key and mount datasets:

    sudo zfs load-key -a
    sudo zfs mount -a

Confirm datasets and mountpoints:

    zfs list
    mount | grep /srv/nas || true

If the pool does not appear automatically, search specific devices:

    sudo zpool import -d /dev ironwolf
    sudo zpool import -d /dev/disk/by-id ironwolf

## 9) Swap and cache configuration

Verify swap is active:

    swapon --show

If /dev/sda1 appears as a 32 G partition with TYPE=partition, swap is configured automatically.

Confirm the ZFS cache device is active:

    sudo zpool status ironwolf

If needed, reattach manually:

    sudo zpool add ironwolf cache /dev/sda2

## 10) NAS setup (NFS exports)

Enable and start the NFS server:

    sudo systemctl enable --now nfs-server

Create the export directory if not already present:

    sudo mkdir -p /srv/nas
    sudo chown -R alchemist:alchemist /srv/nas

Add an export rule for the local network:

    echo "/srv/nas  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

Apply and verify exports:

    sudo exportfs -ra
    sudo exportfs -v

Check that the export is visible locally:

    sudo apt install nfs-common
    sudo showmount -e localhost

## 11) Borg server setup

Astute exposes /srv/backups over SSH for BorgBackup. This allows other hosts
(for example audacious) to push encrypted backups to Astute without giving them
shell access.

    sudo adduser --system \
        --home /srv/backups \
        --shell /bin/sh \
        --group borg

Prepare the SSH directory for the borg user:

    sudo mkdir -p /srv/backups/.ssh
    sudo chmod 700 /srv/backups/.ssh
    sudo chown borg:borg /srv/backups/.ssh

Copy the public key from the client host (for example
~/.ssh/audacious-backup.pub on audacious). Add it to authorized_keys with a
restricted command:

    sudo tee /srv/backups/.ssh/authorized_keys >/dev/null <<'EOF'
    command="borg serve --restrict-to-path /srv/backups",restrict ssh-ed25519 AAAA...REPLACE_WITH_PUBLIC_KEY... audacious-backup
    EOF

    sudo chown borg:borg /srv/backups/.ssh/authorized_keys
    sudo chmod 600 /srv/backups/.ssh/authorized_keys

Test the SSH restriction from the client:

    ssh -i ~/.ssh/audacious-backup borg@astute

Expected: connection is accepted, no interactive shell is provided.

Test repository access:

    borg list borg@astute:/srv/backups/audacious-borg

## 12) ZFS maintenance and disk health

Enable weekly scrubs on the NAS pool:

    sudo systemctl enable --now zfs-scrub-weekly@ironwolf.timer
    systemctl list-timers --all | grep zfs-scrub

Ensure ZED is running (ZFS event daemon):

    sudo systemctl start zfs-zed.service
    systemctl status zfs-zed.service

Trim is for SSD/NVMe only. Astute uses `fstrim.timer` for `/` and the SSD
mounts:

    systemctl status fstrim.timer

Install SMART tools and check disk health using stable by-id paths:

    sudo apt install smartmontools
    sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62ETJT
    sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62F68T
