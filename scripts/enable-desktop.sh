#!/bin/bash
set -euo pipefail

# Install the graphical session launcher and make it the default desktop entry.
ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"

install -Dm755 desktop/start-session.sh "$ROOT_DIR/usr/local/bin/rebuilt-desktop"
mkdir -p "$ROOT_DIR/etc/profile.d"
cat > "$ROOT_DIR/etc/profile.d/rebuilt-desktop.sh" <<'EOF'
# Rebuilt LFS graphical desktop launcher.
export REBUILT_LFS_DESKTOP=xfce
EOF

echo "Desktop integration staged."
