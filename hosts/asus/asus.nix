{ self, config, pkgs, home-manager, username, ... }: {
  imports = [
    ./cpu.nix
    ./file_system.nix
    (self + "/modules/hardware/intel.nix")
    (self + "/modules/sys/sys.nix")
    (self + "/modules/cmd/cmd.nix")
    (self + "/modules/gui/gui.nix")
  ];

  home-manager.users.${username} = import (self + "/modules/home/home.nix");
}