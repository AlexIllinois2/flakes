{ config, pkgs, username, ... }: 

{
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      # ── 系统管理 ──
      "wheel"          # sudo
      "networkmanager" # nmcli / 网络控制

      # ── 安卓 / 移动开发 ──
      "adbusers"       # adb 免 sudo 访问设备
      "plugdev"        # 通用 USB 设备访问（部分设备需要）

      # ── 虚拟化 ──
      "kvm"            # 使用 /dev/kvm（Android Emulator、QEMU）
      "libvirtd"       # 如果你用 virt-manager / libvirt
      "docker"         # Docker（如果用 docker 而非 podman）
      "podman"

      # ── 硬件 / 多媒体 ──
      "audio"          # 音频设备（pipewire/pulse）
      "video"          # GPU / 摄像头 / 硬件加速
      "input"          # 输入设备（某些场景下需要）
      "bluetooth"      # 蓝牙管理

      # ── 外设 ──
      "lp"             # 打印机
      "scanner"        # 扫描仪

      # ── 存储 / 挂载 ──
      "disk"           # 手动挂载磁盘（如果你不用 udisks）
      "storage"        # 可移动存储

      # ── 开发工具 ──
      "wireshark"      # dumpcap 抓包免 sudo
    ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };
}
