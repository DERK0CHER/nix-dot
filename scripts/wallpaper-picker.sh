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

# Build a screen-sized image for one output: the source scaled to fill the
# screen height and centered, with each side filled by the image's outermost
# edge column stretched across the gap and given subtle per-pixel noise — a
# grainy, near-uniform texture that matches the colors at the image edge.
compose() {
    local src="$1" w="$2" h="$3" out="$4"
    local sw
    sw="$(magick "$src" -format "%[fx:round(w*${h}/h)]" info:)"
    if [ "$sw" -ge "$w" ]; then
        # Already covers the width at full height — crop the sides, no fill.
        magick "$src" -resize "x${h}" -gravity center -extent "${w}x${h}" "$out"
        return
    fi
    local padL=$(( (w - sw) / 2 )) padR
    padR=$(( w - sw - padL ))
    local tmp; tmp="$(mktemp -d)"
    magick "$src" -resize "x${h}" "$tmp/mid.png"
    local parts=()
    if [ "$padL" -gt 0 ]; then
        magick "$tmp/mid.png" -gravity West -crop "1x${h}+0+0" +repage \
            -resize "${padL}x${h}!" -attenuate 0.4 +noise Gaussian "$tmp/l.png"
        parts+=("$tmp/l.png")
    fi
    parts+=("$tmp/mid.png")
    if [ "$padR" -gt 0 ]; then
        magick "$tmp/mid.png" -gravity East -crop "1x${h}+0+0" +repage \
            -resize "${padR}x${h}!" -attenuate 0.4 +noise Gaussian "$tmp/r.png"
        parts+=("$tmp/r.png")
    fi
    magick "${parts[@]}" +append "$out"
    rm -rf "$tmp"
}

apply() {
    local wall="$1"
    # Make sure the wallpaper daemon is up, otherwise `awww img` fails.
    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
        awww-daemon >/dev/null 2>&1 &
        for _ in $(seq 1 30); do awww query >/dev/null 2>&1 && break; sleep 0.1; done
    fi
    # Regenerate the palette and render all templates to ~/.cache/wallust.
    wallust run "$wall"
    # Each monitor gets its own composite, sized to that output's resolution.
    local name w h out
    while read -r name w h; do
        [ -n "$name" ] || continue
        out="$HOME/.cache/wallust/wall-${name}.png"
        compose "$wall" "$w" "$h" "$out"
        awww img -o "$name" "$out" --resize crop \
            --transition-type fade --transition-duration 1.5 --transition-fps 60 || true
    done < <(hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width) \(.height)"')
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
