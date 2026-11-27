{ config, pkgs, username, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;  # 完整版，含 git-svn、git-p4 等工具
    userName = "${username}";
    userEmail = "${username}";
    
    # 默认分支名
    extraConfig.init.defaultBranch = "main";
    
    # 全局忽略规则
    ignores = [
      "*~"
      "*.swp"
      ".DS_Store"
      "result"        # nix build 的产物
      "result-*"
    ];
    
    # aliases = {
    #   st = "status";
    # };
    
    # 额外配置（直接写入 .gitconfig 的任意段）
    extraConfig = {
      pull.rebase = false;
      push.autoSetupRemote = true;
      core.editor = "vim";

    };
    url."git@github.com:".insteadOf = [ "https://github.com/" ];
  };
}