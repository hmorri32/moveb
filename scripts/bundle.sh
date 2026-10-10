#!/bin/sh
# Builds MoveB and wraps it in a signed .app bundle at build/MoveB.app.
# macOS ties Accessibility permission to the app's identity, so it needs to be a real bundle.
set -eu

cd "$(dirname "$0")/.."

swift build -c release

app=build/MoveB.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/MoveB "$app/Contents/MacOS/MoveB"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>local.moveb</string>
    <key>CFBundleName</key>
    <string>MoveB</string>
    <key>CFBundleExecutable</key>
    <string>MoveB</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
echo "Built $app"
