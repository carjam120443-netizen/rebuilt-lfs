#!/bin/bash
set -euo pipefail

# Automated Linux From Scratch build using the official ALFS/jhalfs project.
# Keep the jhalfs checkout separate from its generated build directory.

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
fi
sudo mkdir -p "$LFS_HOME"
sudo chown "$LFS_USER:$LFS_GROUP" "$LFS_HOME"

if [ ! -d "$JHALFS_SRC/.git" ]; then
  git clone --depth=1 https://git.linuxfromscratch.org/jhalfs.git "$JHALFS_SRC"
fi

cd "$JHALFS_SRC"

# jhalfs' configuration file is Kconfig syntax. String values must be quoted.
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

# The checked-out jhalfs Makefile does not provide Linux-kernel-style
# olddefconfig. Generate/load the supplied configuration without curses.
# Kconfig's menuconfig target is intentionally never invoked in Actions.
export TERM=xterm
if [ -f Makefile ] && grep -q '^[[:space:]]*conf:' Makefile; then
  make -s conf
else
  if [ -x ./jhalfs ]; then
    ./jhalfs -h || true
  fi
  echo "Unsupported jhalfs checkout: no noninteractive configuration target was found." >&2
  echo "Available Make targets:" >&2
  make -qp 2>/dev/null | awk -F: '/^[A-Za-z0-9_.-]+:([^=]|$)/ {print $1}' | sort -u | head -80 >&2 || true
  exit 1
fi

# The generated build target is provided by jhalfs after configuration.
if make -qp 2>/dev/null | grep -q '^all:'; then
  make -s all
elif make -qp 2>/dev/null | grep -q '^build:'; then
  make -s build
else
  echo "jhalfs generated no supported noninteractive build target." >&2
  make -qp 2>/dev/null | awk -F: '/^[A-Za-z0-9_.-]+:([^=]|$)/ {print $1}' | sort -u | head -100 >&2 || true
  exit 1
fi

for candidate in "$BUILD_DIR/lfs" "$BUILD_DIR/rootfs" "$JHALFS_BUILD/lfs" "$JHALFS_BUILD/rootfs"; do
  if [ -d "$candidate" ]; then
    rm -rf "$ROOT_DIR"
    mv "$candidate" "$ROOT_DIR"
    break
  fi
done

[ -d "$ROOT_DIR" ] || {
  echo "jhalfs completed without producing the expected root filesystem at $ROOT_DIR" >&2
  echo "Inspect $BUILD_DIR and $JHALFS_BUILD for generated LFS build output." >&2
  exit 1
}

echo "Automated LFS build complete: $ROOT_DIR"
