# Ecosystem map — repos relevant to Bazzite Asahi on J313

Survey of upstream and adjacent projects. Grouped by what they provide to
this build. The CI watch (`dracinn/apple-silicon-watch` repo) tracks the
high-signal subset.

## Hardware enablement

| Repo | What it gives us |
|---|---|
| `AsahiLinux/linux` | Upstream Asahi kernel. Our `kernel-16k` comes from the Fedora @asahi COPR build of this tree. |
| `omacom/linux-aurora` | Aurora kernel tree (Asahi-derived), upstream of `aurora-silicon/linux`. |
| `aurora-silicon/linux` | Very active downstream on `aurora-stable` — DWC3 USB-C fixes, nvme-apple, ISP/camera work, G17 GPU ray queries, mt7932 wifi/BT. Watch for fixes we can take via the COPR or cherry-pick. |
| `AsahiLinux/m1n1` | Boot stage + hypervisor (SPTM support landing). Version in image via `m1n1` package. |
| `aurora-silicon/u-boot` | Asahi U-Boot fork with J700 (MacBook Neo) work on `aurora-wip`. Our U-Boot is `uboot-images-armv8` from Fedora. |
| `AsahiLinux/asahi-installer` / `asahi-installer-data` | Installer + OS catalog. The catalog format is what third-party payloads register into (see Bootsahi). |
| `AsahiLinux/asahi-fix27` | Fix for macOS 27 bootability flag from Linux — relevant since this machine is on Darwin 27. |
| `AsahiLinux/avd-fw` | Video decode firmware. |
| `nix-community/nixos-apple-silicon` | Most mature per-device docs/tooling (incl. J313): kernel config notes, firmware extraction, m1n1/uboot packaging. Read their J313 docs for quirks. |

## Audio (safety-critical on J313)

| Repo | What it gives us |
|---|---|
| `AsahiLinux/speakersafetyd` | Speaker protection daemon — **required**; unprotected speakers can be damaged. Verify it is in our image (should arrive via `asahi-platform-metapackage-audio`; it was not confirmed in the package dump). |
| `AsahiLinux/asahi-audio`, `alsa-ucm-conf-asahi` | Pipewire/ALSA config already pulled in via `asahi-remix.yaml`. |
| `aurora-silicon/speakerguardd` | Aurora's speakersafetyd-compatible interlock — alternative if upstream lags. |

## Install / image tooling

| Repo | What it gives us |
|---|---|
| `tuna-os/bootc-installer-asahi` (**Bootsahi**) | The missing piece: an asahi-installer catalog path for bootc images, explicitly designed for "Bluefin, Bazzite"-family OCI images. One bootstrap payload + first-boot `bootc install` of the chosen registry ref; includes a golden-manifest boot harness (qemu+U-Boot) and `asahi-bootbin-sync`. Long-term this replaces our `to-existing-root` conversion as the real install path. |
| `tuna-os/fisherman` | Backend installer service Bootsahi uses to run `bootc install`. |
| `tuna-os/tunaOS` (+ `bonito`/`grouper` images) | Working Asahi bootc distro — only two variants pass their boot manifest, useful precedent for what a "verified" image needs. |
| `omacom/omarchy-mac-installer` | Omarchy Mac's image pipeline: build → VM acceptance on ARM64 runners → release catalog. Reference for CI-side bootability testing without hardware. |
| `omarchy-mac` (distro) + `omarchy-mac/omarchy-pkgs-aarch64` | Arch/Hyprland Apple Silicon distro + aarch64 package builds — source of ARM64 userspace packages/configs (pkgbuilds, patches). |
| `leifliddy/*` Fedora Asahi builders, `quinneden/nixos-asahi-package` | Payload layout conventions Bootsahi also models on. |

## Phase 3 — gaming / x86 compat

| Repo | What it gives us |
|---|---|
| `AsahiLinux/muvm` | microVM wrapper — the modern path for x86 apps (Steam) on Asahi. Active. |
| `AsahiLinux/fex-emu-rootfs-generator` + `FEX-Emu/FEX` | FEX x86-64 emulation + rootfs generation. |
| `aurora-silicon/fex` | Aurora's FEX fork. |
| `aurora-silicon/aurora-steam-native` | Native ARM Steam attempt — worth watching; if it lands, the whole Steam story changes. |
| `AsahiLinux/hidpipe`, `binfmt-dispatcher` | Input passthrough / binfmt helpers used by the gaming stack. |

## Distributions worth diffing against

- **Fedora Asahi Remix Atomic** (kiwi-descriptions + @asahi COPRs) — our current base; check what their Atomic variant does for boot/m1n1 handling.
- **Omarchy Mac** — Arch-based, image+acceptance pipeline; their VM acceptance harness is the pattern to copy for pre-hardware CI boot checks.
- **TunaOS bonito/grouper-asahi** — only two catalog entries that passed Bootsahi's 36-check boot manifest; diff their image manifests vs ours to see what bootability actually requires (ESP layout, grub vs sd-boot, etc.).
- **NixOS Apple Silicon** — alternate packaging of the same kernel/firmware stack.

## J313-specific notes

- macOS 27 (this machine) may need `asahi-fix27` for boot-picker compatibility — J313.md already lists it in the validation matrix.
- DWC3 USB-C module-build fix (`aurora-silicon/linux` PR #321) — track whether the @asahi COPR kernel picks it up; affects USB-C/recovery behavior.
- `tiny-dfr` is in our package list but J313 has physical function keys — harmless, likely unneeded.
- `asahi-platform-metapackage*` already pulls most of the right stack; gaps to verify: `speakersafetyd`, `asahi-nvram`/`aurora-bless` handling, `update-m1n1` service wiring.

## Watchlist

The dedicated `dracinn/apple-silicon-watch` repo covers the signal-dense
subset: kernel/installer activity across Asahi, Aurora, Omarchy,
TunaOS/bootc installer, NixOS, and upstream Bazzite. Add repos to
`WATCH_REPOS` in that repo's workflow.
