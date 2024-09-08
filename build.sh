#!/bin/bash
# NOTE: change `set` flags to accommodate edge cases
set -ouex pipefail

# NOTE: For /etc vs. /usr/etc, see: https://github.com/ublue-os/bluefin/pull/441#issuecomment-1694785648

## Setup

readonly RELEASE="$(rpm -E %fedora)"
readonly WORKSPACE="$(pwd)"

# wget wrapper, sets default flags
function _wget {
  wget --secure-protocol=TLSv1_3 --hsts-file=/tmp/.wget-hsts "$@"
  return
}

# For COPR enablement, pass in `user` and `project`
# NOTE: See https://github.com/ublue-os/bazzite/blob/cbc41100a641dee1bb4abd96909678981d194ae9/Containerfile#L168-L193
function copr_enable {
  if [[ "$#" -ne 2 ]]; then
    printf '%s expected 2 arguments, got %i' "$0" "$#"
    return 1
  fi
  local copr_user="$1"
  local copr_project="$2"
  local copr_dest="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:$copr_user:$copr_project.repo"
  local copr_url="https://copr.fedorainfracloud.org/coprs/$copr_user/$copr_project/repo/fedora-$RELEASE/$copr_user-$copr_project-fedora-$RELEASE.repo"
  if _wget -O "$copr_dest" "$copr_url"; then
    # TODO: maybe some checksumming, GPG verification, etc.
    return 0
  fi
  return
}

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

# Setup install tools
_wget -O /usr/bin/copr https://raw.githubusercontent.com/ublue-os/COPR-command/main/copr
chmod +x /usr/bin/copr
rpm-ostree install dnf5
dnf5 install -y rust cargo
TMPFILE="$(mktemp -d /tmp/cargo-home.XXXXXXXXXX)" || exit 1
export CARGO_HOME="${TMPFILE}/"

# Ensure flathub enabled
flatpak remote-add --system --noninteractive --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

## Installations

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
#   https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1
# Can also use `dnf5` for builds:
#   https://github.com/coreos/rpm-ostree/issues/718#issuecomment-2125711817

# SwayFX
# TODO: can this be delegated to the Bazzite `copr` helper?
# copr enable swayfx/swayfx
copr_enable swayfx swayfx
dnf5 install --setopt=install_weak_deps=false -y swayfx
dnf5 install -y sway-systemd swayidle qt5-qtwayland qt6-qtwayland

# Waybar
dnf5 install --setopt=install_weak_deps=false -y waybar

# TODO: build and install Ironbar to compare w/ Waybar

# Onagre w/ Launcher
# TODO: RPM packaging?
TMPFILE="$(mktemp -d /tmp/pop-launcher-build.XXXXXXXXXX)" || exit 1
cd "${TMPFILE}"
git clone --depth=1 --branch='1.2.1' https://github.com/pop-os/launcher.git launcher
cd ./launcher
# patch out the PopOS-specific scripts
rm -rf ./scripts/system76-power
# patch justfile for better root prefix handling
sed -i "s|rootdir + '/usr/'|rootdir + 'usr/'|g" ./justfile
just vendor
just vendor=1
just rootdir=/ \
  plugins="desktop_entries files find pulse recent scripts terminal web" \
  install
cd "${WORKSPACE}"
TMPFILE="$(mktemp -d /tmp/onagre-build.XXXXXXXXXX)" || exit 1
cd "${TMPFILE}"
git clone --depth=1 --branch='1.1.0' https://github.com/onagre-launcher/onagre.git onagre
cd ./onagre
cargo build --release --locked
install -Dm0755 target/release/onagre /usr/bin/
cd "${WORKSPACE}"

# LibreWolf
flatpak install --system --noninteractive --or-update flathub io.gitlab.librewolf-community

## Removals

# Firefox
flatpak uninstall --system --noninteractive --delete-data org.mozilla.firefox

## Configurations

# Overwrite the default Sway configs for Bluefin DX
# Also moving to /usr/etc/ since it will be overlaid onto /etc/
mkdir -p /usr/etc/sway/
mv -n /etc/sway/* /usr/etc/sway/
overwrite_with_checksum /tmp/configs/sway/config "$(cat /tmp/configs/sway/config.orig.sha1)" /usr/etc/sway/config

# Move the default Waybar configs
mkdir -p /usr/etc/xdg/waybar/
mv -n /etc/xdg/waybar/* /usr/etc/xdg/waybar/

# Add default Onagre configs
mkdir -p /usr/etc/xdg/onagre/
install -Dm0644 /tmp/configs/onagre/theme.scss /usr/etc/xdg/onagre/

# TODO: LibreWolf native messaging - need to symlink and configure for flatpaks
# https://librewolf.net/docs/faq/#how-do-i-get-native-messaging-to-work

# TODO: Fix up Bluefin justfiles for new system flatpaks: https://github.com/ublue-os/bluefin/blob/b31172b0f35a3e2b989c4d9bb25dde1ea4f1a480/just/bluefin-system.just#L267
# TODO: Fix up Bluefin rebase helper: https://github.com/ublue-os/bluefin/blob/b31172b0f35a3e2b989c4d9bb25dde1ea4f1a480/system_files/shared/usr/bin/ublue-rollback-helper

## Finishing

# Flatpak cleanup
flatpak --system -y uninstall --unused

# Cleanup and remove dnf5/temp install tools
dnf5 remove -y rust cargo
export -n CARGO_HOME
dnf5 autoremove -y
dnf5 clean -y all
rpm-ostree uninstall dnf5

# NOTE: invoke rpm-ostree outside of script to complete build cleanup
