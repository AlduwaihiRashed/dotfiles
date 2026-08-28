#!/bin/sh
layout=$(swaymsg -t get_inputs -r | jq -r '
  [.[] | select(.type == "keyboard")
        | select(.identifier | test("Power_Button|Sleep_Button|Video_Bus") | not)]
  | .[0].xkb_active_layout_name // "English (US)"
')

case "$layout" in
    *Arabic*) echo "AR" ;;
    *) echo "EN" ;;
esac
