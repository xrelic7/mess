#!/usr/bin/env bash
set -euo pipefail

echo "🍎 Starting optimized KDE Plasma 6 + macOS Sequoia setup on CachyOS..."

# === STEP 0: Install yay if missing ===
if ! command -v yay &>/dev/null; then
  echo "Installing yay AUR helper..."
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
  rm -rf /tmp/yay
fi

# === STEP 1: Update system and install KDE Plasma 6 + essentials ===
echo "📦 Installing KDE Plasma 6 and core packages..."
sudo pacman -Syu --noconfirm

sudo pacman -S --noconfirm \
  plasma-meta \
  kde-applications-meta \
  sddm sddm-kcm \
  xdg-desktop-portal-kde \
  qt6-wayland \
  plasma-workspace \
  dolphin konsole firefox \
  pipewire pipewire-pulse wireplumber \
  networkmanager \
  plasma-systemmonitor \
  kcalc kate ark spectacle \
  gwenview okular \
  kde-gtk-config breeze-gtk

# Enable essential services
sudo systemctl enable sddm
sudo systemctl enable NetworkManager

# === STEP 2: Install focused AUR packages (performance-minded) ===
echo "📥 Installing AUR packages..."
yay -S --noconfirm \
  apple-fonts \
  ttf-sf-pro \
  bibata-cursor-theme \
  whitesur-icon-theme \
  whitesur-gtk-theme \
  plasma6-applets-panel-colorizer \
  plasma6-applets-window-appmenu \
  swww \
  albert

# === STEP 3: Clone and install MacSequoia theme ===
echo "🎨 Installing MacSequoia KDE theme..."
git clone --depth=1 https://github.com/vinceliuice/MacSequoia-kde.git ~/MacSequoia-kde
cd ~/MacSequoia-kde
./install.sh -c -l -p -s -i
cd ~
rm -rf ~/MacSequoia-kde

# === STEP 4: Configure fonts (SF Pro family) ===
echo "🔤 Configuring fonts..."
kwriteconfig5 --file kdeglobals --group General --key font "SF Pro Display,11,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file kdeglobals --group General --key fixed "SF Mono,11,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file kdeglobals --group General --key smallestReadableFont "SF Pro Text,9,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file kdeglobals --group General --key menuFont "SF Pro Text,11,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file kdeglobals --group General --key toolBarFont "SF Pro Display,10,-1,5,50,0,0,0,0,0"

# === STEP 5: Apply macOS Sequoia theme ===
echo "🎨 Applying theme..."
lookandfeeltool -a MacSequoiaLight
kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme Bibata-Modern-Ice
kwriteconfig5 --file kdeglobals --group Icons --key Theme MacSequoia

# === STEP 6: Setup 5120x1440 Sequoia wallpapers ===
echo "🖼️ Setting up 5120x1440 Sequoia wallpapers..."
mkdir -p ~/Pictures/Wallpapers/Sequoia

# High-res wallpapers for your ultrawide display
curl -Lo ~/Pictures/Wallpapers/Sequoia/sequoia-5k-light.jpg "https://512pixels.net/downloads/macos-sequoia/macos-sequoia-light-5120x2880.jpg" || \
curl -Lo ~/Pictures/Wallpapers/Sequoia/sequoia-5k-light.jpg "https://wallpapercave.com/wp/wp12806941.jpg"

curl -Lo ~/Pictures/Wallpapers/Sequoia/sequoia-5k-dark.jpg "https://512pixels.net/downloads/macos-sequoia/macos-sequoia-dark-5120x2880.jpg" || \
curl -Lo ~/Pictures/Wallpapers/Sequoia/sequoia-5k-dark.jpg "https://wallpapercave.com/wp/wp12806942.jpg"

# Fallback - create a solid color if downloads fail
if [[ ! -f ~/Pictures/Wallpapers/Sequoia/sequoia-5k-light.jpg ]]; then
  convert -size 5120x1440 xc:'#f0f0f0' ~/Pictures/Wallpapers/Sequoia/sequoia-fallback.jpg 2>/dev/null || echo "Install ImageMagick for fallback wallpaper generation"
