#!/bin/bash
set -euo pipefail

# Build the graphical stack for Rebuilt LFS.
# Xorg is used as the initial display server and XFCE as the desktop.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
SRC_DIR="${SRC_DIR:-$PWD/work/sources}"
JOBS="${JOBS:-$(nproc)}"

mkdir -p "$SRC_DIR"

# Package names are kept in one place so the LFS build can be expanded as
# dependencies are completed. The actual LFS package build functions are
# supplied by the package framework in the next stage.
cat > "$ROOT_DIR/etc/rebuilt-lfs-desktop" <<'EOF'
DISPLAY_SERVER=xorg
DESKTOP=xfce
SESSION_COMMAND=/usr/local/bin/rebuilt-desktop
TERMINAL=xfce4-terminal
EOF

# Desktop directories and menu locations.
mkdir -p "$ROOT_DIR"/usr/share/{applications,xsessions,backgrounds}
mkdir -p "$ROOT_DIR"/etc/xdg/xfce4

cat > "$ROOT_DIR/usr/share/xsessions/rebuilt-xfce.desktop" <<'EOF'
[Desktop Entry]
Name=Rebuilt LFS XFCE
Comment=Rebuilt LFS graphical desktop
Exec=/usr/local/bin/rebuilt-desktop
TryExec=/usr/local/bin/rebuilt-desktop
Type=Application
DesktopNames=XFCE
EOF

cat > "$ROOT_DIR/etc/xdg/xfce4/rebuilt-desktop.conf" <<'EOF'
# Rebuilt LFS XFCE defaults
# NetworkManager provides the graphical network connection UI.
EOF

printf '%s\n' "XFCE/Xorg desktop configuration staged in $ROOT_DIR"
printf '%s\n' "The package framework must build Xorg and XFCE dependencies before this session can boot."
