# Roadmap

## Phase 1 — J313 bring-up
- [x] Verify Fedora 44 ARM64 Atomic/Kinoite base exists
- [x] Verify Fedora carries core Asahi userspace packages
- [x] Identify current Asahi kernel/U-Boot/Mesa build streams
- [x] Build an ARM64 container layer from the Fedora Asahi Atomic image
- [x] Add a reproducible rpm-ostree compose path for a bootable OCI archive
- [ ] Publish the composed OCI image
- [ ] Generate an Asahi-installer-compatible boot/root image package
- [ ] Install the Asahi boot payload on J313
- [ ] Boot and validate display, keyboard, trackpad, Wi-Fi, Bluetooth, audio, USB-C and NVMe

## Phase 2 — Bazzite userspace
- [ ] Add ARM64-compatible gaming packages
- [ ] Establish Gamescope/Steam strategy for ARM64
- [ ] Evaluate FEX/box64 and Proton compatibility
- [ ] Add image publishing
- [ ] Add Bazzite branding and first-boot configuration

## Phase 3 — Apple Silicon expansion
- [ ] Additional M1/M2/M3/M4 Mac models
- [ ] Device-specific validation matrix
- [ ] Automated hardware smoke-test documentation

## Design rule

Do not fork or replace Asahi components unnecessarily. Prefer Fedora/Asahi
packages and upstream support; use Aurora Silicon components only where they
provide a concrete advantage or are needed for a specific device/kernel path.

## Current implementation boundary

The GitHub Actions compose job produces a bootable OCI archive using the same
rpm-ostree compose model used by Fedora Asahi Atomic Desktop images. This is
the correct image-build layer, but it is not yet the final Asahi installer
ZIP. The installer requires a boot payload plus separate EFI, boot and root
partition images.
