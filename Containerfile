# Bazzite Asahi — layered on the Fedora Asahi Remix Atomic (Kinoite) image.
#
# The upstream image (built daily by the Fedora Asahi SIG from
# fedora-asahi-remix-atomic-desktops/images) carries the Asahi kernel-16k,
# m1n1/U-Boot integration, Mesa, firmware, and the EFI/BOOT grubaa64.efi
# postprocess required for bootc-installed systems to boot via shim.
# This layer only adds ARM64-safe Bazzite-adjacent packages; do not add
# Bazzite's x86_64/i686 kernel or multilib stack here.
ARG BASE_IMAGE=quay.io/fedora-asahi-remix-atomic-desktops/kinoite:44
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="Bazzite Asahi" \
      org.opencontainers.image.description="Bazzite-oriented Fedora Atomic image for Apple Silicon Macs" \
      org.opencontainers.image.source="https://github.com/dracinn/bazzite-asahi" \
      org.opencontainers.image.vendor="Bazzite Asahi"

# speakersafetyd is hardware-safety-critical on J313 (unprotected speakers
# can be damaged); install explicitly even though the platform metapackage
# should already pull it in. usbmuxd/libimobiledevice enable iPhone USB
# tethering (ipheth); Android RNDIS tethering needs no extra packages.
RUN dnf5 -y install \
        gamemode \
        zstd \
        usbmuxd \
        libimobiledevice-utils \
        speakersafetyd \
    && dnf5 clean all \
    && rm -rf /var/log/* /var/cache/dnf

# Steam/Gamescope/Proton/FEX are deferred until J313 boot and hardware
# validation pass (see docs/J313.md).
