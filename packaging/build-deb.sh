#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
PKG="ge360-suitecrm-engine"
BUILD_ROOT="$ROOT_DIR/build/deb/root"
OUT_DIR="$ROOT_DIR/dist"
LIB_DIR="$BUILD_ROOT/usr/lib/ge360-suitecrm-engine"
BIN_DIR="$BUILD_ROOT/usr/bin"

rm -rf "$ROOT_DIR/build/deb"
mkdir -p "$BUILD_ROOT/DEBIAN" "$LIB_DIR/scripts" "$LIB_DIR/docker" "$LIB_DIR/config" "$BIN_DIR" "$OUT_DIR"

cp "$ROOT_DIR/VERSION" "$LIB_DIR/"
cp "$ROOT_DIR/UPSTREAM.lock" "$LIB_DIR/"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$LIB_DIR/"
cp "$ROOT_DIR/docker-compose.yml" "$LIB_DIR/"
cp "$ROOT_DIR/docker/"* "$LIB_DIR/docker/"
cp "$ROOT_DIR/config/"* "$LIB_DIR/config/"
cp "$ROOT_DIR/scripts/"*.sh "$LIB_DIR/scripts/"
chmod 0755 "$LIB_DIR/scripts/"*.sh

cat > "$BUILD_ROOT/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: GE360
Depends: bash, curl, ca-certificates, openssl, coreutils, tar, gzip
Suggests: docker.io
Description: GE360 self-hosted wrapper for SuiteCRM 8
 Installs lifecycle tooling and a Docker runtime definition for the official
 SuiteCRM 8 release. SuiteCRM is downloaded from its official AGPL-3.0
 upstream release and verified by SHA-256 during image build.
EOF

cat > "$BUILD_ROOT/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
echo "GE360 SuiteCRM Engine installato."
echo "Avvio installazione CRM: sudo ge360-suitecrm-install"
exit 0
EOF
chmod 0755 "$BUILD_ROOT/DEBIAN/postinst"

make_wrapper() {
  local name="$1"
  local script="$2"
  cat > "$BIN_DIR/$name" <<EOF
#!/usr/bin/env bash
exec bash /usr/lib/ge360-suitecrm-engine/scripts/$script "\$@"
EOF
  chmod 0755 "$BIN_DIR/$name"
}

make_wrapper ge360-suitecrm-install install.sh
make_wrapper ge360-suitecrm-status status.sh
make_wrapper ge360-suitecrm-doctor doctor.sh
make_wrapper ge360-suitecrm-backup backup.sh
make_wrapper ge360-suitecrm-restore restore.sh
make_wrapper ge360-suitecrm-update update.sh
make_wrapper ge360-suitecrm-uninstall uninstall.sh

dpkg-deb --root-owner-group --build "$BUILD_ROOT" "$OUT_DIR/${PKG}_${VERSION}_all.deb"
echo "Creato: $OUT_DIR/${PKG}_${VERSION}_all.deb"
