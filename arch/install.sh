#!/usr/bin/env bash
# ============================================================================
# arch/install.sh - install these dotfiles on the CachyOS / Arch host.
#
# Idempotent and non-destructive: nothing is ever deleted. An existing
# ~/.config/<name> that is not already the correct symlink is MOVED to
# ~/.config/<name>.bak.<timestamp>.
#
# NixOS users want nixos/ + home-manager/ instead. See arch/README.md.
# ============================================================================
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

# --------------------------------------------------------------------- output
c_bold=''; c_red=''; c_yel=''; c_grn=''; c_off=''
if [[ -t 1 ]]; then
    c_bold=$'\033[1m'; c_red=$'\033[31m'; c_yel=$'\033[33m'
    c_grn=$'\033[32m'; c_off=$'\033[0m'
fi
info()  { printf '%s==>%s %s\n'   "$c_grn$c_bold" "$c_off" "$*"; }
warn()  { printf '%s==> WARN:%s %s\n' "$c_yel$c_bold" "$c_off" "$*" >&2; }
die()   { printf '%s==> ERROR:%s %s\n' "$c_red$c_bold" "$c_off" "$*" >&2; exit 1; }
step()  { printf '\n%s--- %s%s\n' "$c_bold" "$*" "$c_off"; }
run()   { if (( DRY_RUN )); then printf '    [dry-run] %s\n' "$*"; else "$@"; fi; }

usage() {
    cat <<'USAGE'
usage: arch/install.sh [-n|--dry-run] [--no-packages] [-h|--help]

  -n, --dry-run     print what would happen, change nothing
      --no-packages skip pacman/yay, only link configs and enable services
USAGE
}

DO_PACKAGES=1
while (( $# )); do
    case "$1" in
        -n|--dry-run)  DRY_RUN=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        -h|--help)     usage; exit 0 ;;
        *)             usage >&2; die "unknown argument: $1" ;;
    esac
    shift
done

# ------------------------------------------------------------ sanity: not root
if [[ "$(id -u)" -eq 0 ]]; then
    die "do not run this as root. It installs into \$HOME and calls sudo itself."
fi

# --------------------------------------------------------- sanity: Arch-derived
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    os_id="$(. /etc/os-release && printf '%s' "${ID:-}")"
    # shellcheck disable=SC1091
    os_like="$(. /etc/os-release && printf '%s' "${ID_LIKE:-}")"
else
    die "/etc/os-release is missing; cannot confirm this is an Arch-derived system."
fi
if [[ " $os_id $os_like " != *" arch "* ]]; then
    die "this host reports ID='$os_id' ID_LIKE='$os_like' - not Arch-derived.
     On NixOS use nixos/ and home-manager/ instead (see arch/README.md)."
fi
info "host: ${os_id:-unknown} (ID_LIKE='${os_like:-}')  repo: $REPO_DIR"
(( DRY_RUN )) && warn "dry run - nothing will be changed"

# ============================================================================
# 1. packages
# ============================================================================
install_list() {
    # $1 = file, $2 = human label; echoes the stripped list on stdout
    local file="$1"
    [[ -r "$file" ]] || return 1
    grep -vE '^[[:space:]]*(#|$)' "$file" | sed 's/[[:space:]]*#.*$//' | awk 'NF'
}

