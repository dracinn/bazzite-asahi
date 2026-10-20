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

## Phase 2 — install path (hardware) — DONE 2026-10-16

- [x] Installed via the direct installer payload (Phase 3's Path A) —
      the bootc-conversion path was never needed. Asahi installer ran
      from macOS, wrote the payload, first boot landed in Bazzite Asahi.
- [x] Recorded in `docs/J313.md`: validator PASS=17 FAIL=0, all manual
      items confirmed — camera, suspend/resume (s2idle), reboot/shutdown,
      hold-power boot picker, update → reboot → rollback round-trip.
- [x] Audio resolved: `speakersafetyd` was disabled in the base image
      (upstream preset); now enabled in-image. Cards + audible output
      confirmed. Known-flaky areas from watched issues did NOT reproduce
      (suspend, shutdown, USB-C — though external display untested).
- [x] Update lifecycle: `bootc update` delta pull (536 MB) → staged →
      reboot into new deployment → `rpm-ostree rollback` confirmed.
      Image updates never touch m1n1/U-Boot — boot.bin lifecycle still
      needs `asahi-bootbin-sync` or equivalent (Phase 3).

## Phase 3 — installer payload (in progress)

- [x] Evaluated Bootsahi (`tuna-os/bootc-installer-asahi`): their model is a
      bootstrap payload + first-boot `bootc install` of a registry ref —
      elegant, but requires internet *inside Linux* at first boot, which
      this project can't assume (Tetrd has no aarch64 client).
- [x] Adapted their `make-payload.sh` into `scripts/make-installer-payload.sh`
      with a **direct-install** layout matching the official Fedora Asahi
      os_list schema (EFI + Boot + Root/expand): the installer writes the
      real OS, first boot lands in Bazzite Asahi, zero Linux-side downloads.
- [x] Verify payload builds in CI (`payload` job in build-j313.yml).
- [x] Hardware-test the payload install on J313 — proven end-to-end
      2026-10-16 (partitioning, blessing, first boot all clean).
- [ ] If proven, cut a release hosting the zip + installer_data.json so the
      catalog URL is stable. Note: GitHub Releases caps assets at 2 GB;
      our zip is ~3.4 GB — split the archive or keep the artifact flow.
- [ ] Optional: contribute our ref to Bootsahi's catalog for users who DO
      have Linux-side internet (their alpha is hardware-starved —
      issue #154/#160).
- [x] Boot-bin sync — verified on hardware 2026-10-20.
      `m1n1-bootbin-sync` regenerates `m1n1/boot.bin` from the running
      deployment's m1n1 + DTBs + gzipped U-Boot, writes only on change,
      keeps `.bak`. Found+mounted the ESP itself via the device-tree
      `asahi,efi-system-partition` PARTUUID (bootc writes no fstab —
      discovered via esp-check; first unit version gated on a mounted
      path that never existed).

## Phase 4 — Bazzite userspace (in progress, started 2026-10-20)

- [x] Gaming stack added to the image: `steam` (@asahi/steam COPR,
      enabled via repos/asahi-steam.repo), `fex-emu`, `muvm`, `box64`,
      `gamescope`, `xwayland-run`, `virglrenderer` (@asahi/mesa).
      First steam launch downloads the client (~1-2 GB) — note for
      metered connections.
- [ ] Hardware-test: steam first launch via FEX+muvm, a native-aarch64
      game through box64, gamescope session.
- [ ] Reference: `xXJSONDeruloXx/bazzite` `asahi-build` branch (28-file
      draft, got Bazzite booting on M2 Max) — especially their fex/box64
      OOTB approach.
- [ ] Watch `aurora-silicon/aurora-steam-native` for Steam-native work.

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
