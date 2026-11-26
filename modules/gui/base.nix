{ config, pkgs, lib, self, ... }:

{
  programs.firefox.enable = true;
  environment.systemPackages = with pkgs; [
    brightnessctl 
    google-chrome vscodium
    android-tools qtscrcpy
    localsend
    self.packages.${pkgs.stdenv.hostPlatform.system}.trae-cn
    # nur.repos.MCSeekeri.workbuddy # 资源在 https://github.com/acgq/workbuddy-linux
  ];

  # localsend端口放行
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
}
