# nix-dot

Personal NixOS + Hyprland dotfiles. The whole `~/.config` is tracked, together with
the system flake (`nixos/`) and the Home Manager flake (`home-manager/`).

The goal: **GNOME, but better, in Hyprland** — minimalist, translucent, libadwaita
look (Adwaita dark palette, `#3584e4` accent, 8–12 px radii, Cantarell/Adwaita Sans),
with a real game mode for an AMD-only box.

## Target hardware

| Component | Value |
|-----------|-------|
| CPU       | AMD Ryzen 7 |
| GPU       | AMD Radeon RX 9060 XT (Navi 44, RDNA4) — amdgpu / mesa / RADV |
| RAM       | 16 GB + zram |
| Disk      | ZFS root |
| Monitors  | HDMI-A-1 LG 32GP850 2560x1440@144 (VRR broken → `misc:vrr = 0`), DP-1 1920x1080@300 |
| OS        | NixOS unstable, Hyprland ≥ 0.55, GDM → Hyprland |

## Layout

| Path | Purpose |
|------|---------|
| `hypr/hyprland.conf` | Entry point, sources `hypr/hyprland/*.conf` then `hypr/custom/*.conf` |
| `hypr/hyprland/` | Base config: general, keybinds, rules (0.55 `match:` syntax), execs, env, gaming |
| `hypr/custom/` | Personal overrides, sourced last |
| `hypr/scripts/game-mode` | Game mode toggle script |
| `quickshell/hyprshell/` | The desktop shell (bar, app menu, quick settings, notifications) |
| `nixos/` | System flake; `modules/desktop.nix` (shell, theming, portals, fonts), `modules/gaming.nix` (gamemode, scx, steam) |
| `home-manager/` | Home Manager: fish, GTK/Qt theming, dconf, user packages |
| `wofi/` | Launcher (Adwaita dark, translucent) |
| `gtk-3.0/`, `gtk-4.0/`, `qt6ct/` | adw-gtk3-dark / Adwaita icons / Cantarell 11 |

## Install

```sh
git clone git@github.com:DERK0CHER/nix-dot.git ~/.config
sudo ln -sfn ~/.config/nixos /etc/nixos      # or copy hardware-configuration.nix in
sudo nixos-rebuild switch
cd ~/.config/home-manager && home-manager switch --flake .#beba
```

Log in through GDM and pick the Hyprland session.

## The shell: hyprshell (Quickshell)

`waybar` and `dunst` are gone. Everything is one Quickshell config, started from
`hypr/hyprland/execs.conf` with `qs -c hyprshell`.

- **Top bar** (`hyprshell-bar` layer): workspaces on the left, the *active app's name*
  next to them (GNOME/macOS style), clock in the centre, status indicators on the right.
- **App menu** — click the app name: the app's `.desktop` actions, window actions
  (fullscreen, float, pin, move to workspace, close), "Open folder" / recent files.
  Works for any app via `DesktopEntries` + `ToplevelManager`.
- **Quick Settings** — click the right side of the bar: GNOME-45 style panel with
  volume, brightness, network, Bluetooth, night light, do-not-disturb, power, game mode.
- **Notification center** — click the clock. Notifications pop up top-centre.
- Everything is `rgba(30,30,30,0.72)` + Hyprland blur (`layerrule = blur on, … match:namespace ^hyprshell-`).

IPC (usable from keybinds and scripts):

```sh
qs -c hyprshell ipc call shell toggleQuickSettings
qs -c hyprshell ipc call shell toggleNotifications
qs -c hyprshell ipc call shell toggleAppMenu
qs -c hyprshell ipc call shell toggleBar
qs -c hyprshell ipc call shell toggleLauncher
qs -c hyprshell ipc call shell setGameMode true   # or false
```

## Game mode

`hypr/scripts/game-mode on | off | toggle | status | run [--exclusive] -- <cmd...>`

`on` makes the focused window the only thing that matters: fullscreen, pinned,
focus-locked, immediate/tearing + direct scanout; blur, shadows, animations, gaps,
rounding and the bar are switched off, notifications are suppressed, background
services (easyeffects, gammastep, hypridle, …) are paused and `gamemoded` is engaged.
`off` restores every value from the saved state. `run` wraps a command (e.g. a Steam
launch option) so the mode is entered and left automatically.

Keys: **Super+G** toggle, **Super+Shift+G** status notification.

## Keybindings

| Keys | Action |
|------|--------|
| Super+Space | Launcher (wofi) |
| Super+I | Quick Settings |
| Super+N | Notification center |
| Super+A | App menu |
| Super+B | Toggle bar |
| Super+G | Game mode toggle |
| Super+Return | Terminal (kitty) |
| Super+E | Files (nautilus) |
| Super+W | Browser (firefox) |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Super+1…0 | Workspaces |
| Shift+Alt+3 / 4 | Screenshot screen / region |
| Super+V | Clipboard history (cliphist) |

## Performance notes (AMD)

- RADV (mesa) is the Vulkan driver; no proprietary bits anywhere.
- `AQ_NO_ATOMIC=1` (set in `nixos/modules/hyprland.nix`) and `misc:vrr = 0` stay:
  atomic DRM + VRR crashed the compositor on this GPU/monitor combination.
- `misc:vfr = 1`, direct scanout and `immediate`/tearing rules for `steam_app_*`.
- `scx_lavd` (sched_ext) and `gamemode` come from `nixos/modules/gaming.nix`.
- zram swap; ZFS ARC is capped so games keep their RAM.

## Customizing

- Hyprland: put overrides in `hypr/custom/*.conf` (sourced after the base files).
- Shell colours, fonts, radii and spacing: `quickshell/hyprshell/Theme.qml`.
- GTK/Qt look: `home-manager/home.nix` (`gtk`, `qt`, `dconf.settings`).

## Planned work

[TODO.md](TODO.md) holds the backlog: 44 specified tasks across the launcher, an Alt+Tab switcher, a command
palette with an in-place keybind editor, a Claude usage widget, Proton mail/calendar/VPN,
a lockdown mode, and the Neovim config plus its tutorial. Each task names the files to
touch, the steps, and the acceptance checks. Task IDs are stable, so commits can reference
them (`L3: finish the wofi restyle`).
