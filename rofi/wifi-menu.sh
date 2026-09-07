#!/usr/bin/env bash

# Bright Green for saved/trusted networks
TRUSTED_COLOR="#a9b665"

notify-send "Getting list of available Wi-Fi networks..."

# 1. Get saved profile names and SSIDs from NetworkManager
saved_conns=$(nmcli -g NAME connection)
saved_ssids=$(nmcli -g 802-11-wireless.ssid connection)
all_saved=$(echo -e "${saved_conns}\n${saved_ssids}" | sort -u | grep -v "^$")

# 2. Get available Wi-Fi networks (SECURITY and SSID only)
raw_scan=$(nmcli --terse --fields "SECURITY,SSID" device wifi list | sed '/^:/d')

formatted_list=""
seen_ssids=""

while IFS=':' read -r security ssid; do
    # Skip blank SSIDs
    [ -z "$ssid" ] && continue
    
    # Avoid duplicate rows in Rofi
    if echo "$seen_ssids" | grep -qx "$ssid"; then
        continue
    fi
    seen_ssids+="$ssid\n"

    # Set security icon
    if [[ "$security" =~ "WPA" ]]; then
        sec_icon=""
    else
        sec_icon=""
    fi

    # Check if SSID matches any of your saved connections
    if echo "$all_saved" | grep -qx "$ssid"; then
        # Highlight saved networks in GREEN and mark as (Saved)
        line="$sec_icon <span foreground=\"$TRUSTED_COLOR\"><b>$ssid</b> (Saved)</span>"
    else
        # Normal unsaved network
        line="$sec_icon $ssid"
    fi

    formatted_list+="$line\n"
done <<< "$raw_scan"

# Check Wi-Fi toggle state
connected=$(nmcli -fields WIFI g)
if [[ "$connected" =~ "enabled" ]]; then
    toggle="󰖪  Disable Wi-Fi"
elif [[ "$connected" =~ "disabled" ]]; then
    toggle="󰖩  Enable Wi-Fi"
fi

# 3. Open Rofi
chosen_network=$(echo -e "$toggle\n$formatted_list" | rofi -dmenu -i -markup-rows -selected-row 1 -p "Wi-Fi SSID" -theme /home/$(whoami)/.config/rofi/config.rasi)

[ -z "$chosen_network" ] && exit 0

# Strip HTML markup and (Saved) tag to get clean SSID
clean_chosen=$(echo "$chosen_network" | sed -E 's/<[^>]*>//g' | sed 's/ (Saved)//g')

# Extract SSID without icon
chosen_id=$(echo "$clean_chosen" | sed 's/^[][[:space:]]*//')

if [ "$clean_chosen" = "󰖩  Enable Wi-Fi" ]; then
    nmcli radio wifi on
elif [ "$clean_chosen" = "󰖪  Disable Wi-Fi" ]; then
    nmcli radio wifi off
else
    success_message="You are now connected to \"$chosen_id\"."
    
    # If saved, connect directly. Otherwise, prompt for password.
    if echo "$all_saved" | grep -qx "$chosen_id"; then
        nmcli connection up id "$chosen_id" | grep "successfully" && notify-send "Connection Established" "$success_message"
    else
        if [[ "$chosen_network" =~ "" ]]; then
            wifi_password=$(rofi -dmenu -p "Password" -theme /home/$(whoami)/.config/rofi/config.rasi)
            [ -z "$wifi_password" ] && exit 0
        fi
        nmcli device wifi connect "$chosen_id" password "$wifi_password" | grep "successfully" && notify-send "Connection Established" "$success_message"
    fi
fi