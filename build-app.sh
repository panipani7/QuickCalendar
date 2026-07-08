#!/bin/bash
# Swift版 QuickCalendar をビルドして dist/QuickCalendar.app を生成する
# 使い方:
#   ./build-app.sh            ビルドのみ
#   ./build-app.sh --install  ビルド後 /Applications にインストールして起動
set -euo pipefail
cd "$(dirname "$0")"

echo "アプリをビルド中..."
swift build -c release --package-path QuickCalendarSwift

APP="dist/QuickCalendar.app"
BIN="QuickCalendarSwift/.build/release/QuickCalendar"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/QuickCalendar"
cp icon.png icon@2x.png "$APP/Contents/Resources/"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Finder用アプリアイコン（.icns）を appicon.svg から生成
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" appicon.svg \
        --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    d=$((size * 2))
    sips -s format png -z "$d" "$d" appicon.svg \
        --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$ICONSET")"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>QuickCalendar</string>
	<key>CFBundleIdentifier</key>
	<string>com.local.quickcalendar</string>
	<key>CFBundleName</key>
	<string>QuickCalendar</string>
	<key>CFBundleDisplayName</key>
	<string>Quick Calendar</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleVersion</key>
	<string>2.0</string>
	<key>CFBundleShortVersionString</key>
	<string>2.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

# アドホック署名（Apple Developer ID がある場合は -s を差し替える）
codesign --force --sign - "$APP"

echo "ビルド完了: $APP"

if [ "${1:-}" = "--install" ]; then
    DEST="/Applications/QuickCalendar.app"
    pkill -x QuickCalendar 2>/dev/null || true
    rm -rf "$DEST"
    cp -R "$APP" "$DEST"
    open "$DEST"
    echo "インストール完了: $DEST"
fi
