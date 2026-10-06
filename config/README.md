# Fedora Asahi configuration notes

The Apple Silicon image uses the Fedora Asahi Remix Atomic Desktop manifests as its hardware-enablement source rather than rebuilding the Asahi stack in a generic Fedora Atomic container.

The compose path is pinned to the Fedora Atomic Desktop manifest commit used by the upstream Fedora Asahi Atomic image definitions. The local asahi-remix.yaml mirrors the Fedora Asahi package/repository layer.

Do not add the generic Fedora kernel or x86_64/i686 Bazzite kernel/akmods stack to this image. Fedora Asahi supplies the Apple Silicon kernel, U-Boot, Mesa, firmware integration and related platform packages.

The Bazzite layer should remain ARM64-safe until the base image boots on J313.

## Boot and installation boundary
The image build is responsible for producing the Atomic OS payload. It should not assume that an EFI System Partition exists during container composition.

EFI/bootloader installation belongs to the deployment environment and the current Asahi UEFI installation path. Do not add hard-coded paths for staged grubaa64.efi, ESP mounts, or other installer-only files to compose postprocess.

Before adding custom boot generation, compare the required EFI artifacts with the current Fedora Asahi Atomic image definitions and verify whether the existing bootable-container tooling already provides them.