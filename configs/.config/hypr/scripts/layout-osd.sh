#!/usr/bin/env bash
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
  while read -r line; do
    case "$line" in
    activelayout\>\>*)
      layout="${line#*,}" # формат: activelayout>>keyboard-name,Layout Name
      swayosd-client --custom-message "$layout" --custom-icon input-keyboard-symbolic
      ;;
    esac
  done
