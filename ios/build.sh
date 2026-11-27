#!/usr/bin/env bash
# 今日事 iOS 移植版 · 交叉编译与打包脚本
# 依赖：clang / lld、python3 + Pillow、zip、iPhoneOS SDK，可选 ldid
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/TodoLite.app"
SRC="$ROOT/src"
VERSION="${VERSION:-2.0.0}"
IPA="$BUILD/今日事-iOS-v${VERSION}-unsigned.ipa"

die() { echo "错误：$*" >&2; exit 1; }

# ---------- 依赖检查 ----------
command -v clang >/dev/null 2>&1 || die "找不到 clang，请先安装 clang / llvm / lld"
command -v python3 >/dev/null 2>&1 || die "找不到 python3"
python3 -c "import PIL" 2>/dev/null || die "缺少 Pillow，请执行 pip3 install pillow"
command -v zip >/dev/null 2>&1 || die "找不到 zip"

# ---------- 定位 iPhoneOS SDK ----------
if [ -z "${SDK:-}" ]; then
    for cand in "$ROOT"/sdks/iPhoneOS*.sdk "$HOME"/sdks/iPhoneOS*.sdk \
                /opt/theos/sdks/iPhoneOS*.sdk /usr/local/theos/sdks/iPhoneOS*.sdk; do
        if [ -d "$cand" ]; then SDK="$cand"; break; fi
    done
fi
[ -n "${SDK:-}" ] && [ -d "$SDK" ] || die "找不到 iPhoneOS SDK。请下载 https://github.com/theos/sdks 并设置 SDK=/path/to/iPhoneOS16.5.sdk"
echo "==> SDK: $SDK"

# ---------- 定位 ldid ----------
LDID_BIN="${LDID:-}"
if [ -z "$LDID_BIN" ]; then
    if command -v ldid >/dev/null 2>&1; then
        LDID_BIN="$(command -v ldid)"
    elif [ -x "$HOME/ldid/ldid" ]; then
        LDID_BIN="$HOME/ldid/ldid"
    fi
fi

# ---------- 图标 ----------
mkdir -p "$BUILD/icons"
python3 "$ROOT/tools/make_icon.py" >/dev/null
echo "==> 图标已生成"

# ---------- 编译 ----------
echo "==> 编译 arm64 iOS 可执行文件"
clang -target arm64-apple-ios14.0 \
      -isysroot "$SDK" \
      -fuse-ld=lld \
      -fobjc-arc \
      -O2 \
      -Wall \
      -Wno-unused-parameter \
      -Wno-nullability-completeness \
      -Wno-deprecated-declarations \
      -Wno-unguarded-availability-new \
      -framework UIKit \
      -framework CoreGraphics \
      -framework QuartzCore \
      -framework Foundation \
      -framework UserNotifications \
      -framework UniformTypeIdentifiers \
      -o "$BUILD/TodoLite" \
      "$SRC"/*.m

command -v llvm-strip >/dev/null 2>&1 && llvm-strip -x "$BUILD/TodoLite" 2>/dev/null || true

# ---------- 组装 App ----------
echo "==> 组装 App 包"
rm -rf "$APP"
mkdir -p "$APP"
cp "$BUILD/TodoLite" "$APP/TodoLite"
cp "$ROOT/Info.plist" "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"
cp "$BUILD/icons/AppIcon60x60.png" "$APP/AppIcon60x60.png"
cp "$BUILD/icons/AppIcon60x60@2x.png" "$APP/AppIcon60x60@2x.png"
cp "$BUILD/icons/AppIcon60x60@3x.png" "$APP/AppIcon60x60@3x.png"
cp "$BUILD/icons/AppIcon1024.png" "$APP/AppIcon1024.png"

# ---------- 临时签名 ----------
if [ -n "$LDID_BIN" ] && [ -x "$LDID_BIN" ]; then
    echo "==> ldid 临时签名：$LDID_BIN"
    "$LDID_BIN" -S "$APP/TodoLite"
else
    echo "==> 未找到 ldid，跳过临时签名（侧载工具重签时会重新签名）"
fi

# ---------- 打包 IPA ----------
echo "==> 打包 IPA"
rm -rf "$BUILD/Payload"
mkdir -p "$BUILD/Payload"
cp -R "$APP" "$BUILD/Payload/"
rm -f "$IPA"
(cd "$BUILD" && zip -qry "$(basename "$IPA")" Payload)

echo "==> 完成：$IPA"
ls -lh "$IPA"
