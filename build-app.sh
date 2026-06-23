#!/bin/bash
set -e

APP_NAME="OCMonitor"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP_DIR="$ROOT/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "🔨 Building release binary..."
swift build -c release --quiet

echo "📦 Creating .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

echo "🎨 Generating icon..."
python3 -c "
import Cocoa
img = Cocoa.NSImage.imageWithSystemSymbolName_accessibilityDescription_('chart.bar.fill', '')
if img:
    img.setSize_((512,512))
    rep = Cocoa.NSBitmapImageRep.alloc().initWithData_(img.TIFFRepresentation())
    data = rep.representationUsingType_properties_(Cocoa.NSPNGFileType, None)
    data.writeToFile_atomically_('$RESOURCES_DIR/icon.png', True)
" 2>/dev/null || touch "$RESOURCES_DIR/icon.png"

cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>OC Monitor</string>
    <key>CFBundleIdentifier</key>
    <string>dev.agent-orchestrator.ocmonitor</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "✅ Done: $APP_DIR"
echo ""
echo "  open $APP_DIR"
