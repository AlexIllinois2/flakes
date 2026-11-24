{ config, pkgs, ... }: {
  imports = [
    ./base.nix
    ./zsh.nix
    ./dev.nix
    ./net.nix
    ./appimage.nix
    ./heavy.nix
  ];
}
