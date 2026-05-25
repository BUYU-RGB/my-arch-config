# My Arch Config

This is a personal Arch Linux + Hyprland restore project.

It is not a fork of the original desktop distro, not a distribution, and does not depend on the upstream runtime paths used by that project.

The goal is to rebuild a similar personal desktop on top of a minimal Arch installation by using normal Arch packages, AUR packages, user config files, and local helper scripts.

## What Is Included

- `packages/pacman-core.txt`: core Arch repo packages for the Hyprland desktop
- `packages/pacman-extra.txt`: extra personal applications and optional tools
- `packages/aur-core.txt`: core AUR packages
- `packages/aur-extra.txt`: extra AUR applications
- `config/`: Hyprland, Waybar, Walker, Mako, and Alacritty config
- `local/bin/my-*`: local helper scripts used by Hyprland and Waybar
- `scripts/clean-apps`: quarantines broken user-level desktop launchers
- `scripts/backup-current`: refreshes config backups from the current system
- `scripts/audit`: runs static checks

## Scope

The important parts of this setup are:

- Hyprland: window rules, keybindings, startup behavior, input behavior
- Waybar: top bar layout, status modules, click actions
- Walker: app launcher style and search behavior
- Mako: notifications
- Alacritty: the only configured terminal

Avoid adding extra terminal configs, editor configs, or application-specific tweaks unless they directly support the desktop interaction model.

## Core Interaction

These two shortcuts are the center of the system:

```text
Super + Space       -> my-launcher -> Walker app launcher
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

## Restore On A Fresh Arch System

Install a minimal Arch system first. Create your normal user, give it sudo access, boot into the installed system, connect to the network, and log in as that user.

Minimal commands:

```bash
sudo pacman -Syu --needed git base-devel curl
git clone https://github.com/BUYU-RGB/my-arch-config.git ~/my-arch-config
cd ~/my-arch-config
./install.sh
```

This installs only the core package lists by default.

To install extra personal applications too:

```bash
INSTALL_EXTRA=1 ./install.sh
```

For a non-interactive restore:

```bash
NONINTERACTIVE=1 ./install.sh
```

After installation:

```bash
reboot
```

Then choose the Hyprland session from SDDM.

## Optional Install Flags

The installer keeps destructive or session-changing actions disabled by default.

```bash
INSTALL_EXTRA=1      # install extra package lists
RUN_CLEAN_APPS=1     # quarantine broken user-level .desktop files
RESTART_DESKTOP=1    # restart Waybar and Mako after install
ENABLE_IWD=1         # enable iwd.service
ENABLE_BLUETOOTH=1   # enable bluetooth.service
ENABLE_PRINTING=1    # enable cups.service
NONINTERACTIVE=1     # pass --noconfirm to pacman/yay
```

SDDM is enabled by default. To prevent that:

```bash
ENABLE_SDDM=0 ./install.sh
```

## Local Machine Overrides

Hardware and locale-specific variables should go into:

```text
config/hypr/envs.local.conf
```

Keep `config/hypr/envs.conf` generic.

Examples:

```conf
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = LANG,zh_CN.UTF-8
env = LC_CTYPE,zh_CN.UTF-8
```

## Daily Use

After uninstalling software, run:

```bash
clean-apps
```

This moves broken user-level launchers into:

```bash
~/.local/state/my-arch/desktop-apps
```

It does not delete the original files in place.

## Refresh This Backup

After changing your desktop config, run:

```bash
my-arch-backup-current
```

or from this repository:

```bash
./scripts/backup-current
```

Generated package snapshots are written under:

```text
packages/generated/
```

Curated package lists are not overwritten automatically.

## Static Audit

Run:

```bash
./scripts/audit
```

It checks shell syntax, Waybar JSON, legacy distro residue, and Git status.
