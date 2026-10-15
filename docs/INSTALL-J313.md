# Installing Bazzite Asahi on J313 (MacBook Air M1, 2020)

The development image is published at:

```
ghcr.io/dracinn/bazzite-asahi:j313        # moving dev tag
ghcr.io/dracinn/bazzite-asahi:j313-<sha>  # immutable per-commit tag
```

It is an ostree-native bootc container image layered on the Fedora Asahi Remix Atomic kinoite base, keyless-signed
with cosign from the GitHub Actions identity. Verify a tag before install:

```
cosign verify \
  --certificate-identity-regexp "https://github.com/dracinn/bazzite-asahi/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/dracinn/bazzite-asahi:j313
```

Signing currently provides provenance; install-time signature enforcement
(`ostree-image-signed:` plus a sigstore policy) is a later roadmap item.

Do not install on a machine whose macOS/APFS installation you need to keep —
see "Test policy" in J313.md.

## Connectivity without home broadband

The install path here assumes the uplink is a phone — Tetrd has no Linux
ARM64 client, so it cannot provide connectivity once booted into Linux.
Working alternatives:

- **Phone Wi-Fi hotspot** — simplest if the carrier allows it; J313 Wi-Fi
  works under the Asahi kernel once firmware is loaded.
- **Android USB tethering** — works out of the box: the kernel's RNDIS/NCM
  drivers expose `usb0` and NetworkManager runs DHCP on it.
- **iPhone USB tethering** — needs `ipheth` plus `usbmuxd` and a pairing
  step (`idevicepair pair` from `libimobiledevice-utils`); both packages
  are in the image. Trust must be accepted on the phone.
- **Fully offline** — two options, both macOS-side downloads only:
  Path A with a local `bazzite-asahi-j313.zip` placed in the installer's
  `os/` directory (recommended), or the `bazzite-asahi-j313-oci` Actions
  artifact on a USB stick used with Path B's `podman pull oci-archive:`.

## Path A — direct install via the Asahi installer (recommended)

CI packages the built image as an asahi-installer payload — an OS entry
just like "Fedora Asahi Remix" in the official catalog — so the whole
install happens through the normal Asahi flow on macOS. All downloads run
on macOS (works with Tetrd); the installed system needs no network.

The artifacts are per build:

- `bazzite-asahi-j313-installer` (Actions artifact) or release assets:
  `bazzite-asahi-j313.zip` (esp/ + boot.img + root.img) and
  `installer_data.json`.

1. On the J313 under macOS, fetch the official installer package the same
   way `alx.sh` does, then overlay our catalog + payload:

   ```
   PKG_VER=$(curl -sL https://cdn.asahilinux.org/installer/latest)
   curl -LO "https://cdn.asahilinux.org/installer/installer-$PKG_VER.tar.gz"
   mkdir -p ~/bazzite-asahi-install && cd ~/bazzite-asahi-install
   tar xf ~/Downloads/installer-$PKG_VER.tar.gz
   # from the bazzite-asahi-j313-installer Actions artifact:
   cp /path/to/installer_data.json .
   mkdir -p os && cp /path/to/bazzite-asahi-j313.zip os/
   ```

   The catalog's `package` field is a relative path, which the installer
   resolves to `os/bazzite-asahi-j313.zip` — no payload download happens
   during install (fully offline-capable).

2. Run it in expert mode and pick **Bazzite Asahi**:

   ```
   caffeinate -dis sudo -E env EXPERT=1 ./install.sh
   ```

   (The entry is marked `expert`, so it only appears with `EXPERT=1`.)
   The installer resizes APFS, writes the stub + ESP + partitions, and
   copies the payload in — all from local files.

3. Reboot, hold the power button for the boot picker, select the new OS
   entry and complete the one-time `bputil` blessing in recoveryOS as the
   Asahi flow instructs. First boot lands directly in Bazzite Asahi.

## Path B — convert a Fedora Asahi Remix install with bootc (fallback)

