{ config, pkgs, ... }:

{
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";

  imports = [
    ./packages.nix
    ./programs.nix
    ./i3.nix
  ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
