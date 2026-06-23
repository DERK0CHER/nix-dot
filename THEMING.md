# theming-experiments

Wallpaper-driven colorschemes, in the style of
[Z3R0-F0UR/dotfiles](https://github.com/Z3R0-F0UR/dotfiles): pick a wallpaper →
the whole desktop recolors from it.

## How it works

```
Super+Shift+W → rofi thumbnail picker (~/Pictures/wallpapers)
            → awww sets the wallpaper (fade transition)
            → wallust extracts a 16-color palette
            → renders templates to ~/.cache/wallust/
            → kitty / waybar / wofi / hyprland live-reload
```

Generated color files live in `~/.cache/wallust/` (untracked), so wallpaper
switches never show up as git noise. The live configs reference them by
absolute path:

| App      | Wiring                                                             |
|----------|--------------------------------------------------------------------|
| kitty    | `include ~/.cache/wallust/kitty.conf` (home-manager source)        |
| waybar   | `@import` in `waybar/style.css` → `@accent` overrides at the bottom |
| wofi     | `@import` in `wofi/style.css`                                       |
| hyprland | `source = /home/beba/.cache/wallust/hypr-colors.conf` → `$accent`   |
| dunst    | launched with `-config ~/.cache/wallust/dunstrc`; `dunstctl reload` |

dunst has no `@import`, so its whole config is templated. The tracked source
of truth stays at `dunst/dunstrc`; the wallust template `wallust/templates/dunstrc`
is the themed mirror — edit both if you change dunst layout/behaviour.

Tune the palette mood (`softdark16`, `dark16`, `harddark16`, …) in
`wallust/wallust.toml`. Tweak which palette slots map to the accent in
`wallust/templates/*`.

## Activate

```sh
# 1. install deps (awww, wallust, rofi, jq, imagemagick)
sudo nixos-rebuild switch

# 2. apply the kitty include
cd home-manager && home-manager switch --flake .#beba && cd ..

# 3. reload hyprland (picks up awww autostart + the new keybind)
hyprctl reload

# 4. drop some wallpapers in ~/Pictures/wallpapers, then:
Super+Shift+W
```

The repo ships seeded `~/.cache/wallust/*` files (current gruvbox palette) so
every config loads correctly even before wallust runs once.

## waylandar (calendar widget)

Added as a flake input (`nixos/flake.nix`) and installed via `packages.nix`
(`inputs.waylandar.packages.${pkgs.system}.default`). It ships these binaries:
`waylandar` (sync), `waylandar-init-theme`, `waylandar-widget`, `waylandar-dashboard`.

It needs interactive setup before autostart, so the `exec-once` in `execs.conf`
is left commented:

```sh
sudo nixos-rebuild switch        # builds + installs waylandar (first build is slow)
waylandar-init-theme             # initialise ~/.config/waylandar frontend/theme
# configure a calendar source (Google OAuth / Nextcloud CalDAV / iCloud / local .ics)
waylandar-widget                 # test it runs, then uncomment the exec-once
```

waylandar can theme itself with **matugen** (a different engine than the wallust
setup above). Left at its default for now — wire it to the same wallpaper later
if you want one source of truth.

## Notes

- **hyprpaper** was swapped for **awww** (swww fork) in `execs.conf`; the old static
  wallpaper line is gone.
- Borders are themed but `border_size = 0`, so they're invisible until you bump
  it in `hypr/hyprland/general.conf`.
