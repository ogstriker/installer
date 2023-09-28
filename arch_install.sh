#!/bin/bash
# and configures systemd as the init system (removing sysvinit).
#
# You should read through this script before running it in case you want to
# make any modifications, in particular, the variables just below, and the
# following functions:
#
#    install_packages - Customize packages installed in base system
#                       (desktop environment, etc.)
#    install_aur_packages - More packages after packer (AUR helper) is
#                           installed
#    set_netcfg - Preload netcfg profiles

## CONFIGURE THESE VARIABLES
## ALSO LOOK AT THE install_packages FUNCTION TO SEE WHAT IS ACTUALLY INSTALLED

# Drive to install to.
#DRIVE='/dev/sda'

# Hostname of the installed machine.
HOSTNAME='strikerhost'

# Encrypt everything (except /boot).  Leave blank to disable.
#ENCRYPT_DRIVE='TRUE'

# Passphrase used to encrypt the drive (leave blank to be prompted).
#DRIVE_PASSPHRASE='a'

# Root password (leave blank to be prompted).
ROOT_PASSWORD=''

# Main user to create (by default, added to wheel group, and others).
USER_NAME='striker'

# The main user's password (leave blank to be prompted).
USER_PASSWORD=''

# System timezone.
TIMEZONE='America/Montevideo'

# Have /tmp on a tmpfs or not.  Leave blank to disable.
# Only leave this blank on systems with very little RAM.
TMP_ON_TMPFS='TRUE'

KEYMAP='us'
# KEYMAP='dvorak'

# Choose your video driver
# For Intel
#VIDEO_DRIVER="i915"
# For nVidia
#VIDEO_DRIVER="nouveau"
# For ATI
#VIDEO_DRIVER="radeon"
# For generic stuff
#VIDEO_DRIVER="vesa"

# Wireless device, leave blank to not use wireless and use DHCP instead.
WIRELESS_DEVICE="wlan0"
# For tc4200's
#WIRELESS_DEVICE="eth1"

setup() {
    echo 'Installing base system'
    install_base

    echo 'Chrooting into installed system to continue setup...'
    cp $0 /mnt/setup.sh
    arch-chroot /mnt ./setup.sh chroot

    if [ -f /mnt/setup.sh ]
    then
        echo 'ERROR: Something failed inside the chroot, not unmounting filesystems so you can investigate.'
        echo 'Make sure you unmount everything before you try to run this script again.'
    else
        echo 'Unmounting filesystems'
        unmount_filesystems
        echo 'Done! Reboot system.'
    fi
}

configure() {

    echo 'Installing additional packages'
    install_packages

#    echo 'Installing AUR packages'
#    install_aur_packages

    echo 'Clearing package tarballs'
    clean_packages

#    echo 'Updating pkgfile database'
#    update_pkgfile

    echo 'Setting hostname'
    set_hostname "$HOSTNAME"

    echo 'Setting timezone'
    set_timezone "$TIMEZONE"

    echo 'Setting locale'
    set_locale

    echo 'Setting console keymap'
    set_keymap

    echo 'Setting hosts file'
    set_hosts "$HOSTNAME"

#    echo 'Setting fstab'
#    set_fstab "$TMP_ON_TMPFS" "$boot_dev"

#    echo 'Setting initial modules to load'
#    set_modules_load

    echo 'Configuring bootloader'
    grub_bootloader

#    echo 'Configuring initial ramdisk'
#    set_initcpio

#    echo 'Setting initial daemons'
#    set_daemons "$TMP_ON_TMPFS"

    echo 'Configuring sudo'
    set_sudoers

#    if [ -n "$WIRELESS_DEVICE" ]
#    then
#        echo 'Configuring netcfg'
#        set_netcfg
#    fi

    if [ -z "$ROOT_PASSWORD" ]
    then
        echo 'Enter the root password:'
        stty -echo
        read ROOT_PASSWORD
        stty echo
    fi
    echo 'Setting root password'
    set_root_password "$ROOT_PASSWORD"

    if [ -z "$USER_PASSWORD" ]
    then
        echo "Enter the password for user $USER_NAME"
        stty -echo
        read USER_PASSWORD
        stty echo
    fi
    echo 'Creating initial user'
    create_user "$USER_NAME" "$USER_PASSWORD"

#    echo 'Building locate database'
#    update_locate

    rm /setup.sh
}

