#!/usr/bin/env bash

BINDS=$(hyprctl binds -j | jq -r '
  .[] |
  select(.has_description == true and .description != "") |
  . as $b |
  (
    [
      (if $b.modmask % 128 >= 64 then "SUPER" else empty end),
      (if $b.modmask % 2   >= 1  then "SHIFT" else empty end),
      (if $b.modmask % 8   >= 4  then "CTRL"  else empty end),
      (if $b.modmask % 16  >= 8  then "ALT"   else empty end)
    ] | join("+")
  ) as $mods |
  (if $mods != "" then $mods + "+" else "" end) + $b.key + "\t" + $b.description
')

[ -z "$BINDS" ] && {
  notify-send "hyprkeys" "No described binds found"
  exit 1
}

echo "$BINDS" | column -t -s $'\t' | rofi -dmenu \
  -i \
  -p " Keys" \
  -theme-str 'window {width: 750px; font: "JetBrains Mono 11";}' \
  -no-custom
