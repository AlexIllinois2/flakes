{ pkgs, ... }:

{
  # 开发/搜索类工具：都是纯用户态、跨平台，桌面与 xplay6 共用。
  #
  # 闭包参考（aarch64-linux，含共享的 glibc 等依赖，解压后）：
  #   git 335M / elfutils 91M / fzf 56M / bat 66M / fd 59M / eza 53M
  # 这些是 nix 生态里最常规的一套，不算“重量级”，故默认全部启用。
  environment.systemPackages = with pkgs; [
    openssl pkg-config
    git gh

    # 搜索/筛选
    ripgrep # rg，比 grep 快的递归搜索
    fzf
    fd # nixpkgs 包名是 fd，二进制也是 fd（即 Debian 的 fd-find）
    bat # 二进制名为 bat（即 Debian 的 batcat）
    eza # ls 替代

    python3 python3Packages.pip python3Packages.virtualenv 
    uv

    # ELF 分析（readelf/eu-stack/eu-readelf 等）
    qemu OVMF gdb binutils elfutils
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
