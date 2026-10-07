#!/bin/bash

for _ in $(seq 1 20); do
  pgrep -x awww-daemon >/dev/null && pgrep -x swaync >/dev/null && break
  sleep 0.5
done

python ~/.local/bin/wallpaper_change.py ~/Pictures/Wallpapers/shaded_landscape.jpg
notify-send -u normal -t 10000 "Aurora is ready ✨" \
  "Your system has been configured successfully.

Press <b>Super + Space</b> to launch apps.
Press <b>Super + /</b> for the keybinds cheatsheet.

Enjoy your setup."

CONFIG="$HOME/.config/hypr/autostart.lua"

if [ -f "$CONFIG" ]; then
  sed -i '/^[[:space:]]*hl\.exec_cmd(.*welcome\.sh/s/^/-- /' "$CONFIG"
fi
