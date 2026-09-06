# CLAUDE.md

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Project: Hyprland Dotfiles (NixOS + CachyOS, two hosts)

**Repo:** `git@github.com:DERK0CHER/nix-dot.git` — the entire `~/.config` is tracked.

One tree describes **two machines**. Both must stay buildable from it; never
delete one host's settings to make the other work.

| Host | OS | CPU / GPU | Monitors | Install path |
|------|----|-----------|----------|--------------|
| `nix`   | NixOS unstable, ZFS root, user `beba` | Ryzen 7 (no iGPU) / Radeon RX 9060 XT (amdgpu, RADV) | HDMI-A-1 2560x1440@144, DP-1 1920x1080@300 | `nixos/` + `home-manager/` |
| `cachy` | CachyOS (Arch, pacman + yay) | Intel i5-9400F (no iGPU) / NVIDIA RTX 2060, open modules | DP-1 3440x1440@160 ultrawide, DP-2 1920x1080@300 | `arch/install.sh` |

Branch `cachyos-nvidia-intel` targets the **cachy** machine. `nixos/` and
`home-manager/` do not apply there and are left alone on this branch.

### Key directories

| Path | Purpose |
|------|---------|
| `hypr/` | Hyprland config — split into `hyprland/` (base), `hosts/` (per-machine), `custom/` (user overrides) |
| `hypr/hosts/` | One file per machine: `cachy.conf`, `nix.conf` — monitors, GPU env, vendor workarounds. `~/.config/hypr/host.conf` is a symlink to one of them |
| `hypr/hyprland/general.conf` | Input, animations, decorations, misc (no `monitor =` lines — those live in `hypr/hosts/`) |
| `hypr/hyprland/keybinds.conf` | All keybindings |
| `hypr/hyprland/rules.conf` | Window/layer/workspace rules (0.55 `match:` syntax) |
| `hypr/hyprland/execs.conf` | Autostart programs (starts `qs -c hyprshell`) |
| `hypr/hyprland/env.conf` | Environment variables |
| `hypr/hyprland/gaming.conf` | Game-related rules / options |
| `hypr/custom/` | Local overrides sourced after base |
| `hypr/scripts/game-mode` | Game mode script: `on | off | toggle | status | run [--exclusive] -- <cmd>`; probes GPU/CPU vendor at runtime so one file serves both hosts |
| `quickshell/hyprshell/` | The desktop shell (Quickshell 0.3.x): bar, app menu, quick settings, notifications, OSD. `shell.qml` entry; singletons `Theme.qml`, `ShellState.qml`, `Notifs.qml`, `Host.qml`; **every** component must be listed in `qmldir`, singleton or not, and must not shadow a QtQuick type name. GPU stats are vendor-aware (`nvidia-smi` / amdgpu sysfs) |
| `arch/` | CachyOS/Arch install path: `packages.txt` (pacman), `packages-aur.txt` (yay), `install.sh`, `README.md` |
| `nixos/modules/desktop.nix` | Shell packages, Adwaita theming, portals, fonts, Qt platform theme |
| `nixos/modules/gaming.nix` | gamemode, scx, steam, kernel/sysctl tuning |
| `nixos/modules/` | Other NixOS system modules (packages, environment, users, hyprland) |
| `home-manager/` | Home Manager flake (fish, GTK/Qt/dconf theming, user packages) |
| `fish/` | Fish shell config |
| `nvim/` | Neovim config (neotex setup) |
| `niri/` | Niri compositor config |

### Workflow notes

- **Shared vs host-scoped.** `hypr/hyprland/*.conf` is shared by both machines and
  must stay vendor-neutral: no `monitor =` lines, no GPU env, no driver
  workarounds. Anything machine-specific goes in `hypr/hosts/<host>.conf` — never
  in the shared files, never in `nixos/` for the Arch host. `hypr/custom/*.conf`
  stays for personal, machine-independent overrides.
- Source order in `hypr/hyprland.conf`: `hyprland/*.conf` → `~/.config/hypr/host.conf`
  → `custom/*.conf`. `host.conf` is an untracked symlink into `hypr/hosts/`,
  created by `arch/install.sh` (or by hand:
  `ln -sfn ~/.config/hypr/hosts/cachy.conf ~/.config/hypr/host.conf`).
- Edit `hypr/hyprland/*.conf` for base config; `hypr/custom/*.conf` for personal overrides.
- `waybar/` and `dunst/` were removed; the shell is Quickshell: `qs -c hyprshell`.
  IPC: `qs -c hyprshell ipc call shell <toggleQuickSettings|toggleNotifications|toggleAppMenu|toggleBar|toggleLauncher|setGameMode true|false>`.
- Layer namespaces: `hyprshell-bar`, `hyprshell-panel`, `hyprshell-osd`, `hyprshell-notif`.
- Hyprland ≥ 0.55 rule syntax: `windowrule = float on, center on, match:title ^(Open File)`; `layerrule = blur on, match:namespace ^hyprshell-bar$`.
- `AQ_NO_ATOMIC=1` (nixos/modules/hyprland.nix) and `misc:vrr = 0` are **AMD-only** —
  atomic DRM + VRR crash on the RX 9060 XT. They stay scoped to the `nix` host and
  must not leak into shared files or `hosts/cachy.conf`.
- NVIDIA (`cachy`): open kernel modules, driver 610.x, single GPU (no PRIME/offload).
  All NVIDIA env lives in `hypr/hosts/cachy.conf`; `GBM_BACKEND` is the first line to
  comment out if apps render black, and `cursor:no_hardware_cursors = true` is the
  commented cursor fallback (not the legacy `WLR_NO_HARDWARE_CURSORS`).
- NixOS (`nix`): modules live at `/etc/nixos/` symlinked from `nixos/`; rebuild with
  `sudo nixos-rebuild switch`, then `cd home-manager && home-manager switch --flake .#beba`.
- CachyOS (`cachy`): `arch/install.sh` — pacman + yay from `arch/packages*.txt`, then
  the `~/.config` symlinks and the `host.conf` symlink. It is idempotent and backs up
  anything it would replace.
- Hyprland uses `windowrule` (not deprecated `windowrulev2`) and `shadow {}`/`blur {}` nested blocks.
