#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}" >&2; exit 1; }

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="AutoQSL"

VERSION_FILE="$PROJECT_DIR/.version"
BUILD_FILE="$PROJECT_DIR/.build_number"

[ ! -f "$VERSION_FILE" ] && echo "1.0.0" > "$VERSION_FILE"
[ ! -f "$BUILD_FILE" ]   && echo "0" > "$BUILD_FILE"

VERSION=$(cat "$VERSION_FILE" | tr -d ' \n\r')
BUILD=$(cat "$BUILD_FILE" | tr -d ' \n\r')
BUILD=$((BUILD + 1))
echo "$BUILD" > "$BUILD_FILE"

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  AutoQSL Lokaler Release-Build: v${VERSION} (Build ${BUILD})${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo ""

cat > "$PROJECT_DIR/Sources/AutoQSL/BuildNumber.swift" <<EOF
public let APP_VERSION = "$VERSION"
public let APP_BUILD_NUMBER = $BUILD
EOF
success "BuildNumber.swift aktualisiert: v$VERSION (b$BUILD)"

info "Kompiliere Universal Binary..."
killall "$APP_NAME" 2>/dev/null || true
sleep 1

swift build -c release --triple arm64-apple-macosx
swift build -c release --triple x86_64-apple-macosx

BUNDLE="$PROJECT_DIR/${APP_NAME}.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

lipo -create -output "$BUNDLE/Contents/MacOS/$APP_NAME" \
    "$PROJECT_DIR/.build/arm64-apple-macosx/release/$APP_NAME" \
    "$PROJECT_DIR/.build/x86_64-apple-macosx/release/$APP_NAME"
chmod +x "$BUNDLE/Contents/MacOS/$APP_NAME"

[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ] && \
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/"

cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key>              <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>                <string>AppIcon</string>
    <key>CFBundleIdentifier</key>              <string>com.dj6gi.autoqsl</string>
    <key>CFBundleName</key>                    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>                 <string>$BUILD</string>
    <key>CFBundleShortVersionString</key>      <string>$VERSION</string>
    <key>CFBundlePackageType</key>             <string>APPL</string>
    <key>NSHighResolutionCapable</key>         <true/>
    <key>LSMinimumSystemVersion</key>          <string>14.0</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>AutoQSL benötigt Zugriff auf Apple Mail, um QSL-Karten automatisch zu versenden.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024–2026 Georg Isenbürger · DJ6GI</string>
</dict></plist>
PLIST

info "Signiere AutoQSL.app Bundle ad-hoc..."
codesign --force --deep --sign - "$BUNDLE"
success "AutoQSL.app Bundle erstellt & ad-hoc signiert"

INSTALLER_NAME="AutoQSL Installer"
INSTALLER_BUNDLE="$PROJECT_DIR/${INSTALLER_NAME}.app"
rm -rf "$INSTALLER_BUNDLE"
mkdir -p "$INSTALLER_BUNDLE/Contents/MacOS" "$INSTALLER_BUNDLE/Contents/Resources"

lipo -create -output "$INSTALLER_BUNDLE/Contents/MacOS/$INSTALLER_NAME" \
    "$PROJECT_DIR/.build/arm64-apple-macosx/release/AutoQSLInstaller" \
    "$PROJECT_DIR/.build/x86_64-apple-macosx/release/AutoQSLInstaller"
chmod +x "$INSTALLER_BUNDLE/Contents/MacOS/$INSTALLER_NAME"

[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ] && \
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$INSTALLER_BUNDLE/Contents/Resources/"

cat > "$INSTALLER_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key>              <string>$INSTALLER_NAME</string>
    <key>CFBundleIconFile</key>                <string>AppIcon</string>
    <key>CFBundleIdentifier</key>              <string>com.dj6gi.autoqsl.installer</string>
    <key>CFBundleName</key>                    <string>$INSTALLER_NAME</string>
    <key>CFBundleVersion</key>                 <string>$BUILD</string>
    <key>CFBundleShortVersionString</key>      <string>$VERSION</string>
    <key>CFBundlePackageType</key>             <string>APPL</string>
    <key>NSHighResolutionCapable</key>         <true/>
    <key>LSMinimumSystemVersion</key>          <string>14.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024–2026 Georg Isenbürger · DJ6GI</string>
</dict></plist>
PLIST

info "Signiere AutoQSL Installer.app Bundle ad-hoc..."
codesign --force --deep --sign - "$INSTALLER_BUNDLE"
success "AutoQSL Installer.app Bundle erstellt & ad-hoc signiert"

info "Erstelle .dmg..."
DMG_NAME="${APP_NAME}-v${VERSION}-b${BUILD}.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"
DMG_LATEST="$PROJECT_DIR/$APP_NAME.dmg"
rm -f "$DMG_PATH" "$DMG_LATEST"

STAGING=$(mktemp -d)
cp -R "$BUNDLE" "$STAGING/"
cp -R "$INSTALLER_BUNDLE" "$STAGING/"
if [ -f "$PROJECT_DIR/Install AutoQSL.command" ]; then
    cp "$PROJECT_DIR/Install AutoQSL.command" "$STAGING/"
    chmod +x "$STAGING/Install AutoQSL.command"
fi
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "$APP_NAME v$VERSION" -srcfolder "$STAGING" \
    -ov -format UDZO "$DMG_PATH" > /dev/null
rm -rf "$STAGING"
cp "$DMG_PATH" "$DMG_LATEST"
success "DMG: $DMG_NAME"

git add .
git commit -m "Release v$VERSION Build $BUILD (local)" || warn "Nichts zu committen"
git tag -a "v${VERSION}-b${BUILD}" -m "AutoQSL v$VERSION (Build $BUILD)" || warn "Tag existiert bereits"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  Lokaler Release v$VERSION (Build $BUILD) fertig erstellt! ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📦 DMG:        $DMG_PATH"
echo -e "  📦 Latest DMG: $DMG_LATEST"
echo ""