if (( DO_PACKAGES )); then
    step "official repository packages"
    if ! command -v pacman >/dev/null 2>&1; then
        warn "pacman not found - skipping repo packages entirely."
    elif [[ ! -r "$REPO_DIR/arch/packages.txt" ]]; then
        warn "arch/packages.txt not found - skipping repo packages."
    else
        pkgs="$(install_list "$REPO_DIR/arch/packages.txt" || true)"
        if [[ -z "$pkgs" ]]; then
            warn "arch/packages.txt is empty after stripping comments."
        else
            printf '    %s package(s)\n' "$(printf '%s\n' "$pkgs" | wc -l)"
            if (( DRY_RUN )); then
                printf '    [dry-run] sudo pacman -S --needed --noconfirm - < packages.txt\n'
            else
                # Do not abort the whole install if a single name has been
                # renamed upstream - report and continue.
                if ! printf '%s\n' "$pkgs" |
                     sudo pacman -S --needed --noconfirm - ; then
                    warn "pacman returned non-zero. A package name in packages.txt is
     probably wrong (the ones marked '# verify' are the suspects).
     Check with: pacman -Si <name>   - continuing."
                fi
            fi
        fi
    fi

    step "AUR packages"
    aur="$(install_list "$REPO_DIR/arch/packages-aur.txt" 2>/dev/null || true)"
    if [[ -z "$aur" ]]; then
        info "no AUR packages listed - nothing to do."
    elif ! command -v yay >/dev/null 2>&1; then
        warn "yay is not installed - skipping the AUR list:
$(printf '       %s\n' $aur)
     Install it with:
       sudo pacman -S --needed git base-devel
       git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && cd /tmp/yay-bin && makepkg -si
     then re-run this script. Continuing."
    else
        if (( DRY_RUN )); then
            printf '    [dry-run] yay -S --needed --noconfirm %s\n' "$(printf '%s ' $aur)"
        else
            # shellcheck disable=SC2086
            yay -S --needed --noconfirm $aur || \
                warn "yay returned non-zero; verify each name with 'yay -Si <name>'. Continuing."
        fi
    fi
else
    step "packages"; info "skipped (--no-packages)"
fi

# ============================================================================
# 2. config symlinks
# ============================================================================
step "linking config directories into $CONFIG_DIR"

if [[ "$(readlink -f "$REPO_DIR")" == "$(readlink -f "$CONFIG_DIR")" ]]; then
    info "repo IS \$XDG_CONFIG_HOME - nothing to link."
else
    run mkdir -p "$CONFIG_DIR"
    LINK_DIRS=(hypr quickshell gtk-3.0 gtk-4.0 qt6ct wofi kitty
               btop fcitx5 vesktop rustdesk Thunar)

    for d in "${LINK_DIRS[@]}"; do
        src="$REPO_DIR/$d"
        dst="$CONFIG_DIR/$d"
        if [[ ! -d "$src" ]]; then
            printf '    skip   %-12s (not in repo)\n' "$d"
            continue
        fi
        if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
            printf '    ok     %-12s (already linked)\n' "$d"
            continue
        fi
        if [[ -e "$dst" || -L "$dst" ]]; then
            bak="$dst.bak.$STAMP"
            printf '    backup %-12s -> %s\n' "$d" "$(basename "$bak")"
            run mv -- "$dst" "$bak"
        fi
        printf '    link   %-12s -> %s\n' "$d" "$src"
        run ln -sfn -- "$src" "$dst"
    done

    # single files that are equally per-machine-agnostic
    for f in pavucontrol.ini; do
        src="$REPO_DIR/$f"; dst="$CONFIG_DIR/$f"
        [[ -f "$src" ]] || continue
        if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
            printf '    ok     %-12s (already linked)\n' "$f"; continue
        fi
        [[ -e "$dst" || -L "$dst" ]] && run mv -- "$dst" "$dst.bak.$STAMP"
        printf '    link   %-12s -> %s\n' "$f" "$src"
        run ln -sfn -- "$src" "$dst"
    done
fi

# ============================================================================
# 3. host.conf symlink
# ============================================================================
step "host symlink"

host_name=""
if command -v hostnamectl >/dev/null 2>&1; then
    host_name="$(hostnamectl --static 2>/dev/null || true)"
fi
[[ -n "$host_name" ]] || host_name="$(cat /etc/hostname 2>/dev/null || true)"
[[ -n "$host_name" ]] || host_name="${HOSTNAME:-}"

hosts_dir="$CONFIG_DIR/hypr/hosts"
if [[ ! -d "$hosts_dir" ]]; then
    warn "$hosts_dir does not exist yet - skipping host.conf.
     Create hypr/hosts/cachy.conf in the repo, then re-run this script."