The Asahi Installer does not offer an ostree/Atomic variant, so there is no
Atomic base to rebase from. Instead, install the normal Fedora Asahi Remix
(a dnf-based system) and convert it in place with
`bootc install to-existing-root` — it reinitializes `/boot`/`/boot/efi`
and deploys the image while preserving the rest of the system under
`/sysroot` for later cleanup.

1. From macOS on the J313, run the Asahi installer:

   ```
   curl https://alx.sh | sh
   ```

   Choose **Fedora Asahi Remix** (KDE Plasma — it ships podman and
   NetworkManager; the minimal variant lacks podman, which the offline
   path needs). Do not touch APFS structures manually.

2. Boot the installed system once to confirm the m1n1/U-Boot/UEFI chain and
   Fedora Asahi userspace work.

3. Insert the USB disk and pull the image into local container storage:

   ```
   img=$(sudo podman pull -q \
     oci-archive:/run/media/$USER/Bazzite/bazzite-asahi-j313/bazzite-asahi-kinoite.ociarchive)
   sudo podman tag "$img" localhost/bazzite-asahi:j313
   ```

4. Convert the running system to the image:

   ```
   sudo podman run --rm --privileged \
     -v /dev:/dev \
     -v /var/lib/containers:/var/lib/containers \
     -v /:/target \
     --pid=host \
     --security-opt label=type:unconfined_t \
     localhost/bazzite-asahi:j313 \
     bootc install to-existing-root
   ```

   This rewrites `/boot` and `/boot/efi` (the Asahi m1n1/U-Boot stub is a
   separate partition and is not touched) and deploys the image as the new
   default boot entry. The previous system's files remain accessible under
   `/sysroot` after reboot — home data and `/etc` survive, but the old
   Fedora Asahi system itself no longer boots.

5. Reboot into the Bazzite Asahi deployment. If it fails to boot, the
   previous boot chain is gone with `/boot` — recovery means reinstalling
   via Path C or the Asahi installer, so only proceed once you accept that.

## Path C — manual install via UEFI environment and bootc

Use this to validate the bare UEFI path or when no Fedora Asahi install exists.

1. Asahi installer → "UEFI environment only (no OS)". This creates the APFS
   stub with m1n1 + U-Boot and leaves free space for the OS.

2. Boot a Fedora aarch64 live/server ISO from USB through the UEFI boot
   picker.

3. Partition only the free space — never the APFS containers or the Asahi
   ESP. A standard aarch64 layout works: a FAT32 ESP plus a root filesystem
   (ext4/btrfs/xfs are all fine for bootc).

4. Pull the image into the live environment's container storage and run
   `bootc install to-filesystem` against the mounted target:

   ```
   sudo podman pull oci-archive:/run/media/$USER/Bazzite/bazzite-asahi-j313/bazzite-asahi-kinoite.ociarchive
   sudo podman run --rm --privileged \
     -v /dev:/dev \
     -v /var/lib/containers:/var/lib/containers \
     -v /mnt/sysroot:/target \
     --pid=host \
     --security-opt label=type:unconfined_t \
     localhost/<image>:j313 \
     bootc install to-filesystem /target
   ```

   (`to-existing-root` converts the running host root; `to-filesystem`
   targets an externally created filesystem.) Check
   `bootc install to-filesystem --help` for the boot/ESP mount-spec flags
   on the installed bootc version — they differ across releases.

5. Reboot and pick the Linux entry in the UEFI boot picker.

## Firmware boundary

m1n1, U-Boot and Apple device firmware are not owned by this image. The image
ships `update-m1n1` and `asahi-fwupdate` so a booted system can refresh the
boot chain, but OS image updates must never be treated as proof that m1n1 or
Apple firmware is current. If boot regresses after an OS update, suspect the
deployment first; if the machine will not reach U-Boot at all, suspect the
Asahi-side boot artifacts.

## After install

Run the validation script (`scripts/validate-j313.sh` in this repo — copy it
onto the same USB stick if the machine is offline). It reports PASS/FAIL/
MANUAL/SKIP for every item in the J313.md matrix and is read-only.
