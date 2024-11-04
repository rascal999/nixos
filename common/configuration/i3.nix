{ config, pkgs, ... }:

{
  services.xserver = {
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
        polybar
      ];
    };
  };

  # Additional packages useful for i3
  environment.systemPackages = with pkgs; [
    # Terminal emulator
    alacritty

    # System tray
    networkmanagerapplet
    pasystray  # PulseAudio system tray

    # Screen management
    arandr
    autorandr

    # File manager
    pcmanfm

    # Screenshot
    flameshot

    # Notifications
    dunst
    libnotify
  ];
}
