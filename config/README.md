# Fedora Asahi configuration notes

The Apple Silicon image uses the Fedora Asahi Remix Atomic Desktop manifests
as its hardware-enablement source rather than rebuilding the Asahi stack in a
generic Fedora Atomic container.

The compose path is pinned to the Fedora Atomic Desktop manifest commit used
by the upstream Fedora Asahi Atomic image definitions. The local
asahi-remix.yaml mirrors the current Fedora Asahi package/repository layer and
includes the Apple-specific GRUB EFI workaround.

Do not add the generic Fedora kernel or x86_64/i686 Bazzite kernel/akmods
stack to this image. Fedora Asahi supplies the Apple Silicon kernel, U-Boot,
Mesa, firmware integration and related platform packages.

The Bazzite layer should remain ARM64-safe until the base image boots on J313.
