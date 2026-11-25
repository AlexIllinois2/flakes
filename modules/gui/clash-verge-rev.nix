{ config, pkgs, ... }:

{
  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    serviceMode = true;
    # 如需将服务 Socket 权限授予特定用户组，可按需配置：
    # group = "wheel";
  };

  networking.firewall = {
    trustedInterfaces = [ "Mihomo" ];
    extraReversePathFilterRules = ''
      iifname { "Mihomo" } accept comment "trusted interface"
    '';
  };
}
