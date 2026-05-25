#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d-%H%M%S)"

noninteractive() {
  [[ "${NONINTERACTIVE:-0}" == "1" ]]
}

require_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer is intended for Arch Linux systems with pacman." >&2
    exit 1
  fi
}

pacman_install_from_file() {
  local list="$1"
  [[ -s "$list" ]] || return 0

  local args=(-Syu --needed)
  if noninteractive; then
    args+=(--noconfirm)
  fi

  echo "Installing pacman packages from: ${list#$ROOT_DIR/}"
  sudo pacman "${args[@]}" - < "$list"
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

yay_install_from_file() {
  local list="$1"
  [[ -s "$list" ]] || return 0

  install_yay

  local args=(-S --needed)
  if noninteractive; then
    args+=(--noconfirm)
  fi

  echo "Installing AUR packages from: ${list#$ROOT_DIR/}"
  yay "${args[@]}" - < "$list"
}

install_bootstrap_packages() {
  echo "Installing bootstrap packages..."

  local args=(-Syu --needed git base-devel)
  if noninteractive; then
    args+=(--noconfirm)
  fi

  sudo pacman "${args[@]}"
}

install_packages() {
  if [[ -s "$ROOT_DIR/packages/pacman-core.txt" ]]; then
    pacman_install_from_file "$ROOT_DIR/packages/pacman-core.txt"
    [[ "${INSTALL_EXTRA:-0}" == "1" ]] && pacman_install_from_file "$ROOT_DIR/packages/pacman-extra.txt"
  else
    pacman_install_from_file "$ROOT_DIR/packages/pacman-packages.txt"
  fi

  if [[ -s "$ROOT_DIR/packages/aur-core.txt" ]]; then
    yay_install_from_file "$ROOT_DIR/packages/aur-core.txt"
    [[ "${INSTALL_EXTRA:-0}" == "1" ]] && yay_install_from_file "$ROOT_DIR/packages/aur-extra.txt"
  else
    yay_install_from_file "$ROOT_DIR/packages/aur-packages.txt"
  fi
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

  if [[ -d "$ROOT_DIR/local/bin" ]]; then
    while IFS= read -r -d '' script; do
      install -m 0755 "$script" "$HOME/.local/bin/$(basename "$script")"
    done < <(find "$ROOT_DIR/local/bin" -maxdepth 1 -type f -print0)
  fi

  install -m 0755 "$ROOT_DIR/scripts/clean-apps" "$HOME/.local/bin/clean-apps"
  install -m 0755 "$ROOT_DIR/scripts/backup-current" "$HOME/.local/bin/my-arch-backup-current"
  install -m 0755 "$ROOT_DIR/scripts/audit" "$HOME/.local/bin/my-arch-audit"
}

refresh_desktop_database() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" || true
  fi
}

enable_system_services() {
  if [[ "${ENABLE_SDDM:-1}" == "1" ]]; then
    echo "Enabling SDDM..."
    sudo systemctl enable sddm.service
  fi

  if [[ "${ENABLE_IWD:-0}" == "1" ]]; then
    echo "Enabling iwd..."
    sudo systemctl enable iwd.service
  fi

  if [[ "${ENABLE_BLUETOOTH:-0}" == "1" ]]; then
    echo "Enabling bluetooth..."
    sudo systemctl enable bluetooth.service 2>/dev/null || true
  fi

  if [[ "${ENABLE_PRINTING:-0}" == "1" ]]; then
    echo "Enabling printing services..."
    sudo systemctl enable cups.service 2>/dev/null || true
  fi

  if [[ "${ENABLE_POWER_PROFILE:-0}" == "1" ]]; then
    echo "Enabling power-profiles-daemon..."
    sudo systemctl enable power-profiles-daemon.service 2>/dev/null || true
  fi
}

restart_user_services() {
  systemctl --user daemon-reload || true
  systemctl --user restart waybar.service 2>/dev/null || true
  systemctl --user restart mako.service 2>/dev/null || true
}

main() {
  require_arch

  install_bootstrap_packages
  install_packages

  backup_existing_configs
  restore_configs
  refresh_desktop_database
  enable_system_services

  if [[ "${RUN_CLEAN_APPS:-0}" == "1" ]]; then
    "$ROOT_DIR/scripts/clean-apps" || true
  fi

  if [[ "${RESTART_DESKTOP:-0}" == "1" ]]; then
    restart_user_services
  fi

  echo
  echo "Done."
  echo "Previous configs, if any, were moved to: $BACKUP_DIR"
  echo "Reboot into SDDM, then start the Hyprland session."
  echo
  echo "Optional flags:"
  echo "  INSTALL_EXTRA=1      install extra personal applications"
  echo "  RUN_CLEAN_APPS=1     quarantine broken user-level .desktop files"
  echo "  RESTART_DESKTOP=1    restart Waybar and Mako after install"
  echo "  ENABLE_IWD=1         enable iwd.service"
  echo "  ENABLE_BLUETOOTH=1   enable bluetooth.service"
  echo "  ENABLE_PRINTING=1    enable cups.service"
  echo "  NONINTERACTIVE=1     pass --noconfirm to pacman/yay"
}

main "$@"
