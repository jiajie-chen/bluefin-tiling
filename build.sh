#!/bin/bash
# NOTE: change `set` flags to accommodate edge cases
# set -ouex pipefail
set -xu

## Setup

readonly RELEASE="$(rpm -E %fedora)"

# For COPR enablement, pass in `user` and `project`
function copr_enable {
  if [[ "$#" -ne 2 ]]; then
    printf '%s expected 2 arguments, got %i' "$0" "$#"
    return 1
  fi
  local copr_user="$1"
  local copr_project="$2"
  local copr_dest="/usr/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:$copr_user:$copr_project.repo"
  local copr_url="https://copr.fedorainfracloud.org/coprs/$copr_user/$copr_project/repo/fedora-$RELEASE/$copr_user-$copr_project-fedora-$RELEASE.repo"
  if wget --secure-protocol=TLSv1_3 -O "$copr_dest" "$copr_url"; then
    # TODO: maybe some checksumming, GPG verification, etc.
    return 0
  fi
  return 1
}

## Installations

rpm-ostree install dnf5

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
#   https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1
# TODO: test using `dnf` for builds:
#   https://github.com/coreos/rpm-ostree/issues/718#issuecomment-2125711817

dnf copr enable swayfx/swayfx \
&& dnf install --setopt=install_weak_deps=false -y swayfx \
&& dnf install -y sway-systemd swayidle qt5-qtwayland qt6-qtwayland \
|| exit 1

## Removals
# TODO: `dnf swap` sway-wallpapers and swaybg and override default config

## Configurations

# Overwrite the default sway configs
# TODO: consider `dnf swap` to sway-config-minimal
mkdir -p /usr/etc/sway/config.d/ \
&& mv -n /etc/sway/* /usr/etc/sway/ \ 
&& sed -i.orig \
  -e '/^set \$term foot/c\set \$term ptyxis' \
  -e '/^output \* bg/c\output \* bg \/usr\/share\/backgrounds\/f40\/default\/f40-01-day.png fit' \
  /usr/etc/sway/config \
|| exit 1
printf 'swaybg_command -' > /usr/etc/sway/config.d/20-swaybg-command.conf

## Finishing

dnf clean all \
&& rpm-ostree uninstall dnf5 \
|| exit 1