fi

# Set wallpaper
if command -v swww &>/dev/null; then
  swww init
  sleep 2
  swww img ~/Pictures/Wallpapers/Sequoia/sequoia-5k-light.jpg --transition-type fade --transition-duration 2
else
  # X11 fallback
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (i=0;i<allDesktops.length;i++) {
        d = allDesktops[i];
        d.wallpaperPlugin = \"org.kde.image\";
        d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");
        d.writeConfig(\"Image\", \"file://$HOME/Pictures/Wallpapers/Sequoia/sequoia-5k-light.jpg\");
    }
  "
fi

# === STEP 7: Configure macOS-like dock using Plasma Panel ===
echo "🚢 Setting up macOS-like dock with Panel Colorizer..."

# Configure the bottom panel to behave like macOS dock
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --key activityId ""
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --key formfactor 2
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --key immutability 1
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --key lastScreen 0
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --key location 4
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --key plugin "org.kde.panel"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --key wallpaperplugin "org.kde.image"

# Panel configuration - macOS dock style
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key alignment 132
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key panelOpacity 0
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key length 70
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key maxLength 70
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key minLength 70
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key offset 0

# Panel visibility - auto-hide like macOS dock
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key panelVisibility 1

# Configure panel size (height for bottom panel)
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group General --key thickness 52

# Add Task Manager to the dock panel
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --key immutability 1
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --key plugin "org.kde.plasma.taskmanager"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --key PreloadWeight 100

# Task Manager configuration - macOS dock behavior
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --group General --key launchers "applications:systemsettings.desktop,applications:org.kde.dolphin.desktop,applications:firefox.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kate.desktop"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --group General --key showOnlyCurrentDesktop false
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --group General --key showOnlyCurrentActivity false
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --group General --key groupingStrategy 0
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --group General --key onlyGroupWhenFull true
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --group General --key forceStripes true
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 21 --group Configuration --group General --key iconSize 2

# Add Panel Colorizer for transparency effects
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 22 --key immutability 1
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 22 --key plugin "org.kde.plasma.panelcolorizer"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 22 --group Configuration --key PreloadWeight 100

# Panel Colorizer configuration for macOS-like transparency
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 22 --group Configuration --group General --key panelTransparency 40
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 22 --group Configuration --group General --key panelBlur true
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 22 --group Configuration --group General --key panelBgColor "240,240,240"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 22 --group Configuration --group General --key panelRoundness 12

# Create autostart entry to reload plasma configuration after login
mkdir -p ~/.config/autostart
cat <<EOF > ~/.config/autostart/plasma-dock-setup.desktop
[Desktop Entry]
Type=Application
Exec=sh -c 'sleep 3 && qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "var panels = panels(); for (var i in panels) { if (panels[i].location == \"bottom\") { panels[i].height = 52; } }"'
Hidden=false
X-GNOME-Autostart-enabled=true
Name=macOS Dock Setup
Comment=Configure dock panel after login
EOF

# === STEP 8: Optimized KWin effects (performance-focused) ===
echo "✨ Configuring KWin effects..."
# Enable only essential effects for macOS look
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key fadeEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key minimizeanimationEnabled true

# Disable performance-heavy effects
kwriteconfig5 --file kwinrc --group Plugins --key wobblywindowsEnabled false
kwriteconfig5 --file kwinrc --group Plugins --key cubeEnabled false
kwriteconfig5 --file kwinrc --group Plugins --key presentwindowsEnabled false
kwriteconfig5 --file kwinrc --group Plugins --key desktopgridEnabled false

# Optimal compositing for performance
kwriteconfig5 --file kwinrc --group Compositing --key OpenGLIsUnsafe false
kwriteconfig5 --file kwinrc --group Compositing --key Backend "wayland"
kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 2

# macOS-like window management
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XIA"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
kwriteconfig5 --file kwinrc --group Windows --key FocusPolicy "ClickToFocus"

# === STEP 9: SDDM theme ===
echo "🔐 Configuring SDDM..."
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null <<EOF
[Theme]
Current=MacSequoia

[General]
Numlock=on
EOF

# === STEP 10: Albert launcher (lightweight Spotlight alternative) ===
echo "🚀 Configuring Albert..."
mkdir -p ~/.config/albert

# Start Albert manually after first boot (avoid autostart bloat)
cat > ~/.local/share/applications/albert-setup.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=albert
Name=Setup Albert (Run Once)
Comment=Configure Albert as Spotlight replacement - Cmd+Space
Icon=albert
EOF

# Minimal Albert config
cat > ~/.config/albert/albert.conf <<EOF
{
  "general": {
    "showInTray": false,
    "showOnStartup": false,
    "useGlobalShortcut": true,
    "globalShortcut": "Meta+Space",
    "theme": "Arc",
    "alwaysOnTop": true,
    "hideOnFocusLoss": true,
    "showCentered": true,
    "maxProposals": 6
  },
  "plugins": {
    "applications": {
      "enabled": true
    },
    "calculator": {
      "enabled": true
    },
    "files": {
      "enabled": true
    }
  }
}
EOF

# === STEP 11: Konsole terminal customization (macOS Terminal.app style) ===
echo "💻 Configuring Konsole to match macOS Terminal..."
mkdir -p ~/.local/share/konsole ~/.local/share/kxmlgui5/konsole

# Create macOS-like color scheme
cat > ~/.local/share/konsole/macOS-Sequoia.colorscheme <<EOF
[Background]
Color=248,248,248

[BackgroundFaint]
Color=248,248,248

[BackgroundIntense]
Color=248,248,248

[Color0]
Color=0,0,0

[Color0Faint]
Color=104,104,104

[Color0Intense]
Color=128,128,128

[Color1]
Color=194,54,33

[Color1Faint]
Color=144,39,24

[Color1Intense]
Color=255,69,44

[Color2]
Color=37,188,36

[Color2Faint]
Color=27,138,26

[Color2Intense]
Color=53,255,52

[Color3]
Color=173,173,39

[Color3Faint]
Color=128,128,29

[Color3Intense]
Color=234,234,53

[Color4]
Color=73,46,225

[Color4Faint]
Color=54,34,167

[Color4Intense]
Color=99,69,255

[Color5]
Color=211,56,211

[Color5Faint]
Color=157,42,157

[Color5Intense]
Color=255,84,255

[Color6]
Color=51,187,200

[Color6Faint]
Color=38,139,148

[Color6Intense]
Color=73,255,255

[Color7]
Color=203,204,205

[Color7Faint]
Color=150,152,154

[Color7Intense]
Color=255,255,255

[Foreground]
Color=28,28,28

[ForegroundFaint]
Color=28,28,28

[ForegroundIntense]
Color=28,28,28

[General]
Blur=false
ColorRandomization=false
Description=macOS Sequoia
FillStyle=Tile
Opacity=1.0
Wallpaper=
EOF

# Create macOS-like Konsole profile
cat > ~/.local/share/konsole/macOS-Sequoia.profile <<EOF
[Appearance]
AntiAliasFonts=true
BoldIntense=false
ColorScheme=macOS-Sequoia
Font=SF Mono,13,-1,5,50,0,0,0,0,0
LineSpacing=0
UseFontLineCharacters=false

[Cursor Options]
CursorShape=0
CustomCursorColor=28,28,28
UseCustomCursorColor=true

[General]
Command=/bin/zsh
Environment=TERM=xterm-256color,COLORTERM=truecolor
LocalTabTitleFormat=%d : %n
Name=macOS Sequoia
Parent=FALLBACK/
RemoteTabTitleFormat=%d : %n
ShowTerminalSizeHint=false
StartInCurrentSessionDir=true
TerminalCenter=true
TerminalColumns=120
TerminalRows=30

[Interaction Options]
AllowEscapedLinks=false
AutoCopySelectedText=true
CtrlRequiredForDrag=true
CopyTextAsHTML=false
MiddleClickPasteMode=0
MouseWheelZoomEnabled=true
OpenLinksByDirectClickEnabled=false
PasteFromClipboardEnabled=true
PasteFromSelectionEnabled=false
TrimLeadingSpacesInSelectedText=true
TrimTrailingSpacesInSelectedText=true
UnderlineFilesEnabled=false
UnderlineLinksEnabled=true
WordCharacters=:@-./_~?&=%+#

[Keyboard]
KeyBindings=default

[Scrolling]
HighlightScrolledLines=true
HistoryMode=1
HistorySize=10000
ReflowLines=true
ScrollBarPosition=2
ScrollFullPage=false

[Terminal Features]
BidiRenderingEnabled=true
BlinkingCursorEnabled=true
BlinkingTextEnabled=true
FlowControlEnabled=true
PeekPrimaryKeySequence=
ReverseUrlHints=false
UrlHintsModifiers=0
VerticalLine=false
VerticalLineAtChar=80
EOF

# Set macOS profile as default
kwriteconfig5 --file konsolerc --group Desktop\ Entry --key DefaultProfile "macOS-Sequoia.profile"
kwriteconfig5 --file konsolerc --group KonsoleWindow --key ShowWindowTitleOnTitleBar false
kwriteconfig5 --file konsolerc --group MainWindow --key MenuBar Disabled

# === STEP 12: Dolphin file manager (Finder-style customization) ===
echo "🐬 Configuring Dolphin to match macOS Finder..."

# Dolphin main configuration
kwriteconfig5 --file dolphinrc --group General --key ShowFullPath false
kwriteconfig5 --file dolphinrc --group General --key ShowSpaceInfo true
kwriteconfig5 --file dolphinrc --group General --key BrowseThroughArchives false
kwriteconfig5 --file dolphinrc --group General --key AutoExpandFolders false
kwriteconfig5 --file dolphinrc --group General --key ShowToolTips true
kwriteconfig5 --file dolphinrc --group General --key ShowSelectionToggle false

# Icon view settings (similar to Finder icon view)
kwriteconfig5 --file dolphinrc --group IconsMode --key PreviewSize 64
kwriteconfig5 --file dolphinrc --group IconsMode --key IconSize 48
kwriteconfig5 --file dolphinrc --group CompactMode --key PreviewSize 22

# Details view (like Finder list view)
kwriteconfig5 --file dolphinrc --group DetailsMode --key IconSize 22
kwriteconfig5 --file dolphinrc --group DetailsMode --key PreviewSize 22
kwriteconfig5 --file dolphinrc --group DetailsMode --key FontWeight 400

# Sidebar configuration (Finder-like places panel)
kwriteconfig5 --file dolphinrc --group PlacesPanel --key IconSize 22

# Window settings
kwriteconfig5 --file dolphinrc --group MainWindow --key MenuBar Disabled
kwriteconfig5 --file dolphinrc --group MainWindow --key ToolBarsMovable Disabled

# Create custom Dolphin toolbar layout (Finder-like)
mkdir -p ~/.local/share/kxmlgui5/dolphin
cat > ~/.local/share/kxmlgui5/dolphin/dolphinui.rc <<EOF
<?xml version="1.0"?>
<!DOCTYPE kpartgui SYSTEM "kpartgui.dtd">
<kpartgui version="2" name="dolphin">
 <MenuBar>
  <Menu name="file"/>
  <Menu name="edit"/>
  <Menu name="view"/>
  <Menu name="go"/>
  <Menu name="tools"/>
  <Menu name="settings"/>
  <Menu name="help"/>
 </MenuBar>
 <ToolBar noMerge="1" name="mainToolBar">
  <Action name="go_back"/>
  <Action name="go_forward"/>
  <Separator/>
  <Action name="icons"/>
  <Action name="compact"/>
  <Action name="details"/>
  <Separator/>
  <Action name="view_zoom_in"/>
  <Action name="view_zoom_out"/>
  <Separator/>
  <Action name="create_folder"/>
  <Separator/>
  <Action name="show_filter_bar"/>
 </ToolBar>
 <State name="new_file">
  <disable>
   <Action name="edit_undo"/>
   <Action name="edit_redo"/>
  </disable>
 </State>
</kpartgui>
EOF

# === STEP 13: Enhanced KDE theming for cohesiveness ===
echo "🎨 Fine-tuning theme cohesiveness..."

# Window decoration fine-tuning
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key BorderSize None
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key CloseOnDoubleClickOnMenu true

# Plasma theme settings for better macOS look
kwriteconfig5 --file plasmarc --group Theme --key name MacSequoia

# Panel configuration (macOS-like top bar)
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key alignment 0
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key panelOpacity 2
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key length 100
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key maxLength 100
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key minLength 100

# === STEP 14: System-wide application theming ===
echo "🎛️ Configuring system-wide application theming..."

# GTK applications to match KDE theme
kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle Breeze
kwriteconfig5 --file gtkrc-2.0 --group '' --key gtk-theme-name "MacSequoia-Light"
kwriteconfig5 --file ~/.config/gtk-3.0/settings.ini --group Settings --key gtk-theme-name "MacSequoia-Light"
kwriteconfig5 --file ~/.config/gtk-4.0/settings.ini --group Settings --key gtk-theme-name "MacSequoia-Light"

# Create GTK configuration for consistent theming
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0

cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-application-prefer-dark-theme=false
gtk-theme-name=MacSequoia-Light
gtk-icon-theme-name=MacSequoia
gtk-font-name=SF Pro Display 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-decoration-layout=close,minimize,maximize:
EOF

cat > ~/.config/gtk-4.0/settings.ini <<EOF
[Settings]
gtk-application-prefer-dark-theme=false
gtk-theme-name=MacSequoia-Light
gtk-icon-theme-name=MacSequoia
gtk-font-name=SF Pro Display 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-decoration-layout=close,minimize,maximize:
EOF

# === STEP 15: Plasma panel optimization ===
echo "📊 Optimizing panels..."
# Keep default panel but optimize it
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key showToolTips true

# === STEP 16: Final system optimizations ===
echo "⚡ Applying performance optimizations..."

# Optimize for SSD (if applicable)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

# Disable heavy startup services
systemctl --user mask baloo-file
systemctl --user mask baloo-file-extractor

echo -e "\n✅ Enhanced macOS Sequoia setup complete!"
echo -e "🔄 Reboot to apply all changes."
echo -e "\n📋 Post-install verification steps:"
echo -e "   1. Open Konsole and verify macOS Sequoia profile is active"
echo -e "   2. In Dolphin: View > Show Panels > Places (if not visible)"
echo -e "   3. Run Albert once: 'albert' then configure autostart if desired"
echo -e "   4. Bottom panel should auto-configure as macOS-like dock"
echo -e "   5. System Settings > Appearance > Application Style > Configure GNOME/GTK Application Style"
echo -e "\n🍎 Automated macOS Dock Setup:"
echo -e "   • Panel Colorizer configured for dock-like transparency and blur"
echo -e "   • Bottom panel set to auto-hide with centered alignment"
echo -e "   • Task Manager configured with macOS-style app launchers"
echo -e "   • Panel height optimized at 52px for dock appearance"
echo -e "\n🎨 Theme coherence improvements:"
echo -e "   • Konsole matches macOS Terminal.app colors and fonts"
echo -e "   • Dolphin toolbar simplified to Finder-like layout"
echo -e "   • GTK apps will use MacSequoia theme"
echo -e "   • Window decorations optimized for macOS feel"
echo -e "   • System fonts properly configured across all applications"
echo -e "\n⚡ Performance optimizations applied:"
echo -e "   • Baloo indexing disabled"
echo -e "   • SSD optimization enabled"
echo -e "   • Minimal autostart configuration"
