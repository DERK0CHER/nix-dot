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
    done | rofi -dmenu -i -config "$ROFI_CFG" -p "Wallpaper" \
        -kb-accept-entry "Return,KP_Enter,space"
}

# Build a screen-sized image for one output: the source scaled to fill the
# screen height and centered, with each side gap filled by taking a strip of
# the image's edge and "smouching" it — randomly scattering (-spread) and
# softening (-blur) the edge pixels into a uniform cloud of those colors,
# plus a touch of grain. No directional streaks.
SMOUCH_STRIP=80     # px of edge sampled as the source pattern
SMOUCH_SPREAD=70    # random pixel displacement radius (the "smouch")
SMOUCH_BLUR="0x10"  # softening after scattering

# smouch <mid.png> <gravity West|East> <pad_w> <h> <out>
smouch() {
    local mid="$1" grav="$2" pw="$3" h="$4" out="$5"
    local strip=$SMOUCH_STRIP
    magick "$mid" -gravity "$grav" -crop "${strip}x${h}+0+0" +repage \
        -resize "${pw}x${h}!" \
        -virtual-pixel mirror -spread "$SMOUCH_SPREAD" -blur "$SMOUCH_BLUR" \
        -attenuate 0.25 +noise Gaussian "$out"
}

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
        smouch "$tmp/mid.png" West "$padL" "$h" "$tmp/l.png"
        parts+=("$tmp/l.png")
    fi
    parts+=("$tmp/mid.png")
    if [ "$padR" -gt 0 ]; then
        smouch "$tmp/mid.png" East "$padR" "$h" "$tmp/r.png"
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
    # Phase 1: build every monitor's composite first (slow, sequential).
    local name w h names=()
    while read -r name w h; do
        [ -n "$name" ] || continue
        compose "$wall" "$w" "$h" "$HOME/.cache/wallust/wall-${name}.png"
        names+=("$name")
    done < <(hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width) \(.height)"')
    # Phase 2: fire all outputs at once so the transitions stay in sync.
    for name in "${names[@]}"; do
        awww img -o "$name" "$HOME/.cache/wallust/wall-${name}.png" --resize crop \
            --transition-type fade --transition-duration 1.5 --transition-fps 60 &
    done
    wait
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
    # Toggle like wofi: if the picker is already open, close it and stop.
    if pgrep -x rofi >/dev/null 2>&1; then
        pkill -x rofi
        exit 0
    fi
    WALL="$(pick)"
fi
[ -n "${WALL:-}" ] || exit 0
apply "$WALL"
