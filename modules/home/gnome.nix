{ config, pkgs, ... }: 

{
   home.packages = with pkgs.gnomeExtensions; [
    net-speed-simplified
    just-perfection
    gsconnect
  ];

  programs.gnome-shell = {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      net-speed-simplified
      just-perfection
      gsconnect
    ];
  };

  dconf.enable = true;
  dconf.settings."org/gnome/shell" = {
    disable-user-extensions = false;
    enabled-extensions = with pkgs.gnomeExtensions; [
      net-speed-simplified.extensionUuid
      just-perfection.extensionUuid
      gsconnect.extensionUuid
    ];
  };
}