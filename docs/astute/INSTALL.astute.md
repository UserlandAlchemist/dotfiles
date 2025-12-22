# Debian 13 (Trixie) on ZFS - Installation Guide

**Target system:** Astute (headless NAS)
**Configuration:** ext4 root on NVMe, ZFS mirror at /srv/nas, SATA SSD for swap/cache/log, SSH-only access

---

## System layout

- **Hostname:** astute
- **User:** alchemist
- **System disk:** /dev/nvme0n1 (ext4 root, EFI)
- **SATA SSD:** /dev/sda (swap + ZFS cache/log)
- **Data disks:** /dev/sdb and /dev/sdc (IronWolf mirror)
- **Access:** SSH, Wake-on-LAN, suspend/resume

---

## §1 Boot the installer

Prepare a minimal headless install for a NAS role.

Steps:
1. Boot the Debian 13.1 (Trixie) netinst USB stick.
2. Choose "Install" (standard mode).
3. Configure locale, keyboard, and network.
4. Choose "Manual" partitioning.

Expected result: Installer is ready for manual disk layout.

---

## §2 Partition disks

Keep the system drive unencrypted for unattended boots and reserve the IronWolf disks for ZFS.

Steps:
1. On /dev/nvme0n1 (system):
   - 512 MB EFI System Partition, FAT32, mountpoint /boot/efi
   - Remaining space, ext4, mountpoint /
2. On /dev/sda (SATA SSD):
   - 32 GB swap (or to preference)
   - Remaining space unformatted (ZFS cache/log)
3. On /dev/sdb and /dev/sdc (IronWolf HDDs):
   - Leave unused during install (no partitions, no filesystems)
4. Finish partitioning and install GRUB to /dev/nvme0n1.

Expected result: Debian installs to NVMe, IronWolf disks remain untouched.

---

## §3 Software selection

Keep the base system minimal and headless.

Steps:
1. At "Software selection":
   - Select: standard system utilities
   - Select: SSH server
   - Do NOT select a desktop environment
2. Continue installation and reboot.

Expected result: Debian 13.1 boots to a console with SSH available.

---

## §4 First boot bootstrap

Install sudo and ensure the admin user can perform privileged tasks.

Steps:
1. Log in locally and become root:

```sh
su -
```

2. Install base packages:

```sh
apt update
apt install -y sudo cryptsetup
```

3. Add the admin user to the sudo group:

```sh
usermod -aG sudo alchemist
```

Expected result: `alchemist` can use sudo.

---

## §5 SSH key setup

Set up key-based admin access (optionally from an encrypted USB).

Steps:
1. Unlock the encrypted USB if used for SSH keys:

```sh
lsblk
cryptsetup luksOpen /dev/sdX1 keyusb
mkdir -p /mnt/keyusb
mount /dev/mapper/keyusb /mnt/keyusb
```

2. Install the admin key:

```sh
mkdir -p /home/alchemist/.ssh
cat /mnt/keyusb/id-alchemist.pub >> /home/alchemist/.ssh/authorized_keys
chmod 700 /home/alchemist/.ssh
chmod 600 /home/alchemist/.ssh/authorized_keys
chown -R alchemist:alchemist /home/alchemist/.ssh
```

3. Unmount and close the USB:

```sh
umount /mnt/keyusb
cryptsetup luksClose keyusb
```

4. Enable SSH:

```sh
systemctl enable --now ssh
```

Expected result: SSH accepts the admin key.

---

## §6 Verify SSH access

Confirm remote access before proceeding.

Steps:
1. From another system:

```sh
ssh -i ~/.ssh/id_alchemist alchemist@<astute-ip>
```

Expected result: SSH login succeeds without password prompts.

---

## §7 Base packages

Install ZFS, NAS, and monitoring dependencies.

Steps:
1. Enable the contrib component required for ZFS:

```sh
sudo sed -i 's/main non-free-firmware/main contrib non-free-firmware/' /etc/apt/sources.list
sudo apt update
```

2. Install core packages:

```sh
sudo apt install zfs-dkms zfsutils-linux borgbackup nfs-kernel-server \
  powertop git stow ethtool vim htop lm-sensors cpufrequtils
```

3. Install kernel headers and build ZFS for the running kernel:

```sh
sudo apt install linux-headers-$(uname -r)
sudo dkms autoinstall
```

