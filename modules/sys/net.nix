{ config, pkgs, ... }: 

{
  networking = {
    hostName = "nixos";
    nameservers = [ "119.29.29.29" "182.254.116.116" "114.114.114.114" ];

    networkmanager = {
      enable = true;
      dns = "none";          
    };

    # useDHCP = false;
    # dhcpcd.enable = false;

    # wireless.enable = true;
  };
  
  services.resolved.enable = false;  # 别让 resolved 再插一脚
}
