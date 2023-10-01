#!/bin/bash
# You should read through this script before running it in case you want to
# make any modifications, in particular, the variables just below, and the
# following functions:
#
#    install_packages - Customize packages installed in base system
#                       (desktop environment, etc.)
#    install_aur_packages - More packages after packer (AUR helper) is
#                           installed

## CONFIGURE THESE VARIABLES
## ALSO LOOK AT THE install_packages FUNCTION TO SEE WHAT IS ACTUALLY INSTALLED

## TO GET THE SCRIPT:
## Install git through "pacman -Sy archlinux-keyring git"
## and then pull the script "git clone https://github.com/ogstriker/installer"

## You need to first connect to a internet and format the drives you gonna use
## then mount them to /mnt and /mnt/boot/EFI and finally execute the script



#################################################################################



# Drive to install to.
#DRIVE='/dev/nvme0n1p1'

# Encrypt everything (except /boot).  Leave blank to disable.
#ENCRYPT_DRIVE='TRUE'

# Passphrase used to encrypt the drive (leave blank to be prompted).
#DRIVE_PASSPHRASE='a'

# Choose your video driver
# For Intel
#VIDEO_DRIVER="i915"
# For nVidia
#VIDEO_DRIVER="nouveau"
# For ATI
#VIDEO_DRIVER="radeon"
# For generic stuff
#VIDEO_DRIVER="vesa"

# Hostname of the installed machine.
HOSTNAME='strikerhost'

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
        #echo 'Done! Reboot system.'
        reboot
    fi
}

user_chroot(){
    exit
    cp $0 /mnt/userchroot.sh
    arch-chroot -u $USER_NAME /mnt ./userchroot.sh chroot
}

configure() {

    echo 'Installing additional packages'
    install_packages

#    echo 'Installing AUR packages'
#    install_aur_packages

    echo 'Clearing package tarballs'
    clean_packages

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
#    set_fstab

    echo 'Configuring bootloader'
    grub_bootloader

    echo 'Setting initial daemons'
    set_daemons "$TMP_ON_TMPFS"

    echo 'Configuring sudo'
    set_sudoers

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
    echo 'Creating user'
    set_user_password "$USER_PASSWORD"
    create_user "$USER_NAME" "$USER_PASSWORD"

#    echo 'Building locate database'
#    update_locate

    rm /setup.sh
}

install_base() {
#    echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

    pacstrap /mnt base base-devel grub efibootmgr linux-zen linux-firmware nano
}

unmount_filesystems() {
    umount -R /mnt/boot/EFI
    umount -R /mnt
}

install_packages() {
    local packages=''
#
    # General utilities/libraries
    packages+=' alsa-utils aspell-en cpupower mlocate net-tools ntp openssh p7zip pkgfile python3 rfkill rsync unrar unzip wget zsh git'

    # Development packages
#    packages+=' cmake gdb git maven '

    # Netcfg
    if [ -n "$WIRELESS_DEVICE" ]
    then
        packages+=' dialog wireless_tools wpa_supplicant'
    fi

    # Java stuff
#    packages+=' jdk17-openjdk jre17-openjdk'

    # Libreoffice
#    packages+=' libreoffice-calc libreoffice-en-US'

    # Misc programs
#    packages+=' firefox vlc gparted jdk8-openjdk unrar qemu-desktop virt-manager zenity qbittorrent htop python-pip corectrl intellij-idea-community-edition ncdu fuse2 discord firejail telegram-desktop ntfs-3g noto-fonts-emoji bash-completion kdenlive zram-generator'

    # Network and Security
#    packages+=' tcpdump wireshark-qt whois macchanger binwalk keepassxc'
    
    # Plasma desktop
    packages+=' xdg-desktop-portal-kde plasma plasma-wayland-session packagekit-qt5 plasma-systemmonitor flatpak-kcm kdeplasma-addons'

    # XFCE desktop
#    packages+=' xfce xfce-goodies nm-connection-editor nm-tray'
    # Wine and games dependencies
#    packages=+' gamescope gamemode lib32-gamemode wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses ocl-icd lib32-ocl-icd libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader'

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

# FIX THIS

chaotic_aur(){
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm

    cat > /etc/pacman.conf <<EOF
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#CleanMethod = KeepInstalled
Architecture = auto

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
#Color
#NoProgressBar
CheckSpace
#VerbosePkgLists
#ParallelDownloads = 5

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

# NOTE: You must run `pacman-key --init` before first using pacman; the local
# keyring can then be populated with the keys of all official Arch Linux
# packagers with `pacman-key --populate archlinux`.

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture
#
# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[core-testing]
#Include = /etc/pacman.d/mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

#[extra-testing]
#Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist 
EOF

pacman -Sy --noconfirm
}

#install_yay() {
#    mkdir -p /foo
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
#    yay -S --noconfirm lightly-git appimagelauncher q4wine-git protonup-qt-bin obs-studio heroic-games-launcher pamac-aur zulu-jdk-fx-bin detect-it-easy-bin vkbasalt lib32-vkbasalt mangohud-git lib32-mangohud-git goverlay-git
#    unset TMPDIR
#    rm -rf /foo
#}

clean_packages() {
    yes | pacman -Scc
}

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

    systemctl enable cpupower.service sddm.service

    if [ -n "$WIRELESS_DEVICE" ]
    then
        systemctl enable NetworkManager
    fi
    
    if [ -z "$tmp_on_tmpfs" ]
    then
        systemctl mask tmp.mount
    fi
}

# IF U HAVE +8GB RAM, IN "zram-size = ram" DIVIDE BY 2, E.G: "zram-size = ram / 2"
setup_zram(){
    cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
}

config_zsh(){
    wget --no-check-certificate http://install.ohmyz.sh -O - | sh
    cat > ~/.zshrc <<EOF
    
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
EOF
}

swapspace(){
    git clone https://github.com/Tookmund/Swapspace && cd Swapspace
    autoreconf -i
    ./configure && make && make install
    mv swapspace.service /etc/systemd/system
    systemctl enable swapspace
    cd .. & rm -rf Swapspace/
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

set_user_password() {
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
