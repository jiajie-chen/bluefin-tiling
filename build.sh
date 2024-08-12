#!/bin/bash
# NOTE: change `set` flags to accommodate edge cases
set -ouex pipefail

# NOTE: For /etc vs. /usr/etc, see: https://github.com/ublue-os/bluefin/pull/441#issuecomment-1694785648

## Setup

readonly RELEASE="$(rpm -E %fedora)"

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

## Installations

# Setup install tools
_wget -O /usr/bin/copr https://raw.githubusercontent.com/ublue-os/COPR-command/main/copr
chmod +x /usr/bin/copr
rpm-ostree install dnf5

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
#   https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1
# TODO: test using `dnf` for builds:
#   https://github.com/coreos/rpm-ostree/issues/718#issuecomment-2125711817

# TODO: can this be delegated to the Bazzite `copr` helper?
# copr enable swayfx/swayfx
copr_enable swayfx swayfx
dnf5 install --setopt=install_weak_deps=false -y swayfx
dnf5 install -y sway-systemd swayidle qt5-qtwayland qt6-qtwayland

## Removals
# TODO: `dnf swap` sway-wallpapers and swaybg and override default config

## Configurations

# Overwrite the default sway configs
# TODO: is moving to /usr/etc/ necessary?
mkdir -p /usr/etc/sway/
mv -n /etc/sway/* /usr/etc/sway/
sed -i.orig \
  -e '/^set \$term foot/c\set \$term ptyxis' \
  -e '/^output \* bg/c\output \* bg \/usr\/share\/backgrounds\/f40\/default\/f40-01-day.png fit' \
  /usr/etc/sway/config
printf 'swaybg_command -' > /usr/etc/sway/config.d/20-swaybg-command.conf

## Finishing

# Cleanup and remove dnf5
dnf5 clean all
rpm-ostree uninstall dnf5
