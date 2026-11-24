{ config, pkgs, ... }: 

{
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  # services.ibinput.enable = true;
}
