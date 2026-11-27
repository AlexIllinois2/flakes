{ config, pkgs, ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      # 属性名 = Host 别名
      "github.com" = {
        hostname = "ssh.github.com";   # 对应 HostName
        port = 443;                      # 对应 Port
        user = "git";                    # GitHub over SSH 固定用户
        # 可选：显式指定密钥，避免 443 端口走错 key
        # identityFile = toString ~/.ssh/id_ed25519;
      };
    };
  };
}