#!/bin/bash
## NOTE: For /etc vs. /usr/etc, see: https://bootc-dev.github.io/bootc/filesystem.html#usretc

## NOTE: change `set` flags to accommodate edge cases
set -ouex pipefail

### Setup

readonly WORKSPACE="$(pwd)"

### Install packages

## Packages can be installed from any enabled yum repo on the image.
## RPMfusion repos are available by default in ublue main images
## List of rpmfusion packages can be found here:
## https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/42/x86_64/repoview/index.html&protocol=https&redirect=1

## this installs a package from fedora repos
# dnf5 install -y tmux 

## Use a COPR Example:
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
## Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

## Example for enabling a System Unit File
# systemctl enable podman.socket

## Build Deps (Remove at end)
# dnf5 install -y rust cargo
# TMPFILE="$(mktemp -d /tmp/cargo-home.XXXXXXXXXX)" || exit 1
# export CARGO_HOME="${TMPFILE}/"

## SwayFX
## Avoid installing everything, to customize terminal, etc. later on
## NOTE(2025-10-30): qt5-base is installed already - adding qt6 as well
dnf5 -y copr enable swayfx/swayfx
dnf5 install --setopt=install_weak_deps=false -y swayfx
dnf5 install -y sway-systemd swayidle qt5-qtwayland qt6-qtwayland

## Waybar
## For use with Sway
dnf5 install --setopt=install_weak_deps=false -y waybar

## Dotnet (for `git-credential-manager`)
## Assumes local bootstrapping for a user
## NOTE(2025-10-30): GCM uses `dotnet-sdk-8.0` at the moment
## TODO(2025-10-30): Find ways to install GCM system-wide?
dnf5 install -y dotnet-sdk-8.0

### Removals

### Finishing

## Remove build tools, cleanup dnf5
# dnf5 remove -y rust cargo
# export -n CARGO_HOME

dnf5 autoremove -y
dnf5 clean -y all
