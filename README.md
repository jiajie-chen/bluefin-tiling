# My Personal Bluefin Tiling

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/jiajie-chen-bluefin-tiling)](https://artifacthub.io/packages/search?repo=jiajie-chen-bluefin-tiling)

[![Build container image](https://github.com/jiajie-chen/bluefin-tiling/actions/workflows/build.yml/badge.svg)](https://github.com/jiajie-chen/bluefin-tiling/actions/workflows/build.yml)

[![Build disk images](https://github.com/jiajie-chen/bluefin-tiling/actions/workflows/build-disk.yml/badge.svg)](https://github.com/jiajie-chen/bluefin-tiling/actions/workflows/build-disk.yml)

This repo defines the custom setup I use for Bluefin, using the [ublue-os/image-template]().

The goal is to make it easy to bootstrap my system with tiling WMs for hobby development.

## Installing Image

There are two ways to install the distro:
* Rebasing from an existing bootc-based distro
* Using the provided installation media

> [!NOTE]
> Installation media is not built automatically (yet).

> [!TIP]
> The distro images are signed using [./`cosign.pub`](https://github.com/jiajie-chen/bluefin-tiling/blob/main/cosign.pub).

## Development

This repo was last updated to [`342dae4`](https://github.com/ublue-os/image-template/tree/342dae4afc916698c82dc49c5380990c1f19cc68)
of the upstream template repository.

Review the README in that repo to understand the prerequisites for development.

### Image Build

The build script entrypoint is in `build_files/build.sh`.
This is executed by in `Containerfile` to construct the image's contents.

#### Installing Packages

> Adapted from the `build_files/build.sh` comments in
> [ublue-os/image-template](https://github.com/ublue-os/image-template/tree/342dae4afc916698c82dc49c5380990c1f19cc68).

Packages can be installed from any enabled yum repo on the image.
RPMfusion repos are available by default in ublue main images.

> [!TIP]
> List of rpmfusion packages can be found here:
> - [Fedora 42 (x86_64)](https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/42/x86_64/repoview/index.html&protocol=https&redirect=1)

This installs a package from fedora repos
```bash
_dnf5_helper install tmux
```

For COPR repos:
```bash
## Enable COPR repo
_dnf5_helper copr enable ublue-os/staging
_dnf5_helper install package
## Disable COPRs so they don't end up enabled on the final image:
_dnf5_helper copr disable ublue-os/staging
## See also: https://github.com/ublue-os/bluefin/blob/stable-20251024/build_files/shared/copr-helpers.sh
```

Example for enabling a System Unit File:
```bash
systemctl enable podman.socket
```

For Flatpaks, use the [`preinstall.d` convention](https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-preinstall).
These are added to the image via `system_files/`.

#### System Files

Static system files to include in the image are in `system_files/`.
The files in this directory will be `rsync`'d into the image at root (`/`).