install_base() {
    echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

    pacstrap /mnt base base-devel
}

unmount_filesystems() {
    umount -R /mnt/boot/EFI
    umount -R /mnt
}

install_packages() {
    local packages=''
#
    # General utilities/libraries
#    packages+=' alsa-utils aspell-en chromium cpupower gvim mlocate net-tools ntp openssh p7zip pkgfile powertop python3 rfkill rsync sudo unrar unzip wget zip systemd-sysvcompat zsh'

# DPS CONFIGURAR O OH-MY-ZSH

    # Development packages
#    packages+=' cmake gdb git maven tcpdump '

    # Netcfg
    if [ -n "$WIRELESS_DEVICE" ]
    then
        packages+='dialog wireless_tools wpa_supplicant'
    fi

    # Java stuff
    packages+=' jdk17-openjdk jre17-openjdk'

    # Libreoffice
#    packages+=' libreoffice-calc libreoffice-en-US'

    # Misc programs
    packages+=' firefox vlc gparted wget jdk8-openjdk unrar qemu-desktop virt-manager zenity steam zsh qbittorrent htop python-pip corectrl spotify intellij-idea-community-edition ncdu discord firejail telegram-desktop ntfs-3g windscribe-bin noto-fonts-emoji minecraft-launcher bash-completion kdenlive'

    # Plasma Desktop
    packages+=' plasma plasma-wayland-session packagekit-qt5'

    # Xserver
    packages+=' xorg-apps xorg-server xorg-xinit xterm'

    # Sddm login manager
    packages+=' sddm'

    # Fonts
    packages+=' ttf-dejavu ttf-liberation noto-fonts-emoji'

    # For laptops
    packages+=' xf86-input-synaptics'

    # Extra packages for tc4200 tablet
    #packages+=' ipw2200-fw xf86-input-wacom'

    pacman -Sy --noconfirm $packages
}

#install_yay() {
 #   mkdir -p /foo
#    cd /foo
#    git clone https://aur.archlinux.org/yay.git
#    cd yay
#    makepkg -si --noconfirm
#
#    cd /
#    rm -rf /foo
#}

#install_aur_packages() {
#    mkdir /foo
#    export TMPDIR=/foo
#    yay -S --noconfirm lightly-git
#    yay -S --noconfirm q4wine-git
#    yay -S --noconfirm appimagelauncher
#    unset TMPDIR
#    rm -rf /foo
#}

clean_packages() {
    yes | pacman -Scc
}

#update_pkgfile() {
#    pkgfile -u
#}

grub_bootloader() {
    grub-install --target=x86_64-efi --bootloader-id="Striker's Arch Linux" --recheck

    grub-mkconfig -o /boot/grub/grub.cfg
}

set_hostname() {
    local hostname="$1"; shift

    echo "$hostname" > /etc/hostname
}

set_timezone() {
    local timezone="$1"; shift

    ln -sTf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
}

set_locale() {
    echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
    echo 'LC_COLLATE="C"' >> /etc/locale.conf
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
}

set_keymap() {
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
}

set_hosts() {
    local hostname="$1"; shift

    cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost $hostname
::1       localhost.localdomain localhost $hostname
EOF
}

set_fstab() {
genfstab -U /mnt

}

set_daemons() {
    local tmp_on_tmpfs="$1"; shift

    systemctl enable cpupower.service

    if [ -n "$WIRELESS_DEVICE" ]
    then
        systemctl enable NetworkManager
    fi
    
    if [ -z "$tmp_on_tmpfs" ]
    then
        systemctl mask tmp.mount
    fi
}

