# theming-experiments

Wallpaper-driven colorschemes, in the style of
[Z3R0-F0UR/dotfiles](https://github.com/Z3R0-F0UR/dotfiles): pick a wallpaper →
the whole desktop recolors from it.

## How it works

```
Super+Shift+W → rofi thumbnail picker (~/Pictures/wallpapers)
            → swww sets the wallpaper (fade transition)
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
| hyprland | `source = ~/.cache/wallust/hypr-colors.conf` → `$accent` borders    |

Tune the palette mood (`softdark16`, `dark16`, `harddark16`, …) in
`wallust/wallust.toml`. Tweak which palette slots map to the accent in
`wallust/templates/*`.

## Activate

```sh
# 1. install deps (swww, wallust, rofi-wayland, jq, imagemagick)
sudo nixos-rebuild switch

# 2. apply the kitty include
cd home-manager && home-manager switch --flake .#beba && cd ..

# 3. reload hyprland (picks up swww autostart + the new keybind)
hyprctl reload

# 4. drop some wallpapers in ~/Pictures/wallpapers, then:
Super+Shift+W
```

The repo ships seeded `~/.cache/wallust/*` files (current gruvbox palette) so
every config loads correctly even before wallust runs once.

## Notes / not done yet

- **dunst** isn't themed live — it has no include mechanism, so recoloring it
  means templating the whole `dunstrc`. Left out to keep the blast radius small.
- **hyprpaper** was swapped for **swww** in `execs.conf`; the old static
  wallpaper line is gone.
- Borders are themed but `border_size = 0`, so they're invisible until you bump
  it in `hypr/hyprland/general.conf`.
- **waylandar** (the calendar widget) is unrelated to theming and not included
  here — it's a separate Quickshell/Nix module to add later if wanted.
