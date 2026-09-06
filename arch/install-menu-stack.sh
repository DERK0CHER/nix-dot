#!/usr/bin/env bash
# Installs the pieces the global-menu work needs, then runs the one experiment
# that decides whether the whole idea is viable on this machine: does ANY
# application here export its menu over DBus?
#
# Run as your normal user. It will ask for sudo once, for pacman.
set -uo pipefail

RED=$'\e[31m'; GRN=$'\e[32m'; YEL=$'\e[33m'; BLD=$'\e[1m'; RST=$'\e[0m'
say()  { printf '%s==>%s %s\n' "$BLD" "$RST" "$*"; }
warn() { printf '%s==> %s%s\n' "$YEL" "$*" "$RST"; }
ok()   { printf '%s  ok%s   %s\n' "$GRN" "$RST" "$*"; }
bad()  { printf '%s  no%s   %s\n' "$RED" "$RST" "$*"; }

[ "$(id -u)" -eq 0 ] && { echo "Run as your user, not root."; exit 1; }
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------- packages
# Grouped by why they are here, so nothing is installed without a reason.
PKGS=(
  # Qt menu producer. Without the KDE platform theme, Qt apps draw their own
  # menubar and export nothing. This is the single most important package here.
  plasma-integration
  # A Qt app that actually HAS a menubar, to test against. Dolphin hides its
  # menubar by default, which makes it a poor first test subject.
  kate
  # GTK3 menu producer.
  appmenu-gtk-module
  # The canonical protocol XML (Qt ships a copy, this is the upstream source).
  plasma-wayland-protocols
  # Hyprland plugins are normally built with cmake or meson; neither is present.
  cmake
  meson
  # The quick-settings gear button currently has nothing to launch.
  gnome-control-center
  # For the registrar probe below.
  python-dbus
  python-gobject
)

say "installing ${#PKGS[@]} packages"
if ! sudo pacman -S --needed --noconfirm "${PKGS[@]}"; then
    warn "pacman returned non-zero - continuing so the probe still runs."
    warn "Check the names above; anything missing will show up as 'no' below."
fi

# ---------------------------------------------------------------- the probe
say "probe: does any app export a menu over DBus?"
echo
echo "  This starts a stub that owns com.canonical.AppMenu.Registrar, then"
echo "  launches Kate with the KDE platform theme. If Kate registers, the DBus"
echo "  path works and the menu bar is buildable. If nothing registers, the"
echo "  compositor-side Wayland protocol is the only remaining route."
echo

STUB="$REPO/tools/appmenu-probe/registrar-stub.py"
[ -x "$STUB" ] || { bad "missing $STUB"; exit 1; }

LOG="$(mktemp -t appmenu-probe.XXXXXX)"
"$STUB" > "$LOG" 2>&1 &
STUB_PID=$!
sleep 2

if ! kill -0 "$STUB_PID" 2>/dev/null; then
    bad "registrar stub died:"; sed 's/^/       /' "$LOG"; exit 1
fi
ok "registrar stub running (pid $STUB_PID)"

if command -v kate >/dev/null 2>&1; then
    say "launching Kate for 12 s (QT_QPA_PLATFORMTHEME=kde)"
    QT_QPA_PLATFORMTHEME=kde kate >/dev/null 2>&1 &
    KATE_PID=$!
    sleep 12
    kill "$KATE_PID" 2>/dev/null
    wait "$KATE_PID" 2>/dev/null
else
    bad "kate is not installed - skipping the Qt half of the probe"
fi

kill "$STUB_PID" 2>/dev/null
wait "$STUB_PID" 2>/dev/null

echo
say "result"
if grep -q "^REGISTER" "$LOG"; then
    ok "an application registered a menu:"
    grep "^REGISTER" "$LOG" | sed 's/^/       /'
    echo
    echo "  ${BLD}The DBus route works.${RST} A2 can read a real menu tree, and the"
    echo "  bar can be built without patching the compositor first."
else
    bad "nothing registered."
    echo
    echo "  Either the Qt platform theme is not exporting, or Qt on Wayland only"
    echo "  announces through org_kde_kwin_appmenu - which Hyprland does not"
    echo "  implement. In that case the Hyprland plugin (phase A1) is required."
    echo
    echo "  Full probe log:"; sed 's/^/       /' "$LOG"
fi
echo
echo "  Log kept at: $LOG"
