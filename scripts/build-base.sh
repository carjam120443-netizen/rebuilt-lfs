#!/bin/bash
set -euo pipefail

# Rebuilt LFS bootstrap placeholder.
# This stage prepares a build workspace for the Linux From Scratch toolchain.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
mkdir -p "$ROOT_DIR"/{bin,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}
mkdir -p "$ROOT_DIR"/usr/{bin,lib,sbin,share}
chmod 1777 "$ROOT_DIR/tmp"

echo "Rebuilt LFS base workspace prepared at: $ROOT_DIR"
echo "Next stage: build the LFS toolchain and install the base system."
