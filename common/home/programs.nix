{ config, pkgs, ... }:

{
  programs = {
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
      };
    };

    git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };

    tmux = {
      enable = true;
      shortcut = "a";
      terminal = "screen-256color";
    };
  };
}
