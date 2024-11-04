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

# Help message
show_help() {
    echo "Usage: $0 [usb|iso]"
    echo
    echo "Commands:"
    echo "  usb    Create bootable USB with repository"
    echo "  iso    Create bootable ISO with repository"
    echo
    echo "Example:"
    echo "  $0 usb    # Create USB installation media"
    echo "  $0 iso    # Create ISO file"
}

# Function to unmount all partitions of a device
unmount_all() {
    local device=$1
    echo -e "${BLUE}Unmounting all partitions of ${device}...${NC}"
    mapfile -t mounted_parts < <(lsblk -nlo NAME,MOUNTPOINT | grep "^${device##*/}" | awk '$2 != "" {print $1}')
    
    for part in "${mounted_parts[@]}"; do
        echo "Unmounting /dev/$part..."
        umount "/dev/$part" 2>/dev/null || true
    done
}

# Function to create bootable USB
create_usb() {
    # List available USB devices
    echo -e "\n${BLUE}Available USB devices:${NC}"
    lsblk -d -o NAME,SIZE,TYPE,TRAN | grep "usb"

    # Ask for target device
    echo -e "\n${GREEN}Enter the target device (e.g., sdb):${NC}"
    read -r TARGET_DEVICE

    # Confirm
    echo -e "${RED}WARNING: This will erase all data on /dev/${TARGET_DEVICE}${NC}"
    echo -e "Are you sure you want to continue? (yes/no)"
    read -r CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo "Aborting."
        exit 1
    fi

    # Unmount all partitions
    unmount_all "/dev/${TARGET_DEVICE}"

    # Zero out the first few megabytes
    echo -e "${BLUE}Clearing partition table...${NC}"
    dd if=/dev/zero of="/dev/${TARGET_DEVICE}" bs=1M count=8
    sync

    # Create fresh GPT partition table
    echo -e "${BLUE}Creating fresh partition table...${NC}"
    parted "/dev/${TARGET_DEVICE}" mklabel gpt
    sync

    # Calculate sizes in MB
    ISO_SIZE=$(stat -c%s "$BASE_ISO")
    ISO_SIZE_MB=$((ISO_SIZE / 1024 / 1024 + 64))  # Add 64MB buffer
    TOTAL_SIZE_MB=$(lsblk -b "/dev/${TARGET_DEVICE}" -o SIZE | tail -n1)
    TOTAL_SIZE_MB=$((TOTAL_SIZE_MB / 1024 / 1024))
    REPO_SIZE_MB=$((TOTAL_SIZE_MB - ISO_SIZE_MB))

    # Create partitions
    echo -e "${BLUE}Creating partitions...${NC}"
    parted "/dev/${TARGET_DEVICE}" -- \
        mkpart primary 1MiB "${ISO_SIZE_MB}MiB" \
        mkpart primary "${ISO_SIZE_MB}MiB" 100%
    sync

    # Force kernel to reread partition table
    echo -e "${BLUE}Refreshing partition table...${NC}"
    partprobe "/dev/${TARGET_DEVICE}"
    sleep 2

    # Write ISO to first partition
    echo -e "${BLUE}Writing ISO to first partition...${NC}"
    dd if="$BASE_ISO" of="/dev/${TARGET_DEVICE}1" bs=4M status=progress
    sync

    # Format second partition
    echo -e "${BLUE}Formatting repository partition...${NC}"
    mkfs.vfat -F 32 "/dev/${TARGET_DEVICE}2"
    sync

    # Mount the repository partition
    MOUNT_POINT="/mnt/nixos-repo"
    mkdir -p "$MOUNT_POINT"
    mount "/dev/${TARGET_DEVICE}2" "$MOUNT_POINT"

    # Copy repository
    copy_repository "$MOUNT_POINT"

    # Cleanup
    sync
    umount "$MOUNT_POINT"
    rmdir "$MOUNT_POINT"
}

