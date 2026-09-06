# nix-dot

Personal Hyprland dotfiles for **two machines**: a NixOS box (system flake in
`nixos/`, Home Manager flake in `home-manager/`) and a CachyOS box (`arch/`).
The whole `~/.config` is tracked.

The goal: **GNOME, but better, in Hyprland** — minimalist, translucent, libadwaita
look (Adwaita dark palette, `#3584e4` accent, 8–12 px radii, Cantarell/Adwaita Sans),
with a real game mode on both boxes.

## Hosts

Everything that differs between the machines lives in **one file per machine**
under `hypr/hosts/`: monitors, GPU environment variables, vendor workarounds and
per-machine performance overrides.

`hypr/hyprland.conf` sources `~/.config/hypr/host.conf` right before the
`custom/*.conf` glob, and `host.conf` is a **symlink** into `hypr/hosts/`, created
by the install script (or by hand):

```sh
ln -sfn ~/.config/hypr/hosts/cachy.conf ~/.config/hypr/host.conf
```

`host.conf` itself is per-machine state and is not tracked — never edit it, edit
the `hosts/<host>.conf` it points at. Everything in `hypr/hyprland/*.conf` is
shared by both machines and must stay vendor-neutral (no `monitor =` lines, no
GPU env, no driver workarounds). See [`hypr/hosts/README.md`](hypr/hosts/README.md).

| | `nix` | `cachy` |
|---|---|---|
| OS | NixOS unstable, ZFS root, user `beba` | CachyOS (Arch-based, pacman + yay) |
| CPU | AMD Ryzen 7 (no iGPU) | Intel Core i5-9400F, 6C/6T, no iGPU |
| GPU | Radeon RX 9060 XT (Navi 44, RDNA4) — amdgpu / RADV | GeForce RTX 2060 6 GB (TU106, Turing) — open kernel modules |
| Monitors | HDMI-A-1 2560x1440@144, DP-1 1920x1080@300 | DP-1 LG ultrawide 3440x1440@160 (primary), DP-2 AOC 25G4S 1920x1080@300 |
| RAM | 16 GB + zram | 16 GB |
| Quirks | `AQ_NO_ATOMIC=1`, `misc:vrr = 0` (atomic DRM + VRR crash the compositor) | NVIDIA env in `hosts/cachy.conf`; no PRIME — the F-suffix CPU has no iGPU |
| Install | `nixos/` + `home-manager/` | `arch/install.sh` |

Hyprland ≥ 0.55 on both (0.56.2 on `cachy`). This repo uses the **`.conf`**
format, not the newer Lua one.

## Layout

| Path | Purpose |
|------|---------|
| `hypr/hyprland.conf` | Entry point: sources `hypr/hyprland/*.conf`, then `host.conf`, then `hypr/custom/*.conf` |
| `hypr/hyprland/` | Shared base config: general, keybinds, rules (0.55 `match:` syntax), execs, env, colors, gaming |
| `hypr/hosts/` | Per-machine files: `cachy.conf`, `nix.conf` — target of the `host.conf` symlink |
| `hypr/custom/` | Personal overrides, sourced last |
| `hypr/scripts/game-mode` | Game mode toggle script (detects GPU/CPU vendor at runtime) |
| `quickshell/hyprshell/` | The desktop shell (bar, app menu, quick settings, notifications, OSD) |
| `arch/` | CachyOS install path: `packages.txt`, `packages-aur.txt`, `install.sh`, its own README |
| `nixos/` | NixOS system flake; `modules/desktop.nix` (shell, theming, portals, fonts), `modules/gaming.nix` (gamemode, scx, steam) |
| `home-manager/` | Home Manager: fish, GTK/Qt theming, dconf, user packages |
| `wofi/` | Launcher (Adwaita dark, translucent) |
| `gtk-3.0/`, `gtk-4.0/`, `qt6ct/` | adw-gtk3-dark / Adwaita icons / Cantarell 11 |

## Install

### NixOS (`nix`)

```sh
git clone git@github.com:DERK0CHER/nix-dot.git ~/.config
sudo ln -sfn ~/.config/nixos /etc/nixos      # or copy hardware-configuration.nix in
sudo nixos-rebuild switch
cd ~/.config/home-manager && home-manager switch --flake .#beba
ln -sfn ~/.config/hypr/hosts/nix.conf ~/.config/hypr/host.conf
```

Log in through GDM and pick the Hyprland session.

### CachyOS / Arch (`cachy`)

```sh
git clone git@github.com:DERK0CHER/nix-dot.git ~/src/nix-dot
~/src/nix-dot/arch/install.sh
```

