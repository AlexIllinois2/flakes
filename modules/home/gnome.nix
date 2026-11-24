{ config, pkgs, ... }: 

{
  programs.gnome-shell = {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      { package = net-speed-simplified; }
      { package = just-perfection; }
      { package = gsconnect; }
    ];
  };

  dconf.enable = true;
}
