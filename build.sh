#!/bin/bash
# 上班鼓励器 · macOS 菜单栏 App 构建脚本
# 最低兼容 macOS 13.0 (Ventura)，编译 Apple Silicon + Intel 通用二进制
set -e
cd "$(dirname "$0")"

mkdir -p build

COMMON="-O -parse-as-library -framework AppKit -framework ServiceManagement"

swiftc $COMMON -target arm64-apple-macos13.0 \
  Sources/*.swift -o build/WorkCheer-arm64

swiftc $COMMON -target x86_64-apple-macos13.0 \
  Sources/*.swift -o build/WorkCheer-x86_64

lipo -create build/WorkCheer-arm64 build/WorkCheer-x86_64 -output build/WorkCheer

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

echo "构建完成: $APP ($(lipo -archs build/WorkCheer))"
