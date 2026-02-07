#!/usr/bin/env bash
# curl -fsSL https://raw.githubusercontent.com/puyonexus/puyonexus/refs/heads/master/install-here.sh | sudo bash -s -- [--branch <branch>]

set -euo pipefail

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root" >&2
#    exit 1
fi

# Default values
BRANCH="master"
CONFIG="hz-ojama-staging"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--branch <branch>]" >&2
            exit 1
            ;;
    esac
done

# Warn user
echo "WARNING: This script will wipe the disk and install the Puyo Nexus base setup to *this machine*."
echo "Now would be a very good time to double check what terminal you're running this on."
echo "Branch: $BRANCH"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r </dev/tty
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Aborted."
    exit 0
fi

# Why is this ever needed?
modprobe ext4

# Download disko configuration
echo "Downloading disko.nix from branch $BRANCH..."
DISKO_URL="https://raw.githubusercontent.com/puyonexus/puyonexus/refs/heads/${BRANCH}/modules/disko.nix"
curl -fsSL "$DISKO_URL" -o /tmp/disko.nix

# Run disko
echo "Running disko to partition and format disks..."
nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --yes-wipe-all-disks /tmp/disko.nix

# Install base configuration
echo "Installing base NixOS configuration..."
nixos-install --flake "github:puyonexus/puyonexus/${BRANCH}#base" --no-root-password

echo ""
echo "Installation complete! You can now reboot into Puyo Nexus."
echo "Remember to unmount the installation media before rebooting."
