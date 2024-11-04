{
  description = "NixOS configuration with flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hardware, ... }: {
    nixosConfigurations = {
      vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./common/configuration
          ./hosts/vm/configuration.nix
          ./hosts/vm/hardware-configuration.nix
          ({ modulesPath, ... }: {
            imports = [
              "${modulesPath}/virtualisation/qemu-vm.nix"
            ];
            virtualisation = {
              memorySize = 2048;
              cores = 2;
              graphics = true;
              resolution = { x = 1920; y = 1080; };
            };
          })
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nixos = import ./common/home;
          }
        ];
      };
      
      rig = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./common/configuration
          ./hosts/rig/configuration.nix
          ./hosts/rig/hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nixos = import ./common/home;
          }
        ];
      };
      
      moon = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./common/configuration
          ./hosts/moon/configuration.nix
          ./hosts/moon/hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nixos = import ./common/home;
          }
        ];
      };
    };
  };
}
