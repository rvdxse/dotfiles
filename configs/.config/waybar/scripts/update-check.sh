#!/bin/bash

pacman_updates=$(checkupdates 2>/dev/null | wc -l)
yay_updates=$(yay -Qu --aur 2>/dev/null | wc -l)
flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)

echo "$pacman_updates $yay_updates $flatpak_updates" >/tmp/update-counts

total=$((pacman_updates + yay_updates + flatpak_updates))

if [ "$total" -eq 0 ]; then
  echo "{}"
  exit 0
fi

echo "{\"text\": \"󰮯 $total\", \"tooltip\": \"Pacman: $pacman_updates\nYay: $yay_updates\nFlatpak: $flatpak_updates\"}"
