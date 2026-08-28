#!/bin/sh
choice=$(printf '%s\n' " Lock" "󰍃 Logout" "󰜉 Reboot" "󰤂 Shutdown" | rofi -dmenu -i -p "Power")

case "$choice" in
    *Lock*) swaylock -f ;;
    *Logout*) swaymsg exit ;;
    *Reboot*) systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
