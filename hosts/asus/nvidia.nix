{ config, pkgs, ... }:

{
  # 启用 OpenGL 支持
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 如果需要运行 32 位应用（如 Steam）
  };

  # 加载 NVIDIA 驱动
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # 必须启用 Modesetting
    modesetting.enable = true;

    # 设为 false 使用闭源内核模块（默认）
    # 设为 true 使用开源内核模块（仅限 Turing/RTX 20 系列及更新显卡）
    open = false; 

    # 启用 NVIDIA 设置工具
    nvidiaSettings = true;

    # 选择驱动版本：stable, beta, lts, legacy_470 等
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # 混合显卡配置
    prime = {
      # Offload 模式（推荐，按需调用独显）
      offload.enable = true;
      # 或者使用 Sync 模式（性能更好但更耗电）
      # sync.enable = true; 

      # 替换为你实际的 Bus ID (sudo lshw -c display | grep "bus info")
      intelBusId = "PCI:0:2:0"; # Intel 核显
      # amdgpuBusId = "PCI:5:0:0"; # 如果是 AMD 核显则使用此项
      nvidiaBusId = "PCI:1:0:0"; # NVIDIA 独显
    };
  };

  # 确保禁用开源的 nouveau 驱动以避免冲突
  boot.blacklistedKernelModules = [ "nouveau" ];
}