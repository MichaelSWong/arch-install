#!/bin/bash

# ==============================================================================
# Arch Linux Automated Installation Script with LUKS Encryption and Btrfs
# ==============================================================================
# This script automates the installation of Arch Linux on a specified disk.
# It assumes you have booted into the Arch Linux live environment.
#
# Before running:
# - Ensure the target disk is correct (/dev/nvme0n1).
# - Verify that you have a working internet connection.
#
# NOTE: This script will WIPE all data on /dev/nvme0n1.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- STEP 1: GATHER USER INPUT ---
# Using `read -s` for passwords to prevent them from being displayed.
echo "--------------------------------------------------------------------------------"
echo "                    -@                "
echo "                   .##@               "
echo "                  .####@              "
echo "                  @#####@             "
echo "                . *######@            "
echo "               .##@o@#####@           "
echo "              /############@          "
echo "             /##############@         "
echo "            @######@* *%######@        "
echo "           @######@      %#####o       "
echo "          @######@       ######%      "
echo "        -@#######h       ######@.    "
echo "       /#####h**``        **%@####@   "
echo "      @H@*`                    `*%#@  "
echo "     *`                            `* "
echo "--------------------------------------------------------------------------------"

echo -e "\nEnter username to be created:"
read user

# Function to handle password confirmation
function set_password() {
    local prompt_msg=$1
    local password_var=$2
    local password_confirm_var=$3

    while true; do
        echo -e "\n${prompt_msg}"
        read -s ${password_var}
        echo -e "\nPlease re-enter the password to confirm:"
        read -s ${password_confirm_var}

        if [[ "${!password_var}" == "${!password_confirm_var}" ]]; then
            break
        else
            echo -e "\nPasswords do not match. Please try again."
        fi
    done
}

set_password "Enter new password for $user:" uspw uspw_confirm
set_password "Enter new password for root:" rtpw rtpw_confirm

echo -e "\nEnter new hostname (e.g., arch-pc):"
read host

echo -e "\nEnter desired timezone in format of Country/Region (e.g., America/Los_Angeles):"
read tmzn

# Get number of cores for parallel downloads
while true; do
    echo -e "\nEnter the number of CPU cores for parallel downloads (e.g., 8):"
    read cores
    if [[ "$cores" =~ ^[0-9]+$ ]]; then
        break
    else
        echo -e "\nInvalid input. Please enter a positive integer."
    fi
done

# --- STEP 1.2: Linux Kernel ---
echo "--------------------------------------------------------------------------------"
while true; do
    echo -e "\nWhich Linux Kernel do you want to install?"
    echo "1) Stable (linux)"
    echo "2) Hardened (linux-hardened)"
    echo "3) Longterm (linux-lts)"
    echo "4) Zen (linux-zen)"
    read -p "Enter 1, 2, 3, or 4: " choice

    case "$choice" in
        1)
            linux_packages="linux linux-headers"
            echo "Stable Kernel selected."
            break
            ;;
        2)
            linux_packages="linux-hardened linux-hardened-headers"
            echo "Hardened Kernel selected."
            break
            ;;
        3)
            linux_packages="linux-lts linux-lts-headers"
            echo "LTS Kernel selected."
            break
            ;;
        4)
            linux_packages="linux-zen linux-zen-headers"
            echo "Zen Kernel selected."
            break
            ;;
        *)
            echo "Invalid input. Please enter '1', '2', '3', or '4'."
            ;;
    esac
done

# --- STEP 1.3: NVIDIA DRIVER SELECTION (if applicable) ---
echo "--------------------------------------------------------------------------------"
echo "Checking for NVIDIA GPU..."

# Use lspci to check for a device with "NVIDIA" in its name
if lspci | grep -q "NVIDIA"; then
    echo "NVIDIA GPU detected! 🚀"
    
    # Initialize an empty variable to add NVIDIA packages to
    nvidia_packages=""

    while true; do
        echo -e "\nWhich NVIDIA driver do you want to install?"
        echo "1) Proprietary (Non-DKMS) - For the 'stable' kernel."
        echo "2) Proprietary (DKMS) - For any kernel, especially custom ones like Zen."
        echo "3) Proprietary (Open) - Newer driver for some RTX cards on the 'stable' kernel."
        echo "4) Proprietary (Open-DKMS) - Newer driver for some RTX cards on any kernel."
        read -p "Enter 1, 2, 3, or 4: " choice
        
        case "$choice" in
            1)
                nvidia_packages="nvidia"
                echo "Proprietary (Non-DKMS) drivers selected."
                break
                ;;
            2)
                nvidia_packages="nvidia-dkms"
                echo "Proprietary (DKMS) drivers selected."
                break
                ;;
            3)
                nvidia_packages="nvidia-open"
                echo "Proprietary (Open) drivers selected."
                break
                ;;
            4)
                nvidia_packages="nvidia-open-dkms"
                echo "Proprietary (Open-DKMS) drivers selected."
                break
                ;;
            *)
                echo "Invalid input. Please enter '1', '2', '3', or '4'."
                ;;
        esac
    done
else
    echo "No NVIDIA GPU detected. Skipping driver installation."
    nvidia_packages=""
fi

echo -e "\nInput gathered. Starting installation...\n"

# --- STEP 2: LOAD KEYBOARD LAYOUT ---
# Assuming a US keyboard layout for the live environment.
echo "Loading keyboard layout..."
loadkeys us

