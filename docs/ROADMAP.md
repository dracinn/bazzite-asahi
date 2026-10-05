# Roadmap

## Phase 1 — J313 bring-up
- [x] Verify Fedora 44 ARM64 Atomic/Kinoite base exists
- [x] Verify Fedora carries core Asahi userspace packages
- [x] Identify current Asahi kernel/U-Boot/Mesa build streams
- [ ] Build a minimal J313 image
- [ ] Generate/install the Asahi boot payload
- [ ] Boot and validate display, keyboard, trackpad, Wi-Fi, Bluetooth, audio, USB-C and NVMe

## Phase 2 — Bazzite userspace
- [ ] Add ARM64-compatible gaming packages
- [ ] Establish Gamescope/Steam strategy for ARM64
- [ ] Evaluate FEX/box64 and Proton compatibility
- [ ] Add image publishing

## Phase 3 — Apple Silicon expansion
- [ ] Additional M1/M2/M3/M4 Mac models
- [ ] Device-specific validation matrix
- [ ] Automated hardware smoke-test documentation

## Design rule

Do not fork or replace Asahi components unnecessarily. Prefer Fedora/Asahi
packages and upstream support; use Aurora Silicon components only where they
provide a concrete advantage or are needed for a specific device/kernel path.
