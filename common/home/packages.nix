{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development
    vscode
    git

    # Terminal
    tmux
    fzf
    bat

    # Applications
    firefox
    chromium

    # Add a custom script to restart polybar
    (writeScriptBin "restart-polybar" ''
      #!${pkgs.bash}/bin/bash
      echo "Killing existing polybar instances..."
      killall -q polybar
      
      echo "Waiting for processes to shut down..."
      while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
      
      echo "Starting polybar..."
      polybar -r main &
      
      echo "Polybar started. Check /tmp/polybar.log for details."
    '')
  ];
}