4. Confirm ZFS tools are available:

```sh
sudo modprobe zfs
zfs version
zpool version
```

Expected result: `zfs` and `zpool` commands report versions.

---

## §8 Import existing ZFS pool

Import the IronWolf mirror and mount datasets at /srv/nas.

Steps:
1. List available pools:

```sh
sudo zpool import
```

2. If the expected pool appears (for example `ironwolf`), import it and override the last-host warning:

```sh
sudo zpool import -f -N ironwolf
```

3. Check pool status:

```sh
sudo zpool status ironwolf
```

4. If the pool is encrypted, load keys and mount datasets:

```sh
sudo zfs load-key -a
sudo zfs mount -a
```

5. Confirm datasets and mountpoints:

```sh
zfs list
mount | grep /srv/nas || true
```

6. If the pool does not appear, scan specific devices:

```sh
sudo zpool import -d /dev ironwolf
sudo zpool import -d /dev/disk/by-id ironwolf
```

Expected result: `ironwolf` is online and datasets mount at /srv/nas.

---

## §9 Swap and cache configuration

Verify swap on the SATA SSD and confirm the ZFS cache device is active.

Steps:
1. Verify swap is active:

```sh
swapon --show
```

2. Confirm the ZFS cache device is active:

```sh
sudo zpool status ironwolf
```

3. If needed, reattach the cache device:

```sh
sudo zpool add ironwolf cache /dev/sda2
```

Expected result: Swap shows /dev/sda1 and the pool lists the cache device.

---

## §10 NAS setup (NFS exports)

Expose /srv/nas to the LAN via NFS.

Steps:
1. Enable and start the NFS server:

```sh
sudo systemctl enable --now nfs-server
```

2. Create the export directory and set ownership:

```sh
sudo mkdir -p /srv/nas
sudo chown -R alchemist:alchemist /srv/nas
```

3. Add the export rule for the local network:

```sh
echo "/srv/nas  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
```

4. Apply and verify exports:

```sh
sudo exportfs -ra
sudo exportfs -v
```

5. Check that the export is visible locally:

```sh
sudo apt install nfs-common
sudo showmount -e localhost
```

Expected result: /srv/nas is exported to 192.168.1.0/24.

---

## §11 Borg server setup

Expose /srv/backups over SSH for Borg clients with restricted access.

Steps:
1. Create the borg system user:

```sh
sudo adduser --system \
  --home /srv/backups \
  --shell /bin/sh \
  --group borg
```

2. Prepare the SSH directory:

```sh
sudo mkdir -p /srv/backups/.ssh
sudo chmod 700 /srv/backups/.ssh
sudo chown borg:borg /srv/backups/.ssh
```

3. Add the client public key with a restricted command:

```sh
sudo tee /srv/backups/.ssh/authorized_keys >/dev/null <<'EOF'
command="borg serve --restrict-to-path /srv/backups",restrict ssh-ed25519 AAAA...REPLACE_WITH_PUBLIC_KEY... audacious-backup
EOF
```

```sh
sudo chown borg:borg /srv/backups/.ssh/authorized_keys
sudo chmod 600 /srv/backups/.ssh/authorized_keys
```

4. Test the restriction from the client:

```sh
ssh -i ~/.ssh/audacious-backup borg@astute
```

5. Test repository access:

```sh
borg list borg@astute:/srv/backups/audacious-borg
```

Expected result: SSH accepts the key without a shell, and Borg can list repos.

---

## §12 ZFS maintenance and disk health

Enable scrubs, ZED events, and monitor drive health.

Steps:
1. Enable weekly scrubs on the NAS pool:

```sh
sudo systemctl enable --now zfs-scrub-weekly@ironwolf.timer
systemctl list-timers --all | grep zfs-scrub
```

2. Ensure ZED is running:

```sh
sudo systemctl start zfs-zed.service
systemctl status zfs-zed.service
```

3. Confirm SSD/NVMe trim timers:

```sh
systemctl status fstrim.timer
```

4. Install SMART tools and check disk health using stable by-id paths:

```sh
sudo apt install smartmontools
sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62ETJT
sudo smartctl -a /dev/disk/by-id/ata-ST4000VN006-3CW104_ZW62F68T
```

Expected result: Scrub timers are active, ZED reports healthy, SMART outputs are clean.
