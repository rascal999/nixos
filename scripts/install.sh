#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to list available disks
list_disks() {
    echo "Available disks:"
    lsblk -d -n -o NAME,SIZE,TYPE | grep disk
}

# Check if a disk is provided as an argument
if [ -z "$1" ]; then
    echo "No disk specified. Please choose from the available disks:"
    list_disks
    read -p "Enter the disk to install NixOS on (e.g., /dev/sda): " DISK
else
    DISK="$1"
fi

# Check if any partitions on the disk are in use
if lsblk -n -o MOUNTPOINT ${DISK}* | grep -q '/'; then
    echo "Warning: Partition(s) on $DISK are being used."
    read -p "Do you want to ignore this warning and continue? (ignore/cancel): " RESPONSE
    if [ "$RESPONSE" != "ignore" ]; then
        echo "Installation cancelled."
        exit 1
    fi

    # Attempt to unmount partitions
    for PART in $(lsblk -n -o NAME,MOUNTPOINT ${DISK}* | awk '$2 != "/" {print $1}'); do
        umount "/dev/$PART" || true
    done
fi

# Confirm the selected disk
echo "You have selected $DISK as the target disk."
read -p "Are you sure you want to continue? This will erase all data on $DISK. (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Installation aborted."
    exit 1
fi

# Variables
HOSTNAME="nixos"
TIMEZONE="UTC"
LOCALE="en_US.UTF-8"

# Partition the disk
parted $DISK -- mklabel gpt
parted $DISK -- mkpart primary 512MiB 100%
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 2 boot on

# Format the partitions
mkfs.ext4 -L nixos ${DISK}1
mkfs.fat -F 32 -n boot ${DISK}2

# Mount the file systems
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Generate the NixOS configuration
nixos-generate-config --root /mnt

# Modify the configuration.nix file
cat <<EOF > /mnt/etc/nixos/configuration.nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "$HOSTNAME";

  time.timeZone = "$TIMEZONE";
  i18n.defaultLocale = "$LOCALE";

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "changeme";
  };

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.windowManager.i3.enable = true;

  environment.systemPackages = with pkgs; [
    vim wget git curl htop
  ];

  system.stateVersion = "23.11"; # Update this to match your NixOS version
}
EOF

# Install NixOS
nixos-install

# Set root password
echo "Set root password"
passwd

# Reboot
echo "Installation complete. Rebooting..."
reboot
