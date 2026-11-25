#!/usr/bin/env bash
# 用 patchelf 修 sdkmanager 装的 NDK 主机 ELF，使其在 NixOS 上可执行。
# 触发症状：NDK 下 clang/ld/lldb 等报 "cannot execute"、
#          interpreter "No such file or directory"、缺 libxml2.so/libedit.so。
# 用法：patch_ndk.sh <目标NDK目录> <nix版NDK目录(提供so)> [glibc目录]
#   目标NDK目录 例如 /tmp/<proj>-sdk/ndk/<app要求的版本>
#   nix版NDK目录 例如 devshell store 里的 ndk/<devshell自带版本>（或别的已 patched 的 NDK）
set -euo pipefail
export PATH=/run/current-system/sw/bin:$PATH

TARGET="${1:?用法: patch_ndk.sh <目标NDK目录> <nix版NDK目录> [glibc目录]}"
DONOR="${2:?需要 nix 版 NDK 目录来提供 .so}"
GLIBC="${3:-$(ls -d /nix/store/*glibc-2.*/lib 2>/dev/null | head -1)}"

PATCHELF="$(ls -d /nix/store/*patchelf*/bin/patchelf 2>/dev/null | head -1 || true)"
[ -z "$PATCHELF" ] && PATCHELF="$(command -v patchelf || true)"
[ -z "$PATCHELF" ] && { echo "找不到 patchelf" >&2; exit 1; }

LOADER="$GLIBC/ld-linux-x86-64.so.2"
[ -f "$LOADER" ] || { echo "找不到 glibc loader: $LOADER" >&2; exit 1; }

ZLIB="$(ls -d /nix/store/*zlib-1.*/lib 2>/dev/null | head -1 || true)"
LIBGCC="$(ls -d /nix/store/*gcc-lib/lib 2>/dev/null | head -1 || true)"

# 1) 把 donor NDK 的库拷进目标 NDK 的 lib64（libxml2/libedit/lldb 等）。
mkdir -p "$TARGET/lib64"
if [ -d "$DONOR/lib" ]; then
  cp -a "$DONOR"/lib/*.so* "$TARGET/lib64/" 2>/dev/null || true
fi

# 2) 拼 rpath：目标 lib64 + glibc + zlib + libgcc。
RPATH="$TARGET/lib64:$GLIBC"
[ -n "$ZLIB" ]   && RPATH="$RPATH:$ZLIB"
[ -n "$LIBGCC" ] && RPATH="$RPATH:$LIBGCC"

# 3) 遍历目标 NDK 的主机 ELF（bin/ 与 lib/ 下的可执行/共享库），改 interp + rpath。
count=0
while IFS= read -r -d '' f; do
  # 只处理 ELF，跳过脚本/文本。
  if head -c 4 "$f" 2>/dev/null | grep -q $'\x7fELF'; then
    "$PATCHELF" --set-interpreter "$LOADER" "$f" 2>/dev/null || true
    "$PATCHELF" --set-rpath "$RPATH" "$f" 2>/dev/null || true
    count=$((count + 1))
  fi
done < <(find "$TARGET/bin" "$TARGET/lib64" -type f \( -perm -u+x -o -name '*.so*' \) -print0 2>/dev/null)

echo "已处理 $count 个 ELF（interp=$LOADER, rpath=$RPATH）"
echo "抽查: $TARGET/bin/clang --version | head -1"
