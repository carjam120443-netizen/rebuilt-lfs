#!/bin/bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
SUDO_VERSION="${SUDO_VERSION:-1.9.17p2}"
SRC_DIR="${SRC_DIR:-$PWD/work/sources}"
JOBS="${JOBS:-$(nproc)}"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
TARBALL="sudo-${SUDO_VERSION}.tar.gz"
URL="https://www.sudo.ws/dist/$TARBALL"

if [ ! -f "$TARBALL" ]; then
  wget -O "$TARBALL" "$URL"
fi
rm -rf "sudo-${SUDO_VERSION}"
tar -xf "$TARBALL"
cd "sudo-${SUDO_VERSION}"

./configure --prefix=/usr --sysconfdir=/etc --with-env-editor --with-logfac=auth
make -j"$JOBS"
make DESTDIR="$ROOT_DIR" install

mkdir -p "$ROOT_DIR/etc/sudoers.d"
cat > "$ROOT_DIR/etc/sudoers" <<'EOF'
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
root ALL=(ALL:ALL) ALL
%sudo ALL=(ALL:ALL) ALL
EOF
chmod 0440 "$ROOT_DIR/etc/sudoers"

# Create the administrative group if it is not already present.
if ! grep -q '^sudo:' "$ROOT_DIR/etc/group" 2>/dev/null; then
  echo 'sudo:x:27:' >> "$ROOT_DIR/etc/group"
fi

printf '%s\n' "sudo installed and configured in $ROOT_DIR"