set_sudoers() {
    cat > /etc/sudoers <<EOF
## sudoers file.
##
## This file MUST be edited with the 'visudo' command as root.
## Failure to use 'visudo' may result in syntax or file permission errors
## that prevent sudo from running.
##
## See the sudoers man page for the details on how to write a sudoers file.
##

##
## Host alias specification
##
## Groups of machines. These may include host names (optionally with wildcards),
## IP addresses, network numbers or netgroups.
# Host_Alias	WEBSERVERS = www1, www2, www3

##
## User alias specification
##
## Groups of users.  These may consist of user names, uids, Unix groups,
## or netgroups.
# User_Alias	ADMINS = millert, dowdy, mikef

##
## Cmnd alias specification
##
## Groups of commands.  Often used to group related commands together.
# Cmnd_Alias	PROCESSES = /usr/bin/nice, /bin/kill, /usr/bin/renice, \
# 			    /usr/bin/pkill, /usr/bin/top

##
## Defaults specification
##
## You may wish to keep some of the following environment variables
## when running commands via sudo.
##
## Locale settings
# Defaults env_keep += "LANG LANGUAGE LINGUAS LC_* _XKB_CHARSET"
##
## Run X applications through sudo; HOME is used to find the
## .Xauthority file.  Note that other programs use HOME to find   
## configuration files and this may lead to privilege escalation!
# Defaults env_keep += "HOME"
##
## X11 resource path settings
# Defaults env_keep += "XAPPLRESDIR XFILESEARCHPATH XUSERFILESEARCHPATH"
##
## Desktop path settings
# Defaults env_keep += "QTDIR KDEDIR"
##
## Allow sudo-run commands to inherit the callers' ConsoleKit session
# Defaults env_keep += "XDG_SESSION_COOKIE"
##
## Uncomment to enable special input methods.  Care should be taken as
## this may allow users to subvert the command being run via sudo.
# Defaults env_keep += "XMODIFIERS GTK_IM_MODULE QT_IM_MODULE QT_IM_SWITCHER"
##
## Uncomment to enable logging of a command's output, except for
## sudoreplay and reboot.  Use sudoreplay to play back logged sessions.
# Defaults log_output
# Defaults!/usr/bin/sudoreplay !log_output
# Defaults!/usr/local/bin/sudoreplay !log_output
# Defaults!/sbin/reboot !log_output

##
## Runas alias specification
##

##
## User privilege specification
##
root ALL=(ALL) ALL

## Uncomment to allow members of group wheel to execute any command
%wheel ALL=(ALL) ALL

## Same thing without a password
# %wheel ALL=(ALL) NOPASSWD: ALL

## Uncomment to allow members of group sudo to execute any command
# %sudo ALL=(ALL) ALL

## Uncomment to allow any user to run sudo if they know the password
## of the user they are running the command as (root by default).
# Defaults targetpw  # Ask for the password of the target user
# ALL ALL=(ALL) ALL  # WARNING: only use this together with 'Defaults targetpw'

%rfkill ALL=(ALL) NOPASSWD: /usr/sbin/rfkill
%network ALL=(ALL) NOPASSWD: /usr/bin/netcfg, /usr/bin/wifi-menu

## Read drop-in files from /etc/sudoers.d
## (the '#' here does not indicate a comment)
#includedir /etc/sudoers.d
EOF

    chmod 440 /etc/sudoers
}

set_root_password() {
    local password="$1"; shift

    echo -en "$password\n$password" | passwd
}

create_user() {
    local name="$1"; shift
    local password="$1"; shift

    useradd -m -s /bin/zsh -G adm,systemd-journal,wheel,rfkill,games,network,video,audio,optical,floppy,storage,scanner,power "$name"
    echo -en "$password\n$password" | passwd "$name"
}

#update_locate() {
#    updatedb
#}

get_uuid() {
    blkid -o export "$1" | grep UUID | awk -F= '{print $2}'
}

set -ex

if [ "$1" == "chroot" ]
then
    configure
else
    setup
fi
