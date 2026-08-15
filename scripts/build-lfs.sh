#!/bin/bash
set -euo pipefail

# Rebuilt LFS automated source/bootstrap stage.
# Uses the official LFS 12.4 package manifest as the authoritative source list.
# This stage downloads and verifies the official sources and prepares the build
# environment. Full LFS Chapter 5-10 commands are intentionally kept in the
# upstream book rather than guessed here; package commands change between
# releases and must match the selected LFS book exactly.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
SRC_DIR="${SRC_DIR:-$PWD/work/sources}"
LFS_VERSION="${LFS_VERSION:-12.4}"
LFS_MIRROR="https://www.linuxfromscratch.org/lfs/downloads/${LFS_VERSION}"

mkdir -p "$ROOT_DIR" "$SRC_DIR"

curl -fsSL "$LFS_MIRROR/wget-list" -o "$SRC_DIR/wget-list"
curl -fsSL "$LFS_MIRROR/md5sums" -o "$SRC_DIR/md5sums"

# Download with retries and resume support. LFS explicitly documents wget-list
# as the supported bulk-download mechanism.
wget --input-file="$SRC_DIR/wget-list" --continue --directory-prefix="$SRC_DIR" \
  --tries=5 --timeout=30

# Verify every official source that has an MD5 entry. Ignore comments/blank
# lines, and fail if any checksum does not match.
(
  cd "$SRC_DIR"
  md5sum -c md5sums --quiet
)

mkdir -p "$ROOT_DIR"/{dev,etc,home,proc,run,sys,tmp,var}
chmod 1777 "$ROOT_DIR/tmp"

echo "Official LFS ${LFS_VERSION} sources downloaded and verified."
echo "The next stage consumes the selected LFS book's exact build commands."
