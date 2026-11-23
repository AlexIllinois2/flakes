{ config, pkgs, ... }: {
  imports = [
    ./base.nix
    ./zsh.nix
    ./dev.nix
    ./net.nix
    ./heavy.nix
  ];
}
