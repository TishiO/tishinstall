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

part_confirm=true

while [ "$part_confirm" = true ] ; do
    read -p "Enter main partition (include /dev/): " mntpath
    echo "Entered partition:" $mntpath
    echo "Are you SURE you would like to use this partition?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) part_confirm=false;break;;
            No ) break;;
        esac
    done
done

mount $mntpath /mnt

echo ""
echo "It continues."
echo ""

##SWAP SELECTION

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
            Yes ) swap_confirm=false;break;;
            No ) break;;
        esac
    done
done

swapon $swappath

continue_confirm=true

while [ "$continue_confirm" = true ] ; do
    echo "Are you SURE you would like to use this partition scheme?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) continue_confirm=false;break;;
            No ) umount /mnt;swapoff $swappath;exit;;
        esac
    done
done

echo ""
echo "It continues again."

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
$EDITOR /etc/pacman.d/mirrorlist

#PACSTRAP
pacstrap /mnt base
genfstab -p /mnt >> /mnt/etc/fstab
arch-chroot /mnt

name_confirm=true

while [ "$name_confirm" = true ] ; do
    read -p "Enter computer name: " compy_name
    echo "Entered name:" $compy_name
    echo "Are you SURE you would like to use this partition?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) name_confirm=false;break;;
            No ) break;;
        esac
    done
done

echo $compy_name > /etc/hostname

ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime

echo "LANG=en_US.UTF-8" >> /etc/locale.gen
locale-gen

mkinitcpio -p linux
passwd

pacman -S grub os-prober

grub_confirm=true

while [ "$grub_confirm" = true ] ; do
    read -p "Enter device for grub installation (include /dev/): " grubpath
    echo "Entered device:" $grubpath
    echo "Are you SURE you would like to use this device?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) grub_confirm=false;break;;
            No ) break;;
        esac
    done
done

os-prober
grub-install --recheck --target=i386-pc $grubpath
grub-mkconfig -o /boot/grub/grub.cfg