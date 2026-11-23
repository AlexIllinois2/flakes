{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl
    google-chrome vscodium
    nur.repos.lonerOrz.trae
    nur.repos.MCSeekeri.workbuddy
  ];
}
