{ config, pkgs, username, ... }:

{
  environment.systemPackages = with pkgs; [
    distrobox
    podman
    slirp4netns
    fuse-overlayfs
  ];

  # 启用 Podman 服务
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # 创建 docker 命令别名，方便兼容部分脚本
      dockerCompat = true;
      # 启用 DNS 支持（容器间通信推荐）
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # 将用户加入相关组（可选，视需求而定）
  users.users.${username}.extraGroups = [ "podman" ];
}