#!/usr/bin/env bash
# Make running GTK apps (nautilus, thunar, dialogs) re-read
# ~/.config/gtk-3.0/gtk.css and ~/.config/gtk-4.0/gtk.css WITHOUT restarting.
#
# GTK reloads its style providers when the interface gtk-theme setting changes,
# so we flip it to "" (which renders the same default) and back — two change
# signals that trigger a reload, with no visible theme switch.
set -euo pipefail

I="org.gnome.desktop.interface"
command -v gsettings >/dev/null 2>&1 || exit 0

theme="$(gsettings get "$I" gtk-theme 2>/dev/null | tr -d "'")"
[ -n "$theme" ] || theme="Adwaita"

gsettings set "$I" gtk-theme "" 2>/dev/null || true
gsettings set "$I" gtk-theme "$theme" 2>/dev/null || true

# libadwaita 1.6+ honors a live system accent; keep it on orange too.
gsettings set "$I" accent-color "orange" 2>/dev/null || true
