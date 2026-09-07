#!/usr/bin/env bash

# Fetch status output
STATUS_RAW=$(protonvpn status 2>/dev/null)

# Check connection status
IS_CONNECTED=$(echo "$STATUS_RAW" | grep -iE "Status:.*Connected|Connected")

# Extract connected server or country name (if active)
SERVER_INFO=$(echo "$STATUS_RAW" | grep -iE "Server|Country" | head -n 1 | awk '{print $2}')

# Format options
if [ -n "$IS_CONNECTED" ]; then
    STATUS_ROW="<span foreground='#00FF66' weight='bold'>● Connected ($SERVER_INFO)</span>"
    OPTIONS="${STATUS_ROW}\n󰅛 Disconnect\n󰤨 Reconnect (Fastest)\nExit"
else
    STATUS_ROW="<span foreground='#FF5555'>○ Disconnected</span>"
    OPTIONS="${STATUS_ROW}\n󰤨 Connect (Fastest)\nExit"
fi

# Launch Rofi
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -markup-rows -p "Proton VPN")

[ -z "$CHOICE" ] || [ "$CHOICE" = "Exit" ] || [[ "$CHOICE" == *"Connected"* ]] && exit 0

connect_and_notify() {
    notify-send "Proton VPN" "Connecting to best available free server..."
    
    # Run official connect command
    protonvpn connect &>/dev/null &
    
    # Poll status for up to 8 seconds
    for i in {1..8}; do
        sleep 1
        if protonvpn status 2>/dev/null | grep -q -i "Connected"; then
            NEW_SERVER=$(protonvpn status 2>/dev/null | grep -iE "Server|Country" | head -n 1 | awk '{print $2}')
            notify-send "Proton VPN" "Connected! ($NEW_SERVER)"
            return 0
        fi
    done
    
    notify-send "Proton VPN" "Connection attempt finished. Check status."
}

case "$CHOICE" in
    *"Disconnect"*)
        protonvpn disconnect
        notify-send "Proton VPN" "Disconnected"
        ;;
    *"Connect"*|*"Reconnect"*)
        connect_and_notify
        ;;
esac
