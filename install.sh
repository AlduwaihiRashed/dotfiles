#!/usr/bin/env bash
# Reproduces the Fedora Minimal + Sway desktop this repo documents, starting
# from a fresh `dnf install fedora-minimal`-equivalent system. Run as your
# normal user (not root) — it calls sudo itself for the privileged steps and
# will prompt for your password interactively.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root — it calls sudo where needed." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEDORA_VER="$(rpm -E %fedora)"

step() { echo -e "\n==> $*"; }

step "Enabling RPM Fusion free/nonfree"
sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

step "Enabling imput/helium copr (for helium-bin)"
sudo dnf copr enable -y imput/helium

step "Installing packages"
CORE_PKGS=(
    sway swaybg swaylock swayidle waybar rofi kitty micro git helium-bin dolphin
)
AUDIO_PKGS=(
    pipewire pipewire-pulseaudio pipewire-alsa wireplumber
    pavucontrol-qt playerctl
)
DESKTOP_PKGS=(
    brightnessctl grim slurp wl-clipboard
    sddm sddm-themes sddm-wayland-sway xorg-x11-server-Xwayland
    xdg-desktop-portal xdg-desktop-portal-wlr polkit lxqt-policykit
    NetworkManager NetworkManager-wifi bluez bluez-tools
    udiskie udisks2 gvfs gvfs-mtp gvfs-smb qt6-qtwayland
    jetbrains-mono-fonts-all papirus-icon-theme papirus-icon-theme-dark qt6ct
)
DEV_PKGS=(
    gcc gcc-c++ clang llvm make cmake meson ninja-build gdb
    python3 python3-pip python3-devel python3-virtualenv
    rust cargo golang nodejs npm
)
SHELL_PKGS=(
    fish gh fzf
)

sudo dnf install -y "${CORE_PKGS[@]}" "${AUDIO_PKGS[@]}" "${DESKTOP_PKGS[@]}" "${DEV_PKGS[@]}" "${SHELL_PKGS[@]}"
sudo dnf group install -y "Development Tools"

# foot ships as a weak dep of the sway package but is never referenced by any
# config here — kitty is the only terminal.
if rpm -q foot &>/dev/null; then
    sudo dnf remove -y foot
fi

step "Enabling services"
sudo systemctl enable sddm.service NetworkManager.service bluetooth.service
sudo systemctl set-default graphical.target

step "Installing JetBrains Mono Nerd Font (the non-Nerd dnf package lacks waybar's icon glyphs)"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
mkdir -p "$FONT_DIR"
curl -fL -o /tmp/JetBrainsMono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -oq /tmp/JetBrainsMono.zip -d "$FONT_DIR"
fc-cache -f "$FONT_DIR" >/dev/null

step "Installing Nordic-darker GTK theme (v2.2.0, pinned to match this config)"
mkdir -p "$HOME/.themes"
curl -fL -o /tmp/Nordic-darker.tar.xz \
    https://github.com/EliverLara/Nordic/releases/download/v2.2.0/Nordic-darker.tar.xz
tar -xf /tmp/Nordic-darker.tar.xz -C "$HOME/.themes"

