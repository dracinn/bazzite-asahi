# Installing Bazzite Asahi on J313 (MacBook Air M1, 2020)

The development image is published at:

```
ghcr.io/dracinn/bazzite-asahi:j313        # moving dev tag
ghcr.io/dracinn/bazzite-asahi:j313-<sha>  # immutable per-commit tag
```

It is an rpm-ostree compose image (ostree-native container), unsigned, public.
Do not install on a machine whose macOS/APFS installation you need to keep —
see "Test policy" in J313.md.

## Path A — rebase from Fedora Asahi Remix Atomic (recommended)

The least invasive route: let the Asahi Installer set up the Apple boot
environment and a working Atomic install, then rebase onto this image.

1. From macOS on the J313, run the Asahi installer:

   ```
   curl https://alx.sh | sh
   ```

2. Choose the Fedora Asahi Remix Atomic option (Kinoite variant) and let the
   installer create the APFS container and stub OS. Do not touch APFS
   structures manually.

3. Boot the installed system once to confirm the m1n1/U-Boot/UEFI chain and
   Fedora Asahi userspace work.

4. Rebase onto the Bazzite Asahi image:

   ```
   sudo rpm-ostree rebase \
     ostree-unverified-registry:ghcr.io/dracinn/bazzite-asahi:j313
   ```

   Then reboot. `ostree-unverified-registry` is required because the image is
   not signed yet (Phase 2 roadmap item).

5. If the new deployment fails to boot, pick the previous deployment from the
   bootloader menu, or run `rpm-ostree rollback` after booting it.

## Path B — manual install via UEFI environment and bootc

Use this to validate the bare UEFI path or when no Fedora Asahi install exists.

1. Asahi installer → "UEFI environment only (no OS)". This creates the APFS
   stub with m1n1 + U-Boot and leaves free space for the OS.

2. Boot a Fedora aarch64 live/server ISO from USB through the UEFI boot
   picker.

3. Partition only the free space — never the APFS containers or the Asahi
   ESP. A standard aarch64 layout works: a FAT32 ESP plus a root filesystem
   (ext4/btrfs/xfs are all fine for bootc).

4. From the live environment:

   ```
   sudo bootc install to-existing-root \
     --root-ssh-config ~/.ssh \
     ghcr.io/dracinn/bazzite-asahi:j313
   ```

   See `bootc install to-existing-root --help` for exact mount expectations;
   the root must be mounted at the sysroot location the command prints.

5. Reboot and pick the Linux entry in the UEFI boot picker.

## Firmware boundary

m1n1, U-Boot and Apple device firmware are not owned by this image. The image
ships `update-m1n1` and `asahi-fwupdate` so a booted system can refresh the
boot chain, but OS image updates must never be treated as proof that m1n1 or
Apple firmware is current. If boot regresses after an OS update, suspect the
deployment first; if the machine will not reach U-Boot at all, suspect the
Asahi-side boot artifacts.

## After install

Work through the validation matrix in J313.md — display, keyboard, SPI-HID
trackpad, Wi-Fi, suspend, and the Atomic lifecycle items (update, rollback,
failed-deployment recovery).