`install.sh` installs `arch/packages.txt` with `pacman -S --needed` and
`arch/packages-aur.txt` with `yay`, symlinks the config directories into
`~/.config`, picks `hypr/hosts/$(hostnamectl --static).conf` for the `host.conf`
symlink (falling back to `cachy.conf`), and enables `ananicy-cpp` /
`power-profiles-daemon`. It is idempotent and moves anything it would overwrite
to `~/.config/<name>.bak.<timestamp>` instead of deleting it. `--dry-run` shows
what it would do; details in [`arch/README.md`](arch/README.md).

`nixos/` and `home-manager/` are ignored on this host, and `arch/` is ignored on
NixOS. Neither path touches the other's files.

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
- GPU stats are vendor-aware: `nvidia-smi` on `cachy`, amdgpu sysfs on `nix`.
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
launch option) so the mode is entered and left automatically. The script probes the
GPU and CPU vendor at runtime, so the same file works on both machines.

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

## NVIDIA notes (`cachy`)

- The **open** kernel modules are in use (`linux-cachyos-nvidia-open` plus one
  `-nvidia-open` package for every kernel you boot, the LTS one included — a kernel
  without it falls back to nouveau). Turing is the oldest generation they support,
  so the RTX 2060 sits exactly on the boundary; the proprietary `nvidia-dkms` is the
  fallback if the display never comes up.
- `nvidia_drm.modeset=1` is required for Wayland; verify with
  `cat /sys/module/nvidia_drm/parameters/modeset`.
- All NVIDIA env lives in `hypr/hosts/cachy.conf`, never in the shared
  `hypr/hyprland/env.conf`. **`GBM_BACKEND` is the first line to comment out** if
  Electron apps or Firefox come up black or blank.
- Hardware cursors are the classic NVIDIA glitch (invisible cursor, trails,
  flicker over fullscreen games). `hosts/cachy.conf` ships
  `cursor:no_hardware_cursors = false` with the `true` fallback right below it,
  commented — use that, not the legacy `WLR_NO_HARDWARE_CURSORS` env, which
  Hyprland no longer reads.
- The AMD box's `AQ_NO_ATOMIC=1` and `misc:vrr = 0` are amdgpu workarounds and
  **deliberately do not apply here** — they stay in `hosts/nix.conf` /
  `nixos/modules/hyprland.nix`.
- Single GPU on both machines: neither the Ryzen 7 nor the i5-9400F has an
  iGPU, so there is no PRIME, hybrid or render-offload setup to configure.

## Performance notes

**Both** — `misc:vfr`, direct scanout and `immediate`/tearing rules for
`steam_app_*` (`hypr/hyprland/gaming.conf`), plus `gamemode`.

**`nix` (AMD)** — RADV (mesa) is the Vulkan driver, no proprietary bits;
`AQ_NO_ATOMIC=1` (set in `nixos/modules/hyprland.nix`) and `misc:vrr = 0` stay,
because atomic DRM + VRR crashed the compositor on that GPU/monitor combination;
`scx_lavd` and `gamemode` come from `nixos/modules/gaming.nix`; zram swap, ZFS
ARC capped so games keep their RAM.

**`cachy` (NVIDIA + Intel)** — the AOC secondary (DP-2) came up at **1920x1080@60**,
which was only the fallback mode; it is now set to the **300 Hz** the panel
advertises, with a commented **240 Hz** fallback in `hosts/cachy.conf` in case
300 is unstable over the cable. Blur is cut to `size 4 / passes 2` on this host
because a 6 GB RTX 2060 driving 3440x1440@160 pays for blur in milliseconds per
frame. `ananicy-cpp` is active; `scx-scheds`/`scxctl` are installed but no
sched_ext scheduler is loaded by default.

## Customizing

- Hyprland, both machines: `hypr/custom/*.conf` (sourced last, wins over everything).
- Hyprland, one machine only: `hypr/hosts/<host>.conf`.
- Shell colours, fonts, radii and spacing: `quickshell/hyprshell/Theme.qml`.
- GTK/Qt look: `home-manager/home.nix` on NixOS (`gtk`, `qt`, `dconf.settings`);
  `gtk-3.0/`, `gtk-4.0/`, `qt6ct/` are used directly on CachyOS.

## Planned work

[TODO.md](TODO.md) holds the backlog: 50 specified tasks across the launcher, an Alt+Tab switcher, a command
palette with an in-place keybind editor, a Claude usage widget, Proton mail/calendar/VPN,
a lockdown mode, and the Neovim config plus its tutorial. Each task names the files to
touch, the steps, and the acceptance checks. Task IDs are stable, so commits can reference
them (`L3: finish the wofi restyle`).
