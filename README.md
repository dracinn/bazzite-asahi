# Bazzite Asahi

A private planning and implementation repository for building a Bazzite-like Fedora Atomic/bootc gaming image for Apple Silicon while preserving Fedora Asahi Remix hardware enablement and boot compatibility.

## Core principle

**Asahi owns the hardware-enablement layer; Bazzite-style components live above it.**

The project should preserve Apple Silicon boot and hardware integration instead of replacing it with Bazzite's current x86-oriented kernel, akmods, or hardware assumptions.

## Target architecture

```text
Apple boot policy / recoveryOS
        ↓
m1n1
        ↓
U-Boot
        ↓
Asahi-compatible kernel + DTBs
        ↓
Fedora Asahi Remix hardware stack
        ↓
Atomic / bootc system image
        ↓
Bazzite-style gaming and desktop layer
```

## Initial reference target

- Apple M1 MacBook Air
- aarch64
- Fedora Asahi Remix / Fedora 44 generation as the compatibility baseline
- KDE Plasma
- Asahi graphics stack
- Steam through the supported Asahi x86/x86-64 compatibility path where appropriate
- muvm + FEX for translated x86 workloads
- bootc/OCI image workflow

## Current phase

Baseline inventory and compatibility mapping.

See:

- [PROGRESS.md](PROGRESS.md) — current status and next actions
- [docs/PLAN.md](docs/PLAN.md) — staged implementation plan
- [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) — what must be preserved from Asahi and what can be ported from Bazzite
- [docs/FUTURE-INSTRUCTIONS.md](docs/FUTURE-INSTRUCTIONS.md) — structure for future hands-on build instructions

## First milestone

Produce a known-good Apple Silicon Fedora/Asahi baseline inventory, then construct the smallest possible aarch64 bootc image that preserves the Asahi platform stack before adding gaming features.
