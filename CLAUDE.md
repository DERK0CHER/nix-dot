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

## Project: NixOS Dotfiles

**Repo:** `git@github.com:DERK0CHER/nix-dot.git` — the entire `~/.config` is tracked.

### Key directories

| Path | Purpose |
|------|---------|
| `hypr/` | Hyprland config — split into `hyprland/` (base) and `custom/` (user overrides) |
| `hypr/hyprland/general.conf` | Monitor, input, animations, decorations, misc |
| `hypr/hyprland/keybinds.conf` | All keybindings |
| `hypr/hyprland/rules.conf` | Window/layer/workspace rules (0.55 `match:` syntax) |
| `hypr/hyprland/execs.conf` | Autostart programs (starts `qs -c hyprshell`) |
| `hypr/hyprland/env.conf` | Environment variables |
| `hypr/hyprland/gaming.conf` | Game-related rules / options |
| `hypr/custom/` | Local overrides sourced after base |
| `hypr/scripts/game-mode` | Game mode script: `on | off | toggle | status | run [--exclusive] -- <cmd>` |
| `quickshell/hyprshell/` | The desktop shell (Quickshell): bar, app menu, quick settings, notifications; `shell.qml`, `State.qml`, `Theme.qml` |
| `nixos/modules/desktop.nix` | Shell packages, Adwaita theming, portals, fonts, Qt platform theme |
| `nixos/modules/gaming.nix` | gamemode, scx, steam, kernel/sysctl tuning |
| `nixos/modules/` | Other NixOS system modules (packages, environment, users, hyprland) |
| `home-manager/` | Home Manager flake (fish, GTK/Qt/dconf theming, user packages) |
| `fish/` | Fish shell config |
| `nvim/` | Neovim config (neotex setup) |
| `niri/` | Niri compositor config |

### Workflow notes

- Edit `hypr/hyprland/*.conf` for base config; `hypr/custom/*.conf` for personal overrides.
- `waybar/` and `dunst/` were removed; the shell is Quickshell: `qs -c hyprshell`.
  IPC: `qs -c hyprshell ipc call shell <toggleQuickSettings|toggleNotifications|toggleAppMenu|toggleBar|toggleLauncher|setGameMode true|false>`.
- Layer namespaces: `hyprshell-bar`, `hyprshell-panel`, `hyprshell-osd`, `hyprshell-notif`.
- Hyprland ≥ 0.55 rule syntax: `windowrule = float on, center on, match:title ^(Open File)`; `layerrule = blur on, match:namespace ^hyprshell-bar$`.
- Keep `AQ_NO_ATOMIC=1` (nixos/modules/hyprland.nix) and `misc:vrr = 0` — atomic DRM + VRR crash on the RX 9060 XT. No NVIDIA config.
- NixOS modules live at `/etc/nixos/` symlinked from `nixos/`; rebuild with `sudo nixos-rebuild switch`.
- Home Manager: `cd home-manager && home-manager switch --flake .#beba`.
- Hyprland uses `windowrule` (not deprecated `windowrulev2`) and `shadow {}`/`blur {}` nested blocks.
