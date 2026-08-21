# Future Build Instructions

This document defines how hands-on instructions should be added as the project matures.

## Instruction quality rules

Future procedures should:

- assume Apple Silicon / aarch64 unless explicitly stated otherwise;
- identify whether a command runs in macOS, Fedora Asahi, a container build environment, or recoveryOS;
- preserve the Asahi boot and hardware stack unless a change is explicitly researched and justified;
- include a verification command after each major change;
- include a rollback or recovery note for risky operations;
- avoid replacing Asahi kernel, firmware, device-tree, audio-safety, m1n1, or U-Boot components with generic Bazzite equivalents;
- record exact package names and versions when compatibility depends on them.

## Planned instruction sets

### 1. Baseline inventory
Collect all information needed from a known-good Fedora Asahi installation.

### 2. Development workstation setup
Install git, podman/buildah/bootc tooling, and any required Universal Blue development tools without modifying the working hardware stack.

### 3. Package compatibility matrix
Compare Fedora Asahi packages with Bazzite components and classify each as KEEP, PORT, REWORK, or SKIP.

### 4. Userspace prototype
Install Bazzite-like desktop and gaming components incrementally on Fedora Asahi and validate after each group.

### 5. Minimal ARM bootc image
Construct the smallest image that can reproduce the validated Asahi-compatible system state.

### 6. Gaming layer
Add Steam, muvm/FEX integration, MangoHud, vkBasalt, Gamescope where supported, and controller configuration.

### 7. Deployment
Document how the image is deployed behind Asahi's Apple boot-policy, m1n1, and U-Boot flow.

### 8. Recovery
Document how to return to a known-good Fedora Asahi deployment if a bootc image fails.

## Per-step template

```text
Goal:
Environment:
Prerequisites:
Commands:
Expected result:
Verification:
Rollback:
Notes / known limitations:
```

Do not convert exploratory commands into official instructions until they have been tested on the reference machine.
