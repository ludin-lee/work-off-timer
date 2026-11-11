#!/bin/sh
set -e
cd "$(dirname "$0")"
APP=WorkOffTimer.app
VERSION=1.0.0
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
cp AppIcon.icns $APP/Contents/Resources/
swiftc -O main.swift -o $APP/Contents/MacOS/WorkOffTimer
cat > $APP/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>WorkOffTimer</string>
<key>CFBundleIdentifier</key><string>local.workofftimer</string>
<key>LSUIElement</key><true/>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
</dict></plist>
EOF
echo "built $APP"
