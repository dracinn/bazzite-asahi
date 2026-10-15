# Build plan — bazzite-asahi (revised 2026-10-15)

Derived from the ecosystem survey (`docs/ECOSYSTEM.md`) and the watched-repo
issue tracker. Supersedes the phase layout in `ROADMAP.md` where they differ.

## Key upstream facts that shape the plan

1. **Upstream Bazzite wants this**: `ublue-os/bazzite#2155` (aarch64 via
   Fedora Asahi Remix) and `#2179` (m1n1/U-Boot integration) are open.
   Their intended pattern: build on `quay.io/fedora-asahi-remix-atomic-desktops/`
   images the same way x86 Bazzite layers on `ublue-os/main`.
2. **An official-ish Atomic Asahi build already exists**:
   `fedora-asahi-remix-atomic-desktops/images` (@travier / Fedora Asahi SIG)
   publishes kinoite/silverblue Asahi Atomic images with the same manifest
   layout we mirror locally (asahi-remix.yaml, kinoite-asahi-remix.yaml,
   the same .repo files, plus `base-atomic-asahi-remix.yaml` and a signing
   key). Install is their known blocker (issue #1); kiwi support is the
   long-term path (OSInside/kiwi#38).
3. **Bootloader updates can't go through ostree/bootc**: per the #2155
   thread, m1n1/U-Boot updates can't be delivered via image updates, and a
   stale boot.bin can render the system unbootable. Bootsahi's
   `asahi-bootbin-sync` component exists precisely to sync boot bins from
   the image to the ESP — we should adopt that mechanism rather than
   invent our own.
4. **Installer catalog (live)**: Fedora Asahi Remix 44 KDE/GNOME/Server/
   Minimal, UEFI-only (current + 6.18-DTS), tethered. No Atomic option —
   the bootc conversion path stands until kiwi/bootsahi lands. Note the
   F44→F45 version jump our conversion performs.
5. **Bootsahi (tuna-os/bootc-installer-asahi)** has the real long-term
   install path: asahi-installer payload → first-boot `bootc install` of a
   registry ref, gated by a 36-check golden boot manifest. Only
   bonito/grouper pass today. Its alpha is blocked on hardware testing —
   something we can actually help with.

## Phase 1 — realign the image (done 2026-10-15)

- [x] **Diffed vs `fedora-asahi-remix-atomic-desktops/images`**: same
      manifest layout — and their `asahi-remix.yaml` carries a postprocess
      ours lacked (copies `grubaa64.efi` into `EFI/BOOT/` so shim finds it;
      without it a bootc-installed system may not boot).
- [x] **Decision: layer on the upstream image.** They publish signed,
      daily kinoite/silverblue images for Fedora 43/44 — our compose was
      building rawhide. The Containerfile now does `FROM
      quay.io/fedora-asahi-remix-atomic-desktops/kinoite:44` +
      `dnf install` of our package set; compose manifests/workflow removed.
- [x] **`speakersafetyd` installed explicitly** in the layer (hardware-safety
      gate for J313, even if the metapackage already pulls it).
- [ ] Re-pin check: the watch's manifest-drift check no longer applies —
      replace with a "new upstream kinoite tag" check or drop it.

## Phase 2 — install path (hardware)

- [ ] Rebuild the USB kit after the Phase-1 image lands (kit was wiped).
- [ ] Path A (current): Asahi installer → Fedora Asahi Remix 44 KDE →
      `bootc install to-existing-root` (documented in INSTALL-J313.md).
      Upstream suggests `to-filesystem` is their intended variant — test
      and reconcile which actually survives on real hardware.
- [ ] Record results in `docs/J313.md` matrix via `validate-j313.sh`.
- [ ] Known-flaky areas to exercise first (from watched issues):
      suspend/resume (omacom/linux-aurora#123/#124 PMP/thunderbolt s2idle),
      USB-C + external display (aurora-silicon/linux#275 DCP/tipd recovery),
      display-after-poweroff (AsahiLinux/linux#582 drm crash latch),
      SEP/Touch ID after reboot (aurora-silicon/linux#69),
      macOS 27 bootability flag (AsahiLinux/asahi-fix27 — this machine).
- [ ] Boot.bin lifecycle: verify `update-m1n1` runs correctly post-install;
      document that image updates do NOT update m1n1/U-Boot, and test
      rollback behavior after a failed boot.

## Phase 3 — Bootsahi / proper installer (parallel, no hardware needed to start)

- [ ] Read Bootsahi `docs/DESIGN.md` + `install-config.schema.json`; run
      their `make-payload.sh` against our ociarchive locally (qemu+U-Boot
      harness is their opt-in `test-bootstrap-boot.sh`).
- [ ] Contribute our image ref to their catalog once it can pass the
      36-check golden manifest — this also helps unblock their alpha
      (they're hardware-starved, issue #154/#160).
- [ ] Adopt `asahi-bootbin-sync` (or equivalent) so boot bins sync from
      image → ESP on update — closes the "update renders unbootable" gap.

## Phase 4 — Bazzite userspace (after first boot validated)

- [ ] Reference: `xXJSONDeruloXx/bazzite` `asahi-build` branch (28-file
      draft, got Bazzite booting on M2 Max) — especially their fex/box64
      OOTB approach.
- [ ] x86 gaming path: `AsahiLinux/muvm` + FEX (`fex-emu-rootfs-generator`),
      watch `aurora-silicon/aurora-steam-native`.
- [ ] Gamescope/Steam only after display+audio matrix passes.

## Phase 5 — upstream convergence

- [ ] Track ublue-os/bazzite#2155: if upstream's Asahi build lands, the
      endgame for this repo is the Bazzite layer on the shared Asahi
      base — coordinate with travier/Fedora Asahi SIG rather than
      diverging.

## Open questions

- Bootsahi catalog accepts third-party refs? (Read their schema/CI gate.)
- Does the upstream kinoite:44 image include everything the old compose
  pulled (e.g. `asahi-platform-metapackage` chain)? CI's package-verify
  step asserts the essentials.
