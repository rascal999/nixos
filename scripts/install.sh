#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to list available disks
list_disks() {
    echo -e "${BLUE}Available disks:${NC}"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
}

# Function to unmount any mounted partitions on the target disk
unmount_partitions() {
    local device=$1
    echo -e "${BLUE}Unmounting any mounted partitions on /dev/${device}...${NC}"
    for partition in $(lsblk -ln -o NAME "/dev/${device}" | tail -n +2); do
        umount "/dev/${partition}" 2>/dev/null || true
    done
}

# Function to create standard partitions
create_standard_partitions() {
    local device=$1
    
    # Unmount any existing partitions
    unmount_partitions "$device"
    
    # Clear existing filesystem signatures
    echo -e "${BLUE}Wiping existing filesystem signatures on /dev/${device}...${NC}"
    wipefs -a "/dev/${device}"
    
    echo -e "${BLUE}Creating standard partitions on ${device}...${NC}"
    
    # Create partitions
    parted "/dev/${device}" -- mklabel gpt
    parted "/dev/${device}" -- mkpart ESP fat32 1MiB 512MiB
    parted "/dev/${device}" -- set 1 esp on
    parted "/dev/${device}" -- mkpart primary 512MiB 100%
    
    # Force kernel to reread partition table
    sync
    partprobe "/dev/${device}"
    sleep 2
    
    # Format partitions
    mkfs.fat -F 32 -n boot "/dev/${device}1"
    mkfs.ext4 -L nixos "/dev/${device}2"
    
    # Mount partitions
    mount "/dev/${device}2" /mnt
    mkdir -p /mnt/boot
    mount "/dev/${device}1" /mnt/boot
}

# Function to copy configuration to the target system
copy_configuration() {
    local source_dir=$1
    local target_dir=$2
    
    echo -e "${BLUE}Copying configuration to target system...${NC}"
    
    # Use nix-shell to ensure rsync is available
    nix-shell -p rsync --run "rsync -av --exclude '/mnt' '$source_dir/' '$target_dir/'"
}

# Main installation function
install_nixos() {
    local host=$1
    local device=$2
    
    # Create partitions
    create_standard_partitions "$device"
    
    # Generate hardware configuration
    echo -e "${BLUE}Generating hardware configuration...${NC}"
    nixos-generate-config --root /mnt
    
    # Copy the repository to the target system
    copy_configuration "$REPO_ROOT" /mnt/etc/nixos/config
    
    # Install NixOS
    echo -e "${BLUE}Installing NixOS...${NC}"
    nixos-install --root /mnt --flake "/mnt/etc/nixos/config#${host}" --no-root-passwd --show-trace
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# List available disks
list_disks

# Get target disk
echo -e "\n${GREEN}Enter the target disk (e.g., sda):${NC}"
read -r TARGET_DISK

# Confirm disk selection
echo -e "${RED}WARNING: This will erase all data on /dev/${TARGET_DISK}${NC}"
echo -e "Are you sure you want to continue? (yes/no)"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborting."
    exit 1
fi

# Install NixOS
install_nixos "your-host-name" "$TARGET_DISK"