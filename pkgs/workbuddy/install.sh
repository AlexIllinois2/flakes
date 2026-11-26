#!/usr/bin/env bash
# 安装/升级 WorkBuddy：优先使用 ~/Downloads 下的同名 tarball，避免从 GitHub 下载大文件。
set -euo pipefail

repo="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
cd "$repo"

name="$(nix eval --raw .#packages.x86_64-linux.workbuddy.src.name)"
local_file="$HOME/Downloads/$name"

if [ -f "$local_file" ]; then
  echo "==> 使用本地文件：$local_file"
  nix-store --add-fixed sha256 "$local_file" >/dev/null
else
  echo "==> ~/Downloads 中没有 $name，将从 GitHub Releases 下载"
fi

if nix profile list --json 2>/dev/null | grep -q '"workbuddy"'; then
  exec nix profile upgrade workbuddy
else
  exec nix profile install .#workbuddy
fi
