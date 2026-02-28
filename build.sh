#!/bin/bash
# =================================================================
# LacOS Build Script - Final Arc & App Store macOS Edition
# =================================================================

# 1. Install Build Tools
sudo apt-get update
sudo apt-get install -y squashfs-tools genisoimage wget git unzip dbus-x11

# 2. Download Official Linux Mint 21.3 ISO
wget -O mint.iso https://mirrors.layeronline.com

# 3. Extract ISO and SquashFS
mkdir mnt source
sudo mount -o loop mint.iso mnt
cp -a mnt/* source/
sudo umount mnt
sudo unsquashfs -d squashfs-root source/casper/filesystem.squashfs

# 4. CUSTOMIZE: Entering the LacOS Transformation Chamber (Chroot)
sudo chroot squashfs-root /bin/bash <<EOF
# --- A. Repositories & App Installation ---
add-apt-repository ppa:agornostal/ulauncher -y
# Repository for Arc Browser (Ubuntu/Mint compatible)
curl -s https://packages.arc-browser.org | sudo gpg --dearmor -o /usr/share/keyrings/arc-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/arc-archive-keyring.gpg] https://packages.arc-browser.org stable main" | sudo tee /etc/apt/sources.list.d/arc.list

apt-get update
# Install Requested Apps: Arc, Cheese, Notes, and tools
apt-get install -y ulauncher plank sddm plymouth-themes gnome-sushi \
                   wget curl git fonts-inter-variable conky-all neofetch \
                   zenity cheese arc-browser xnotes

# Install WPS Office
wget https://wdl1.pcloud.com
apt-get install -y ./wps-office_11.1.0.11719.amd64.deb
rm wps-office_11.1.0.11719.amd64.deb

# --- B. Remove Bloatware (Firefox, LibreOffice & Others) ---
apt-get purge -y firefox* libreoffice* thunderbird hexchat transmission-common \
               transmission-gtk sticky notes drawing
apt-get autoremove -y

# --- C. Deep Rebranding (Software Manager -> App Store) ---
sed -i 's/Linux Mint/LacOS/g' /etc/linuxmint/info
sed -i 's/Linux Mint/LacOS/g' /etc/lsb-release
echo "LacOS" > /etc/issue

# Rename Software Manager to App Store
if [ -f "/usr/share/applications/mintinstall.desktop" ]; then
    sed -i 's/Name=Software Manager/Name=App Store/g' /usr/share/applications/mintinstall.desktop
    sed -i 's/Icon=mintinstall/Icon=appstore/g' /usr/share/applications/mintinstall.desktop
fi

# --- D. Wallpaper & Themes ---
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

# --- E. Apple Menu & About This Mac ---
mkdir -p /usr/share/lacos/branding
cp /usr/share/icons/Hatter/apps/scalable/apple.svg /usr/share/lacos/branding/apple-menu.svg

cat <<ABOUT > /usr/local/bin/about-lacos
#!/bin/bash
zenity --info --title="About This Mac" --width=250 --text="<b>LacOS Sequoia</b>\nVersion 1.0\n\nDesign by LacOS Team" --icon-name="apple"
ABOUT
chmod +x /usr/local/bin/about-lacos

# --- F. Conky Desktop Widget ---
mkdir -p /etc/skel/.config/conky
cat <<CONKY > /etc/skel/.config/conky/lacos.conkyrc
conky.config = {
    alignment = 'top_right',
    background = true,
    font = 'Inter:size=10',
    gap_x = 20,
    gap_y = 60,
    own_window = true,
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 0,
    update_interval = 1.0,
}
conky.text = [[
\${color white}LacOS \${hr}
\${color white}Uptime: \${uptime}
\${color white}CPU: \${cpu cpu0}%
\${color white}RAM: \${mem} / \${memmax}
]]
CONKY

# --- G. Autostart & System Layout (DCONF) ---
mkdir -p /etc/skel/.config/autostart
mkdir -p /etc/skel/.config/dconf
cp /usr/share/applications/ulauncher.desktop /etc/skel/.config/autostart/
cp /usr/share/applications/plank.desktop /etc/skel/.config/autostart/

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

# 5. Package the Final ISO
sudo mksquashfs squashfs-root source/casper/filesystem.squashfs -noappend -always-use-fragments
sudo genisoimage -D -r -V "LacOS-Final" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o LacOS-Sequoia.iso source/
