#!/bin/bash

python ~/.local/bin/wallpaper_change.py ~/Pictures/Wallpapers/shaded_landscape.jpg
pkill waybar
waybar &
notify-send "Aurora is ready ✨" \
  "Your system has been configured successfully.

Press Super + Space to launch apps.
Press Super + Return to open a terminal.

Enjoy your setup."

CONFIG="$HOME/.config/hypr/autostart.conf"

if [ -f "$CONFIG" ]; then
  sed -i "/exec-once = .*welcome.sh/s/^/# /" "$CONFIG"
fi
