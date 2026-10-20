#!/bin/bash
# phone-tether — route this machine's traffic through an Android phone's
# mobile data over USB, as a Tetrd replacement (Tetrd's Linux server is
# x86_64-only). Like Tetrd's tethering mode, connections are made by an
# app on the phone: Termux runs sshd, adb forwards it over USB, and
# sshuttle turns it into a system-wide TCP + DNS tunnel.
#
# Phone (once): install Termux from F-Droid, then in Termux:
#   pkg install openssh python && passwd && sshd
# Enable Developer options -> USB debugging, plug in, accept the prompt.
set -euo pipefail

PORT=${PHONE_TETHER_PORT:-8022}
REMOTE="termux@127.0.0.1:$PORT"

need_phone() {
    if ! adb get-state >/dev/null 2>&1; then
        echo "phone-tether: no phone over ADB." >&2
        echo "  Enable USB debugging, plug in, accept the 'Allow USB debugging' prompt." >&2
        echo "  'adb devices' should list the phone as 'device'." >&2
        exit 1
    fi
    adb forward "tcp:$PORT" "tcp:$PORT" >/dev/null
}

case "${1:-up}" in
    setup)
        need_phone
        [ -f "$HOME/.ssh/id_ed25519" ] || ssh-keygen -t ed25519 -N '' -f "$HOME/.ssh/id_ed25519"
        echo "Copying SSH key to Termux (enter the password set with 'passwd' in Termux)..."
        ssh-copy-id -p "$PORT" termux@127.0.0.1
        echo "Done. Run 'phone-tether' to connect."
        ;;
    up)
        need_phone
        echo "Tunnelling all TCP + DNS through the phone. Ctrl+C to stop."
        exec sshuttle --dns -x 127.0.0.0/8 -r "$REMOTE" 0/0
        ;;
    down)
        adb forward --remove "tcp:$PORT" 2>/dev/null || true
        ;;
    *)
        echo "usage: phone-tether [setup|up|down]" >&2
        exit 2
        ;;
esac
