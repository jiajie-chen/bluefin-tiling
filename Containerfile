## 1. BUILD ARGS
## These allow changing the produced image by passing different build args to adjust
## the source from which your image is built.
## Build args can be provided on the commandline when building locally with:
##   podman build -f Containerfile --build-arg SOURCE_TAG=40 -t local-image

## SOURCE_IMAGE arg can be anything from ublue upstream which matches your desired version:
## See list here: https://github.com/orgs/ublue-os/packages
ARG SOURCE_IMAGE="bluefin-dx"

## SOURCE_TAG arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG SOURCE_TAG="stable@sha256:f67b8daf2ea4e4edb9f0543272f2b43cd43d6a41f3755572d6bca4f3221b8165"

### 1a. COPY BUILD FILES
## Allow build scripts to be referenced without being copied into the final image
## (Alternatively, can bind mount the files directly)
FROM scratch AS ctx
COPY ./system_files /system_files
COPY ./build_files /build_files

### 2. BASE IMAGE
## this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}:${SOURCE_TAG}

### 2a. [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### 3. MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build.sh

### 4. LINTING
## Verify final image and contents are correct.
## NOTE: For /etc vs. /usr/etc, see: https://bootc-dev.github.io/bootc/filesystem.html#usretc
RUN bootc container lint
