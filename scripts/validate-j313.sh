#!/usr/bin/env bash
# Bazzite Asahi J313 validation — reports hardware/Atomic state.
# Read-only; run on the installed system. Works fully offline.
# Usage: bash validate-j313.sh

set -u

pass=0; fail=0; manual=0; skip=0

report() {
    case "$1" in
        PASS)   pass=$((pass+1));;
        FAIL)   fail=$((fail+1));;
        MANUAL) manual=$((manual+1));;
        SKIP)   skip=$((skip+1));;
    esac
    printf '%-6s  %-26s  %s\n' "$1" "$2" "$3"
}

have() { command -v "$1" >/dev/null 2>&1; }

## Platform

krel=$(uname -r)
case "$krel" in
    *asahi*) report PASS kernel "asahi kernel $krel" ;;
    *)       report FAIL kernel "unexpected kernel $krel" ;;
esac

if [ "$(uname -m)" = aarch64 ]; then
    report PASS arch "aarch64"
else
    report FAIL arch "$(uname -m)"
fi

## Atomic deployment

if have rpm-ostree && have python3; then
    img=$(rpm-ostree status --json 2>/dev/null | python3 -c \
        'import json,sys; d=json.load(sys.stdin); print(d["deployments"][0].get("container-image-reference") or "")' 2>/dev/null)
    case "$img" in
        *bazzite-asahi*) report PASS deployment "$img" ;;
        *) report FAIL deployment "unexpected image: ${img:-none}" ;;
    esac
    n=$(rpm-ostree status --json 2>/dev/null | python3 -c \
        'import json,sys; print(len(json.load(sys.stdin)["deployments"]))' 2>/dev/null)
    report MANUAL lifecycle "${n:-?} deployment(s); test update/rollback per J313.md"
else
    report SKIP deployment "rpm-ostree or python3 not found"
fi

## Display

con=$(grep -l '^connected' /sys/class/drm/card*/*/status 2>/dev/null | head -1)
if [ -n "$con" ]; then
    report PASS display "connected connector: $(basename "$(dirname "$con")")"
else
    report FAIL display "no connected DRM connector"
fi

## Input

if grep -qiE 'keyboard' /proc/bus/input/devices 2>/dev/null; then
    report PASS keyboard "$(grep -m1 -iE 'keyboard' /proc/bus/input/devices | sed 's/^.*Name="//;s/"$//')"
else
    report FAIL keyboard "no keyboard input device"
fi

if grep -qiE 'trackpad|applespi' /proc/bus/input/devices 2>/dev/null; then
    report PASS trackpad "$(grep -m1 -iE 'trackpad|applespi' /proc/bus/input/devices | sed 's/^.*Name="//;s/"$//')"
else
    report FAIL trackpad "no SPI-HID trackpad device"
fi

leds=$(ls -d /sys/class/leds/*kbd* /sys/class/leds/*backlight* 2>/dev/null | head -1)
if [ -n "$leds" ]; then
    report PASS kbd-backlight "$(basename "$leds")"
else
    report FAIL kbd-backlight "no backlight LED device"
fi

## Connectivity / storage

wifi=""
if have nmcli; then
    wifi=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
elif have iw; then
    wifi=$(iw dev 2>/dev/null | awk '/Interface/{print $2; exit}')
fi
if [ -n "$wifi" ]; then
    report PASS wifi "interface $wifi"
else
    report FAIL wifi "no wifi interface"
fi

if ls /sys/class/bluetooth/hci* >/dev/null 2>&1; then
    report PASS bluetooth "hci present"
else
    report FAIL bluetooth "no hci device"
fi

if ls /sys/class/typec/port* >/dev/null 2>&1 || have lsusb && lsusb >/dev/null 2>&1; then
    report PASS usb-c "typec/usb bus present"
else
    report FAIL usb-c "no typec or usb devices"
fi

if ls /dev/nvme* >/dev/null 2>&1; then
    report PASS nvme "$(lsblk -dno NAME,SIZE /dev/nvme0n1 2>/dev/null | awk '{print $1" "$2}')"
else
    report FAIL nvme "no nvme device"
fi

## Audio / camera

if [ -s /proc/asound/cards ] && grep -q '^\s*[0-9]' /proc/asound/cards; then
    report PASS audio "$(sed -n 's/^[ ]*[0-9] \[\([^]]*\)\].*/\1/p' /proc/asound/cards | head -1 | xargs)"
else
    report FAIL audio "no sound cards"
fi

if grep -q 'capture' /proc/asound/pcm 2>/dev/null; then
    report PASS mic "capture pcm present"
else
    report FAIL mic "no capture pcm"
fi

if ls /dev/video* >/dev/null 2>&1; then
    report MANUAL camera "$(ls /dev/video* | tr '\n' ' ')— check image quality"
else
    report SKIP camera "no /dev/video* (Apple ISP camera may be unsupported)"
fi

## Power / thermals

bat=$(ls -d /sys/class/power_supply/* 2>/dev/null | xargs -I{} sh -c 'grep -l Battery {}/type 2>/dev/null' | head -1)
if [ -n "$bat" ]; then
    batdir=$(dirname "$bat")
    cap=$(cat "$batdir/capacity" 2>/dev/null)
    st=$(cat "$batdir/status" 2>/dev/null)
    report PASS battery "${cap:-?}% ${st:-?}"
else
    report FAIL battery "no battery power_supply"
fi

ac=$(ls -d /sys/class/power_supply/* 2>/dev/null | xargs -I{} sh -c 'grep -l -E "Mains|USB" {}/type 2>/dev/null' | head -1)
if [ -n "$ac" ]; then
    report PASS charging "$(basename "$(dirname "$ac")") present"
else
    report MANUAL charging "no mains adapter seen; plug in USB-C charger"
fi

zones=$(ls -d /sys/class/thermal/thermal_zone* 2>/dev/null | wc -l | tr -d ' ')
if [ "$zones" -gt 0 ]; then
    t=$(for z in /sys/class/thermal/thermal_zone*/temp; do cat "$z" 2>/dev/null; done | sort -n | tail -1)
    report PASS thermal "$zones zones, max ${t:-?} millidegC"
else
    report FAIL thermal "no thermal zones"
fi

if grep -q s2idle /sys/power/mem_sleep 2>/dev/null || grep -q mem /sys/power/state 2>/dev/null; then
    report MANUAL suspend "modes: $(cat /sys/power/mem_sleep 2>/dev/null || cat /sys/power/state); test systemctl suspend"
else
    report FAIL suspend "no sleep modes advertised"
fi

report MANUAL boot-picker "reboot and confirm macOS/Asahi picker intact"
report MANUAL shutdown "verify clean poweroff/reboot"

echo
echo "PASS=$pass  FAIL=$fail  MANUAL=$manual  SKIP=$skip"
[ "$fail" -eq 0 ]
