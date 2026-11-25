{ config, pkgs, ... }: {
  imports = [
    ./base.nix
    ./fcitx5.nix
    ./gnome.nix
    ./flatpak.nix
    ./clash-verge-rev.nix
  ];
}
