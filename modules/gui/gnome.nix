{ config, pkgs, ... }: 

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-browser-connector
    gnomeExtensions.appindicator
    # gnomeExtensions.blur-my-shell
  ];

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/shell" = {
      disable-user-extensions = false;
    };
  }];
}
