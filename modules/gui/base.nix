{ config, pkgs, lib, ... }:

{
  programs.firefox.enable = true;
  services.flatpak.enable = true;
  environment.systemPackages = with pkgs; [
    brightnessctl 
    google-chrome vscodium
    android-tools qtscrcpy
    localsend clash-verge-rev
    nur.repos.lonerOrz.trae
    nur.repos.MCSeekeri.workbuddy # 资源在 https://github.com/acgq/workbuddy-linux
  ];

  # localsend端口放行
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
}
