# Roadmap

## Phase 1 — J313 bring-up

### 1. Build and composition
- [x] Verify Fedora 44 ARM64 Atomic/Kinoite base exists
- [x] Verify Fedora carries core Asahi userspace packages
- [x] Identify current Asahi kernel/U-Boot/Mesa build streams
- [x] Build an ARM64 container layer from the Fedora Asahi Atomic image
- [x] Add a reproducible rpm-ostree compose path for a bootable OCI archive
- [x] Fix the current Compose J313 failure
- [x] Produce and inspect a complete bootable OCI artifact
- [x] Publish a development OCI image for repeatable installation testing

### 2. Asahi installation path
- [ ] Validate the current Asahi Installer UEFI-only installation path
- [ ] Confirm the image EFI/boot requirements against the current Asahi UEFI environment
- [ ] Avoid maintaining a custom Asahi installer unless upstream integration requires it
- [x] Document the safe disk-preparation procedure for Apple Silicon
- [x] Add a reproducible installation/test procedure for J313

### 3. First boot
- [ ] Install the development image on a dedicated/test J313 installation
- [ ] Boot successfully through the normal Asahi m1n1/U-Boot/UEFI chain
- [ ] Validate internal display
- [ ] Validate keyboard and SPI-HID trackpad
- [ ] Validate keyboard backlight
- [ ] Validate Wi-Fi and Bluetooth
- [ ] Validate USB-C
- [ ] Validate NVMe/storage
- [ ] Validate speakers/headphone audio
- [ ] Validate microphone and camera
- [ ] Validate suspend/resume
- [ ] Validate battery/charging
- [ ] Validate thermal management
- [ ] Validate reboot/shutdown and boot-picker behavior

## Phase 2 — Atomic update and release infrastructure
- [ ] Establish the image registry/publishing workflow
- [ ] Establish signed image/update metadata
- [ ] Verify atomic update and rollback behavior on J313
- [ ] Define m1n1/firmware update handling separately from OS image updates
- [ ] Add CI image metadata and bootability checks
- [ ] Add installation smoke tests that do not modify a developer's primary disk

## Phase 3 — Bazzite userspace
- [ ] Add ARM64-compatible gaming packages
- [ ] Establish the ARM64 Steam strategy
- [ ] Evaluate Gamescope support
- [ ] Evaluate FEX/box64 and Proton compatibility
- [ ] Add Bazzite branding and first-boot configuration
- [ ] Add gaming/QoL packages only after the base J313 image is proven stable

## Phase 4 — Apple Silicon expansion
- [ ] Add additional M1/M2 Mac models
- [ ] Build a device-specific support matrix
- [ ] Add automated hardware smoke-test documentation
- [ ] Separate common Apple Silicon enablement from model-specific quirks

## Design rules
- Do not fork or replace Asahi components unnecessarily.
- Prefer Fedora/Asahi packages and upstream support.
- Keep the Apple Silicon path ARM64-native; do not pull Bazzite's x86_64/i686 kernel, multilib, or akmods assumptions into this image.
- Use Aurora Silicon components only where they provide a concrete, demonstrable advantage for a specific device or kernel path.
- Keep bootloader/firmware lifecycle separate from normal Atomic OS updates.
- Treat the Asahi Installer as the platform installation boundary rather than recreating Apple's disk/boot setup inside this project.

## Current implementation boundary
The GitHub Actions compose job is the OS image-build layer. It must first produce a valid bootable OCI image.

The installation milestone is intentionally **not** a custom EFI/boot/root partition-image generator. Asahi's current distribution guidance recommends using its minimal UEFI environment and the normal UEFI boot path for workstation-class distributions. A custom forked installer/disk-image flow should only be introduced if this project later has a concrete requirement for it.

Compose, inspection and registry publishing are done. The immediate blocker is now:

**Install the published development image on J313 via docs/INSTALL-J313.md and boot it through the current Asahi UEFI environment.**