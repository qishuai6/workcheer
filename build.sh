#!/bin/bash
# 上班鼓励器 · macOS 菜单栏 App 构建脚本
set -e
cd "$(dirname "$0")"

mkdir -p build
swiftc -O -parse-as-library \
  -framework AppKit -framework ServiceManagement \
  Sources/*.swift \
  -o build/WorkCheer

APP="build/上班鼓励器.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp build/WorkCheer "$APP/Contents/MacOS/WorkCheer"
cp Info.plist "$APP/Contents/Info.plist"
if [ -f AppIcon.icns ]; then
  cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
  plutil -replace CFBundleIconFile -string AppIcon "$APP/Contents/Info.plist"
fi
touch "$APP"

echo "构建完成: $APP"
