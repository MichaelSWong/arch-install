# arch-install

A simple, automated Arch Linux installation script with LUKS encryption and Btrfs filesystem.
Table of Contents

1. [Introduction](#introduction)

2. [Features](#features)

3. [Prerequisites](#prerequisites)

4. [Usage](#usage)

5. [Configuration](#configuration)

6. [Notes and Warnings](#notes-and-warnings)

7. [Acknowledgments](#acknowledgments)

## Introduction

This script automates the installation of Arch Linux on a specified disk. It is designed for a simple, single-disk setup with a separate boot partition and an encrypted Btrfs root filesystem. The script is interactive, prompting the user for essential information such as usernames, passwords, and hostname.
Features

    Automated Partitioning: Creates a 1GiB FAT32 boot partition and a remaining Btrfs root partition.

    Full Disk Encryption: Uses cryptsetup with LUKS to encrypt the root partition.

    Secure Password Handling: Uses hidden input to prevent passwords from being displayed on the screen.

    Essential Package Installation: Installs base, base-devel, and other crucial packages for a minimal system.

    Grub Bootloader Configuration: Installs and configures Grub for UEFI boot with the necessary cryptdevice kernel parameters.

    User and Hostname Setup: Creates a user with sudo privileges and sets the system hostname.

    Network Configuration: Enables NetworkManager for easy network setup after boot.

## Prerequisites

    You must have the Arch Linux live environment booted on your target machine.

    Your target disk for installation is /dev/nvme0n1. This script will erase all data on this disk.

    A stable internet connection is required to download packages.

## Usage

    Boot into the Arch Linux live environment.

    Ensure you have an internet connection.

    Download the script from this repository using curl:
    curl -L https://github.com/your-username/arch-install/raw/main/arch-install.sh -o install.sh

    Make the script executable:
    chmod +x install.sh

    Run the script as the root user (default in the live environment):
    ./install.sh

    Follow the on-screen prompts to enter your desired username, passwords, hostname, and timezone.

    The script will complete the installation, unmount the filesystems, and reboot the machine.

## Configuration

### You can modify the script to fit your needs, such as:

    Disk: Change the DISK variable at the beginning of the script to your desired target disk.

    Packages: Edit the pacstrap command to add or remove packages from the base installation.

    User Groups: Adjust the groups a new user is added to in the useradd command.

    Hooks: Modify the mkinitcpio.conf hooks to include or remove kernel modules.

## Notes and Warnings

    DATA LOSS WARNING: This script will completely wipe all data on /dev/nvme0n1. Proceed with caution.

    UEFI Only: This script is configured for UEFI boot and will not work on BIOS/Legacy systems without modification.

    Manual Intervention: Some manual steps may be required post-installation depending on your specific hardware and desired setup (e.g., graphics drivers, desktop environment).

## Acknowledgments

This script is based on the official Arch Linux Installation Guide and best practices from the community.
