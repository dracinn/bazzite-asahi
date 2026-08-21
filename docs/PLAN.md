# Bazzite Asahi Plan

## Objective
Build a Bazzite-like Fedora Atomic/bootc gaming image for Apple Silicon while preserving Fedora Asahi Remix hardware enablement and boot compatibility.

## Design rule
Asahi owns the hardware layer. Bazzite-style customizations live above it.

## Phase 0 — Baseline inventory
- Capture kernel, firmware, Mesa/Vulkan, audio, boot, and Asahi package inventory from a known-good Fedora Asahi install.
- Record machine model and working hardware.
- Identify packages/configuration that must never be replaced by generic Bazzite components.

## Phase 1 — Userspace prototype
- Start from Fedora Asahi KDE.
- Add Bazzite-like userspace pieces incrementally.
- Validate Steam, Flatpak, MangoHud, vkBasalt, Gamescope where usable, controller support, and ujust-style tooling.
- Use Asahi's supported muvm/FEX path for translated x86/x86-64 workloads.

## Phase 2 — Atomic/bootc image
- Build an aarch64 OCI/bootc image.
- Preserve Asahi kernel, DTBs, firmware, audio safety configuration, boot integration, and Apple-specific platform services.
- Avoid Bazzite OGC kernel and x86-only akmods assumptions.

## Phase 3 — Installer integration
- Keep the Asahi macOS-side installer and Apple boot-policy flow.
- Use m1n1 + U-Boot as provided by Asahi.
- Deploy the Bazzite-Asahi image only after the platform boot chain is established.

## Phase 4 — Gaming validation
- Native aarch64 applications.
- Steam compatibility through muvm/FEX.
- Proton validation.
- Gamescope validation.
- Input/controller validation.
- Performance and thermal testing.

## Initial target
Apple M1 MacBook Air first, then broader M1/M2 coverage after validation.
