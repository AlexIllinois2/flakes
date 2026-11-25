#!/usr/bin/env python3
"""store 路径解析助手：按关键字找出 /nix/store 里的真实路径，避免硬编码历史 hash。

Nix 升级或 gc 后 store hash 会变，构建脚本里的 JAVA_HOME/gradle/patchelf 等
不应写死。用本脚本现场解析后再拼进脚本或环境变量。

用法：
  python3 example.py openjdk-17          # 打印匹配目录（可能多个，逐个核对）
  python3 example.py gradle
  python3 example.py patchelf
  python3 example.py system-path
"""
import glob
import sys

def main():
    if len(sys.argv) < 2:
        print("用法: example.py <关键字> [更多关键字...]", file=sys.stderr)
        sys.exit(2)
    for kw in sys.argv[1:]:
        print(f"# --- {kw} ---")
        hits = sorted(glob.glob(f"/nix/store/*{kw}*"))
        if not hits:
            print("(无匹配)")
        for h in hits:
            print(h)

if __name__ == "__main__":
    main()
