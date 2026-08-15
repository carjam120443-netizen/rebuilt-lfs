#!/bin/bash
set -euo pipefail

# Automated Linux From Scratch build using the official ALFS/jhalfs project.
# Keep the jhalfs source checkout separate from its generated build directory;
# jhalfs rejects configurations where these two paths are identical or nested.

WORK_DIR="${WORK_DIR:-$PWD/work/lfs}"
JHALFS_SRC="${JHALFS_SRC:-$WORK_DIR/jhalfs-src}"
BUILD_DIR="${BUILD_DIR:-$WORK_DIR/jhalfs-build}"
LFS_BOOK="${LFS_BOOK:-12.4}"
JOBS="${JOBS:-2}"
ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"

mkdir -p "$WORK_DIR" "$BUILD_DIR"

if [ ! -d "$JHALFS_SRC/.git" ]; then
  git clone --depth=1 https://git.linuxfromscratch.org/jhalfs.git "$JHALFS_SRC"
fi

cd "$JHALFS_SRC"

rm -f configuration
cat > configuration <<EOF
BOOK_LFS_SYSD=y
PROGNAME=lfs
BRANCH_ID=${LFS_BOOK}
INITSYS=systemd
BUILDDIR=$BUILD_DIR
JHALFSDIR=$JHALFS_SRC
SRC_ARCHIVE=$WORK_DIR/source-archive
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

mkdir -p "$WORK_DIR/source-archive"

# jhalfs asks for confirmation when invoked directly. Feed it non-interactively
# for GitHub Actions.
printf 'yes\n' | ./jhalfs run

# jhalfs may place the completed target system at BUILDDIR/lfs. Expose that
# system at the stable path used by the remaining Rebuilt LFS stages.
if [ -d "$BUILD_DIR/lfs" ]; then
  rm -rf "$ROOT_DIR"
  mv "$BUILD_DIR/lfs" "$ROOT_DIR"
elif [ -d "$BUILD_DIR/rootfs" ]; then
  rm -rf "$ROOT_DIR"
  mv "$BUILD_DIR/rootfs" "$ROOT_DIR"
fi

[ -d "$ROOT_DIR" ] || {
  echo "jhalfs completed without producing the expected root filesystem at $ROOT_DIR" >&2
  echo "Inspect $BUILD_DIR for the generated LFS build output." >&2
  exit 1
}

echo "Automated LFS build complete: $ROOT_DIR"
