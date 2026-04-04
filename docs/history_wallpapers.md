# Deprecated Wallpapers Script

This version of the `wallpapers.sh` script is deprecated. It suffered from IPC breakage introduced in `hyprpaper` v0.8.3 (due to the new IPC block config) and was computationally heavy on startup because it used `find` to recursively scan directories, resulting in significant CPU overhead.

```bash
#!/usr/bin/env bash

# Legacy wallpapers.sh using find and hyprctl IPC

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Find all wallpapers, computationally heavy on startup
# This scans the entire directory tree every time the script runs
WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -iname \*.jpg -o -iname \*.png -o -iname \*.jpeg -o -iname \*.webp \)))

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found."
    exit 1
fi

# Select a random wallpaper
RANDOM_INDEX=$((RANDOM % ${#WALLPAPERS[@]}))
SELECTED_WALLPAPER="${WALLPAPERS[$RANDOM_INDEX]}"

# Preload the wallpaper via hyprctl (broken in hyprpaper v0.8.3 if IPC is blocked in hyprpaper.conf)
hyprctl hyprpaper preload "$SELECTED_WALLPAPER"

# Get active monitors
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')

# Set the wallpaper for each monitor
for MONITOR in $MONITORS; do
    hyprctl hyprpaper wallpaper "$MONITOR,$SELECTED_WALLPAPER"
done

# Unload unused wallpapers to free memory
hyprctl hyprpaper unload all
```
