# VM Testing Environment Architecture

**Purpose:** Test installation documentation for Audacious and Astute

---

## Overview

Virtual machines for testing Project Shipshape installation procedures, with
faithful emulation of Wolfpack host disk layouts (Audacious/Astute).

---

## Hypervisor Selection

**Choice:** QEMU/KVM with libvirt

**Rationale:**

- Native to Debian, well-supported
- Excellent performance (KVM hardware virtualization)
- libvirt provides stable abstraction layer
- Compatible with future cloud/container workflows
- Industry standard for Linux virtualization

**Management Tools:**

- `virsh` (CLI, scriptable, minimal)
- `virt-manager` (GUI, optional, helpful for initial setup)
- `virt-install` (automated VM creation)

**Why NOT:**

- VirtualBox: Proprietary kernel modules, Oracle licensing concerns
- VMware: Proprietary, overkill for testing
- Docker/Podman: Not suitable for full OS testing with custom boot

---

## VM Inventory

### 1. test-audacious

**Purpose:** Test install-audacious.md installation procedures

**Specifications:**

- RAM: 4GB (ZFS needs memory)
- vCPUs: 2
- Architecture: x86_64 (matches Audacious)
- Firmware: UEFI (required for systemd-boot testing)

**Disk Layout:**

- vda: 30GB (simulate nvme0n1 - first mirror disk)
- vdb: 30GB (simulate nvme1n1 - second mirror disk)
- Total: 60GB provisioned (thin)

**Emulates:**

- ZFS RAID1 encrypted root
- Dual ESP with auto-sync
- Systemd-boot with UKI
- Sway desktop (optional - can test headless)

**Network:**

- Single virtio NIC
- Bridge to host network (can talk to test-astute)

---

### 2. test-astute

**Purpose:** Test install-astute.md installation procedures

**Specifications:**

- RAM: 2GB (lighter than Audacious)
- vCPUs: 2
- Architecture: x86_64
- Firmware: UEFI (consistency, though not strictly required)

**Disk Layout:**

- vda: 20GB (simulate nvme - ext4 root)
- vdb: 20GB (simulate sdb - IronWolf mirror disk 1)
- vdc: 20GB (simulate sdc - IronWolf mirror disk 2)
- Total: 60GB provisioned (thin)

**Emulates:**

- ext4 root on NVMe
- ZFS mirror data pool (ironwolf)
- GRUB bootloader
- SSH-only access (no GUI)

**Network:**

- Single virtio NIC
- Bridge to host network (NFS exports to test-audacious)

---

## Storage Strategy

**Format:** qcow2 (QEMU Copy-On-Write v2)

**Rationale:**

- Thin provisioning (60GB allocated = ~2GB actual until used)
- Snapshots for testing (rollback failed installs)
- Compression support
- Portable between hosts

**Location:** `/var/lib/libvirt/images/` (standard libvirt location)

**Naming Convention:**

```text
test-audacious-vda.qcow2
test-audacious-vdb.qcow2
test-astute-vda.qcow2
test-astute-vdb.qcow2
test-astute-vdc.qcow2
```

**Alternative:** Raw images for performance

- Only if qcow2 proves slow for ZFS operations
- Sacrifice thin provisioning for performance
- Not recommended initially

---

## Network Architecture

**Choice:** Bridge mode with shared bridge

**Configuration:**

```text
Host (audacious)
  ├─ br0 (192.168.1.147)
  │   ├─ enp7s0 (physical)
  │   ├─ vnet0 → test-audacious
  │   └─ vnet1 → test-astute
  └─ Router (192.168.1.254)
```

**IP Allocation:**

- test-audacious: DHCP or static 192.168.1.200
- test-astute: DHCP or static 192.168.1.201

**Benefits:**

- VMs visible on LAN (can test NAS from test-audacious)
- SSH from host to VMs
- VMs can access internet directly
- Mirrors real network topology

**Alternative:** NAT mode

- Use if bridge interferes with host networking
- VMs get 192.168.122.x addresses
- Port forwarding for SSH access

