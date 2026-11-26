{ config, pkgs, lib, self, ... }:

{
  programs.firefox.enable = true;
  environment.systemPackages = with pkgs; [
    desktop-file-utils libnotify brightnessctl 
    google-chrome vscodium
    android-tools qtscrcpy
    localsend
    self.packages.${pkgs.stdenv.hostPlatform.system}.trae-cn
  ];

  # localsend端口放行
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
}
