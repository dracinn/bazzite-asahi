#!/usr/bin/env bash
# make-installer-payload.sh — package a bootc aarch64 image as an
# asahi-installer OS payload:
#
#   out/<name>.zip           — esp/ tree (incl. m1n1/boot.bin) + boot.img + root.img
#   out/installer_data.json  — os_list entry pointing at the zip
#
# Direct-install layout mirroring the official Fedora Asahi Remix os_list
# entry (EFI + Boot + Root/expand): the user picks "Bazzite Asahi" in the
# installer and lands straight in the real OS — no bootstrap, no agent, no
# first-boot pull. Adapted from tuna-os/bootc-installer-asahi
# (make-payload.sh, MIT), which uses a bootstrap partition instead.
#
# Usage:
#   sudo ./make-installer-payload.sh <bootc-image-ref> <payload-name> [root-size-gb]
#
# Requirements: run as root on an aarch64 host (CI: ubuntu-24.04-arm),
# with podman.
set -euo pipefail

IMAGE="${1:?usage: make-installer-payload.sh <bootc-image-ref> <payload-name> [root-size-gb]}"
NAME="${2:?usage: make-installer-payload.sh <bootc-image-ref> <payload-name> [root-size-gb]}"
# Loopback disk size for `bootc install to-disk`; must hold the full
# installed desktop (ESP + boot + root). Not the device's disk layout —
# Root expands on install.
DISK_GB="${3:-16}"
OUT="${OUT_DIR:-out}"
PACKAGE_URL="${PACKAGE_URL:-${NAME}.zip}"
TITLE="${INSTALLER_TITLE:-Bazzite Asahi (Apple Silicon)}"
OS_NAME="${INSTALLER_OS_NAME:-Bazzite Asahi}"

WORK=$(mktemp -d)
mkdir -p "$OUT"

echo "==> Installing ${IMAGE} to a ${DISK_GB}G loopback disk (bootc install to-disk)..."
truncate -s "${DISK_GB}G" "$WORK/disk.img"
podman run --rm --privileged --pid=host \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers:/var/lib/containers \
    -v /dev:/dev \
    -v "$WORK":/work \
    "$IMAGE" \
    bootc install to-disk --generic-image --skip-fetch-check \
    --filesystem ext4 --via-loopback /work/disk.img

echo "==> Splitting ESP, boot and root out of the disk..."
LOOP=$(losetup --find --show -P "$WORK/disk.img")
cleanup() { losetup -d "$LOOP" 2>/dev/null || true; rm -rf "$WORK"; }
trap cleanup EXIT

# bootc to-disk layout: ESP (vfat), boot (small ext4), root. Identify by
# filesystem type + GPT label rather than assuming partition numbers.
ESP_PART="" BOOT_PART="" ROOT_PART=""
for part in "$LOOP"p*; do
    fstype=$(blkid -o value -s TYPE "$part" 2>/dev/null || true)
    plabel=$(blkid -o value -s PARTLABEL "$part" 2>/dev/null || true)
    case "$fstype:$plabel" in
    vfat:*)             ESP_PART="$part" ;;
    ext4:boot)          BOOT_PART="$part" ;;
    xfs:*|ext4:*|btrfs:*)
        [ "$plabel" = "boot" ] && continue
        ROOT_PART="$part" ;;
    esac
done
[ -n "$ESP_PART" ]  || { echo "ERROR: no ESP (vfat) partition found" >&2; exit 1; }
[ -n "$ROOT_PART" ] || { echo "ERROR: no root partition found" >&2; exit 1; }

mkdir -p "$WORK/esp"
mount -o ro "$ESP_PART" "$WORK/mnt-esp" --mkdir
cp -a "$WORK/mnt-esp/." "$WORK/esp/"
umount "$WORK/mnt-esp"