---

## Resource Allocation

**Host Resources (Audacious):**

- CPU: Intel i5-13600KF (20 threads total)
- RAM: 32GB total
- Available for VMs: ~8-12GB RAM, 4-8 vCPUs

**Concurrent VM Limits:**

- Comfortable: 2 VMs running simultaneously
- Testing mode: 1 VM at a time (full resources)

**Allocation:**

```text
test-audacious: 4GB RAM, 2 vCPUs
test-astute: 2GB RAM, 2 vCPUs
---
Total: 6GB RAM, 4 vCPUs
```

---

## Installation Media

**Storage Location:** `/var/lib/libvirt/boot/`

**ISO to Download:**

- Debian 13 (Trixie) netinst: ~400MB
- Source:
  <https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/>

**Download:**

```bash
sudo mkdir -p /var/lib/libvirt/boot
cd /var/lib/libvirt/boot
sudo wget [Debian ISO URL]
```

---

## VM Creation Workflow

### Phase 1: Host Preparation

1. Install virtualization packages
2. Enable libvirtd service
3. Add user to libvirt group
4. Set up bridge networking (if not NAT)

### Phase 2: Create VMs

1. Create disk images (qcow2)
2. Define VM with virt-install
3. Attach disks, network, ISO
4. Set UEFI firmware

### Phase 3: Test Installation

1. Boot from ISO
2. Follow INSTALL.*.md documentation
3. Document deviations/issues
4. Snapshot after successful install
5. Test recovery procedures

### Phase 4: Iterate

1. Destroy VM
2. Restore from snapshot or recreate
3. Test again with fixes
4. Update documentation

---

## Snapshot Strategy

**Purpose:** Quick rollback during testing

**Snapshots to Create:**

1. `fresh` - After VM creation, before first boot
2. `post-install` - After successful base install
3. `post-dotfiles` - After dotfiles deployment
4. `working` - Rolling snapshot before risky changes

**Commands:**

```bash
virsh snapshot-create-as test-audacious fresh "Fresh VM before install"
virsh snapshot-revert test-audacious fresh
virsh snapshot-list test-audacious
```

**Storage Impact:**

- qcow2 snapshots are incremental
- ~500MB-2GB per snapshot depending on changes
- Clean up old snapshots periodically

---

## Serial Console Access

**Configuration:** Add serial console to VMs

**Rationale:**

- Headless access without VNC
- Capture boot logs
- Debug boot failures
- More authentic server experience

**Access:**

```bash
virsh console test-astute
```

**Exit:** Ctrl+] or Ctrl+5 depending on terminal

---

## Testing Workflow

### Test Scenario 1: Fresh Audacious Install

1. Boot test-audacious from Debian ISO
2. Follow install-audacious.md step-by-step
3. Note any deviations or unclear instructions
4. Test ZFS mirror creation, encryption, dual ESP
5. Verify systemd-boot UKI boots correctly
6. Deploy dotfiles from git
7. Test recovery procedures in recovery-audacious.md
8. Document time taken (~2-3 hours expected)

### Test Scenario 2: Fresh Astute Install

1. Boot test-astute from Debian ISO
2. Follow install-astute.md step-by-step
3. Test ZFS data pool creation
4. Configure NFS exports
5. Test NFS mount from test-audacious
6. Deploy dotfiles
7. Test recovery procedures in recovery-astute.md
8. Document time taken (~1-2 hours expected)

### Test Scenario 3: Drive Replacement

1. Simulate drive failure (detach vdb from test-audacious)
2. Follow recovery-audacious.md §9.2.2 (drive replacement)
3. Verify resilver completes successfully
4. Test all systems operational after replacement

### Test Scenario 4: Documentation Gaps

1. Maintain notes during each test
2. Identify missing steps, unclear instructions
3. Update documentation immediately
4. Re-test updated sections

---

## Performance Considerations

**Expected Performance:**

