{ config, pkgs, ... }: {
  imports = [
    ./base.nix
    ./fcitx5.nix
    #./workbuddy.nix
  ];
}
