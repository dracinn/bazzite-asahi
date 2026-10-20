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
# can be damaged); install AND enable it — the base image ships it
# preset-disabled, which leaves speaker volumes locked at boot.
# usbmuxd/libimobiledevice enable iPhone USB tethering (ipheth); Android
# RNDIS tethering needs no extra packages. android-tools + sshuttle back
# phone-tether, the Tetrd replacement (Tetrd's Linux server is x86_64-only).
RUN dnf5 -y install \
        gamemode \
        zstd \
        usbmuxd \
        libimobiledevice-utils \
        speakersafetyd \
        asahi-scripts \
        android-tools \
        sshuttle \
    && dnf5 clean all \
    && rm -rf /var/log/* /var/cache/dnf \
    && systemctl enable speakersafetyd

# bootc updates never touch the ESP, so m1n1/boot.bin goes stale and can
# eventually fail to boot a newer image. This oneshot regenerates it from
# the running deployment each boot and writes only on change.
COPY scripts/m1n1-bootbin-sync.sh /usr/libexec/m1n1-bootbin-sync
COPY units/m1n1-bootbin-sync.service /usr/lib/systemd/system/m1n1-bootbin-sync.service
RUN chmod 0755 /usr/libexec/m1n1-bootbin-sync \
    && systemctl enable m1n1-bootbin-sync

# phone-tether: Tetrd replacement (Android over ADB + Termux sshd + sshuttle).
COPY --chmod=0755 scripts/phone-tether.sh /usr/bin/phone-tether

# Phase 4: Asahi gaming stack — hardware baseline passed 2026-10-16.
# steam comes from the official @asahi/steam COPR (FEX + muvm x86 path);
# everything else is Fedora proper or the already-enabled @asahi/mesa.
# The steam package is only a launcher; the client downloads on first run.
COPY repos/asahi-steam.repo /etc/yum.repos.d/asahi-steam.repo
RUN dnf5 -y install \
        fex-emu \
        muvm \
        box64 \
        gamescope \
        xwayland-run \
        virglrenderer \
        steam \
    && dnf5 clean all \
    && rm -rf /var/log/* /var/cache/dnf
