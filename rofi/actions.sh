#!/usr/bin/env bash

POWER_OPT="⏻  Power Off"
WIFI_OPT="  Wi-Fi Settings"
BT_OPT="󰂯  Bluetooth Settings"
WALLPAPER_OPT="󰸉  Wallpaper Settings"
VPN_OPT="󰤨  Proton VPN"

MENU="${POWER_OPT}\n${VPN_OPT}\n${WIFI_OPT}\n${BT_OPT}\n${WALLPAPER_OPT}"

CHOICE=$(echo -e "$MENU" | rofi \
    -dmenu \
    -i \
    -p "System" \
    -theme /home/$(whoami)/.config/rofi/config.rasi)

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    "$POWER_OPT")
        systemctl poweroff
        ;;
    "$VPN_OPT")
        /home/emy/.config/rofi/vpn-menu.sh &
        ;;
    "$WIFI_OPT")
        /home/emy/.config/rofi/wifi-menu.sh &
        ;;
    "$BT_OPT")
        /home/emy/.config/rofi/bluetooth-menu.sh &
        ;;
    "$WALLPAPER_OPT")
        /home/emy/.config/rofi/wallpaper-picker.sh &
        ;;
esac