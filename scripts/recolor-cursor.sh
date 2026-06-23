#!/usr/bin/env bash
# Recolor the system cursor to a hex color (per wallpaper) via hyprcursor.
# Builds are cached per color, so reusing a color is just a copy + setcursor
# instead of a full extract/recolor/recompile.
#
# Usage: recolor-cursor.sh RRGGBB
set -euo pipefail

COLOR="${1:?usage: recolor-cursor.sh RRGGBB}"
COLOR="${COLOR#\#}"
SIZE="${CURSOR_SIZE:-24}"
ADWAITA="/run/current-system/sw/share/icons/Adwaita"
BASE="$HOME/.cache/wallust/cursor-base"           # extracted Adwaita (uncolored)
CACHE="$HOME/.cache/wallust/cursors"              # compiled themes, per color
CUR="$HOME/.cache/wallust/cursor-current"
ICONS="$HOME/.local/share/icons"
THEME="wallust-cursor"

command -v hyprcursor-util >/dev/null 2>&1 || exit 0
command -v xcur2png       >/dev/null 2>&1 || { echo "xcur2png missing — run sudo nixos-rebuild" >&2; exit 0; }
command -v mogrify        >/dev/null 2>&1 || exit 0

# Already showing this color — nothing to do but (re)assert it.
if [ "$(cat "$CUR" 2>/dev/null || true)" = "$COLOR" ] && [ -d "$ICONS/$THEME" ]; then
    hyprctl setcursor "$THEME" "$SIZE" >/dev/null 2>&1 || true
    exit 0
fi

# Build this color into the cache if we haven't already.
if [ ! -f "$CACHE/$COLOR/manifest.hl" ]; then
    # Extract Adwaita into an editable working state once, with a stable name.
    if [ ! -f "$BASE/manifest.hl" ]; then
        rm -rf "$BASE"; tmp="$(mktemp -d)"
        hyprcursor-util --extract "$ADWAITA" -o "$tmp" >/dev/null 2>&1 || { rm -rf "$tmp"; exit 0; }
        src="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
        [ -n "$src" ] || { rm -rf "$tmp"; exit 0; }
        mkdir -p "$BASE"; cp -r "$src"/. "$BASE"/; rm -rf "$tmp"
        sed -i "s/^name *=.*/name = $THEME/" "$BASE/manifest.hl" 2>/dev/null || true
    fi
    # Recolor a throwaway copy: black->black (outline/shadow), white->color.
    parent="$(mktemp -d)"; work="$parent/$THEME"
    cp -r "$BASE" "$work"
    find "$work" -name '*.png' -print0 \
        | xargs -0 -r mogrify -channel RGB +level-colors "black,#$COLOR" +channel
    out="$(mktemp -d)"
    hyprcursor-util --create "$work" -o "$out" >/dev/null 2>&1 || { rm -rf "$parent" "$out"; exit 0; }
    created="$(find "$out" -mindepth 1 -maxdepth 1 -type d | head -1)"
    [ -n "$created" ] || { rm -rf "$parent" "$out"; exit 0; }
    mkdir -p "$CACHE"; rm -rf "$CACHE/$COLOR"; mv "$created" "$CACHE/$COLOR"
    rm -rf "$parent" "$out"
fi

# Install the cached build under the stable theme name and apply it.
mkdir -p "$ICONS"; rm -rf "$ICONS/$THEME"; cp -r "$CACHE/$COLOR" "$ICONS/$THEME"
printf '%s\n' "$COLOR" > "$CUR"
hyprctl setcursor "$THEME" "$SIZE" >/dev/null 2>&1 || true
