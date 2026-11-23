{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    zsh zsh-completions fzf
  ];
  
  users.defaultUserShell = pkgs.zsh;
  
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
}
