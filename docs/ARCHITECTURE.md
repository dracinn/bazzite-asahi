# Architecture

1. **Fedora Atomic base** — ARM64 userspace and immutable image foundation.
2. **Asahi hardware enablement** — kernel, firmware, m1n1/U-Boot, Mesa, audio and platform packages.
3. **Bazzite layer** — desktop, gaming and quality-of-life components compatible with ARM64.
4. **Device layer** — model-specific configuration and validation.

The upstream Bazzite build contains x86-specific package and kernel/akmods assumptions. Apple Silicon therefore gets a separate ARM64 image path rather than changing the existing production workflow prematurely.

Prefer Fedora/Asahi packages and upstream support. Use Aurora Silicon components where they provide a concrete advantage.
