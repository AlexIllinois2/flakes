{ config, pkgs, username, ... }:

{
  home.stateVersion = "26.05";

  imports = [
    ./dotfile.nix
    ./zsh.nix
  ];

  home.username = "${username}";
  home.homeDirectory = "/home/${username}";

  home.packages = [
    # pkgs.hello
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  home.sessionVariables = {
    # EDITOR = "emacs";
  };
}
