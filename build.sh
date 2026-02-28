#!/bin/bash
# =================================================================
# LacOS Build Script - THE ULTIMATE macOS SEQUOIA EDITION
# =================================================================

# 1. Install Build & Remastering Tools
sudo apt-get update
sudo apt-get install -y squashfs-tools genisoimage wget git unzip dbus-x11 curl

# 2. Download Official Linux Mint 21.3 ISO (STABLE MIRROR)
wget --user-agent="Mozilla/5.0" -O mint.iso https://mirrors.kernel.org

# 3. Extract ISO and SquashFS
mkdir mnt source
sudo mount -o loop mint.iso mnt
cp -a mnt/* source/
sudo umount mnt
sudo unsquashfs -d squashfs-root source/casper/filesystem.squashfs

# 4. CUSTOMIZE: The LacOS Transformation (Chroot)
sudo chroot squashfs-root /bin/bash <<EOF
# --- A. Repositories & App Installation ---
add-apt-repository ppa:agornostal/ulauncher -y
# Add Arc Browser Repo
curl -s https://packages.arc-browser.org | gpg --dearmor -o /usr/share/keyrings/arc-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/arc-archive-keyring.gpg] https://packages.arc-browser.org stable main" | tee /etc/apt/sources.list.d/arc.list

apt-get update
apt-get install -y ulauncher plank sddm plymouth-themes gnome-sushi \
                   wget curl git fonts-inter-variable conky-all neofetch \
                   zenity cheese arc-browser xnotes

# Install WPS Office (Skip if download fails)
wget https://wdl1.pcloud.com || true
apt-get install -y ./wps-office_11.1.0.11719.amd64.deb || true

# --- B. Deep Rebranding & Bloatware Removal ---
apt-get purge -y firefox* libreoffice* thunderbird hexchat transmission-common sticky notes drawing
apt-get autoremove -y

sed -i 's/Linux Mint/LacOS/g' /etc/linuxmint/info
sed -i 's/Linux Mint/LacOS/g' /etc/lsb-release
echo "LacOS" > /etc/issue

# Rename Software Manager to App Store
if [ -f "/usr/share/applications/mintinstall.desktop" ]; then
    sed -i 's/Name=Software Manager/Name=App Store/g' /usr/share/applications/mintinstall.desktop
fi
# Rename Installer
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

# --- D. Apple Menu & About This Mac ---
mkdir -p /usr/share/lacos/branding
cp /usr/share/icons/Hatter/apps/scalable/apple.svg /usr/share/lacos/branding/apple-menu.svg

cat <<ABOUT > /usr/local/bin/about-lacos
#!/bin/bash
zenity --info --title="About This Mac" --width=250 --text="<b>LacOS Sequoia</b>\nVersion 1.0\n\nDesign by LacOS Team" --icon-name="apple"
ABOUT
chmod +x /usr/local/bin/about-lacos

# --- E. Autostart Setup (Plank, Ulauncher, Conky) ---
mkdir -p /etc/skel/.config/autostart
cp /usr/share/applications/ulauncher.desktop /etc/skel/.config/autostart/
cp /usr/share/applications/plank.desktop /etc/skel/.config/autostart/

# --- F. System Layout & Keybindings (DCONF) ---
mkdir -p /etc/skel/.config/dconf
cat <<DCONF > /etc/skel/.config/dconf/user-settings
[org/cinnamon]
enabled-applets=['panel1:left:0:menu@cinnamon.org', 'panel1:left:1:globalAppMenu@lestcape', 'panel1:right:0:systray@cinnamon.org', 'panel1:right:1:calendar@cinnamon.org']
panels-enabled=['panel1:0:top']
[org/cinnamon/applets/menu@cinnamon.org]
menu-icon='/usr/share/lacos/branding/apple-menu.svg'
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

# 5. Package the Final ISO (Modern BIOS + UEFI Paths)
sudo genisoimage -D -r -V "LacOS-Final" -cache-inodes -J -l \
    -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -o LacOS-Sequoia.iso source/
