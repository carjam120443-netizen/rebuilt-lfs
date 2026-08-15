#!/bin/bash
set -euo pipefail

# Build a bootable BIOS/UEFI ISO from the completed Rebuilt LFS rootfs.
# The rootfs is expected at work/rootfs unless ROOT_DIR is overridden.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
ISO_DIR="${ISO_DIR:-$PWD/work/iso}"
OUT_DIR="${OUT_DIR:-$PWD/dist}"
ISO_NAME="${ISO_NAME:-rebuilt-lfs-0.1-dev-x86_64.iso}"

command -v xorriso >/dev/null || { echo "xorriso is required" >&2; exit 1; }
command -v grub-mkrescue >/dev/null || { echo "grub-mkrescue is required" >&2; exit 1; }

[ -d "$ROOT_DIR" ] || { echo "Rootfs not found: $ROOT_DIR" >&2; exit 1; }

rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/boot/grub" "$OUT_DIR"

# Copy the finished userspace into the ISO filesystem.
cp -a "$ROOT_DIR"/. "$ISO_DIR/"

# GRUB gives us a straightforward BIOS + UEFI boot path for QEMU and
# VirtualBox while we develop the kernel/initramfs integration.
cat > "$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set timeout=3
set default=0

menuentry "Rebuilt LFS Desktop" {
    linux /boot/vmlinuz root=/dev/ram0 rw quiet
    initrd /boot/initramfs.img
}
EOF

# A real kernel/initramfs must be supplied by the kernel stage before this
# command can produce a bootable operating-system image.
if [ ! -f "$ISO_DIR/boot/vmlinuz" ] || [ ! -f "$ISO_DIR/boot/initramfs.img" ]; then
    echo "Kernel/initramfs missing. Run the kernel stage first." >&2
    exit 1
fi

grub-mkrescue -o "$OUT_DIR/$ISO_NAME" "$ISO_DIR"
echo "ISO created: $OUT_DIR/$ISO_NAME"
