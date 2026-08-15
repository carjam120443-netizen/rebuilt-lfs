#!/bin/bash
set -euo pipefail

# Build and install Porg, the package installation tracker used by Rebuilt LFS.
# Porg records installed files so packages can be inspected or removed later.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
SRC_DIR="${SRC_DIR:-$PWD/work/sources}"
PORG_VERSION="${PORG_VERSION:-0.10}"
PORG_TARBALL="porg-${PORG_VERSION}.tar.gz"
PORG_URL="https://downloads.sourceforge.net/porg/${PORG_TARBALL}"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "$PORG_TARBALL" ]; then
    wget -O "$PORG_TARBALL" "$PORG_URL"
fi

rm -rf "porg-${PORG_VERSION}"
tar -xf "$PORG_TARBALL"
cd "porg-${PORG_VERSION}"

./configure --prefix=/usr --sysconfdir=/etc --disable-gcc-wrapper
make -j"${JOBS:-$(nproc)}"
make DESTDIR="$ROOT_DIR" install

# Provide a small Rebuilt LFS helper around Porg's package database.
mkdir -p "$ROOT_DIR/var/log/porg"
cat > "$ROOT_DIR/usr/local/bin/rebuilt-pkg" <<'EOF'
#!/bin/sh
set -eu
case "${1:-}" in
  list) exec porg -l "${2:-}" ;;
  info) exec porg -i "${2:?package name required}" ;;
  remove) exec porg -r "${2:?package name required}" ;;
  *)
    echo "Usage: rebuilt-pkg {list|info|remove} [package]" >&2
    exit 2
    ;;
esac
EOF
chmod 755 "$ROOT_DIR/usr/local/bin/rebuilt-pkg"
