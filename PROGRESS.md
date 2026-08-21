# Progress

## Status

**Phase 0 — Baseline inventory and compatibility mapping**

The project structure and architecture rules are being established before any image build work begins.

## Completed

- Private GitHub repository created.
- Initial architecture documented.
- Asahi-vs-Bazzite compatibility boundaries documented.
- Initial reference hardware chosen: Apple M1 MacBook Air.
- Project direction chosen: preserve Asahi boot/hardware enablement and layer Bazzite-style userspace above it.

## Next actions

1. Capture the reference Fedora Asahi system inventory:
   - architecture and kernel
   - Fedora release
   - Asahi/m1n1/U-Boot packages
   - Mesa/Vulkan stack
   - audio and firmware packages
   - enabled repositories
2. Record known-working hardware on the reference machine.
3. Build a package matrix with three categories:
   - **KEEP** — required Asahi platform components
   - **PORT** — Bazzite features that appear architecture-independent
   - **BLOCKED/REWORK** — x86-, OGC-kernel-, Deck-, AMD-, or NVIDIA-specific pieces
4. Prototype Bazzite-style userspace additions on a normal Fedora Asahi install.
5. Only after the userspace prototype is stable, begin the aarch64 bootc image.

## Milestones

- [x] M0 — Repository and architecture plan
- [ ] M1 — Known-good Asahi baseline inventory
- [ ] M2 — Bazzite package compatibility matrix
- [ ] M3 — Fedora Asahi userspace prototype
- [ ] M4 — Minimal aarch64 bootc image
- [ ] M5 — Steam + muvm/FEX gaming stack
- [ ] M6 — Gamescope/controller validation
- [ ] M7 — Installer/deployment workflow
- [ ] M8 — Repeatable build instructions

## Decision log

### Preserve Asahi foundation
The project will not begin by recompiling the existing Bazzite image for ARM. Hardware enablement and boot integration remain Asahi/Fedora Asahi responsibilities.

### First hardware target
Apple M1 MacBook Air is the initial validation machine. Broader M1/M2 support comes after the first working image.

### x86 application strategy
Use the Asahi-supported muvm/FEX approach rather than treating standalone FEX configuration as the platform foundation.
