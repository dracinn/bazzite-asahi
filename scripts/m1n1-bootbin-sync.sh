#!/bin/bash
# m1n1-bootbin-sync — keep ESP m1n1/boot.bin in step with the deployment.
#
# bootc/ostree image updates never touch the ESP, so the boot.bin written
# at install time drifts away from the m1n1/U-Boot/DTBs the current image
# expects. This regenerates it at every boot (same recipe as update-m1n1)
# and writes only when the bytes differ.
set -euo pipefail

ESP=/boot/efi
TARGET="$ESP/m1n1/boot.bin"
[ -d "$ESP/m1n1" ] || exit 0   # not an Asahi-ESP system

M1N1_BIN=""
for c in /usr/lib64/m1n1/m1n1.bin /usr/lib/m1n1/m1n1.bin /usr/lib/asahi-boot/m1n1.bin; do
    [ -f "$c" ] && M1N1_BIN="$c" && break
done

UBOOT_BIN=""
for c in /usr/share/uboot/apple_m1/u-boot-nodtb.bin \
         /usr/lib/u-boot-asahi/u-boot-nodtb.bin \
         /usr/lib/u-boot/apple_m1/u-boot-nodtb.bin \
         /usr/lib/asahi-boot/u-boot-nodtb.bin \
         /usr/lib/asahi-boot/u-boot.bin; do
    [ -f "$c" ] && UBOOT_BIN="$c" && break
done

KVER=$(uname -r)
[ -d "/usr/lib/modules/$KVER/dtb/apple" ] \
    || KVER=$(for kd in /usr/lib/modules/*; do [ -d "$kd/dtb/apple" ] && basename "$kd"; done | sort -V | tail -1)
DTBS=$(find "/usr/lib/modules/$KVER/dtb/apple" -name '*.dtb' 2>/dev/null | sort)

if [ -z "$M1N1_BIN" ] || [ -z "$UBOOT_BIN" ] || [ -z "$DTBS" ]; then
    echo "m1n1-bootbin-sync: missing components (m1n1='${M1N1_BIN:-none}' uboot='${UBOOT_BIN:-none}' dtbs='${DTBS:+yes}')" >&2
    exit 1
fi

TMP=$(mktemp)
{ cat "$M1N1_BIN"; cat $DTBS; gzip -cn "$UBOOT_BIN"; } > "$TMP"

if cmp -s "$TMP" "$TARGET" 2>/dev/null; then
    rm -f "$TMP"
else
    cp "$TARGET" "$TARGET.bak" 2>/dev/null || true
    cp "$TMP" "$TARGET.tmp" && mv "$TARGET.tmp" "$TARGET"
    rm -f "$TMP"
    echo "m1n1-bootbin-sync: updated $TARGET (backup: $TARGET.bak)"
fi
