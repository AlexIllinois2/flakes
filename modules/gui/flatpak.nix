{ config, pkgs, lib, ... }:

{
  services.flatpak.enable = true;

  systemd.services.flatpak-mirror = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak pkgs.wget ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub
      
      # 导入 GPG 密钥以防验证失败
      wget -qO /tmp/flathub.gpg https://mirror.sjtu.edu.cn/flathub/flathub.gpg
      flatpak remote-modify --gpg-import=/tmp/flathub.gpg flathub
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