- Disk I/O: 60-80% of bare metal (virtio)
- CPU: 90-95% of bare metal (KVM)
- Network: 90-95% of bare metal (virtio-net)
- RAM: No overhead (direct allocation)

**Optimizations:**

- Use virtio drivers (default in modern libvirt)
- Enable KVM hardware acceleration (default if available)
- Use host CPU passthrough for maximum performance
- Consider hugepages for ZFS if needed (unlikely)

**Bottlenecks:**

- ZFS operations may be slower (fewer disks, no cache)
- Network throughput limited by bridge capacity

---

## Security Considerations

**Isolation:**

- VMs isolated from each other by default
- Bridge mode allows inter-VM communication (by design)
- Host firewall rules apply to VM traffic

**Access Control:**

- libvirt group membership required for VM management
- VMs should have different SSH keys than host
- Test VMs should NOT have access to production secrets

**Secrets in VMs:**

- Use dummy SSH keys (not production keys)
- Use test passphrases (not real passphrases)
- Document that VMs are for TESTING ONLY

---

## Maintenance

**Disk Space Monitoring:**

```bash
sudo du -sh /var/lib/libvirt/images/*
sudo df -h /var/lib/libvirt
```

**Cleanup Old VMs:**

```bash
virsh destroy test-old
virsh undefine test-old --remove-all-storage
```

**Trim qcow2 Images:**

```bash
sudo virt-sparsify --in-place test-audacious-vda.qcow2
```

---

## Documentation Testing Checklist

**Before Each Test:**

- [ ] Read entire install guide start to finish
- [ ] Note any questions or unclear sections
- [ ] Prepare fresh VM or snapshot revert
- [ ] Time the installation process

**During Installation:**

- [ ] Follow documentation exactly as written
- [ ] Note any commands that fail or behave unexpectedly
- [ ] Screenshot or copy error messages
- [ ] Document workarounds if needed

**After Installation:**

- [ ] Verify all expected services running
- [ ] Test key functionality (ZFS, boot, networking)
- [ ] Update documentation with findings
- [ ] Create "working" snapshot for future reference

---

## Implementation Steps

**Setup tasks:**

1. Install libvirt/QEMU packages on Audacious
2. Set up bridge networking (or NAT if preferred)
3. Create disk images for test-audacious and test-astute
4. Define VMs with virt-install commands
5. Download Debian Trixie ISO
6. Walk through first test installation
7. Document any issues found during testing
8. Set up snapshots for quick rollback

**Decisions required:**

- Network mode (bridge vs NAT)
- Resource allocation confirmation
- Testing priorities and schedule

---

## Appendix A: Quick Reference Commands

**VM Management:**

```bash
virsh list --all                    # List all VMs
virsh start test-audacious          # Start VM
virsh shutdown test-audacious       # Graceful shutdown
virsh destroy test-audacious        # Force stop
virsh console test-audacious        # Serial console
virsh undefine test-audacious       # Delete VM definition
```

**Disk Management:**

```bash
qemu-img create -f qcow2 disk.qcow2 30G    # Create disk
qemu-img info disk.qcow2                    # Show disk info
qemu-img resize disk.qcow2 +10G             # Resize disk
```

**Network:**

```bash
virsh net-list --all                # List networks
virsh net-start default             # Start default NAT network
ip link show br0                    # Check bridge status
```

**Snapshots:**

```bash
virsh snapshot-create-as VM name "description"
virsh snapshot-list VM
virsh snapshot-revert VM name
virsh snapshot-delete VM name
```

---

## Appendix B: Troubleshooting

### Issue: KVM not available

```bash
# Check virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Check KVM modules loaded
lsmod | grep kvm
```

### Issue: Permission denied

```bash
# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Logout/login to apply
```

### Issue: Bridge networking doesn't work

```bash
# Check bridge exists
ip link show br0

# Check firewall isn't blocking
sudo iptables -L -n -v
```

### Issue: VM won't start

```bash
# Check detailed error
virsh start test-audacious --console

# Check libvirt logs
sudo journalctl -u libvirtd -n 50
```

---
