{ config, pkgs, ... }:

{
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";

  home.packages = with pkgs; [
    # Development
    vscode
    git
    docker-compose

    # Terminal
    tmux
    fzf
    bat
    exa
    zoxide
    
    # Applications
    firefox
    chromium
    vlc
  ];

  programs = {
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch --flake .#moon";
        cd = "z";  # Using zoxide for smart directory jumping
      };
      initExtra = ''
        eval "$(zoxide init bash)"
      '';
    };

    git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.email@example.com";
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

  # Enable direnv for per-directory environment variables
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
