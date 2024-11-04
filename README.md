# My NixOS Build

This repository contains configuration files to set up a customized NixOS system. Below are descriptions of each file and its purpose.

## Configuration Files

### default.nix
The main configuration file for setting up various aspects of the operating system, including boot loader settings, networking, time zone, graphical environment with i3 window manager, and package installations.
- **Boot Loader**: Uses `systemd-boot` for UEFI systems.
- **Networking**: Enables NetworkManager.
- **Time Zone & Locale**: Configured to UTC and en_US.UTF-8 respectively.
- **Graphics**: Disables PulseAudio and configures basic X11 with the i3 window manager and LightDM display manager.

### packages.nix
This file contains a list of system packages that will be installed on your NixOS system. It includes essential utilities, system tools, and applications like `vim`, `git`, `firefox`, etc.
- **Basic Utilities**: Includes `vim`, `wget`, `curl`, `htop`.
- **System Tools**: Adds `pciutils` and `usbutils`.
- **Applications**: Installs `firefox`.

### programs.nix
This file configures specific programs, such as bash shell aliases, git configurations, and tmux settings.
- **Bash Shell Aliases**: Sets up `ll` and `la` for listing files.
- **Git Configurations**: Specifies default branch name as "main" and enables rebase on pull.
- **Tmux Configuration**: Enables tmux with a shortcut key "a" and terminal type "screen-256color".

### configuration.nix
This file contains additional configurations specific to the environment, particularly for a virtual machine (VM). It includes VM-specific services such as `spice-vdagentd` and `qemuGuest`, and specifies filesystems.

## Usage

1. **Install NixOS**:
   - Boot into your installation medium.
   - Use `install.sh` to partition and format the disk, then install NixOS with the provided configurations.

2. **Update Configuration**:
   - Modify the configuration files (`default.nix`, `packages.nix`, etc.) as needed.
   - Apply changes by running `nixos-rebuild switch`.

3. **Access VM Services**:
   - Ensure that `spice-vdagentd` and `qemuGuest` services are enabled for VM functionality.

## Contributing

Feel free to contribute to this repository by submitting issues or pull requests with improvements, bug fixes, or additional configuration ideas!