# The asahi-installer expects m1n1/boot.bin inside the ESP tree. On a real
# install update-m1n1 regenerates it; the payload must ship an initial one.
if [ ! -f "$WORK/esp/m1n1/boot.bin" ]; then
    echo "==> ESP has no m1n1/boot.bin — harvesting boot components from the image..."
    mkdir -p "$WORK/esp/m1n1"
    CTR=$(podman create "$IMAGE" true)
    MNT=$(podman mount "$CTR")
    # m1n1 + DTBs + gzipped u-boot, concatenated — same recipe as update-m1n1.
    M1N1_BIN=""
    for c in usr/lib64/m1n1/m1n1.bin usr/lib/m1n1/m1n1.bin usr/lib/asahi-boot/m1n1.bin; do
        [ -f "$MNT/$c" ] && M1N1_BIN="$MNT/$c" && break
    done
    UBOOT_BIN=""
    for c in usr/share/uboot/apple_m1/u-boot-nodtb.bin usr/lib/u-boot-asahi/u-boot-nodtb.bin usr/lib/u-boot/apple_m1/u-boot-nodtb.bin usr/lib/asahi-boot/u-boot-nodtb.bin usr/lib/asahi-boot/u-boot.bin; do
        [ -f "$MNT/$c" ] && UBOOT_BIN="$MNT/$c" && break
    done
    KVER=$(for kd in "$MNT/usr/lib/modules"/*; do [ -d "$kd/dtb/apple" ] && basename "$kd"; done | sort -V | tail -1)
    [ -n "$KVER" ] || { echo "ERROR: no Asahi kernel found (no dtb/apple/ in any /usr/lib/modules/*)" >&2; exit 1; }
    echo "==> Selected Asahi kernel: $KVER"
    DTBS=$(find "$MNT/usr/lib/modules/$KVER/dtb/apple" -name '*.dtb' 2>/dev/null | sort)
    [ -n "$M1N1_BIN" ] && [ -n "$UBOOT_BIN" ] && [ -n "$DTBS" ] || {
        echo "ERROR: image lacks m1n1/u-boot/DTBs — not an asahi-capable image?" >&2
        exit 1
    }
    { cat "$M1N1_BIN"; cat $DTBS; gzip -c "$UBOOT_BIN"; } > "$WORK/esp/m1n1/boot.bin"
    podman umount "$CTR" >/dev/null
    podman rm -f "$CTR" >/dev/null
fi

echo "==> Extracting partition images..."
BOOT_BYTES=0
if [ -n "$BOOT_PART" ]; then
    BOOT_BYTES=$(blockdev --getsize64 "$BOOT_PART")
    dd if="$BOOT_PART" of="$WORK/boot.img" bs=8M status=none
fi
ROOT_BYTES=$(blockdev --getsize64 "$ROOT_PART")
dd if="$ROOT_PART" of="$WORK/root.img" bs=8M status=none

ESP_BYTES=$(du -sb "$WORK/esp" | cut -f1)
# ESP partition needs headroom for vendor firmware the installer copies in.
ESP_SIZE=$(( ESP_BYTES / 1048576 + 500 ))MB

echo "==> Zipping payload..."
(cd "$WORK" && zip -r9 -q "$OLDPWD/$OUT/${NAME}.zip" esp boot.img root.img)

echo "==> Writing installer_data.json..."
BOOT_ENTRY=""
if [ "$BOOT_BYTES" -gt 0 ]; then
BOOT_ENTRY=',
          {
            "name": "Boot",
            "type": "Linux",
            "size": "'"${BOOT_BYTES}"'B",
            "image": "boot.img"
          }'
fi
cat > "$OUT/installer_data.json" <<EOF
{
  "os_list": [
    {
      "name": "${TITLE}",
      "default_os_name": "${OS_NAME}",
      "boot_object": "m1n1.bin",
      "next_object": "m1n1/boot.bin",
      "package": "${PACKAGE_URL}",
      "supported_fw": ["12.3", "12.3.1", "13.5", "14.8.3"],
      "expert": true,
      "partitions": [
        {
          "name": "EFI",
          "type": "EFI",
          "size": "${ESP_SIZE}",
          "format": "fat",
          "volume_id": "0x62617a7a",
          "copy_firmware": true,
          "copy_installer_data": true,
          "source": "esp"
        }${BOOT_ENTRY},
        {
          "name": "Root",
          "type": "Linux",
          "size": "${ROOT_BYTES}B",
          "expand": true,
          "image": "root.img"
        }
      ]
    }
  ]
}
EOF

echo "==> Done:"
ls -la "$OUT/"
