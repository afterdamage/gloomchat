#!/usr/bin/env bash
set -euo pipefail

PKGNAME=gloomchat
# Read version from pubspec.yaml (format 2.4.0+3548 -> 2.4.0-3548)
RAW_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | tr -d '\r')
VERSION=${RAW_VERSION/+/-}
ARCH=amd64
BUILD_DIR=build/deb
PKG_ROOT=${BUILD_DIR}/${PKGNAME}_${VERSION}_${ARCH}

rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT/opt/$PKGNAME"
cp -r build/linux/x64/release/bundle/* "$PKG_ROOT/opt/$PKGNAME/"

# Create symlink in /usr/bin
mkdir -p "$PKG_ROOT/usr/bin"
ln -sf "/opt/$PKGNAME/gloomchat" "$PKG_ROOT/usr/bin/$PKGNAME"

# Install icon using the Android launcher icon if available.
mkdir -p "$PKG_ROOT/usr/share/icons/hicolor/256x256/apps"
ICON_SRC="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
if [ ! -f "$ICON_SRC" ]; then
  ICON_SRC="build/linux/x64/release/bundle/data/flutter_assets/assets/logo.png"
fi
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$PKG_ROOT/usr/share/icons/hicolor/256x256/apps/$PKGNAME.png"
fi

# Desktop entry
mkdir -p "$PKG_ROOT/usr/share/applications"
cat > "$PKG_ROOT/usr/share/applications/$PKGNAME.desktop" <<EOF
[Desktop Entry]
Name=GloomChat
Comment=Secure Matrix messenger
Exec=/opt/$PKGNAME/gloomchat
Icon=gloomchat
Type=Application
Categories=Network;InstantMessaging;
Keywords=chat;matrix;messaging;secure;communication;
StartupWMClass=gloomchat
Terminal=false
EOF

# DEBIAN control
mkdir -p "$PKG_ROOT/DEBIAN"
cat > "$PKG_ROOT/DEBIAN/control" <<EOF
Package: $PKGNAME
Version: $VERSION
Section: net
Priority: optional
Architecture: $ARCH
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, libgcc-s1
Maintainer: GloomChat Packager <packager@example.com>
Description: GloomChat - Secure Matrix messenger
 GloomChat packaged for Ubuntu.
EOF

# Set permissions (avoid chmod on symlink in usr/bin)
chmod -R 755 "$PKG_ROOT/opt/$PKGNAME"

# Build .deb
mkdir -p dist
fakeroot dpkg-deb --build "$PKG_ROOT"
mv "${PKG_ROOT}.deb" dist/

echo "Built: dist/${PKGNAME}_${VERSION}_${ARCH}.deb"
