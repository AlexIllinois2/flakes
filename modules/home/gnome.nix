{ config, pkgs, ... }: 

{
  # 注意：不要用 programs.gnome-shell.extensions。
  # 只要它非空，home-manager 每次 switch 都会用一份固定列表覆盖
  # org/gnome/shell.enabled-extensions，手动启用的扩展会被一并关闭
  # （appindicator 等未列入该列表的扩展同样会被关）。
  # 这里只负责把扩展包装进来，启用状态交给 GNOME 自己维护。
  home.packages = with pkgs.gnomeExtensions; [
    net-speed-simplified
    just-perfection
    gsconnect
  ];

  # 与系统级 modules/gui/gnome.nix 保持一致，确保用户扩展不会被整体禁用。
  dconf.settings."org/gnome/shell".disable-user-extensions = false;

  dconf.enable = true;

  # 导出 GNOME 键盘设置
  # dconf dump / | dconf2nix > gnome-keys.nix
  # dconf dump /org/gnome/settings-daemon/plugins/media-keys/ | nix run nixpkgs#dconf2nix
}
