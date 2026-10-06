# Architecture

## Layers
1. **Fedora Atomic base** — ARM64 userspace and immutable image foundation.
2. **Asahi hardware enablement** — kernel, firmware, m1n1/U-Boot integration, Mesa, audio and Apple platform packages.
3. **Bazzite layer** — desktop, gaming and quality-of-life components compatible with ARM64.
4. **Device layer** — model-specific configuration and validation, beginning with J313.
5. **Installation/update layer** — integration with the existing Asahi UEFI environment plus Atomic image/update lifecycle.

The upstream Bazzite build contains x86-specific package, kernel, multilib and akmods assumptions. Apple Silicon therefore uses a separate ARM64 image path.

## Build model
The image is composed with rpm-ostree compose image, following the Fedora Asahi Atomic Desktop build model. The normal Containerfile remains a fast dependency/bootstrap check, but successful development builds must come from the reproducible compose path.

The desired output is a bootable OCI image that can be consumed by the appropriate Fedora/Asahi Atomic installation workflow.

## Boot model
The project does **not** replace the Apple boot chain.

The intended path is:
1. Asahi Installer prepares the Apple Silicon boot environment.
2. Apple's boot infrastructure selects the Asahi installation.
3. m1n1 provides the Apple Silicon boot stage.
4. Asahi U-Boot provides the UEFI environment.
5. The EFI bootloader loads the Bazzite Asahi kernel/initramfs.
6. The Atomic image provides the immutable OS userspace/root.

The exact EFI bootloader and boot artifact requirements must be verified against the current Fedora Asahi Atomic image definitions before custom boot-generation logic is added.

## Installation strategy
For workstation-class Apple Silicon hardware, prefer the Asahi Installer's minimal UEFI environment and a standard AArch64 bootable-media/UEFI workflow. Do not manually shrink or rearrange APFS containers.

A custom fork of the Asahi Installer or a prebuilt disk-image/ZIP installer is a fallback, not the default architecture. It should only be introduced when the standard UEFI path cannot provide a practical installation experience.

## Update strategy
Separate three lifecycles:
- **OS image:** Atomic/rpm-ostree or bootc-style image updates and rollback.
- **Asahi boot/firmware:** m1n1, U-Boot, device trees and required firmware.
- **Apple firmware/vendor state:** updates that must be retrieved through the supported macOS/Recovery/Asahi process.

The project must explicitly test that updating the OS image does not accidentally imply that m1n1 or Apple firmware is current.

## Compatibility rules
- ARM64-native packages first.
- No generic Fedora kernel layered over the Asahi kernel.
- No x86_64/i686 Bazzite multilib stack.
- No gaming compatibility layer before basic hardware boot is proven.
- Keep model-specific work isolated so additional M-series devices can reuse the common Apple Silicon layer.