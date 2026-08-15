#!/bin/bash
set -euo pipefail

# Automated Linux From Scratch build using the official ALFS/jhalfs project.
# jhalfs extracts the exact commands from the selected LFS book instead of
# maintaining a hand-written, version-fragile list of package commands here.

BUILD_DIR="${BUILD_DIR:-$PWD/work/lfs-build}"
JHALFS_DIR="$BUILD_DIR/jhalfs"
LFS_BOOK="${LFS_BOOK:-12.4}"
JOBS="${JOBS:-2}"

mkdir -p "$BUILD_DIR"

if [ ! -d "$JHALFS_DIR/.git" ]; then
  git clone --depth=1 https://git.linuxfromscratch.org/jhalfs.git "$JHALFS_DIR"
fi

cd "$JHALFS_DIR"

# The jhalfs menu is normally interactive. This configuration file selects
# the stable LFS systemd book, downloads sources, enables package management,
# and asks jhalfs to execute the generated Makefile.
cat > configuration <<EOF
BOOK_LFS_SYSD=y
PROGNAME=lfs
BRANCH_ID=${LFS_BOOK}
INITSYS=systemd
BUILDDIR=$BUILD_DIR
JHALFSDIR=$JHALFS_DIR
SRC_ARCHIVE=$BUILD_DIR/source-archive
GETPKG=y
RUNMAKE=y
RUN_ME="./jhalfs run"
PKGMNGT=y
N_PARALLEL=$JOBS
OPTIMIZE=0
NO_PROGRESS_BAR=y
REBUILD_MAKEFILE=n
CLEAN=n
BLFS_TOOL=n
EOF

mkdir -p "$BUILD_DIR/source-archive"

# jhalfs asks for a final confirmation when invoked directly. Feed the
# confirmation non-interactively so GitHub Actions can run unattended.
printf 'yes\n' | ./jhalfs run

# Locate the generated LFS root. jhalfs normally places it under BUILDDIR;
# expose it at the stable path consumed by the Rebuilt LFS ISO stages.
if [ -d "$BUILD_DIR/lfs" ]; then
  rm -rf "$PWD/../rootfs"
  mv "$BUILD_DIR/lfs" "$PWD/../rootfs"
fi

ROOT_DIR="${ROOT_DIR:-$PWD/../rootfs}"
[ -d "$ROOT_DIR" ] || {
  echo "jhalfs completed without producing the expected root filesystem" >&2
  exit 1
}

echo "Automated LFS build complete: $ROOT_DIR"