else
    host_file="$hosts_dir/${host_name}.conf"
    if [[ ! -f "$host_file" ]]; then
        [[ -n "$host_name" ]] && \
            warn "no hosts/${host_name}.conf for hostname '${host_name}' - falling back to cachy.conf"
        host_file="$hosts_dir/cachy.conf"
    fi
    if [[ -f "$host_file" ]]; then
        info "host.conf -> hosts/$(basename "$host_file")"
        run ln -sfn -- "$host_file" "$CONFIG_DIR/hypr/host.conf"
    else
        warn "hosts/cachy.conf is missing too - host.conf not created."
    fi
fi

# ============================================================================
# 4. executable scripts
# ============================================================================
step "script permissions"
if [[ -d "$REPO_DIR/hypr/scripts" ]]; then
    found=0
    while IFS= read -r -d '' s; do
        found=1
        printf '    chmod +x %s\n' "$(basename "$s")"
        run chmod +x -- "$s"
    done < <(find "$REPO_DIR/hypr/scripts" -maxdepth 1 -type f -print0)
    (( found )) || info "hypr/scripts is empty."
else
    warn "hypr/scripts not found - skipping chmod."
fi

# ============================================================================
# 5. services
# ============================================================================
step "system services"
if ! command -v systemctl >/dev/null 2>&1; then
    warn "systemctl not found - skipping service enablement."
else
    unit_files="$(systemctl list-unit-files --no-legend --no-pager 2>/dev/null || true)"
    to_enable=()
    for unit in ananicy-cpp.service power-profiles-daemon.service; do
        if printf '%s\n' "$unit_files" | grep -qE "^${unit}[[:space:]]"; then
            to_enable+=("$unit")
        else
            warn "$unit is not installed - skipping."
        fi
    done
    if (( ${#to_enable[@]} )); then
        info "enabling: ${to_enable[*]}"
        if (( DRY_RUN )); then
            printf '    [dry-run] sudo systemctl enable --now %s\n' "${to_enable[*]}"
        else
            sudo systemctl enable --now "${to_enable[@]}" || \
                warn "enabling services failed; check 'systemctl status'. Continuing."
        fi
    fi
    # No user units are shipped: the shell, hyprpaper, hypridle and the
    # clipboard watchers are all started from hypr/hyprland/execs.conf, which
    # guarantees they inherit HYPRLAND_INSTANCE_SIGNATURE and WAYLAND_DISPLAY.
fi

# ============================================================================
# NEXT STEPS
# ============================================================================
cat <<'NEXT'

============================================================================
  NEXT STEPS
============================================================================

  1. Check the config parses before you rely on it:

         Hyprland --verify-config

     (Run it from a TTY or an existing session; it only parses, it does not
     start a compositor.)

  2. Log out completely, then pick the "Hyprland" session in your display
     manager - or, from a bare TTY:

         uwsm start hyprland-uwsm.desktop      # preferred, proper env
         Hyprland                              # plain fallback

     A full logout matters: the NVIDIA env and the fcitx5/portal variables in
     hypr/hyprland/env.conf are only picked up by a fresh session.

  3. Confirm the host split took effect:

         ls -l ~/.config/hypr/host.conf        # -> hosts/cachy.conf
         hyprctl monitors | grep -E 'DP-|@'    # DP-1 3440x1440, DP-2 1920x1080@300

  4. NVIDIA sanity, once you are in the session:

         cat /sys/module/nvidia_drm/parameters/modeset   # must be Y
         nvidia-smi

     If the cursor misbehaves, set cursor:no_hardware_cursors = true in
     ~/.config/hypr/hosts/cachy.conf - not the old WLR_NO_HARDWARE_CURSORS env.

  5. Anything this script backed up is still on disk as
     ~/.config/<name>.bak.<timestamp> - delete those once you are happy.

============================================================================
NEXT
