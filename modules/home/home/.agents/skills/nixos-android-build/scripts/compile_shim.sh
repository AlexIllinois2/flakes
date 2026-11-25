#!/usr/bin/env bash
# 在 NixOS 上把 libfutimes_shim.c 编成 LD_PRELOAD 用的 .so。
# 思路：用 store 里的 clang + glibc-dev 的 include，产出普通 glibc ELF 即可
# （这个 .so 是给 java/aapt2 这类非 Nix patched 的进程 preload 的，不能静态链）。
set -euo pipefail

# 沙箱 PATH 可能连 bash/coreutils 都没有；需要时先给个基础 PATH。
export PATH=/run/current-system/sw/bin:$PATH

SRC="$(dirname "$0")/libfutimes_shim.c"
OUT="${1:-/tmp/libfutimes_shim.so}"

CLANG="$(ls -d /nix/store/*clang*/bin/clang 2>/dev/null | head -1 || true)"
[ -z "$CLANG" ] && CLANG="$(command -v clang || true)"
[ -z "$CLANG" ] && { echo "找不到 clang" >&2; exit 1; }

# glibc-dev 头文件目录（UTIME_NOW / SYS_utimensat 等需要）。
GLIBC_INC="$(ls -d /nix/store/*glibc*dev*/include 2>/dev/null | head -1 || true)"
INCLUDE_FLAG=""
[ -n "$GLIBC_INC" ] && INCLUDE_FLAG="-isystem $GLIBC_INC"

echo "clang=$CLANG"
echo "include=$GLIBC_INC"
"$CLANG" -shared -fPIC -O2 -Wall $INCLUDE_FLAG -o "$OUT" "$SRC"
ls -l "$OUT"
echo "OK: 构建脚本里 export LD_PRELOAD=$OUT"
