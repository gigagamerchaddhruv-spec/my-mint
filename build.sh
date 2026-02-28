#!/bin/bash
# =================================================================
# LacOS Build Script - RELIABLE EXTRACTION EDITION
# =================================================================

# 1. Install Build Tools
sudo apt-get update
sudo apt-get install -y squashfs-tools xorriso wget git unzip dbus-x11 curl p7zip-full isolinux

# 2. Download Official Linux Mint 21.3 ISO
wget --user-agent="Mozilla/5.0" -O mint.iso https://mirrors.kernel.org

# 3. Extract ISO using 7zip (No mounting needed!)
mkdir source
7z x mint.iso -osource/

# Extract SquashFS
sudo unsquashfs -d squashfs-root source/casper/filesystem.squashfs

# 4. CUSTOMIZE: The LacOS Transformation
sudo chroot squashfs-root /bin/bash <<EOF
# --- A. Repositories & App Installation ---
add-apt-repository ppa:agornostal/ulauncher -y
curl -s https://packages.arc-browser.org | gpg --dearmor -o /usr/share/keyrings/arc-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/arc-archive-keyring.gpg] https://packages.arc-browser.org stable main" | tee /etc/apt/sources.list.d/arc.list

apt-get update
apt-get install -y ulauncher plank sddm plymouth-themes gnome-sushi \
                   wget curl git fonts-inter-variable conky-all neofetch \
                   zenity cheese arc-browser xnotes

# --- B. Deep Rebranding ---
apt-get purge -y firefox* libreoffice* thunderbird hexchat transmission-common sticky notes drawing
apt-get autoremove -y

sed -i 's/Linux Mint/LacOS/g' /etc/linuxmint/info
sed -i 's/Linux Mint/LacOS/g' /etc/lsb-release
echo "LacOS" > /etc/issue

if [ -f "/usr/share/applications/mintinstall.desktop" ]; then
    sed -i 's/Name=Software Manager/Name=App Store/g' /usr/share/applications/mintinstall.desktop
fi
if [ -f "/usr/share/applications/ubiquity.desktop" ]; then
    sed -i 's/Name=Install Linux Mint/Name=Install LacOS/g' /usr/share/applications/ubiquity.desktop
fi

# --- C. Wallpaper & Themes ---
mkdir -p /usr/share/backgrounds/lacos
wget -O /usr/share/backgrounds/lacos/macTahoe.jpg https://raw.githubusercontent.com

git clone https://github.com
cd Hatter-icon-theme && ./install.sh && cd ..
mv /root/.icons/Hatter* /usr/share/icons/

git clone https://github.com
cd WhiteSur-gtk-theme
./install.sh -t light -s light --round
cp -r /root/.themes/* /usr/share/themes/
cd ..

git clone https://github.com /usr/share/sddm/themes/macTahoe
echo "[Theme]\nCurrent=macTahoe" > /etc/sddm.conf
cp /usr/share/backgrounds/lacos/macTahoe.jpg /usr/share/sddm/themes/macTahoe/background.jpg

# --- D. Autostart & System Layout (DCONF) ---
mkdir -p /etc/skel/.config/autostart
mkdir -p /etc/skel/.config/dconf
cp /usr/share/applications/ulauncher.desktop /etc/skel/.config/autostart/
cp /usr/share/applications/plank.desktop /etc/skel/.config/autostart/

cat <<DCONF > /etc/skel/.config/dconf/user-settings
[org/cinnamon]
enabled-applets=['panel1:left:0:menu@cinnamon.org', 'panel1:left:1:globalAppMenu@lestcape', 'panel1:right:0:systray@cinnamon.org', 'panel1:right:1:calendar@cinnamon.org']
panels-enabled=['panel1:0:top']
[org/cinnamon/applets/menu@cinnamon.org]
menu-icon='/usr/share/icons/Hatter/apps/scalable/apple.svg'
menu-label=''
[org/cinnamon/desktop/keybindings]
menu-key-1=['']
custom-list=['custom0']
[org/cinnamon/desktop/keybindings/custom-keybindings/custom0]
binding=['Super_L']
command='ulauncher-toggle'
name='Spotlight'
[org/cinnamon/theme]
name='WhiteSur-Light'
[org/nemo/desktop]
show-desktop-icons=false
[org/cinnamon/desktop/background]
picture-uri='file:///usr/share/backgrounds/lacos/macTahoe.jpg'
[org/cinnamon/desktop/interface]
font-name='Inter Regular 10'
icon-theme='Hatter'
cursor-theme='WhiteSur-cursors'
button-layout='close,minimize,maximize:'
DCONF

apt-get clean
EOF

# 5. Package the Final ISO with XORRISO (Modern Hybrid Boot)
# Note: Mint 21.3 uses EFI/boot/bootx64.efi for UEFI
xorriso -as mkisofs \
    -iso-level 3 -full-iso9660-filenames \
    -volid "LacOS-Sequoia" \
    -eltorito-boot boot/isolinux/isolinux.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output LacOS-Sequoia.iso source/
