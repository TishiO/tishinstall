##tishinstall_part2

default_group="baseuser"
groupadd $default_group

user_confirm=true

while [ "$user_confirm" = true ] ; do
    read -p "Enter main disk (e.g. /dev/sda): " username
    echo "Entered partition:" $username
    echo "Are you SURE you would like to use this disk?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) user_confirm=false;break;;
            No ) break;;
        esac
    done
done

useradd -m -G $default_group $username

echo "Enter password for "$username":"
passwd $username

pacman -S --noconfirm base-devel sudo vim

#Set vim as global editor
echo "EDITOR=vim" >> /etc/profile

#Add new user to sudoers list, give all permissions
echo -e "$username"'\t'"ALL=(ALL) ALL" >> /etc/sudoers

#Install AUR Helper
cd /home/${username}
sudo -u andy mkdir builds
cd builds
sudo -u andy curl https://aur.archlinux.org/cgit/aur.git/snapshot/package-query.tar.gz
sudo -u andy curl https://aur.archlinux.org/cgit/aur.git/snapshot/yaourt.tar.gz
sudo -u andy tar -xvf package-query.tar.gz
sudo -u andy tar -xvf yaourt.tar.gz
cd package-query
sudo -u andy makepkg -sri --noconfirm
cd ..
cd yaourt
sudo -u andy makepkg -sri --noconfirm
cd