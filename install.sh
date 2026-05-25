#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d-%H%M%S)"

require_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer is intended for Arch Linux systems with pacman." >&2
    exit 1
  fi
}

install_bootstrap_packages() {
  echo "Installing bootstrap packages..."
  sudo pacman -Syu --needed git base-devel
}

install_pacman_packages() {
  local list="$ROOT_DIR/packages/pacman-packages.txt"
  [[ -s "$list" ]] || return 0

  echo "Installing pacman packages..."
  sudo pacman -Syu --needed - < "$list"
}

install_yay() {
  command -v yay >/dev/null 2>&1 && return 0

  echo "Installing yay from AUR..."
  local build_dir
  build_dir="$(mktemp -d)"
  trap 'rm -rf "$build_dir"' RETURN

  git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
  (
    cd "$build_dir/yay"
    makepkg -si --noconfirm
  )
}

install_aur_packages() {
  local list="$ROOT_DIR/packages/aur-packages.txt"
  [[ -s "$list" ]] || return 0

  install_yay

  echo "Installing AUR packages..."
  yay -S --needed - < "$list"
}

backup_existing_configs() {
  mkdir -p "$BACKUP_DIR"

  for name in hypr waybar walker mako alacritty; do
    if [[ -e "$HOME/.config/$name" ]]; then
      mv "$HOME/.config/$name" "$BACKUP_DIR/$name"
    fi
  done
}

restore_configs() {
  echo "Restoring config files..."
  mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications"

  cp -a "$ROOT_DIR/config/." "$HOME/.config/"
  if [[ -f "$ROOT_DIR/config/xdg-terminals.list" ]]; then
    cp -a "$ROOT_DIR/config/xdg-terminals.list" "$HOME/.config/xdg-terminals.list"
  fi
  cp -a "$ROOT_DIR/local/bin/." "$HOME/.local/bin/" 2>/dev/null || true
  install -m 0755 "$ROOT_DIR/scripts/clean-apps" "$HOME/.local/bin/clean-apps"
  install -m 0755 "$ROOT_DIR/scripts/backup-current" "$HOME/.local/bin/my-arch-backup-current"

  chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
}

refresh_desktop_database() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" || true
  fi
}

restart_user_services() {
  systemctl --user daemon-reload || true
  systemctl --user restart waybar.service 2>/dev/null || true
  systemctl --user restart mako.service 2>/dev/null || true
}

enable_system_services() {
  echo "Enabling desktop services..."
  sudo systemctl enable sddm.service
  sudo systemctl enable iwd.service
  sudo systemctl enable bluetooth.service 2>/dev/null || true
  sudo systemctl enable cups.service 2>/dev/null || true
  sudo systemctl enable power-profiles-daemon.service 2>/dev/null || true
}

main() {
  require_arch
  install_bootstrap_packages
  install_pacman_packages
  install_aur_packages
  backup_existing_configs
  restore_configs
  "$ROOT_DIR/scripts/clean-apps" || true
  refresh_desktop_database
  enable_system_services
  restart_user_services

  echo
  echo "Done."
  echo "Previous configs, if any, were moved to: $BACKUP_DIR"
  echo "Reboot into SDDM, then start the Hyprland session."
}

main "$@"
