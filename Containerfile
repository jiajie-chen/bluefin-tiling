## 1. BUILD ARGS
# These allow changing the produced image by passing different build args to adjust
# the source from which your image is built.
# Build args can be provided on the commandline when building locally with:
#   podman build -f Containerfile --build-arg SOURCE_TAG=40 -t local-image

# SOURCE_IMAGE arg can be anything from ublue upstream which matches your desired version:
# See list here: https://github.com/orgs/ublue-os/packages?repo_name=bluefin
ARG SOURCE_IMAGE="bluefin"

## SOURCE_SUFFIX arg should include a hyphen and the appropriate suffix name
# aurora, bazzite and bluefin each have unique suffixes. Please check the specific image.
ARG SOURCE_SUFFIX="-dx"

## SOURCE_TAG arg must be a version built for the specific image: eg, 39, 40, gts, latest
ARG SOURCE_TAG="stable"

### 2. SOURCE IMAGE
# this is a standard Containerfile FROM using the build ARGs above to select the right upstream image
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

### 3. MODIFICATIONS
# make modifications desired in your image and install packages by modifying the build.sh script
# the following RUN directive does all the things required to run "build.sh" as recommended.
RUN --mount=type=bind,src=./build.sh,dst=/tmp/build.sh,relabel=private,ro=true \
    mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit

## NOTES:
# - /var/lib/alternatives is required to prevent failure with some RPM installs
# - All RUN commands must end with ostree container commit
#   see: https://coreos.github.io/rpm-ostree/container/#using-ostree-container-commit
