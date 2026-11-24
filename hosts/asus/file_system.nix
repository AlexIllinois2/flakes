{ config, pkgs, ... }: 

{
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/3537f3fb-91d9-46c2-93b5-5667952c28ed";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8221-1AE3";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/c2e337d2-ba0c-406d-8e2c-23c9c11668cf"; }
    ];
}
