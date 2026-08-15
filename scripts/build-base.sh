#!/bin/bash
set -euo pipefail

# Build the initial Rebuilt LFS system from an LFS host environment.
# This script intentionally keeps downloads/cache outside the repository.

ROOT_DIR="${ROOT_DIR:-$PWD/work/rootfs}"
SRC_DIR="${SRC_DIR:-$PWD/work/sources}"
JOBS="${JOBS:-$(nproc)}"
LFS_VERSION="${LFS_VERSION:-12.4}"

mkdir -p "$ROOT_DIR" "$SRC_DIR"
mkdir -p "$ROOT_DIR"/{bin,etc,home,lib,mnt,opt,root,sbin,tmp,usr,var}
mkdir -p "$ROOT_DIR"/usr/{bin,lib,sbin,share,src}
chmod 1777 "$ROOT_DIR/tmp"

# Sanity-check the build host. A full LFS build must run from a supported
# Linux host with the LFS prerequisites installed.
for tool in gcc g++ make bison gawk texinfo wget tar xz; do
    command -v "$tool" >/dev/null || {
        echo "Missing required host tool: $tool" >&2
        exit 1
    }
done

# Keep a deterministic build configuration in the generated system.
cat > "$ROOT_DIR/etc/rebuilt-lfs-release" <<EOF
NAME="Rebuilt LFS"
VERSION="0.1-dev"
LFS_VERSION="$LFS_VERSION"
ARCH="$(uname -m)"
EOF

# Install a minimal passwd/group database so later package and desktop stages
# have the standard system identities available.
cat > "$ROOT_DIR/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/bash
EOF
cat > "$ROOT_DIR/etc/group" <<'EOF'
root:x:0:
EOF

# Basic resolver configuration. NetworkManager/systemd-resolved integration is
# completed by the networking stage once the final userspace is installed.
cat > "$ROOT_DIR/etc/hosts" <<'EOF'
127.0.0.1 localhost
::1 localhost
EOF

printf '%s\n' "Rebuilt LFS base filesystem initialized at $ROOT_DIR"
printf '%s\n' "LFS version target: $LFS_VERSION"
printf '%s\n' "Next build stages: LFS toolchain -> base system -> Porg -> Xorg/XFCE -> networking -> ISO"
