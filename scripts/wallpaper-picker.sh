#!/usr/bin/env bash
# Wallpaper picker → awww transition → wallust recolor → live-reload apps.
# Wallpapers are read from ~/Pictures/wallpapers. Run with no args for the
# rofi thumbnail picker, or pass a path to apply directly (used on login).

set -euo pipefail

WALLS="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
THUMBS="$HOME/.cache/wallpaper-thumbnails"
ROFI_CFG="$HOME/.config/rofi/wallpaper.rasi"
LAST="$HOME/.cache/wallust/last-wallpaper"

mkdir -p "$THUMBS" "$HOME/.cache/wallust"

pick() {
    [ -d "$WALLS" ] || { notify-send "Wallpaper" "No directory: $WALLS"; exit 1; }
    for w in "$WALLS"/*; do
        [ -f "$w" ] || continue
        local t="$THUMBS/$(basename "$w")"
        [ -f "$t" ] || magick "$w" -strip -thumbnail '500x300^' -gravity center -extent '500x300' "$t" 2>/dev/null || true
    done
    for w in "$WALLS"/*; do
        [ -f "$w" ] || continue
        printf '%s\0icon\x1f%s\n' "$w" "$THUMBS/$(basename "$w")"
    done | rofi -dmenu -i -config "$ROFI_CFG" -p "Wallpaper"
}

apply() {
    local wall="$1"
    # Make sure the wallpaper daemon is up, otherwise `awww img` fails.
    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
        awww-daemon >/dev/null 2>&1 &
        for _ in $(seq 1 30); do awww query >/dev/null 2>&1 && break; sleep 0.1; done
    fi
    # Set the wallpaper. Never let a wallpaper hiccup abort the recolor below.
    awww img "$wall" --transition-type fade --transition-duration 1.5 --transition-fps 60 || true
    # Regenerate the palette and render all templates to ~/.cache/wallust.
    wallust run "$wall"
    echo "$wall" > "$LAST"
    # Live-reload everything that reads the generated files.
    pkill -SIGUSR1 kitty 2>/dev/null || true          # kitty re-reads its includes
    pkill -SIGUSR2 waybar 2>/dev/null || true          # waybar reloads CSS
    hyprctl reload >/dev/null 2>&1 || true             # hyprland re-sources colors
    dunstctl reload 2>/dev/null || true                # dunst re-reads its themed config
}

if [ $# -ge 1 ]; then
    WALL="$1"
else
    WALL="$(pick)"
fi
[ -n "${WALL:-}" ] || exit 0
apply "$WALL"
