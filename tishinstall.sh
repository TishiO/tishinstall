EDITOR=vim

##CREDITS AND WARNING BLOCK
echo "TishiO's Arch Install Script"
echo "This script is really, really basic"
echo "CHECKLIST:"
echo "  1) Ensure you have formatted partitions already to install to, since this will NOT do it for you"
echo "  2) Also ensure you have a swap partiton made if you would like to have one (it is, however, skippable"
echo "  3) Ensure you are connected to the internet"

##PROMPT FOR ASSUREDNESS
echo "Would you like to continue with the install script?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

##IF CONTINUES
timedatectl set-ntp true

##PARTITION SELECTION
lsblk

disk_confirm=true

while [ "$disk_confirm" = true ] ; do
    read -p "Enter main disk (e.g. /dev/sda): " diskpath
    echo "Entered partition:" $diskpath
    echo "Are you SURE you would like to use this disk?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) disk_confirm=false;break;;
            No ) break;;
        esac
    done
done

parted -s $diskpath mklabel gpt
parted -s $diskpath mkpart ESP 1MiB 513MiB
parted -s $diskpath set 1 boot on
parted -s $diskpath mkpart primary ext4 513MiB 100%
mkfs.fat -F32 ${diskpath}1
mkfs.ext4 ${diskpath}2
mount ${diskpath}2 /mnt
sudo mkdir -p /mnt/boot
mount ${diskpath}1 /mnt/boot

##SWAP SELECTION
lsblk

swap_confirm=false

echo "Would you like to use swap space?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) swap_confirm=true;break;;
        No ) break;;
    esac
done

while [ "$swap_confirm" = true ] ; do
    read -p "Enter main partition (include /dev/): " swappath
    echo "Entered partition:" $swappath
    echo "Are you SURE you would like to use this partition?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) swap_confirm=false;swapon $swappath;break;;
            No ) break;;
        esac
    done
done

continue_confirm=true

while [ "$continue_confirm" = true ] ; do
    lsblk
    echo "Are you SURE you would like to use this partition scheme?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) continue_confirm=false;break;;
            No ) umount /mnt;swapoff $swappath;exit;;
        esac
    done
done

#Check to see if swap is actually working on current install

##STOLEN CODE
url="https://www.archlinux.org/mirrorlist/?country=US&use_mirror_status=on"

tmpfile=$(mktemp --suffix=-mirrorlist)

# Get latest mirror list and save to tmpfile
curl -so ${tmpfile} ${url}
sed -i 's/^#Server/Server/g' ${tmpfile}

# Backup and replace current mirrorlist file (if new file is non-zero)
if [[ -s ${tmpfile} ]]; then
{ echo " Backing up the original mirrorlist..."
    mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig; } &&
{ echo " Rotating the new list into place..."
    mv -i ${tmpfile} /etc/pacman.d/mirrorlist; }
else
echo " Unable to update, could not download list."
fi
# better repo should go first
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
rm /etc/pacman.d/mirrorlist.tmp
# allow global read access (required for non-root yaourt execution)
chmod +r /etc/pacman.d/mirrorlist
#$EDITOR /etc/pacman.d/mirrorlist

#PACSTRAP
pacstrap /mnt base
genfstab -p /mnt >> /mnt/etc/fstab

name_confirm=true

while [ "$name_confirm" = true ] ; do
    read -p "Enter computer name: " compy_name
    echo "Entered name:" $compy_name
    echo "Are you SURE you would like to use this computer name?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) name_confirm=false;break;;
            No ) break;;
        esac
    done
done

arch-chroot /mnt echo $compy_name > /etc/hostname

#Locale generation
arch-chroot /mnt ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
arch-chroot /mnt echo "en_US.UTF-8 UTF-8" > /etc/locale.conf
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=en_US.UTF-8" >> /etc/locale.gen

arch-chroot /mnt mkinitcpio -p linux
arch-chroot /mnt passwd

efi_confirm=true

while [ "$efi_confirm" = true ] ; do
    read -p "Enter EFI System Partition path (e.g. /boot): " efipath
    echo "Entered path:" $efipath
    echo "Are you SURE you would like to use this path?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) efi_confirm=false;break;;
            No ) break;;
        esac
    done
done

arch-chroot /mnt bootctl install

arch-chroot /mnt cp /usr/share/systemd/bootctl/loader.conf $efipath/loader/
arch-chroot /mnt cp /usr/share/systemd/bootctl/arch.conf $efipath/loader/entries/

sed -i '$d' /mnt$efipath/loader/entries/arch.conf
uuid="$(blkid -s PARTUUID -o value "$diskpath"2)"
echo "options root=PARTUUID="$uuid" rw" >> /mnt$efipath/loader/entries/arch.conf

#Have script copy netctl configuration from USB drive to computer
netctl list

net_confirm=false

echo "Would you like to copy a network profile to the system?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) net_confirm=true;break;;
        No ) break;;
    esac
done

while [ "$net_confirm" = true ] ; do
    read -p "Enter network profile to copy to system: " netprof
    echo "Entered network profile:" $netprof
    echo "Are you SURE you would like to use this device?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) net_confirm=false;cp /etc/netctl/$netprof /mnt/etc/netctl/$netprof;arch-chroot /mnt netctl enable $netprof;break;;
            No ) break;;
        esac
    done
done

wget https://raw.githubusercontent.com/TishiO/tishinstall/master/tishinstall_part2.sh -P /mnt/root

umount ${diskpath}1
umount ${diskpath}2


echo "Installation part 1 is complete"
echo "Device is going for shutdown"
echo "!!Please remove install medium when device shuts down, then boot device"
echo "Run 'tishinstall_part2.sh' when logged in as root"

reboot_confirm=true

while [ "$reboot_confirm" = true ] ; do
    echo "Press yes when ready to go for shutdown."
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) reboot_confirm=false;break;;
            No ) break;;
        esac
    done
done

poweroff