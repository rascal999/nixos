{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Basic utilities
    vim
    wget
    git
    curl
    htop
    ripgrep
    fd
    tree

    # System tools
    pciutils
    usbutils

    # Applications
    firefox
  ];
}
