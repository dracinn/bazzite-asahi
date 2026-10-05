# Architecture

1. Fedora Atomic base — ARM64 userspace and immutable image foundation.
2. Asahi hardware enablement — kernel, firmware, m1n1/U-Boot, Mesa, audio and platform packages.
3. Bazzite layer — desktop, gaming and quality-of-life components compatible with ARM64.
4. Device layer — model-specific configuration and validation.
5. Installer layer — Asahi m1n1/UEFI payload plus EFI, boot and root images.

The upstream Bazzite build contains x86-specific package and kernel/akmods
assumptions. Apple Silicon therefore gets a separate ARM64 image path.

The image is composed with rpm-ostree compose image, following Fedora Asahi's
Atomic Desktop build model. A normal Dockerfile build is retained only as a
fast dependency/bootstrap check.

The final installation path must preserve the Asahi boot chain. The Asahi
installer handles the Apple-specific m1n1/U-Boot setup; our image should
provide the OS payload rather than replacing that boot machinery.

Prefer Fedora/Asahi packages and upstream support. Use Aurora Silicon
components where they provide a concrete advantage.
