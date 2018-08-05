#!/bin/bash

# Setup keyrings
pacman-key --init
pacman-key --populate

# Setup Plymouth
# cat <<-EOF > /etc/mkinitcpio-archiso.conf
# MODULES="vsock vmw_vsock_vmci_transport vmw_balloon vmw_vmci vmwgfx nouveau radeon amdgpu i915"
# HOOKS="base udev plymouth memdisk archiso_shutdown archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_kms block pcmcia filesystems keyboard"
# COMPRESSION="xz"
# EOF

# cat <<-EOF > /etc/mkinitcpio.conf
# HOOKS=(base udev plymouth autodetect modconf block filesystems keyboard fsck)
# EOF


# Attempt to work around build failure on debian hosts.
mkdir -p /build/archiso/work/x86_64/airootfs/run/shm
mkdir -p /build/archiso/work/x86_64/airootfs/var/run/shm
mkdir -p /run/shm
mkdir -p /var/run/shm

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

groupadd liveuser
useradd -g liveuser -d /home/liveuser -m -s /bin/zsh  -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,docker" liveuser
passwd -d liveuser
echo "liveuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers;

# Re-Branding
sed -i.bak 's/Arch Linux/brinkOS/g' /usr/lib/os-release
sed -i.bak 's/arch/brink/g' /usr/lib/os-release
sed -i.bak 's#www.archlinux.org#github.com/jamesbrink/brinkOS#g' /usr/lib/os-release
sed -i.bak 's#bbs.archlinux.org#github.com/jamesbrink/brinkOS#g' /usr/lib/os-release
sed -i.bak 's#bugs.archlinux.org#github.com/jamesbrink/brinkOS#g' /usr/lib/os-release
# cp /usr/lib/os-release /etc/os-release

# Setup theme
echo "Setting theme to $GTK_THEME, $SHELL_THEME, $ICON_THEME, $WALLPAPER"
sudo -u liveuser gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME"
sudo -u liveuser gsettings set org.cinnamon.desktop.wm.preferences theme "$GTK_THEME"
sudo -u liveuser gsettings set org.cinnamon.theme name "$SHELL_THEME"
sudo -u liveuser gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME"
sudo -u liveuser gsettings set org.cinnamon.desktop.background picture-uri "$WALLPAPER"

systemctl enable pacman-init.service choose-mirror.service
# ln -s /usr/lib/systemd/system/lightdm.service /build/archlive/airootfs/etc/systemd/system/display-manager.service
# This throws out warnings but still works.
# systemctl enable lightdm
systemctl enable lightdm-plymouth.service
systemctl enable graphical.target

# Enable network manager
systemctl enable NetworkManager

# Enable open-vm-tools
cat /proc/version > /etc/arch-release
systemctl enable vboxservice.service
systemctl enable vmtoolsd.service
systemctl enable vmware-vmblock-fuse.service

# Enable bluetooth
systemctl enable bluetooth.service

# Enable ntpd
systemctl enable ntpd.service

# Enable docker
systemctl enable docker

# Enable cron
systemctl enable cronie.service

# Enable graphical boot
systemctl set-default graphical.target
