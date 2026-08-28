# My Opinionated Fedora-Sway Dotfiles Setup

A hand-built Fedora Minimal + Sway desktop: Wayland compositor, Waybar status
bar, Rofi launcher, Kitty terminal, Swaylock screen lock, and a matching Nord
theme across GTK, Qt, and the SDDM login screen.

## System requirements

- **Fedora 44** (Minimal install as the starting point — a full Workstation
  install will conflict with some steps `install.sh` runs)
- **~5 GB free disk** for packages, dev toolchain, and fonts
- **Internet access** (RPM Fusion, a COPR repo, and a few GitHub release
  downloads are required)
- **NVIDIA GPU: optional.** `config/environment.d/nvidia.conf` pre-stages the
  Wayland/sway env vars an NVIDIA setup needs, but `install.sh` does **not**
  install the `akmod-nvidia` driver itself — see
  [Optional: NVIDIA driver](#optional-nvidia-driver) to add it by hand.

## What you get

| Component | Tool |
|---|---|
| Compositor | Sway |
| Status bar | Waybar |
| App launcher | Rofi |
| Terminal | Kitty |
| Shell / prompt | Fish + Starship |
| Screen lock | Swaylock + Swayidle |
| Login screen | SDDM (custom Nord Qt6/QML theme) |
| File manager | Dolphin |
| Browser | Helium |
| Editor | micro |
| System info | macchina (via Homebrew) |
| GitHub CLI | gh |
| Fuzzy finder | fzf |
| Icons / GTK theme | Papirus-Dark / Nordic-darker |
| Font | JetBrains Mono Nerd Font |

All configs share one Nord color palette (background `#2E3440`, accent
`#88C0D0`, etc.) hand-kept in sync across Sway, Waybar, Rofi, GTK, Qt, and
SDDM.

## Install

```sh
git clone git@github.com:AlduwaihiRashed/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Run it as your normal user, not root — it calls `sudo` itself for the
privileged steps (RPM Fusion, package install, service enablement, the SDDM
theme) and will prompt for your password interactively.

`install.sh` will:

1. Enable RPM Fusion free/nonfree and the `imput/helium` COPR
2. Install the full package set (desktop, audio, dev toolchain, shell/CLI
   tools — fish, gh, fzf, micro)
3. Enable `sddm`, `NetworkManager`, `bluetooth`, and set the graphical target
4. Download and install the JetBrains Mono **Nerd Font** (the plain
   `jetbrains-mono-fonts-all` dnf package is missing Waybar's icon glyphs)
5. Download and install the **Nordic-darker** GTK theme (pinned to v2.2.0)
6. Install Homebrew and `macchina` (not packaged for Fedora/RPM Fusion)
7. Install the **Starship** prompt
8. Set fish as the default login shell
9. Symlink every config in `config/` into `~/.config/...` (backing up
   anything already there to `<file>.bak`)
10. Symlink the wallpaper into `~/Pictures/Wallpapers/`
11. Install the custom Nord SDDM theme to `/usr/share/sddm/themes/nord`
    (root-owned, so this step needs `sudo`)

### After it finishes

A few things only take effect after logout/reboot, not just `swaymsg
reload`:

- `QT_QPA_PLATFORMTHEME=qt6ct` (needs a fresh systemd user session)
- the systemd/portal integration pulled in by `/etc/sway/config.d/*`
  (`graphical-session.target`)
- the SDDM theme (only visible at the next login screen)

Log out and back in, or reboot, once `install.sh` completes.

## Optional: NVIDIA driver

`install.sh` pre-stages the Wayland env vars (`config/environment.d/nvidia.conf`
→ `GBM_BACKEND`, `__GLX_VENDOR_LIBRARY_NAME`, `LIBVA_DRIVER_NAME`,
`WLR_NO_HARDWARE_CURSORS`) but does **not** install the driver itself, since
most machines running this repo won't have an NVIDIA GPU. If yours does:

```sh
sudo dnf install -y kernel-devel-$(uname -r) akmod-nvidia xorg-x11-drv-nvidia-cuda
sudo akmods --force
modinfo -F version nvidia   # confirms the kernel module built
sudo reboot
```

## Repo layout

```
dotfiles/
├── install.sh              # the installer described above
├── config/                 # mirrors ~/.config/<name>, symlinked in by install.sh
│   ├── sway/
│   ├── waybar/              # config.jsonc, style.css, scripts/
│   ├── kitty/
│   ├── rofi/
│   ├── swaylock/
│   ├── gtk-3.0/ gtk-4.0/
│   ├── qt6ct/
│   ├── environment.d/
│   ├── fish/                # config.fish (fish_variables is generated, not tracked)
│   ├── gh/                  # config.yml only — hosts.yml (auth token) is gitignored
│   ├── micro/                # bindings.json only — buffers/backups are gitignored
│   ├── macchina/
│   ├── starship.toml
│   ├── mimeapps.list
│   └── dolphinrc
├── sddm/nord/               # → /usr/share/sddm/themes/nord
└── wallpapers/               # → ~/Pictures/Wallpapers
```

Not tracked, on purpose: browser profile data (`net.imput.helium/`), PulseAudio
runtime state (`pulse/`), Dolphin's per-session window cache (`session/`),
fish's generated `fish_variables`, micro's edit history/backups, and other
auto-generated or per-machine state (`pavucontrol.ini`, `user-dirs.*`). See
`.gitignore`.

