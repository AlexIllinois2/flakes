{ config, pkgs, ... }: 

{
  imports = [
    ./boot.nix
    ./base.nix
    ./user.nix
    ./gnome.nix
    ./net.nix
    ./sound.nix
    ./input.nix
    ./print.nix
  ];
}
