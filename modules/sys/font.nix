{ config, pkgs, ... }: 

{
  environment.systemPackages = with pkgs; [
    nerd-fonts.sauce-code-pro
  ];
}
