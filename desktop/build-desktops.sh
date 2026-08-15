#!/bin/bash
set -euo pipefail

# Desktop integration for Rebuilt LFS.
# XFCE is the primary desktop. LXQt is also staged as a lightweight fallback.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
mkdir -p "$ROOT_DIR/usr/share/xsessions" "$ROOT_DIR/usr/local/bin"

cat > "$ROOT_DIR/usr/local/bin/rebuilt-startxfce" <<'EOF'
#!/bin/sh
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
exec startxfce4
EOF
chmod 755 "$ROOT_DIR/usr/local/bin/rebuilt-startxfce"

cat > "$ROOT_DIR/usr/local/bin/rebuilt-startlxqt" <<'EOF'
#!/bin/sh
export XDG_CURRENT_DESKTOP=LXQt
export XDG_SESSION_DESKTOP=lxqt
exec startlxqt
EOF
chmod 755 "$ROOT_DIR/usr/local/bin/rebuilt-startlxqt"

cat > "$ROOT_DIR/usr/share/xsessions/rebuilt-xfce.desktop" <<'EOF'
[Desktop Entry]
Name=Rebuilt LFS XFCE
Comment=XFCE desktop for Rebuilt LFS
Exec=/usr/local/bin/rebuilt-startxfce
TryExec=/usr/local/bin/rebuilt-startxfce
Type=Application
DesktopNames=XFCE
EOF

cat > "$ROOT_DIR/usr/share/xsessions/rebuilt-lxqt.desktop" <<'EOF'
[Desktop Entry]
Name=Rebuilt LFS LXQt
Comment=LXQt desktop for Rebuilt LFS
Exec=/usr/local/bin/rebuilt-startlxqt
TryExec=/usr/local/bin/rebuilt-startlxqt
Type=Application
DesktopNames=LXQt
EOF

cat > "$ROOT_DIR/etc/rebuilt-lfs-desktops" <<'EOF'
PRIMARY=xfce
ALTERNATIVE=lxqt
DISPLAY_SERVER=xorg
EOF

printf '%s\n' "XFCE and LXQt desktop sessions configured."