step "Installing Homebrew (for macchina — not packaged in Fedora/RPM Fusion)"
if [[ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install macchina

step "Installing Starship prompt"
curl -sS https://starship.rs/install.sh | sh -s -- -y

step "Setting fish as the default login shell"
sudo chsh -s "$(command -v fish)" "$USER"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mv "$dst" "$dst.bak"
        echo "  backed up existing $dst -> $dst.bak"
    fi
    ln -sfn "$src" "$dst"
}

step "Symlinking configs into ~/.config"
link "$REPO_DIR/config/sway/config"            "$HOME/.config/sway/config"
link "$REPO_DIR/config/waybar/config.jsonc"    "$HOME/.config/waybar/config.jsonc"
link "$REPO_DIR/config/waybar/style.css"       "$HOME/.config/waybar/style.css"
link "$REPO_DIR/config/waybar/scripts/kb-lang.sh"     "$HOME/.config/waybar/scripts/kb-lang.sh"
link "$REPO_DIR/config/waybar/scripts/power-menu.sh"  "$HOME/.config/waybar/scripts/power-menu.sh"
link "$REPO_DIR/config/kitty/kitty.conf"       "$HOME/.config/kitty/kitty.conf"
link "$REPO_DIR/config/rofi/config.rasi"       "$HOME/.config/rofi/config.rasi"
link "$REPO_DIR/config/rofi/nord.rasi"         "$HOME/.config/rofi/nord.rasi"
link "$REPO_DIR/config/swaylock/config"        "$HOME/.config/swaylock/config"
link "$REPO_DIR/config/gtk-3.0/settings.ini"   "$HOME/.config/gtk-3.0/settings.ini"
link "$REPO_DIR/config/gtk-4.0/settings.ini"   "$HOME/.config/gtk-4.0/settings.ini"
link "$REPO_DIR/config/qt6ct/qt6ct.conf"       "$HOME/.config/qt6ct/qt6ct.conf"
link "$REPO_DIR/config/qt6ct/colors/nord.conf" "$HOME/.config/qt6ct/colors/nord.conf"
link "$REPO_DIR/config/environment.d/qt.conf"  "$HOME/.config/environment.d/qt.conf"
link "$REPO_DIR/config/environment.d/nvidia.conf" "$HOME/.config/environment.d/nvidia.conf"
link "$REPO_DIR/config/fish/config.fish"       "$HOME/.config/fish/config.fish"
link "$REPO_DIR/config/gh/config.yml"          "$HOME/.config/gh/config.yml"
link "$REPO_DIR/config/micro/bindings.json"    "$HOME/.config/micro/bindings.json"
link "$REPO_DIR/config/starship.toml"          "$HOME/.config/starship.toml"
link "$REPO_DIR/config/mimeapps.list"          "$HOME/.config/mimeapps.list"
link "$REPO_DIR/config/dolphinrc"              "$HOME/.config/dolphinrc"
link "$REPO_DIR/config/macchina/macchina.toml"        "$HOME/.config/macchina/macchina.toml"
link "$REPO_DIR/config/macchina/ascii/fedora"         "$HOME/.config/macchina/ascii/fedora"
link "$REPO_DIR/config/macchina/themes/Beryllium.toml" "$HOME/.config/macchina/themes/Beryllium.toml"
link "$REPO_DIR/config/macchina/themes/Helium.toml"    "$HOME/.config/macchina/themes/Helium.toml"
link "$REPO_DIR/config/macchina/themes/Hydrogen.toml"  "$HOME/.config/macchina/themes/Hydrogen.toml"
link "$REPO_DIR/config/macchina/themes/Lithium.toml"   "$HOME/.config/macchina/themes/Lithium.toml"
link "$REPO_DIR/config/macchina/themes/Nord.toml"      "$HOME/.config/macchina/themes/Nord.toml"

step "Installing wallpaper"
mkdir -p "$HOME/Pictures/Wallpapers"
link "$REPO_DIR/wallpapers/200096-nordic-landscape-3840x2160.jpg" \
     "$HOME/Pictures/Wallpapers/200096-nordic-landscape-3840x2160.jpg"

step "Installing SDDM theme (root-owned, needs sudo)"
sudo mkdir -p /usr/share/sddm/themes/nord
sudo cp "$REPO_DIR"/sddm/nord/* /usr/share/sddm/themes/nord/
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null <<'EOF'
[Theme]
Current=nord
EOF

cat <<'EOF'

==> Done.

sway's `output * bg` line points at the wallpaper by absolute path — it
already matches $HOME/Pictures/Wallpapers/200096-nordic-landscape-3840x2160.jpg
above, so no edit needed unless you use a different image.

Things that only take effect after logout/reboot, not just `swaymsg reload`:
  - QT_QPA_PLATFORMTHEME=qt6ct (new systemd user session)
  - the systemd/portal integration pulled in by
    /etc/sway/config.d/* (graphical-session.target)
  - the sddm theme (only seen at the next login screen)

Log out and back in (or reboot) once this finishes.
EOF
