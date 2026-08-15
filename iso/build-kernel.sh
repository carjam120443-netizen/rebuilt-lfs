#!/bin/bash
set -euo pipefail

# Build a Linux kernel and initramfs for the Rebuilt LFS ISO.
# The kernel configuration is intentionally VM-friendly for QEMU/VirtualBox.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
SRC_DIR="${SRC_DIR:-$PWD/work/sources}"
KERNEL_VERSION="${KERNEL_VERSION:-6.12.43}"
JOBS="${JOBS:-$(nproc)}"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

TARBALL="linux-${KERNEL_VERSION}.tar.xz"
URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${TARBALL}"

if [ ! -f "$TARBALL" ]; then
  wget -O "$TARBALL" "$URL"
fi

rm -rf "linux-${KERNEL_VERSION}"
tar -xf "$TARBALL"
cd "linux-${KERNEL_VERSION}"

# Start from the architecture's default config, then enable the essentials
# needed for initramfs, virtual disks, consoles, and networking.
make defconfig
scripts/config --enable BLK_DEV_INITRD
scripts/config --enable DEVTMPFS
scripts/config --enable DEVTMPFS_MOUNT
scripts/config --enable TMPFS
scripts/config --enable EXT4_FS
scripts/config --enable VIRTIO
scripts/config --enable VIRTIO_PCI
scripts/config --enable VIRTIO_BLK
scripts/config --enable VIRTIO_NET
scripts/config --enable SCSI_VIRTIO
make olddefconfig
make -j"$JOBS"

mkdir -p "$ROOT_DIR/boot"
cp arch/x86/boot/bzImage "$ROOT_DIR/boot/vmlinuz"

# Generate a minimal initramfs containing an init entry. The later userspace
# stage expands this into the complete init/network/desktop boot sequence.
TMP_INIT="$(mktemp -d)"
mkdir -p "$TMP_INIT"/{dev,proc,sys,newroot}
cat > "$TMP_INIT/init" <<'EOF'
#!/bin/sh
mount -t devtmpfs dev /dev
mount -t proc proc /proc
mount -t sysfs sys /sys

# Find the root filesystem supplied by the boot environment.
for root in /dev/vda /dev/sda /dev/vda1 /dev/sda1; do
    [ -b "$root" ] || continue
    mount "$root" /newroot 2>/dev/null && break
done

if mountpoint -q /newroot; then
    exec switch_root /newroot /sbin/init
fi

echo "Rebuilt LFS: unable to mount the root filesystem."
exec sh
EOF
chmod +x "$TMP_INIT/init"
(cd "$TMP_INIT" && find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9) > "$ROOT_DIR/boot/initramfs.img"
rm -rf "$TMP_INIT"

echo "Kernel and initramfs installed into $ROOT_DIR/boot"
