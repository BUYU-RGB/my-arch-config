# My Arch Config

This directory is a personal Arch/Hyprland setup extracted from the current Omarchy system.

The goal is not to maintain a custom distro. The goal is to keep a small, understandable set of files that can rebuild a similar desktop with normal Arch packages, AUR packages, and user config files.

## What Is Included

- `packages/pacman-packages.txt`: explicitly installed repo packages, excluding `omarchy-*` packages
- `packages/aur-packages.txt`: explicitly installed AUR packages
- `packages/omarchy-packages.txt`: Omarchy-specific packages kept aside for reference
- `config/`: Hyprland, Waybar, Walker, Mako, and Alacritty config
- `scripts/clean-apps`: removes broken user-level desktop launchers
- `scripts/backup-current`: refreshes this directory from the current system

## Scope

The important parts of this setup are:

- Hyprland: window rules, keybindings, startup behavior, input behavior
- Waybar: top bar layout, status modules, click actions
- Walker: app launcher style and search behavior
- Mako: notifications
- Alacritty: the single terminal kept for package installation and occasional maintenance

Everything else should stay secondary. Avoid adding extra terminal configs, editor configs, or app-specific tweaks unless they directly support the desktop interaction model.

## Core Interaction

These two shortcuts are the center of the system:

```text
Super + Space      -> my-launcher -> Walker app launcher
Super + Alt + Space -> my-menu     -> Walker-powered system menu
```

The scripts live in:

```text
local/bin/my-launcher
local/bin/my-menu
```

The Hyprland bindings live in:

```text
config/hypr/bindings.conf
```

This intentionally mirrors the Omarchy feel while using local `my-launcher` and `my-menu` scripts.

## Restore On A Fresh Arch System

Install a minimal Arch system first. During disk setup, do not enable LUKS if you do not want disk encryption. Create your normal user, give it sudo access, boot into the installed system, connect to the network, and log in as that user.

Minimal first commands:

```bash
sudo pacman -Syu --needed git base-devel
git clone https://github.com/YOUR_USER/my-arch-config.git ~/my-arch-config
cd ~/my-arch-config
./install.sh
```

After this finishes:

```bash
reboot
```

Then choose the Hyprland session from SDDM.

The script will:

- install bootstrap packages required to build AUR packages
- install packages from `packages/pacman-packages.txt`
- install `yay` from AUR if needed
- install packages from `packages/aur-packages.txt`
- back up existing configs to `~/.config.backup.YYYYMMDD-HHMMSS`
- copy configs into `~/.config`
- install `clean-apps` into `~/.local/bin`
- avoid copying user-level `.desktop` files by default
- enable SDDM and core desktop services
- keep Alacritty as the only configured terminal
- refresh desktop launcher cache

Once this repository is published, the same flow can be compressed to:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USER/my-arch-config/main/scripts/bootstrap)" -- https://github.com/YOUR_USER/my-arch-config.git
```

## Daily Use

After uninstalling software, run:

```bash
clean-apps
```

This removes broken launchers from:

```bash
~/.local/share/applications
```

It specifically avoids depending on Omarchy for cleanup.

## Refresh This Backup

After changing your desktop config, run:

```bash
my-arch-backup-current
```

or from this directory:

```bash
./scripts/backup-current
```

## Current Limitation

The active Hyprland, Waybar, Walker, and Mako configs are intended to run from pacman/AUR packages plus this repository's `config/` and `local/bin/` files. Omarchy references are kept only in reference notes and package snapshots.

Useful checks:

```bash
rg -n 'omarchy|OMARCHY_PATH|\\.local/share/omarchy' ~/my-arch-config/config
```

The long-term direction is:

- keep Hyprland / Waybar / Walker appearance
- remove Omarchy update/install machinery
- use pacman and AUR for software
- keep only personal config files under this directory
