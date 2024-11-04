{ config, pkgs, ... }:

{
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "video" 
      "audio" 
    ];
    initialPassword = "changeme";
  };
}
