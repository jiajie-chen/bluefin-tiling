#!/bin/bash
## NOTE: For /etc vs. /usr/etc, see: https://bootc-dev.github.io/bootc/filesystem.html#usretc

## NOTE: change `set` flags to accommodate edge cases
set -ouex pipefail

### Setup

readonly WORKSPACE="$(pwd)"

function _dnf5_helper {
    dnf5 -y --setopt='*.countme=0' "$@"
}

### Sync system files from context
rsync -rvK /ctx/system_files/ /

### Install packages

## Packages can be installed from any enabled yum repo on the image.
## RPMfusion repos are available by default in ublue main images
## List of rpmfusion packages can be found here:
## https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/42/x86_64/repoview/index.html&protocol=https&redirect=1

## this installs a package from fedora repos
## disable countme to prevent issues with `/var`
# dnf5 -y install --setopt='*.countme=0' tmux 

## Use a COPR Example:
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
## Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging
## See also: https://github.com/ublue-os/bluefin/blob/stable-20251024/build_files/shared/copr-helpers.sh

## Example for enabling a System Unit File
# systemctl enable podman.socket

## Build Deps (Remove at end)
# dnf5 install -y rust cargo
# TMPFILE="$(mktemp -d /tmp/cargo-home.XXXXXXXXXX)" || exit 1
# export CARGO_HOME="${TMPFILE}/"

## SwayFX
## Avoid installing everything, to customize terminal, etc. later on
## NOTE(2025-10-30): qt5-base is installed already - adding qt6 as well
_dnf5_helper copr enable swayfx/swayfx
_dnf5_helper install --setopt=install_weak_deps=false swayfx
_dnf5_helper install  sway-systemd swayidle qt5-qtwayland qt6-qtwayland
_dnf5_helper copr disable swayfx/swayfx

## Waybar
## For use with Sway

_dnf5_helper install --setopt=install_weak_deps=false waybar

## COSMIC (Testing)
## See: https://packages.fedoraproject.org/pkgs/cosmic-session/cosmic-session/
## TODO(2025-11-06): no way to exclude required deps, without manual RPM download and install
_dnf5_helper install cosmic-session # --exclude='cosmic-term,cosmic-greeter'

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
