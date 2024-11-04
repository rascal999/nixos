{ config, pkgs, ... }:

{
  imports = [
    ./users.nix
    ./packages.nix
    ./i3.nix
  ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Time zone and internationalisation
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Sound
  hardware.pulseaudio.enable = false;

  # Basic X11 configuration
  services = {
    displayManager.defaultSession = "none+i3";

    xserver = {
      enable = true;
      xkb.layout = "us";
    
      # OpenGL
      videoDrivers = [ "modesetting" ];

      # Default to lightdm
      displayManager.lightdm.enable = true;
    };
  };

  hardware.graphics = {
    enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.11";
}
