{ config, pkgs, username, ... }:

{
  environment.systemPackages = with pkgs; [
    distrobox
    podman
  ];

  # 启用 Podman 服务
  virtualisation.podman = {
    enable = true;
    # 启用 rootless 模式（推荐，更安全）
    rootless = {
      enable = true;
      setNetworkNamespace = true;
    };
  };

  # 将用户加入相关组（可选，视需求而定）
  users.users.${username}.extraGroups = [ "podman" ];
}