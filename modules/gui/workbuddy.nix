{ pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage ../pkgs/workbuddy.nix { })
  ];
}
