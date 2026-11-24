{ config, pkgs, ... }: 

{
  boot.kernelModules = [ "kvm-intel" ];
}
