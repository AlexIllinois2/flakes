{ config, pkgs, home-manager, username, ... }:

{ 
  system.stateVersion = "26.05";
  
  nix.package = pkgs.nix; 
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [
      "https://mirrors.cernet.edu.cn/nix-channels/store?priority=10"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=10"
      "https://mirror.sjtu.edu.cn/nix-channels/store?priority=10"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly"; # daily / weekly / monthly
    options = "--delete-older-than 14d";
  };
  nix.settings.min-free = 10 * 1024 * 1024 * 1024; # 10G
  nix.settings.max-free = 20 * 1024 * 1024 * 1024;
  nix.settings.auto-optimise-store = true;
  # nix.settings.keep-derivations = false;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit username; };
  };

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };
}