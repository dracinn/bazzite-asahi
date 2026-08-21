# Compatibility Rules

## Preserve from Asahi / Fedora Asahi Remix

- Apple Silicon kernel configuration and platform enablement
- Device trees and machine-specific boot data
- m1n1 and U-Boot integration
- Apple firmware handling
- GPU/DRM/Mesa integration
- Audio DSP configuration and speaker-safety protections
- Wi-Fi, Bluetooth, NVMe, SMC, power-management, and other Apple-specific services

## Do not import blindly from current Bazzite

- OGC kernel replacement
- x86_64-only kernel packages
- i686-only assumptions
- x86-oriented akmods build stages
- NVIDIA stack
- AMD-specific kernel tuning
- Steam Deck-specific kernel hacks
- Binary packages with no aarch64 build

## Port candidates

- KDE configuration
- Flatpak setup
- ujust-style helper commands
- Steam/user-facing gaming configuration
- MangoHud where available
- vkBasalt where available
- Gamescope where supported
- Controller configuration
- Codecs and desktop quality-of-life tweaks

Every candidate must be tested independently against the Asahi baseline before inclusion in the bootc image.
