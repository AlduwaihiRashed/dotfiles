#!/bin/sh
# Power profile picker backed by the org.freedesktop.UPower.PowerProfiles
# D-Bus interface (implemented here by tuned-ppd), using qdbus-qt6 since
# power-profiles-daemon's own CLI isn't installed on this system.

BUS_DEST=org.freedesktop.UPower.PowerProfiles
BUS_PATH=/org/freedesktop/UPower/PowerProfiles
BUS_IFACE=org.freedesktop.UPower.PowerProfiles

current=$(qdbus-qt6 --system "$BUS_DEST" "$BUS_PATH" org.freedesktop.DBus.Properties.Get "$BUS_IFACE" ActiveProfile)

mark() {
    if [ "$1" = "$current" ]; then printf '%s\n' "$2 (current)"; else printf '%s\n' "$2"; fi
}

choice=$(printf '%s\n' \
    "$(mark power-saver "🍃 Battery Life")" \
    "$(mark balanced "🔋 Balanced")" \
    "$(mark performance "⚡ Performance")" \
    | rofi -dmenu -i -p "Power Profile")

case "$choice" in
    *"Battery Life"*) profile="power-saver" ;;
    *Balanced*) profile="balanced" ;;
    *Performance*) profile="performance" ;;
    *) exit 0 ;;
esac

qdbus-qt6 --system "$BUS_DEST" "$BUS_PATH" org.freedesktop.DBus.Properties.Set "$BUS_IFACE" ActiveProfile "$profile"
