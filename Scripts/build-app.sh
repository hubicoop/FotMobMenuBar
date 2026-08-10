#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
APP_NAME="FotMobMenuBar"
APP_DIR="$ROOT/dist/$APP_NAME.app"

swift build --package-path "$ROOT" -c release
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$ROOT/.build/release/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>FotMobMenuBar</string>
    <key>CFBundleIdentifier</key><string>com.local.FotMobMenuBar</string>
    <key>CFBundleName</key><string>FotMob Menü Çubuğu</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR"
print "Oluşturuldu: $APP_DIR"
