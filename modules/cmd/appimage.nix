{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ appimage-run ];

  programs.appimage = {
    enable = true;
    binfmt = true;
    # 如果有个别 AppImage 缺库，可以 override extraPkgs
    # package = pkgs.appimage-run.override {
    #   extraPkgs = pkgs: [ pkgs.libepoxy ];
    # };
  };
  
  boot.supportedFilesystems = [ "fuse" ];
}