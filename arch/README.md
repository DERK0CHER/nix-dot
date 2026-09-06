# arch/ - CachyOS / Arch install path

This directory installs the dotfiles on the **Arch-derived** host (`cachy`):
CachyOS, Intel i5-9400F, NVIDIA RTX 2060 on the open kernel modules, DP-1
(LG ultrawide 3440x1440) + DP-2 (AOC 25G4S 1920x1080).

**On NixOS, ignore this directory.** The other machine (`nix`, Ryzen + Radeon
RX 9060 XT, ZFS root) is built declaratively from `nixos/` and `home-manager/`.
Both hosts live in the same tree on purpose; neither install path deletes the
other's files.

## Install

```sh
git clone <this repo> ~/src/nix-dot
~/src/nix-dot/arch/install.sh
```

The script is idempotent and never deletes anything: any existing
`~/.config/<name>` that is not already the right symlink is **moved** to
`~/.config/<name>.bak.<timestamp>` first.

It does, in order: refuse root, refuse a non-Arch `/etc/os-release`, install
`packages.txt` with `pacman -S --needed`, install `packages-aur.txt` with `yay`
(skipped with a hint if `yay` is missing), symlink the config directories,
create the host symlink, `chmod +x` the scripts in `hypr/scripts/`, and enable
`ananicy-cpp` / `power-profiles-daemon` if those units exist.

## The host symlink

Machine-specific Hyprland settings (monitors, GPU env, GPU workarounds) live in
one file per host:

| File | Host |
|------|------|
| `hypr/hosts/cachy.conf` | this machine - NVIDIA + Intel, DP-1/DP-2 |
| `hypr/hosts/nix.conf`   | the other machine - AMD, `AQ_NO_ATOMIC=1`, `misc:vrr = 0` |

`hypr/hyprland.conf` sources `~/.config/hypr/host.conf` right before the
`custom/*.conf` glob. `host.conf` is a **symlink**, created by `install.sh`
from `hostnamectl --static` (falling back to `cachy.conf`):

```sh
ln -sfn ~/.config/hypr/hosts/cachy.conf ~/.config/hypr/host.conf
```

It is not tracked - it is per-machine state. Switching hosts is one `ln -sfn`.

## NVIDIA notes

- Open kernel modules (`linux-cachyos-nvidia-open`, `nvidia-open` on plain
  Arch). Turing is the oldest generation they support, so the RTX 2060 is
  exactly on the boundary - if the display never comes up, the proprietary
  `nvidia-dkms` is the fallback.
- Keep a `-nvidia-open` package for **every** kernel you boot (the LTS one too),
  or that kernel falls back to nouveau.
- `nvidia_drm.modeset=1` is required for Wayland. It is the default with recent
  drivers, but verify with `cat /sys/module/nvidia_drm/parameters/modeset`.
- **Do not set `GBM_BACKEND=nvidia-drm` globally.** It fixes nothing on a modern
  driver and breaks GBM for anything that is not the NVIDIA stack (Firefox and
  Electron under XWayland in particular). Any NVIDIA env belongs in
  `hypr/hosts/cachy.conf`, never in the shared `hypr/hyprland/env.conf`.
- Hardware cursors are fine on 610.x; if the cursor flickers or disappears, set
  `cursor:no_hardware_cursors = true` in `hypr/hosts/cachy.conf` rather than the
  legacy `WLR_NO_HARDWARE_CURSORS` env, which Hyprland no longer reads.
- The AMD host's `AQ_NO_ATOMIC=1` and `misc:vrr = 0` are amdgpu workarounds and
  must stay in `hosts/nix.conf`.

## No `arch/systemd/` directory

Deliberate. A user unit for `qs -c hyprshell` would have to wait for
`WAYLAND_DISPLAY` **and** `HYPRLAND_INSTANCE_SIGNATURE`, which only exist once
Hyprland is up; `exec-once` in `hypr/hyprland/execs.conf` gets both for free and
dies with the session, which is the behaviour you want. Same for `hyprpaper`,
`hypridle`, `gammastep` and the two `wl-paste --watch cliphist` processes.

If the shell ever needs `Restart=on-failure`, the right move is
`uwsm app -- qs -c hyprshell` (uwsm is installed and already scopes exec-once
children into systemd units), not a hand-written unit file here.

## Undo

```sh
rm ~/.config/hypr ~/.config/quickshell        # the symlinks, not the repo
mv ~/.config/hypr.bak.<timestamp> ~/.config/hypr
```

Packages installed by `pacman -S --needed` are not tracked by this repo; remove
them by hand if you want the machine back exactly as it was.
