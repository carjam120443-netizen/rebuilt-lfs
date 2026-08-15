#!/bin/bash
set -euo pipefail

# Automated Linux From Scratch build using the official ALFS/jhalfs project.
# jhalfs is checked out separately from its generated working directory.

WORK_DIR="${WORK_DIR:-$PWD/work/lfs}"
JHALFS_SRC="${JHALFS_SRC:-$PWD/work/jhalfs-source}"
BUILD_DIR="${BUILD_DIR:-$WORK_DIR/build}"
JHALFS_BUILD="${JHALFS_BUILD:-$BUILD_DIR/jhalfs}"
LFS_BOOK="${LFS_BOOK:-12.4}"
JOBS="${JOBS:-2}"
ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
LFS_USER="${LFS_USER:-lfs}"
LFS_GROUP="${LFS_GROUP:-lfs}"
LFS_HOME="${LFS_HOME:-/home/lfs}"

mkdir -p "$WORK_DIR" "$BUILD_DIR" "$JHALFS_BUILD" "$(dirname "$JHALFS_SRC")" "$WORK_DIR/source-archive"

if ! getent group "$LFS_GROUP" >/dev/null 2>&1; then
  sudo groupadd --system "$LFS_GROUP"
fi
if ! id -u "$LFS_USER" >/dev/null 2>&1; then
  sudo useradd --system --gid "$LFS_GROUP" --home-dir "$LFS_HOME" --create-home --shell /bin/bash "$LFS_USER"
else
  sudo usermod --home "$LFS_HOME" "$LFS_USER"
  sudo mkdir -p "$LFS_HOME"
fi
sudo mkdir -p "$LFS_HOME"
sudo chown "$LFS_USER:$LFS_GROUP" "$LFS_HOME"

if [ ! -d "$JHALFS_SRC/.git" ]; then
  git clone --depth=1 https://git.linuxfromscratch.org/jhalfs.git "$JHALFS_SRC"
fi

cd "$JHALFS_SRC"

# jhalfs uses Kconfig syntax for this file. String-valued settings must be
# quoted; otherwise Kconfig silently ignores them and falls back to defaults.
cat > configuration <<EOF
BOOK_LFS_SYSD=y
PROGNAME="lfs"
BRANCH_ID="${LFS_BOOK}"
INITSYS="systemd"
BUILDDIR="${BUILD_DIR}"
JHALFSDIR="${JHALFS_BUILD}"
SRC_ARCHIVE="${WORK_DIR}/source-archive"
GETPKG=y
RUNMAKE=y
PKGMNGT=n
N_PARALLEL=${JOBS}
OPTIMIZE=0
NO_PROGRESS_BAR=y
REBUILD_MAKEFILE=n
CLEAN=n
BLFS_TOOL=n
LUSER="${LFS_USER}"
LGROUP="${LFS_GROUP}"
LHOME="${LFS_HOME}"
EOF

# Make sure menuconfig never tries to open curses in GitHub Actions. The
# configuration is already complete, so load it through Kconfig's non-UI path
# and invoke jhalfs' build target directly.
export TERM=xterm
if grep -q '^menuconfig:' Makefile && grep -q '^all:' Makefile; then
  make -s olddefconfig
  make -s all
else
  make -s olddefconfig
  make -s
fi

if [ -d "$BUILD_DIR/lfs" ]; then
  rm -rf "$ROOT_DIR"
  mv "$BUILD_DIR/lfs" "$ROOT_DIR"
elif [ -d "$BUILD_DIR/rootfs" ]; then
  rm -rf "$ROOT_DIR"
  mv "$BUILD_DIR/rootfs" "$ROOT_DIR"
elif [ -d "$JHALFS_BUILD/lfs" ]; then
  rm -rf "$ROOT_DIR"
  mv "$JHALFS_BUILD/lfs" "$ROOT_DIR"
elif [ -d "$JHALFS_BUILD/rootfs" ]; then
  rm -rf "$ROOT_DIR"
  mv "$JHALFS_BUILD/rootfs" "$ROOT_DIR"
fi

[ -d "$ROOT_DIR" ] || {
  echo "jhalfs completed without producing the expected root filesystem at $ROOT_DIR" >&2
  echo "Inspect $BUILD_DIR and $JHALFS_BUILD for generated LFS build output." >&2
  exit 1
}

echo "Automated LFS build complete: $ROOT_DIR"
