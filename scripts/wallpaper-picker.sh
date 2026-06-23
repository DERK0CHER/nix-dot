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
        [ -f "$t" ] || magick "$w" -strip -thumbnail '400x400^' -gravity center -extent '400x400' "$t" 2>/dev/null || true
    done
    for w in "$WALLS"/*; do
        [ -f "$w" ] || continue
        printf '%s\0icon\x1f%s\n' "$w" "$THUMBS/$(basename "$w")"
    done | rofi -dmenu -i -config "$ROFI_CFG" -p "Wallpaper" \
        -kb-accept-entry "Return,KP_Enter,space"
}

# Build a screen-sized image for one output: the source scaled to fill the
# screen height and centered, with each side gap "smouched" from the image's
# edge — a soft, grainy cloud of the edge colors (no directional streaks).
#
# Done in a single magick pipeline (the scaled image is stashed in an MPR and
# its edges are scattered/blurred at low res, then upscaled to each gap), so
# there are no intermediate PNGs or extra processes — that's what made it slow.
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
    [ "$padL" -lt 1 ] && padL=1
    [ "$padR" -lt 1 ] && padR=1
    local th=$(( h / 4 + 1 ))   # low-res working height for the smouch texture
    magick "$src" -resize "x${h}" -write mpr:mid +delete \
        \( mpr:mid -gravity West -crop "90x${h}+0+0" +repage \
           -resize "160x${th}!" -virtual-pixel mirror -spread 16 -blur 0x2 \
           -attenuate 0.3 +noise Gaussian -resize "${padL}x${h}!" \) \
        mpr:mid \
        \( mpr:mid -gravity East -crop "90x${h}+0+0" +repage \
           -resize "160x${th}!" -virtual-pixel mirror -spread 16 -blur 0x2 \
           -attenuate 0.3 +noise Gaussian -resize "${padR}x${h}!" \) \
        +append "$out"
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
    # Vivid, high-contrast, non-grey color (complement of the wallpaper's mean
    # hue, forced saturated + mid-light). Used for the active border + cursor.
    local chue contrast
    chue="$(magick "$wall" -resize 1x1\! -colorspace HSL -format '%[fx:(u.r*360+180)%360]' info: 2>/dev/null)"
    contrast="$(magick -size 1x1 "xc:hsl(${chue:-210},85%,55%)" -alpha off -depth 8 -format '%[hex:p{0,0}]' info: 2>/dev/null)"
    [ -n "$contrast" ] || contrast="2B36EE"
    printf '$contrast = rgb(%s)\n' "$contrast" > "$HOME/.cache/wallust/contrast.conf"
    printf '%s\n' "$contrast" > "$HOME/.cache/wallust/contrast"
    # Cursor middle = complement of the border color (opposite hue), so the two
    # high-contrast colors are a complementary pair. Outline stays dark.
    local cuhue cursorcol
    cuhue="$(magick "$wall" -resize 1x1\! -colorspace HSL -format '%[fx:(u.r*360)%360]' info: 2>/dev/null)"
    cursorcol="$(magick -size 1x1 "xc:hsl(${cuhue:-30},85%,55%)" -alpha off -depth 8 -format '%[hex:p{0,0}]' info: 2>/dev/null)"
    [ -n "$cursorcol" ] || cursorcol="F08A3C"
    # Recolor the system cursor to match (slow recompile, so run it detached).
    [ -x "$HOME/.config/scripts/recolor-cursor.sh" ] && \
        "$HOME/.config/scripts/recolor-cursor.sh" "$cursorcol" >/dev/null 2>&1 &
    # Phase 1: build every monitor's composite, all in parallel.
    local name w h names=()
    while read -r name w h; do
        [ -n "$name" ] || continue
        compose "$wall" "$w" "$h" "$HOME/.cache/wallust/wall-${name}.png" &
        names+=("$name")
    done < <(hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width) \(.height)"')
    wait
    # Phase 2: fire all outputs at once so the transitions stay in sync.
    for name in "${names[@]}"; do
        awww img -o "$name" "$HOME/.cache/wallust/wall-${name}.png" --resize crop \
            --transition-type fade --transition-duration 0.8 --transition-fps 60 &
    done
    wait
    echo "$wall" > "$LAST"
    # Live-reload everything that reads the generated files.
    pkill -SIGUSR1 kitty 2>/dev/null || true          # kitty re-reads its includes
    pkill -SIGUSR2 waybar 2>/dev/null || true          # waybar reloads CSS
    hyprctl reload >/dev/null 2>&1 || true             # hyprland re-sources colors
    dunstctl reload 2>/dev/null || true                # dunst re-reads its themed config
    # fish: universal vars propagate to every open shell (prompt + syntax).
    command -v fish >/dev/null 2>&1 && \
        fish -c "source $HOME/.cache/wallust/colors.fish" 2>/dev/null || true
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
