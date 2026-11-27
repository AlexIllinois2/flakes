{ config, pkgs, username, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;  # 完整版，含 git-svn、git-p4 等工具

    settings = {
      user = {
        name  = "${username}";
        email = "${username}";
      };

      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      push = {
        autoSetupRemote = true;
      };

      core = {
        editor = "vim";
      };
      
      url."git@github.com:".insteadOf = "https://github.com/";
    };
    
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
  };
}