#!/bin/bash
set -euo pipefail

# Assemble the complete Rebuilt LFS userspace needed by the desktop ISO.
# This is deliberately staged: the LFS bootstrap creates the target tree,
# while this script installs the runtime pieces and boot configuration.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
mkdir -p "$ROOT_DIR"/{etc,bin,sbin,usr/bin,usr/sbin,var/lib,run,dev,proc,sys,tmp,home}
chmod 1777 "$ROOT_DIR/tmp"

# Minimal init. It mounts virtual filesystems, starts networking, then launches
# the graphical desktop on tty1 when the desktop stack is available.
cat > "$ROOT_DIR/sbin/init" <<'EOF'
#!/bin/sh
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true

if command -v NetworkManager >/dev/null 2>&1; then
    NetworkManager --no-daemon &
fi

# Give the network service a moment to initialize in simple VM boots.
sleep 2

if [ -x /usr/local/bin/rebuilt-desktop ]; then
    exec /usr/local/bin/rebuilt-desktop </dev/tty1 >/dev/tty1 2>&1
fi

exec /bin/sh
EOF
chmod 755 "$ROOT_DIR/sbin/init"

# Default shell and environment.
cat > "$ROOT_DIR/etc/profile" <<'EOF'
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
EOF

# NetworkManager starts automatically from init and manages DHCP.
mkdir -p "$ROOT_DIR/etc/NetworkManager/system-connections"
cat > "$ROOT_DIR/etc/NetworkManager/NetworkManager.conf" <<'EOF'
[main]
plugins=keyfile

[logging]
level=INFO
EOF

# Common virtual-machine hostname.
echo rebuilt-lfs > "$ROOT_DIR/etc/hostname"

printf '%s\n' "Rebuilt LFS runtime boot configuration installed."
