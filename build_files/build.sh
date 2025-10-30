#!/bin/bash
## NOTE: For /etc vs. /usr/etc, see: https://bootc-dev.github.io/bootc/filesystem.html#usretc

## NOTE: change `set` flags to accommodate edge cases
set -ouex pipefail

### Setup

# Overwrite a file, using a replacement and a SHA1 checksum of the original
# Takes: `src` (file), `checksum` (string), `dest` (file)
function overwrite_with_checksum {
  if [[ "$#" -ne 3 ]]; then
    printf '%s expected 3 arguments, got %i' "$0" "$#"
    return 1
  fi
  local src="$1"
  local checksum="$2"
  local dest="$3"
  if sha1sum -c <(printf '%s  %s' "$checksum" "$dest"); then
    cp "$dest" "$dest".orig \
    && cat "$src" > "$dest"
    return
  fi
  printf '%s does not match checksum: %s' "$dest" "$checksum"
  return 1
}

### Install packages

## Packages can be installed from any enabled yum repo on the image.
## RPMfusion repos are available by default in ublue main images
## List of rpmfusion packages can be found here:
## https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

## this installs a package from fedora repos
# dnf5 install -y tmux 

## Use a COPR Example:
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
## Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

## Example for enabling a System Unit File
# systemctl enable podman.socket

## Build Deps
readonly WORKSPACE="$(pwd)"
dnf5 install -y rust cargo
TMPFILE="$(mktemp -d /tmp/cargo-home.XXXXXXXXXX)" || exit 1
export CARGO_HOME="${TMPFILE}/"

## SwayFX
dnf5 -y copr enable swayfx/swayfx
dnf5 install --setopt=install_weak_deps=false -y swayfx
dnf5 install -y sway-systemd swayidle qt5-qtwayland qt6-qtwayland

## Waybar
dnf5 install --setopt=install_weak_deps=false -y waybar

## TODO: build and install Ironbar to compare w/ Waybar

## Onagre w/ Launcher
## TODO: RPM packaging?
## FIXME(2025-10-28): this is breaking builds
# TMPFILE="$(mktemp -d /tmp/pop-launcher-build.XXXXXXXXXX)" || exit 1
# cd "${TMPFILE}"
# git clone --depth=1 --branch='1.2.1' https://github.com/pop-os/launcher.git launcher
# cd ./launcher
## patch out the PopOS-specific scripts
# rm -rf ./scripts/system76-power
## patch justfile for better root prefix handling
# sed -i "s|rootdir + '/usr/'|rootdir + 'usr/'|g" ./justfile
# just vendor
# just vendor=1
# just rootdir=/ \
#   plugins="desktop_entries files find pulse recent scripts terminal web" \
#   install
# cd "${WORKSPACE}"
# TMPFILE="$(mktemp -d /tmp/onagre-build.XXXXXXXXXX)" || exit 1
# cd "${TMPFILE}"
# git clone --depth=1 --branch='1.1.0' https://github.com/onagre-launcher/onagre.git onagre
# cd ./onagre
# cargo build --release --locked
# install -Dm0755 target/release/onagre /usr/bin/
# cd "${WORKSPACE}"

### Removals

### Configurations

## Overwrite the default Sway configs for Bluefin DX
## FIXME(2025-10-28): need to update checksum
## overwrite_with_checksum /tmp/configs/sway/config "$(cat /tmp/configs/sway/config.orig.sha1)" /etc/sway/config

## Add default Onagre configs
## FIXME(2025-10-28): Onagre builds not workin ATM
# install -Dm0644 /tmp/configs/onagre/theme.scss /etc/xdg/onagre/

### Finishing

## Cleanup and remove dnf5/temp install tools
dnf5 remove -y rust cargo
export -n CARGO_HOME
dnf5 autoremove -y
dnf5 clean -y all