# Function to create bootable ISO
create_iso() {
    echo -e "${BLUE}Creating bootable ISO with repository...${NC}"

    # Create working directory
    WORK_DIR=$(mktemp -d)
    
    # Create nix expression for ISO
    cat > "$WORK_DIR/iso.nix" << 'EOF'
{ config, pkgs, lib, ... }:

{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> ];
  
  # Enable copying the NixOS channel
  isoImage.storeContents = [ pkgs.nixos-install-tools ];
  
  # Make the installer more useful
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];
  
  # Enable SSH if you want remote installation
  services.sshd.enable = true;
  
  # Copy our repository to the ISO
  isoImage.contents = [{
    source = ./nixos-config;
    target = "/nixos-config";
  }];
  
  # Customize ISO properties
  isoImage = {
    isoName = lib.mkForce "nixos-custom.iso";
    volumeID = lib.mkForce "NIXOS_CUSTOM";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
}
EOF

    # Create filtered copy of repository
    echo -e "${BLUE}Creating filtered copy of repository...${NC}"
    mkdir -p "$WORK_DIR/nixos-config"
    rsync -a --exclude='.git' \
             --exclude='*.qcow2' \
             --exclude='*.iso' \
             --exclude='result' \
             --exclude='*.swp' \
             --exclude='.DS_Store' \
             "$REPO_ROOT/" "$WORK_DIR/nixos-config/"

    # Create README
    cat > "$WORK_DIR/nixos-config/README.txt" << 'EOF'
NixOS Installation Instructions:

1. Boot from this media
2. Connect to the internet if needed:
   sudo systemctl start NetworkManager
   nmtui

3. The configuration repository is available at:
   /nixos-config

4. Follow the installation guide in the repository:
   cd /nixos-config
   ./scripts/install-guide.sh
EOF

    # Build the ISO
    echo -e "${BLUE}Building custom NixOS ISO...${NC}"
    cd "$WORK_DIR"
    nix-build '<nixpkgs/nixos>' \
        -A config.system.build.isoImage \
        -I nixos-config=./iso.nix

    # Copy the result
    echo -e "${BLUE}Copying ISO to repository...${NC}"
    cp result/iso/nixos-custom.iso "$REPO_ROOT/"

    # Cleanup
    rm -rf "$WORK_DIR"

    echo -e "${GREEN}ISO created successfully: nixos-custom.iso${NC}"
    echo -e "The repository is available at /nixos-config when booting from the ISO"
}

# Function to copy repository
copy_repository() {
    local target_dir=$1
    
    # Create temporary directory for filtered repository
    TEMP_DIR=$(mktemp -d)
    echo -e "${BLUE}Creating filtered copy of repository...${NC}"

    # Copy repository with exclusions
    rsync -a --exclude='.git' \
             --exclude='*.qcow2' \
             --exclude='*.iso' \
             --exclude='result' \
             --exclude='*.swp' \
             --exclude='.DS_Store' \
             "$REPO_ROOT/" "$TEMP_DIR/nixos-config/"

    # Copy filtered repository to target
    echo -e "${BLUE}Copying repository...${NC}"
    cp -r "$TEMP_DIR/nixos-config" "$target_dir/"

    # Create README
    cat > "$target_dir/README.txt" << 'EOF'
NixOS Installation Instructions:

1. Boot from this media
2. Connect to the internet if needed:
   sudo systemctl start NetworkManager
   nmtui

3. The configuration repository is available at:
   /run/media/nixos/NIXOS_REPO/nixos-config

4. Follow the installation guide in the repository:
   cd /run/media/nixos/NIXOS_REPO/nixos-config
   ./scripts/install-guide.sh
EOF

    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Check dependencies
check_dependencies() {
    local deps=()
    case "$1" in
        "usb")
            deps=(wget parted mkfs.vfat rsync)
            ;;
        "iso")
            deps=(nix-build rsync)
            ;;
    esac

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}$cmd is required but not installed${NC}"
            exit 1
        fi
    done
}

# Main script logic
main() {
    # Show help if no arguments provided
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi

    # Check if running as root (only needed for USB creation)
    if [ "$1" = "usb" ] && [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root for USB creation${NC}"
        exit 1
    fi

    # Check dependencies
    check_dependencies "$1"

    # Process command
    case "$1" in
        "usb")
            create_usb
            ;;
        "iso")
            create_iso
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"
