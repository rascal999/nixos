{ config, pkgs, lib, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
  ];

  networking.hostName = "vm";

  # VM-specific settings
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation = {
    diskImage = "/dev/null";
    mountHostNixStore = false;
    sharedDirectories = lib.mkForce { };
    useDefaultFilesystems = false;
    fileSystems."/" = {
      fsType = "tmpfs";
      options = ["mode=0755"];
    };
  };
}
