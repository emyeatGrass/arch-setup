#!/usr/bin/env bash

# Enable nullglob & nocaseglob so all cases of .png, .jpg, etc. are caught
shopt -s nullglob nocaseglob

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper-list.rasi"

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpaper Error" "Directory $WALLPAPER_DIR does not exist."
    exit 1
fi

ROFI_INPUT=""

# Read wallpaper files
for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
    [ -f "$img" ] || continue
    filename=$(basename "$img")
    
    # Prefixing 'thumbnail://' forces Rofi to render the PNG/image path directly as an icon
    ROFI_INPUT+="${filename}\0icon\x1fthumbnail://${img}\n"
done

if [ -z "$ROFI_INPUT" ]; then
    notify-send "Wallpaper Error" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Show list with thumbnails
CHOICE=$(echo -en "$ROFI_INPUT" | rofi -dmenu -i -p "Wallpaper" -show-icons -theme "$ROFI_THEME")

[ -z "$CHOICE" ] && exit 0

SELECTED_WALLPAPER="$WALLPAPER_DIR/$CHOICE"

# Apply wallpaper with awww
if command -v awww &> /dev/null; then
    pgrep -x awww-daemon > /dev/null || awww-daemon &
    awww img "$SELECTED_WALLPAPER" --transition-type wave --transition-fps 60 --transition-step 10 --transition-duration 1.5
    notify-send "Wallpaper Changed" "Set to $CHOICE"
else
    notify-send "Error" "awww is not installed!"
fi