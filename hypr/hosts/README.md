# hypr/hosts/ — one file per machine

`hypr/hyprland.conf` sources `~/.config/hypr/host.conf` right before the
`custom/*.conf` glob. `host.conf` is a **symlink** into this directory, not a
file — never edit `host.conf`, edit the `hosts/<host>.conf` it points at.

| File | Machine |
|------|---------|
| `cachy.conf` | CachyOS, Intel i5-9400F, NVIDIA RTX 2060 (open modules), DP-1 ultrawide + DP-2 |
| `nix.conf`   | NixOS, Ryzen 7, Radeon RX 9060 XT, `AQ_NO_ATOMIC` note + `misc:vrr = 0` |

## What belongs in a host file

- `monitor = …` lines (names, modes, positions, scale).
- GPU/vendor environment variables (`env = GBM_BACKEND, …`, `env = AMD_VULKAN_ICD, …`).
- Vendor workarounds: `cursor:no_hardware_cursors`, `misc:vrr`, driver quirks.
- Per-machine performance overrides where the hardware differs — e.g. smaller
  `decoration:blur` on the 6 GB card driving 3440x1440.

## What does NOT belong here

Anything a second machine would also want: keybinds, window/layer rules,
animations, colours, autostarts, portable env vars (`MOZ_ENABLE_WAYLAND`).
Those go in `hypr/hyprland/*.conf` and must stay vendor-neutral, so a host file
only ever *adds* or *overrides*. Personal, machine-independent tweaks still go
in `hypr/custom/*.conf`, which is sourced after the host file and wins.

## Adding a third machine

1. `cp hosts/cachy.conf hosts/<hostname>.conf` and rewrite the monitor + GPU block.
2. Name it after `hostnamectl --static` — `arch/install.sh` picks
   `hosts/$(hostnamectl --static).conf` automatically, falling back to `cachy.conf`.
3. Point the symlink at it (the install script does this for you):

```sh
ln -sfn ~/.config/hypr/hosts/<hostname>.conf ~/.config/hypr/host.conf
```
