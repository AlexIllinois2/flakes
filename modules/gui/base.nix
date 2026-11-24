{ config, pkgs, lib, ... }:

{
  programs.firefox.enable = true;
  programs.adb.enable = true;
  environment.systemPackages = with pkgs; [
    brightnessctl 
    android-tools qtscrcpy
    google-chrome vscodium
    nur.repos.lonerOrz.trae
    nur.repos.MCSeekeri.workbuddy # 资源在 https://github.com/acgq/workbuddy-linux
  ];
}
