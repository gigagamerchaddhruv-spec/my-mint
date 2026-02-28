#!/bin/bash
# =================================================================
# LacOS Build Script - MINT 22.3 "ZENA" BASE (SEQUOIA EDITION)
# =================================================================

# 1. Install Modern Build Tools
sudo apt-get update
sudo apt-get install -y squashfs-tools xorriso wget git unzip dbus-x11 curl p7zip-full

# 2. Download Linux Mint 22.3 Cinnamon ISO
wget --user-agent="Mozilla/5.0" -O mint.iso https://mirrors.kernel.org

# 3. Extract ISO using 7zip (Works for Mint 22.x structure)
mkdir source
7z x mint.iso -osource/
SQUASH_PATH=$(find source -name "filesystem.squashfs")
sudo unsquashfs -d squashfs-root "$SQUASH_PATH"

# 4. CUSTOMIZE: Entering the LacOS Transformation Chamber (Chroot)
sudo chroot squashfs-root /bin/bash <<EOF
# --- A. Modern Repositories & App Installation ---
# Arc Browser for Ubuntu 24.04 Base
curl -s https://packages.arc-browser.org | gpg --dearmor -o /usr/share/keyrings/arc-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/arc-archive-keyring.gpg] https://packages.arc-browser.org stable main" | tee /etc/apt/sources.list.d/arc.list

# Ulauncher for Noble
add-apt-repository ppa:agornostal/ulauncher -y

apt-get update
apt-get install -y ulauncher plank sddm plymouth-themes gnome-sushi \
                   wget curl git fonts-inter-variable conky-all neofetch \
                   zenity cheese arc-browser xnotes

# --- B. Deep Rebranding (Mint 22.3 -> LacOS) ---
apt-get purge -y firefox* libreoffice* thunderbird hexchat transmission-common sticky notes drawing
apt-get autoremove -y

sed -i 's/Linux Mint/LacOS/g' /etc/linuxmint/info
sed -i 's/Linux Mint/LacOS/g' /etc/lsb-release
echo "LacOS" > /etc/issue

# Rename Software Manager and Installer for 22.3
[ -f "/usr/share/applications/mintinstall.desktop" ] && sed -i 's/Name=Software Manager/Name=App Store/g' /usr/share/applications/mintinstall.desktop
[ -f "/usr/share/applications/ubiquity.desktop" ] && sed -i 's/Name=Install Linux Mint/Name=Install LacOS/g' /usr/share/applications/ubiquity.desktop

# --- C. macOS Themes & Layout ---
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

# Set macTahoe SDDM (Login Screen)
git clone https://github.com /usr/share/sddm/themes/macTahoe
echo "[Theme]\nCurrent=macTahoe" > /etc/sddm.conf
cp /usr/share/backgrounds/lacos/macTahoe.jpg /usr/share/sddm/themes/macTahoe/background.jpg

# --- D. Autostart & Dconf Settings ---
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

# 5. Package the Final ISO with XORRISO (Mint 22.x Modern Boot)
# Re-squash modified system
sudo mksquashfs squashfs-root "$SQUASH_PATH" -noappend -always-use-fragments

# Use the precise EFI boot image path for Mint 22.3
EFI_IMG=$(find source -name "bootx64.efi" | head -n 1 | sed 's|source/||')

xorriso -as mkisofs \
    -iso-level 3 -full-iso9660-filenames \
    -volid "LacOS-Sequoia" \
    -e "$EFI_IMG" \
    -no-emul-boot \
    -append_partition 2 0xef source/boot/grub/efi.img \
    -isohybrid-gpt-basdat \
    -output LacOS-Sequoia.iso source/