# --- STEP 3: WIPE DISK AND FORMAT PARTITIONS ---
# This step will destroy all data on the target disk.
DISK="/dev/nvme0n1"
BOOT_PARTITION="${DISK}p1"
ROOT_PARTITION="${DISK}p2"

echo "Wiping and re-partitioning disk: ${DISK}..."
# Clear any existing partition tables
sgdisk --zap-all "${DISK}"

# Create a new GPT partition table
parted -s "${DISK}" mklabel gpt

# Create a 1GB boot partition (FAT32)
parted -s "${DISK}" mkpart primary fat32 1MiB 1025MiB
parted -s "${DISK}" set 1 esp on

# Create a second partition for the encrypted root (Btrfs)
parted -s "${DISK}" mkpart primary btrfs 1025MiB 100%

# Format the boot partition
echo "Formatting boot partition: ${BOOT_PARTITION}"
mkfs.fat -F 32 "${BOOT_PARTITION}"

# Encrypt the root partition using LUKS
echo "Encrypting root partition: ${ROOT_PARTITION}"
echo -n "${rtpw}" | cryptsetup --verify-passphrase -v luksFormat "${ROOT_PARTITION}"

# Open the encrypted partition
echo "Opening encrypted partition as 'cryptroot'..."
echo -n "${rtpw}" | cryptsetup luksOpen "${ROOT_PARTITION}" cryptroot

# Format the opened LUKS container with Btrfs
echo "Formatting the LUKS container with Btrfs..."
mkfs.btrfs -f /dev/mapper/cryptroot

# --- STEP 4: MOUNT DISKS ---
echo "Mounting partitions..."
mount /dev/mapper/cryptroot /mnt

# Create the boot directory and mount the boot partition
mkdir -p /mnt/boot
mount "${BOOT_PARTITION}" /mnt/boot

# --- STEP 5: ARCH INSTALL ---
echo "Updating pacman configuration for faster downloads..."
# Change ParallelDownloads setting to user-specified number of cores.
sed -i "s/^#*ParallelDownloads = 5$/ParallelDownloads = ${cores}/" /etc/pacman.conf

echo "Installing base system and essential packages..."
pacstrap /mnt base base-devel vim networkmanager git cryptsetup grub efibootmgr $linux_kernel btrfs-progs $nvidia_packages

echo "Generating fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- STEP 6: SET UP SYSTEM INSIDE CHROOT ---
echo "Entering arch-chroot to configure the new system..."
# Use a here-document to execute a series of commands inside the chroot environment.
arch-chroot /mnt <<EOF
    # Set timezone
    echo "Setting timezone to ${tmzn}..."
    ln -sf /usr/share/zoneinfo/${tmzn} /etc/localtime
    hwclock --systohc

    # Set locale
    echo "Setting locale..."
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    # Set hostname
    echo "Setting hostname..."
    echo "${host}" > /etc/hostname

    # Add hosts entries
    echo "127.0.0.1   localhost" >> /etc/hosts
    echo "::1         localhost" >> /etc/hosts
    echo "127.0.1.1   ${host}.localdomain ${host}" >> /etc/hosts

    # Set root password
    echo "Setting root password..."
    echo -e "${rtpw}\n${rtpw}" | passwd root

    # Add new user
    echo "Adding user ${user} and setting their password..."
    useradd -m -G wheel,storage,video,audio -s /bin/bash "${user}"
    echo -e "${uspw}\n${uspw}" | passwd "${user}"
    
    # Configure sudo for the 'wheel' group
    echo "Configuring sudo for the 'wheel' group..."
    echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

    # Enable autologin on tty1 using a systemd override file
    echo "Enabling autologin for user '${user}' on tty1..."
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    echo "[Service]" >> /etc/systemd/system/getty@tty1.service.d/override.conf
    echo "ExecStart=" >> /etc/systemd/system/getty@tty1.service.d/override.conf
    echo "ExecStart=-/sbin/agetty -a ${user} --noclear %I ${TERM}" >> /etc/systemd/system/getty@tty1.service.d/override.conf
    echo "TTYVTDisallocate=no" >> /etc/systemd/system/getty@tty1.service.d/override.conf
EOF

# --- STEP 7: INITCPIO & GRUB ---
echo "Configuring mkinitcpio..."
# Update HOOKS in mkinitcpio.conf
# Note: The 'btrfs' hook is needed to handle the btrfs filesystem. It must come after 'encrypt'.
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck)/' /mnt/etc/mkinitcpio.conf

echo "Generating initramfs images..."
arch-chroot /mnt mkinitcpio -P

echo "Installing GRUB bootloader..."
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

echo "Getting LUKS partition UUID..."
# Get the UUID of the LUKS partition for grub config
LUKS_UUID=$(blkid -s UUID -o value "${ROOT_PARTITION}")

echo "Configuring GRUB..."
# Add the cryptdevice hook to grub
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${LUKS_UUID}:cryptroot root=\/dev\/mapper\/cryptroot /" /mnt/etc/default/grub

# Generate grub config file
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# --- STEP 8: ENABLE NETWORKMANAGER ---
echo "Enabling NetworkManager service..."
arch-chroot /mnt systemctl enable NetworkManager

echo "Installation complete! Unmounting filesystems and rebooting..."
# Cleanup
umount -R /mnt
reboot
