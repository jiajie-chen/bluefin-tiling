#!/bin/bash
set -ouex pipefail

### Setup

## DNF5 helper function to set consistent base flags
function _dnf5_helper {
    dnf5 -y --setopt='*.countme=0' "$@"
}

## Sync system files from context
rsync -rvK /ctx/system_files/ /

### Install packages

## Build Deps (Remove at end)
# dnf5 install -y rust cargo
# TMPFILE="$(mktemp -d /tmp/cargo-home.XXXXXXXXXX)" || exit 1
# export CARGO_HOME="${TMPFILE}/"

## SwayFX
## Avoid installing everything, to customize terminal, etc. later on
## NOTE(2025-10-30): qt5-base is installed already - adding qt6 as well
## TODO(2025-11-10): can maybe simplify installation of certain weak deps with `exclude_from_weak`
_dnf5_helper copr enable swayfx/swayfx
_dnf5_helper install --setopt=install_weak_deps=false swayfx
_dnf5_helper install sway-systemd swayidle qt5-qtwayland qt6-qtwayland
_dnf5_helper copr disable swayfx/swayfx

## Waybar
## For use with Sway
_dnf5_helper install --setopt=install_weak_deps=false waybar

## Hyprland
_dnf5_helper install --setopt=install_weak_deps=false hyprland hyprland-devel
_dnf5_helper install brightnessctl wofi xdg-desktop-portal-hyprland

## nwg-shell
## For use with Sway or Hyprland
## NOTE(2025-11-10): For now, not using COPR
# _dnf5_helper copr enable tofik/nwg-shell
_dnf5_helper install nwg-panel
# _dnf5_helper copr disable tofik/nwg-shell

## COSMIC (Testing)
## See: https://packages.fedoraproject.org/pkgs/cosmic-session/cosmic-session/
## TODO(2025-11-06): no way to exclude required deps, without manual RPM download and install
## NOTE(2025-11-10): decided to use GNOME + Pop Shell for now
# _dnf5_helper install cosmic-session # --exclude='cosmic-term,cosmic-greeter'

## GNOME Shell Extensions
## NOTE(2025-11-09): Unlike Bluefin, just use Fedora repos vs. source builds
_dnf5_helper install gnome-shell-extension-just-perfection gnome-shell-extension-pop-shell

## Dotnet (for `git-credential-manager`)
## Assumes local bootstrapping for a user
## NOTE(2025-10-30): GCM uses `dotnet-sdk-8.0` at the moment
## TODO(2025-10-30): Find ways to install GCM system-wide?
##   - See: https://github.com/ublue-os/bluefin/blob/stable-20251024/system_files/dx/usr/share/ublue-os/user-setup.hooks.d/10-vscode.sh
_dnf5_helper install dotnet-sdk-8.0

## NOTE(2025-10-30): Look into Brewfile additions & overrides
## See: https://github.com/ublue-os/bluefin/blob/stable-20251024/system_files/dx/usr/share/ublue-os/user-setup.hooks.d/10-vscode.sh

### Removals

### Finishing

## Remove build tools, cleanup dnf5
# dnf5 remove -y rust cargo
# export -n CARGO_HOME

_dnf5_helper autoremove
_dnf5_helper clean all
