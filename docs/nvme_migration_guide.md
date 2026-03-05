# NVMe Disk Migration Guide — dell32

## System Info

| | Old Drive (sda) | New Drive (sdb via USB) |
|---|---|---|
| **Size** | 250G | 232.9G |
| **Used** | 152G | — |
| **Boot** | sda1 · `5966-400D` | sdb1 · `F418-5D97` |
| **Root** | sda2 · `cbd3654c-de9f-46eb-820f-5180ae5d96be` | sdb2 · `b9d04da3-cb9d-4fdb-b869-0ca02e0d76d4` |
| **fstab** | by-uuid, `x-initrd.mount` | new UUIDs |
| **Root type** | tmpfs overlay on ext4 | same |

---

## Phase 1: Prepare New Drive (from running system)

### 1.1 Clean sdb

```bash
# Check if anything is mounted on sdb
mount | grep sdb

# Unmount if needed
sudo umount /dev/sdb1 2>/dev/null
sudo umount /dev/sdb2 2>/dev/null

# Wipe partition table
sudo wipefs -a /dev/sdb
```

### 1.2 Partition sdb

```bash
sudo fdisk /dev/sdb
```

Inside fdisk:
```
g        ← new GPT table
n        ← new partition 1
1        ← partition number
[Enter]  ← default first sector
+512M    ← EFI partition size
t        ← change type
1        ← EFI System
n        ← new partition 2
2        ← partition number
[Enter]  ← default first sector
[Enter]  ← use all remaining space
w        ← write and exit
```

### 1.3 Format

```bash
sudo mkfs.fat -F 32 /dev/sdb1
sudo mkfs.ext4 /dev/sdb2
```

### 1.4 Record new UUIDs

```bash
sudo blkid /dev/sdb1 /dev/sdb2
```

> **Write these down!** You'll need them later.

---

## Phase 2: Prepare NixOS USB

> [!IMPORTANT]
> You need a NixOS live USB to boot from. If you don't have one:

```bash
# Download NixOS minimal ISO (or graphical if preferred)
# From: https://nixos.org/download/#nixos-iso
# Write to USB:
# sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress
```

Make sure the USB boots in **UEFI mode**.

---

## Phase 3: Boot from USB & Clone

### 3.1 Boot from NixOS USB

Shutdown, plug in USB, boot from USB in UEFI mode. Leave both NVMe drives connected (old in M.2 slot, new in USB adapter).

### 3.2 Identify drives

```bash
lsblk -f
sudo blkid
```

> [!WARNING]
> Device names may differ from when running your OS.
> Identify old vs new drive by **UUID** or **size** (old=250G, new=232.9G).
> Below, `OLD_ROOT` and `NEW_ROOT` are placeholders — substitute the actual device paths.

### 3.3 Mount both drives

```bash
# Mount OLD drive (read-only for safety)
sudo mkdir -p /mnt/old
sudo mount -o ro OLD_ROOT_PARTITION /mnt/old
sudo mount -o ro OLD_BOOT_PARTITION /mnt/old/boot

# Mount NEW drive
sudo mkdir -p /mnt/new
sudo mount NEW_ROOT_PARTITION /mnt/new
sudo mkdir -p /mnt/new/boot
sudo mount NEW_BOOT_PARTITION /mnt/new/boot
```

### 3.4 rsync everything

```bash
# Clone root filesystem
sudo rsync -aAXHv --info=progress2 /mnt/old/ /mnt/new/

# Verify
echo "Old:" && sudo du -sh /mnt/old/
echo "New:" && sudo du -sh /mnt/new/
```

> This copies everything: `/nix/store`, `/home`, `/var`, `/root`, `/etc`, boot files — all in one shot.

---

## Phase 4: Update Configuration for New Drive

### 4.1 Get new UUIDs

```bash
sudo blkid NEW_ROOT_PARTITION
sudo blkid NEW_BOOT_PARTITION
```

### 4.2 Update hardware-configuration.nix on the new drive

```bash
sudo nano /mnt/new/home/ubuntu/Nixos-Setup/hardware-configuration.nix
```

Replace the old UUIDs with new ones:

```diff
  fileSystems."/" =
-    { device = "/dev/disk/by-uuid/cbd3654c-de9f-46eb-820f-5180ae5d96be";
+    { device = "/dev/disk/by-uuid/b9d04da3-cb9d-4fdb-b869-0ca02e0d76d4";
      fsType = "ext4";
    };

  fileSystems."/boot" =
-    { device = "/dev/disk/by-uuid/5966-400D";
+    { device = "/dev/disk/by-uuid/F418-5D97";
      fsType = "vfat";
```

### 4.3 Rebuild NixOS targeting new drive

```bash
# Bind-mount system dirs for chroot
sudo mount --bind /dev /mnt/new/dev
sudo mount --bind /proc /mnt/new/proc
sudo mount --bind /sys /mnt/new/sys
sudo mount -t efivarfs efivarfs /mnt/new/sys/firmware/efi/efivars 2>/dev/null

# Enter chroot
sudo chroot /mnt/new /bin/sh -c "
  source /etc/profile
  cd /home/ubuntu/Nixos-Setup
  nixos-rebuild boot --install-bootloader --flake .#dell32
"
```

> [!NOTE]
> `nixos-rebuild boot` builds the new config and installs the bootloader but does NOT switch (safe).
> If `nixos-rebuild` isn't found in chroot, try `nixos-enter --root /mnt/new` instead of manual chroot.

### 4.4 Unmount everything

```bash
sudo umount /mnt/new/sys/firmware/efi/efivars 2>/dev/null
sudo umount /mnt/new/dev /mnt/new/proc /mnt/new/sys
sudo umount /mnt/new/boot
sudo umount /mnt/new
sudo umount /mnt/old/boot
sudo umount /mnt/old
```

---

## Phase 5: Swap & Boot

1. **Shutdown** the laptop
2. **Remove** old NVMe from M.2 slot
3. **Install** new NVMe (from USB adapter) into M.2 slot
4. **Boot** — should come up with your exact system

### If boot fails

Old drive is 100% untouched. Just put it back and you're exactly where you started. Then we debug what went wrong.

---

## Rollback Safety

- Old drive: **never modified** (mounted read-only during rsync)
- New drive: **independently bootable** (own UUIDs, own bootloader)
- At any point: swap old drive back in = instant recovery
