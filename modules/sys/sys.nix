{ config, pkgs, ... }: 

{
  imports = [
    ./boot.nix
    ./base.nix
    ./user.nix
    ./font.nix
    ./net.nix
    ./sound.nix
    ./input.nix
    ./print.nix
  ];
}
