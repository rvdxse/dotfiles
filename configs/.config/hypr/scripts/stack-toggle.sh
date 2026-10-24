#!/usr/bin/env bash
f="$HOME/.config/hypr/mode"
if [ "$(cat "$f" 2>/dev/null)" = "stacking" ]; then
  echo tiling >"$f"
  action="disable"
  msg="Tiling mode"
else
  echo stacking >"$f"
  action="enable"
  msg="Stacking mode"
fi

notify-send -u low -t 1500 "$msg"

hyprctl reload

hyprctl clients -j | jq -r '.[] | select(.mapped) | .address' | while read -r addr; do
  hyprctl dispatch "hl.dsp.window.float({ action = \"$action\", window = \"address:$addr\" })"
done
