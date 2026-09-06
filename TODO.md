# TODO / Backlog

Everything here is planned, not started. Each entry is written so it can be picked up cold:
which files to touch, what to do, and how to tell it actually worked.

Effort is **S** (under an hour), **M** (one to three hours) or **L** (a day or more).
Task IDs are stable, so reference them in commit messages, e.g. `L1: add Launcher.qml`.

The specs were written against the repo as it stands after the Hyprland/Quickshell overhaul.
Anything a spec could not verify is listed under *Open questions* at the end of each section,
and it is worth reading that list before starting a task in it.

## Already verified

Checked against a running Hyprland 0.56 and a real Claude Code transcript on 2026-09-06, so
nobody has to redo it:

- `Super+Shift+C` is taken (colour picker, `hypr/hyprland/keybinds.conf:33`). `Super+Shift+Return`
  and `Super+Slash` are free.
- `hyprctl binds -j` returns one object per bind with `modmask`, `key`, `dispatcher`, `arg`,
  plus `locked` / `mouse` / `repeat` / `release` / `submap` / `description`. The modmask
  arithmetic holds: shift 1, ctrl 4, alt 8, super 64, so 65 is super+shift and 72 is super+alt.
- `qmldir` only needs entries for singletons. Plain components in the same directory resolve
  automatically, which is how `Bar.qml` and `Clock.qml` already work, so new panels and widgets
  need no registration.
- The Claude CLI has both `--print` and `--output-format`.
- Transcript rows carry `timestamp`, `message.model` and `message.usage` with `input_tokens`,
  `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens` and an `iterations`
  array, so the usage aggregator has the fields it needs.

## Overview

| ID | Task | Effort |
|----|------|--------|
| | **Launcher and search** | |
| `L1` | Build Launcher.qml: the Spotlight panel with apps search | L &middot; a day or more |
| `L2` | Add real fuzzy ranking and persisted usage frequency | M &middot; 1-3 h |
| `L3` | Interim: finish the wofi restyle (20-minute throwaway win) | S &middot; under 1 h |
| `L4` | Add in-process prefix modes: commands (>), calculator (=), windows (w ) | M &middot; 1-3 h |
| `L5` | Add external providers: clipboard (:), files (/), PATH commands | M &middot; 1-3 h |
| `L6` | Visual polish pass: motion, empty states, and typography | S &middot; under 1 h |
| `L7` | Retire wofi and move Super+V onto the launcher | S &middot; under 1 h |
| | **Command palette and keybind editor** | |
| `C1` | Seed a command catalogue from the 140 existing binds | M &middot; 1-3 h |
| `C2` | Write the persistence helper: generated block in hypr/custom/keybinds.conf | M &middot; 1-3 h |
| `C3` | Build Commands.qml, the shared catalogue + live-bind model | L &middot; a day or more |
| `C4` | Add the '>' command-palette mode to the launcher | M &middot; 1-3 h |
| `C5` | Build KeybindEditor.qml with press-a-combo capture | L &middot; a day or more |
| `C6` | Add the Super+Slash cheat sheet overlay | M &middot; 1-3 h |
| | **Window switching (Alt+Tab)** | |
| `W1` | Replace cyclenext with a real MRU Alt+Tab switcher overlay | M &middot; 1-3 h |
| `W2` | Add live window thumbnails to the switcher | M &middot; 1-3 h |
| | **Claude usage widget and Claude Code** | |
| `K1` | Write hypr/scripts/claude-usage, a jq aggregator over the local transcripts | M &middot; 1-3 h |
| `K2` | Add ClaudeWidget.qml: a near-invisible bar dot that pulses only during a live session | M &middot; 1-3 h |
| `K3` | Add ClaudePanel.qml: today's tokens, a 7-day sparkline, top projects, live session | M &middot; 1-3 h |
| `K4` | Bind a styled floating Claude Code terminal to Super+Shift+Return, scoped to the focused project | S &middot; under 1 h |
| `K5` | Make claude-code resolve from nixpkgs, not ~/.local/bin, and pin the widget's dependencies | S &middot; under 1 h |
| `K6` | Add a quick-ask input that pipes one question to `claude -p` and shows the answer in a panel | M &middot; 1-3 h |
| | **Proton mail, calendar and VPN** | |
| `P1` | Run protonmail-bridge headless as a systemd user service | M &middot; 1-3 h |
| `P2` | Fix the secrets policy: keyring-only, nothing committed | S &middot; under 1 h |
| `P3` | Set up Evolution as the Proton Mail reader with native desktop notifications | M &middot; 1-3 h |
| `P4` | Add a mail-status poller and a Mail.qml singleton feeding the shell | M &middot; 1-3 h |
| `P5` | Surface mail in StatusPill and the notification center, invisible at zero | S &middot; under 1 h |
| `P6` | Add a Proton VPN toggle driven by NetworkManager state | M &middot; 1-3 h |
| `P7` | Build a calendar view in the notification popover plus a Proton Calendar web-app window | L &middot; a day or more |
| | **Lockdown mode** | |
| `D1` | Write hypr/scripts/lockdown, the local (no-network) core | M &middot; 1-3 h |
| `D2` | Add setLockdown IPC + persistent shield indicator to hyprshell | M &middot; 1-3 h |
| `D3` | Create nixos/modules/lockdown.nix with a single root helper and one sudo rule | M &middot; 1-3 h |
| `D4` | Transparent Tor routing with a fail-closed nftables kill-switch | L &middot; a day or more |
| `D5` | Session hardening: lock, idle, firewall default-deny, optional USB freeze | M &middot; 1-3 h |
| `D6` | Write the lockdown threat model and 'what this does NOT protect against' | S &middot; under 1 h |
| `D7` | Add `lockdown check` — a self-audit that verifies the mode is actually on | M &middot; 1-3 h |
| | **Neovim and the LEARN.md tutorial** | |
| `N1` | Delete deprecated/ and the dead Himalaya keymaps | S &middot; under 1 h |
| `N2` | Write LEARN.md with a :Learn command and a GENERATED keymap reference | L &middot; a day or more |
| `N3` | Add a :checkhealth neotex module for external dependencies | M &middot; 1-3 h |
| `N4` | Modernise LSP to vim.lsp.config/enable and drop mason on NixOS | M &middot; 1-3 h |
| `N5` | Set a startup-time budget and cut eager loads | M &middot; 1-3 h |
| `N6` | Split which-key.lua into per-group modules | M &middot; 1-3 h |
| `N7` | Make the committed lazy-lock.json actually authoritative | M &middot; 1-3 h |
| `N8` | Consolidate the completion stack onto blink.cmp | M &middot; 1-3 h |
| `N9` | Gate formatters and linters on binary availability | S &middot; under 1 h |

---

## Launcher and search

### Recommended approach

Wofi is a dead end for the look you want and you should stop investing in it. Its CSS is a GTK3 subset (no real shadows, no per-row layout, `border-radius` on `window` leaves square corner artifacts, no section headers, no rich two-line rows), its "fuzzy" matching is an unranked substring filter, and it can only ever render one flat list — so grouped results (Apps / Windows / Commands / Clipboard / Files / Calc) are structurally impossible. Fuzzel is faster and cleaner but has the same ceiling (it is a single-column text list by design). rofi-wayland gives you theming power but a decidedly non-GNOME idiom and a config language you will fight. walker/anyrun are the closest off-the-shelf matches, but both mean a second toolkit, a second theme file, and a second process to keep in sync with Theme.qml. The strong option is a `Launcher.qml` inside the shell you already run: it inherits every Theme token, the blur layerrule pattern, the `HyprlandFocusGrab` idiom already proven in AppMenu.qml, and `DesktopEntries` + `Quickshell.Hyprland` + `Quickshell.Io.Process` give you apps, windows, and shell providers without a single new dependency. The trade-off is real: you are writing a search engine in QML/JS, so budget one focused day for tasks 1-2 and expect the first week to surface Quickshell-version API mismatches (the fast-moving parts are `DesktopEntries.applications`, `FileView`/`JsonAdapter` writes, and `Process`/`StdioCollector`) — which is exactly why task 1 keeps wofi installed on Super+Shift+Space as a fallback and task 7 only deletes it once the QML launcher has survived normal use.

### `L1` &middot; Build Launcher.qml: the Spotlight panel with apps search

**Effort:** L &middot; a day or more

**Why.** One rounded translucent panel with real rows and icons is the whole point of the overhaul, and everything else in this area is an extension of it.

**Files**

- `quickshell/hyprshell/Launcher.qml`
- `quickshell/hyprshell/shell.qml`
- `quickshell/hyprshell/State.qml`
- `hypr/hyprland/rules.conf`
- `hypr/hyprland/keybinds.conf`

**Steps**

1. State.qml: add `property bool launcherOpen: false` and add `launcherOpen = false;` to `closePanels()`.
2. New Launcher.qml: `PanelWindow` anchored top+left+right+bottom (fullscreen), `color: "transparent"`, `exclusiveZone: 0`, `visible: State.launcherOpen`, `WlrLayershell.namespace: "hyprshell-launcher"`, `WlrLayershell.layer: WlrLayer.Overlay`, `WlrLayershell.keyboardFocus: State.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None`. Use a separate namespace (not hyprshell-panel) so the launcher can get its own dimaround/blur rule. Backdrop: a full-fill `Rectangle { color: Qt.rgba(0,0,0,0.25) }` with a `MouseArea` that sets `State.launcherOpen = false` on click.
3. Surface: centered `Rectangle` width 640, `y: parent.height * 0.20`, `implicitHeight: Math.min(480, header.height + list.contentHeight + Theme.pad*2)`, `radius: 16`, `color: Theme.bg`, `border.width: 1`, `border.color: Theme.border`, clip true. Wrap it in a `FocusScope` with `Keys.onEscapePressed: State.launcherOpen = false`.
4. Search field: `Rectangle` height 44, radius 22, `color: Theme.card`; inside a `TextInput` (font.family Theme.font, font.pixelSize Theme.fontSize + 2, color Theme.fg) plus a dim placeholder Text bound to `text === ""`. On `onVisibleChanged` when visible: clear text, `currentIndex = 0`, `forceActiveFocus()`. Forward navigation with `Keys.onUpPressed/onDownPressed` adjusting `list.currentIndex`, `Keys.onReturnPressed`/`onEnterPressed` activating, so the input never loses focus.
5. Results: `ListView { id: list; model: root.results; clip: true; highlightMoveDuration: 0; keyNavigationEnabled: false; currentIndex: 0 }`, delegate 44 px `Rectangle` (radius Theme.radiusSmall, `color: ListView.isCurrentItem ? Qt.rgba(1,1,1,0.12) : (hover ? Theme.card : "transparent")`) holding a `Row`: `IconImage { implicitSize: 28; source: Quickshell.iconPath(modelData.icon, true) }`, then a `Column` with the name (Theme.fg) and comment/genericName (Theme.fgDim, fontSizeSmall, elide right).
6. Data + search: build a flat JS array once from `DesktopEntries.applications` (skip `noDisplay` entries) into `property var apps`, rebuild on its change signal. `function recompute()` does a case-insensitive subsequence filter over name/genericName/comment/keywords, sorts, and slices to 40. Drive it from a `Timer { interval: 40; repeat: false }` restarted on every text change so typing stays at 60 fps. Empty query shows the first 12 apps alphabetically (task 3 replaces this with frequency).
7. Activate: `entry.execute(); State.launcherOpen = false`. Bind Ctrl+Return to `Quickshell.execDetached(["foot","-e","sh","-c", entry.exec])` for terminal launches.
8. Wire it: `Launcher {}` in shell.qml's ShellRoot; change `toggleLauncher()` to `State.closePanels(); State.launcherOpen = !State.launcherOpen;`. rules.conf: `layerrule = blur on, ignore_alpha 0.35, animation popin 92%, match:namespace ^hyprshell-launcher$` (0.35 sits above the 0.25 backdrop alpha so only the panel blurs). keybinds.conf line 10 becomes `bind = Super, Space, exec, qs -c hyprshell ipc call shell toggleLauncher`; add `bind = Super+Shift, Space, exec, pkill -x wofi || wofi --show drun` as the fallback.

**Done when**

- [ ] `qs -c hyprshell` restarts with no QML errors: `pkill qs; qs -c hyprshell 2>&1 | grep -iE 'error|warning' ` prints nothing about Launcher.qml.
- [ ] Super+Space opens a centered 640 px translucent rounded panel with the cursor already in the search field; typing `fire` puts Firefox first; Enter launches it and the panel closes.
- [ ] Escape closes it, clicking the dimmed backdrop closes it, and pressing Super+Space again toggles it closed.
- [ ] `hyprctl layers | grep -A3 hyprshell-launcher` shows the layer only while open, and the panel is visibly blurred while the rest of the screen is only dimmed, not blurred.
- [ ] Holding a key down in the field does not drop frames (subjective, but no visible stutter with ~300 desktop entries).
- [ ] Super+Shift+Space still opens wofi.

**Risks**

- `DesktopEntries.applications` may be an ObjectModel needing `.values` rather than a plain list in the installed Quickshell version; check with a `console.log(JSON.stringify(...))` first.
- `WlrKeyboardFocus.Exclusive` on a fullscreen overlay traps the keyboard if the panel ever fails to close — keep the unconditional Escape handler and test the toggle from a spare key before rebinding Super+Space.
- A fullscreen transparent layer plus `blur on` can cost GPU time on the 2560x1440@144 + 1920x1080@300 pair; if it stutters, drop the fullscreen backdrop and size the PanelWindow to the panel with `HyprlandFocusGrab` (the AppMenu.qml pattern) instead.
- Exclusive keyboard focus interacts badly with fullscreen games — gate it on `!State.gameMode` if game-mode ever shows the launcher.

### `L2` &middot; Add real fuzzy ranking and persisted usage frequency

**Effort:** M &middot; 1-3 h

**Why.** Ranking is the only thing wofi genuinely cannot do, and frequency-weighted results are what makes a launcher feel like it reads your mind.

**Files**

- `quickshell/hyprshell/Fuzzy.js`
- `quickshell/hyprshell/Usage.qml`
- `quickshell/hyprshell/qmldir`
- `quickshell/hyprshell/Launcher.qml`

**Steps**

1. Create `Fuzzy.js` starting with `.pragma library`, exporting `score(needle, haystack)` -> `-1` when the needle is not a subsequence of the haystack, else a number: +10 per matched char, +15 extra when the match is adjacent to the previous match (consecutive-run bonus), +20 when the matched char follows a word boundary (`[ \-_./]` or index 0), +25 when index 0, -1 per skipped char before the first match, and `-haystack.length * 0.05` as a length tiebreak.
2. In Launcher.qml score each candidate against several fields and take the max: name x 1.0, genericName x 0.7, comment x 0.55, keywords x 0.5, exec basename x 0.4. Drop anything scoring < 0, sort descending, slice 40.
3. Create `Usage.qml` (`pragma Singleton`) holding a `FileView` on `Quickshell.env("XDG_STATE_HOME") + "/hyprshell/launcher-usage.json"` with `watchChanges: true`, a `JsonAdapter` carrying `property var counts: ({})` and `property var lastUsed: ({})`. Expose `bump(id)` (increment count, set lastUsed to `Date.now()`, write) and `boost(id)` returning `Math.log(1 + count) * 25 + (recent ? 15 : 0)` where recent = used in the last 24 h.
4. Make the state dir before the first write: `Quickshell.execDetached(["mkdir","-p", dir])` in `Component.onCompleted`, and make `onLoadFailed` reset to empty objects so a missing/corrupt file never breaks the launcher.
5. Final ranking is `fuzzyScore + Usage.boost(id)` where `id` is the desktop entry id (fall back to the exec string). Call `Usage.bump(id)` on every activation.
6. With an empty query, show the 12 highest-`boost` entries under a section header reading `Frequent`.
7. Register both in `quickshell/hyprshell/qmldir`: `singleton Usage 1.0 Usage.qml` (Fuzzy.js is imported with `import "Fuzzy.js" as Fuzzy`, no qmldir line needed).

**Done when**

- [ ] Typing `t` ranks a frequently-launched app starting with T above alphabetically-earlier ones after three launches.
- [ ] `cat ~/.local/state/hyprshell/launcher-usage.json | jq` shows counts incrementing by one per launch.
- [ ] `rm ~/.local/state/hyprshell/launcher-usage.json` while the shell runs: the launcher still opens and searches, and the file is recreated on the next launch.
- [ ] Opening the launcher with an empty field shows a `Frequent` header and the apps you actually use most.
- [ ] Typing `gtx` matches `gnome-text-editor` (subsequence across word boundaries) and ranks it above a random substring match.

**Risks**

- The FileView write API differs across Quickshell versions (`writeAdapter()` vs `setText()` vs `JsonAdapter` auto-write); verify against the installed version before writing much code.
- `JsonAdapter` may not exist in the pinned Quickshell — fallback is plain `FileView.setText(JSON.stringify(obj))` and `JSON.parse(FileView.text())`.
- FileView will not create missing parent directories, hence the explicit mkdir; if `XDG_STATE_HOME` is unset outside the home-manager session the path collapses to `/hyprshell` — guard with a `|| Quickshell.env("HOME") + "/.local/state"` fallback.
- Writing on every launch is a synchronous-ish disk touch on ZFS; batch with a 2 s debounce if it ever shows up as latency.

### `L3` &middot; Interim: finish the wofi restyle (20-minute throwaway win)

**Effort:** S &middot; under 1 h

**Why.** Only worth doing if the QML launcher slips past today — it makes the corners actually round and kills the empty void under short result lists, which are the two things that read as unfinished right now.

**Files**

- `wofi/style.css`
- `wofi/config`
- `hypr/hyprland/rules.conf`

**Steps**

1. Fix the square-corner artifact: set `window { background: transparent; border: none; }` and move the surface onto `#outer-box { background: rgba(30,30,30,0.80); border: 1px solid rgba(255,255,255,0.10); border-radius: 12px; padding: 12px; }`. GTK3 clips children to `window`, so the current rule leaves opaque square corners behind the rounded box.
2. Change selection from the blue fill to the libadwaita idiom: `#entry:selected { background: rgba(255,255,255,0.12); box-shadow: inset 3px 0 0 #3584e4; }` plus `#text:selected { color: #ffffff; }` (wofi needs the `#text:selected` selector separately or the label keeps the unselected colour).
3. Stop rows from jumping between icon and icon-less entries: `#entry { min-height: 36px; }` and `#img { min-width: 28px; min-height: 28px; margin-right: 12px; }`.
4. config: add `dynamic_lines=true` and remove `height=420` so the window shrinks to the number of matches instead of leaving a large empty panel; add `parse_search=true` so the query matches the whole line rather than only the display name; add `sort_order=default` so wofi's own drun-usage cache orders results.
5. config: add `line_wrap=off` and `columns=1` to keep single-line rows, and keep `image_size=28` in sync with the CSS above.
6. rules.conf: add `layerrule = dimaround, match:namespace ^wofi$` next to the existing wofi blur rule so the backdrop dims like GNOME's overview.
7. Add `#scroll { padding-right: 4px; }` so the hidden scrollbar does not clip the last pixel column of long names.

**Done when**

- [ ] `wofi --show drun` shows fully rounded corners on all four sides against a wallpaper with no dark square artifacts (check the top-left corner over a light region).
- [ ] Typing a query that matches two apps shrinks the window to roughly two rows instead of staying 420 px tall.
- [ ] The background outside the window is visibly dimmed.
- [ ] The selected row is a subtle light overlay with a blue left edge, not a blue block.
- [ ] Searching for a word that only appears in an app's Comment field (e.g. `spreadsheet`) finds it.

**Risks**

- `dynamic_lines` interacts with an explicit `height`; if the window collapses to nothing, keep `height` and drop `dynamic_lines`.
- I have not verified that this wofi build supports `parse_search` and `sort_order` under those exact names — check `man 5 wofi` on the machine first; unrecognised keys are ignored silently, so the failure mode is only that nothing changes.
- This work is thrown away by task 7 — skip it entirely if task 1 lands the same day.

### `L4` &middot; Add in-process prefix modes: commands (>), calculator (=), windows (w )

**Effort:** M &middot; 1-3 h

**Why.** These three need no external process and turn the launcher into the 'hidden but always there' command surface the design brief asks for, replacing memorised keybinds.

**Files**

- `quickshell/hyprshell/Launcher.qml`
- `quickshell/hyprshell/LauncherProviders.js`
- `quickshell/hyprshell/shell.qml`

**Steps**

1. Parse the leading token in Launcher.qml: `>` = commands, `=` = calculator, `w ` = windows, `/` = files, `:` = clipboard (last two land in task 5). Strip the prefix into `query` and render a small mode chip (`Rectangle` radius 10, `Theme.card`, fontSizeSmall, Theme.fgDim) to the left of the text cursor so the mode is visible without a label.
2. Commands: a static array in LauncherProviders.js of `{name, comment, icon, run}` covering Lock (`hyprlock`), Suspend, Reboot, Power off, Game mode on/off (`~/.config/hypr/scripts/game-mode toggle`), Toggle bar (`qs -c hyprshell ipc call shell toggleBar`), Quick settings, Notifications, Reload shell (`pkill qs; qs -c hyprshell &`), Pick colour (`hyprpicker -a`), Screenshot region (`hyprshot -m region --clipboard-only`), Night light toggle. Use `Quickshell.execDetached(["sh","-c", run])`.
3. Calculator: on `=`, validate the expression against `/^[0-9+\-*/%^(). ,a-zA-Z]*$/`, reject anything containing an identifier not in a whitelist of Math members, map `^` to `**`, then evaluate with `new Function("Math", "return (" + expr + ")")(Math)`. Render one tall row showing the expression dim and the result at fontSize + 6; Enter copies via `Quickshell.execDetached(["sh","-c", "printf %s '" + result + "' | wl-copy"])`.
4. Windows: build rows from `Hyprland.clients` (or `ToplevelManager.toplevels` if the Hyprland model is awkward) with icon from `DesktopEntries.heuristicLookup(client.class)`, title as the primary label and `Workspace N` as the dim secondary. Activate with `Hyprland.dispatch("focuswindow address:" + client.address)`.
5. No-prefix mode searches apps + commands + windows together and groups them via `ListView.section.property: "group"` with a `section.delegate` styled like the `SectionLabel` component in AppMenu.qml (fontSizeSmall, Font.Bold, Theme.fgDim, left padding Theme.pad). Sort groups Apps, Windows, Commands, and cap each group at 6 in mixed mode.
6. Add an IPC entry point `function openLauncherMode(mode: string): void` in shell.qml that sets `State.launcherMode = mode` before opening, so keybinds can jump straight into a mode.
7. Add a discoverable hint row at the bottom of the panel (24 px, Theme.fgDim, fontSizeSmall): `>  commands    =  calc    w  windows    /  files    :  clipboard` — visible only when the query is empty, so it teaches once and then gets out of the way.

**Done when**

- [ ] Typing `>` alone lists all commands with icons; `>lock` filters to Lock and Enter locks the session.
- [ ] `=2^10/4` shows `256` and Enter puts `256` on the clipboard (verify with `wl-paste`).
- [ ] `w ` lists every open window across both monitors with the right workspace numbers; Enter focuses the window and the launcher closes.
- [ ] With an empty query the panel shows the prefix hint row; with any query the hint row is gone.
- [ ] A mixed query like `gnome` shows an `Apps` header and, if a GNOME window is open, a `Windows` header below it.

**Risks**

- The exact shape of `Hyprland.clients` (list vs ObjectModel, `address` with or without the `0x` prefix) varies; log one entry before writing the dispatch string.
- `new Function` may be restricted by the QML JS engine in some builds — fallback is a small hand-written shunting-yard parser in LauncherProviders.js.
- Reload shell as a command kills the process running the command; use `Quickshell.execDetached` with `setsid` so the new instance survives.
- Section headers plus a live-changing model can make ListView jump; set `currentIndex = 0` on every recompute.

### `L5` &middot; Add external providers: clipboard (:), files (/), PATH commands

**Effort:** M &middot; 1-3 h

**Why.** Clipboard search is the one thing Super+V currently shells out to wofi for, and file search removes the last reason to open a terminal for 'where did I put that'.

**Files**

- `quickshell/hyprshell/Launcher.qml`
- `quickshell/hyprshell/LauncherProviders.js`
- `nixos/modules/desktop.nix`
- `home-manager/home.nix`

**Steps**

1. Clipboard: a `Quickshell.Io.Process { command: ["cliphist","list"] }` with a `StdioCollector` on stdout, started only when the mode is `:` and the panel just opened. Split stdout on newlines, split each line on the first tab into `{id, preview}`, fuzzy-match the preview. Activate with `Quickshell.execDetached(["sh","-c", "printf '%s\\t' " + id + " | cliphist decode | wl-copy"])`.
2. Files: on `/`, run `fd --type f --hidden --exclude .git --max-results 60 <query> $HOME` through a `Process`, debounced 150 ms; set `proc.running = false` before restarting so a fast typist never has two `fd` processes alive. Rows show the basename as primary and the dirname (with `$HOME` replaced by `~`) as dim secondary. Enter opens with `xdg-open`, Ctrl+Enter reveals in `nautilus`.
3. PATH commands: on first use of `>` run `["bash","-lc","compgen -c | sort -u"]` once per shell session and cache the result in a property (the login shell is fish, so `sh -c compgen` will not work — bash must be invoked explicitly). Merge these below the curated command list from task 4 so hand-written entries always outrank raw binaries.
4. Guard every provider: never spawn a process unless the prefix matches, always cap results, and clear the model when the launcher closes so no stale clipboard content lingers in memory.
5. Add `fd` to `home.packages` in home-manager/home.nix and to `environment.systemPackages` in nixos/modules/desktop.nix (nixpkgs attr `fd`); add `bashInteractive` if `bash` is not already on PATH in the Hyprland session.
6. Optional upgrade for the calculator: add `libqalculate` and prefer `qalc -t <expr>` over the JS evaluator when the binary exists, which gets you units and currency (`100 usd to eur`, `3 GiB in MB`).

**Done when**

- [ ] `:` lists recent clipboard entries with previews; selecting one and pasting into a text editor yields exactly that content, including a multi-line entry.
- [ ] `/nixos` finds files under ~ within about 300 ms and Enter opens the right one in the right app.
- [ ] Typing quickly in `/` mode never leaves more than one `fd` process alive (`pgrep -c fd` stays <= 1 while typing).
- [ ] `>` shows curated commands first and PATH binaries after; `>htop` finds the binary.
- [ ] `nixos-rebuild build --flake .` (or the repo's build command) succeeds with the new packages, and `which fd` resolves after a rebuild.

**Risks**

- I am not certain `fd` in the pinned nixpkgs supports `--max-results`; if not, pipe through `head -n 60` in a `sh -c` instead.
- Quickshell's Process/StdioCollector property names (`stdout`, `onStreamFinished`, `running`) have changed between releases — check the installed docs before writing all three providers.
- `cliphist decode` reading an id from stdin vs argv differs by version; test `cliphist list | head -1 | cliphist decode` in a shell first.
- Searching all of $HOME with `--hidden` can be slow on a cold ZFS ARC; consider defaulting to a depth limit or a few pinned roots.
- Clipboard previews can contain passwords — decide whether `:` mode should be excluded from the mixed/no-prefix search (it should).

### `L6` &middot; Visual polish pass: motion, empty states, and typography

**Effort:** S &middot; under 1 h

**Why.** The brief is 'especially the looks' — this is the task where the launcher stops being functional and starts feeling like GNOME's overview.

**Files**

- `quickshell/hyprshell/Launcher.qml`
- `quickshell/hyprshell/Theme.qml`
- `hypr/hyprland/rules.conf`

**Steps**

1. Add launcher-scale tokens to Theme.qml rather than hard-coding: `radiusLarge: 16`, `launcherWidth: 640`, `launcherMaxHeight: 480`, `rowHeight: 44`, `fontSizeLarge: 17`. Keep every existing token untouched so the other components are unaffected.
2. Open/close motion: animate the surface with `scale` 0.96 -> 1.0 and `opacity` 0 -> 1 over 130 ms with `Easing.OutCubic`, and the backdrop opacity over 100 ms. Drive it from a `states`/`transitions` pair on `State.launcherOpen` so the close animation actually plays before `visible` flips (bind `visible` to `State.launcherOpen || anim.running`).
3. Height animation: `Behavior on implicitHeight { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }` so the panel grows and shrinks with the result count instead of snapping — this is the single biggest 'feels expensive' change.
4. Empty state: when a query has zero results, replace the list with a centered column — a dim 32 px `system-search-symbolic` IconImage and `No results for "<query>"` in Theme.fgDim — plus one actionable row offering to search the web (`xdg-open https://duckduckgo.com/?q=...`).
5. Selection detail: give the current row a 1 px `Theme.border` inset and, on the right edge, a dim `Return` glyph or an `↵` in fontSizeSmall that only appears on the current item, so the primary action is discoverable without being loud.
6. Match the bar: reuse `Theme.bg` exactly and set the layerrule to `blur on, ignore_alpha 0.35, blurpopups on, animation popin 92%` so the launcher's translucency reads identically to the bar's when both are on screen.
7. Check both monitors: bind the panel to `Hyprland.focusedMonitor` so it opens on the screen with focus, and verify the 640 px panel and 28 px icons are not visually different sizes between the 1440p and 1080p displays (they will be; decide whether to scale by `screen.devicePixelRatio` or accept it).

**Done when**

- [ ] Opening and closing the launcher shows a scale+fade animation with no flash of an unstyled or full-height panel.
- [ ] Typing progressively narrower queries shrinks the panel smoothly rather than snapping.
- [ ] A nonsense query shows the empty state, not a blank rectangle.
- [ ] The launcher opens on whichever monitor has focus, tested by focusing a window on each and pressing Super+Space.
- [ ] Side by side with the bar, the two surfaces are indistinguishable in tint and blur strength (screenshot both with `hyprshot -m output` and compare).

**Risks**

- Animating `implicitHeight` on a layer-shell window can cause per-frame surface resizes and visible tearing under Hyprland; if so, keep the window a fixed 480 px and animate an inner Item's height instead.
- `blurpopups` is a Hyprland layerrule I am not certain applies to layer surfaces (it may be window-only) — check `hyprctl layers` and the 0.55 wiki before relying on it.
- Delaying `visible` behind an animation can leave the exclusive keyboard focus held slightly too long; bind `keyboardFocus` to `State.launcherOpen` alone, not to `visible`.

### `L7` &middot; Retire wofi and move Super+V onto the launcher

**Effort:** S &middot; under 1 h

**Why.** Two launchers with two theme files is exactly the kind of duplicated surface the overhaul was meant to remove — but only after the replacement has earned it.

**Files**

- `hypr/hyprland/keybinds.conf`
- `hypr/hyprland/rules.conf`
- `nixos/modules/desktop.nix`
- `home-manager/home.nix`
- `wofi/config`
- `wofi/style.css`
- `quickshell/hyprshell/README.md`

**Steps**

1. Gate this task: only start it after the QML launcher has been the daily driver for about a week with no fallback use.
2. keybinds.conf: replace line 11 (`bind = Super, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy`) with `bind = Super, V, exec, qs -c hyprshell ipc call shell openLauncherMode :` using the IPC function added in task 4.
3. keybinds.conf: delete the `Super+Shift, Space` wofi fallback binding added in task 1.
4. rules.conf: delete the `layerrule = blur on, ignore_alpha 0.3, animation popin 90%, match:namespace ^wofi$` line (and the interim `dimaround` line if task 3 was done).
5. Remove `wofi` from `environment.systemPackages` in nixos/modules/desktop.nix and from `home.packages` in home-manager/home.nix, then `rm -r wofi/`.
6. Add a short section to quickshell/hyprshell/README.md documenting the launcher: the prefixes, the usage-JSON path, and the IPC calls (`toggleLauncher`, `openLauncherMode`).
7. Rebuild and verify: `nixos-rebuild switch` and the home-manager switch both succeed, then `hyprctl reload` and exercise Super+Space and Super+V.

**Done when**

- [ ] `grep -rn wofi ~/.config` returns nothing.
- [ ] Super+V opens the launcher already in clipboard mode with the field empty and results listed.
- [ ] `which wofi` returns nothing after both rebuilds.
- [ ] A full logout/login gives a working Super+Space with no manual `qs` restart.
- [ ] quickshell/hyprshell/README.md documents every prefix that actually works.

**Risks**

- Doing this before the QML launcher is stable leaves the machine with no launcher at all — the gate in step 1 is the whole safety mechanism.
- `openLauncherMode` must set the mode before the panel becomes visible or the first frame shows app results; set both in one IPC call.
- Other configs may shell out to wofi (a script, a Nix option like `programs.wofi`) — grep the whole repo, not just keybinds, before deleting the package.

### Open questions and unverified assumptions

- Quickshell version pinned in nixpkgs is unverified — the three APIs most likely to differ are `DesktopEntries.applications` (plain list vs ObjectModel needing `.values`), `FileView` write methods (`writeAdapter()` / `setText()` / `JsonAdapter` auto-write), and `Process` + `StdioCollector` (`onStreamFinished` signal name, `running` property). Verify all three with a scratch QML file before writing tasks 2 and 5.
- I have not confirmed `JsonAdapter` exists in the installed Quickshell.Io; plain `JSON.parse`/`JSON.stringify` over `FileView.text()`/`setText()` is the fallback and should be assumed if in doubt.
- `fd --max-results` — I believe it exists in fd 8.3+, but I did not verify the flag against the pinned nixpkgs `fd`. `| head -n 60` inside `sh -c` is the safe equivalent.
- Hyprland `layerrule = blurpopups` may be window-rule-only rather than layer-rule-capable; unverified against 0.55 docs. `blur`, `ignore_alpha`, `dimaround`, `xray` and `animation` are all confirmed by the existing rules.conf.
- Whether `Hyprland.clients` exposes addresses with or without a `0x` prefix, and whether `focuswindow address:` wants the prefix — log one client before writing the dispatch string.
- wofi's `parse_search`, `sort_order` and `dynamic_lines` option names are from memory; check `man 5 wofi` on the machine. Unrecognised keys are ignored silently, so the failure mode is benign.
- `new Function(...)` availability in the QML JS engine for the calculator is untested; a hand-written expression parser is the fallback, or shell out to `qalc -t` (nixpkgs attr `libqalculate`, which I have not verified is the right attribute for the `qalc` binary).
- Whether `bash` is on PATH in the Hyprland session (login shell is fish) — `compgen -c` needs it explicitly. `pkgs.bashInteractive` may need adding.
- Adwaita Sans availability was already flagged as uncertain in desktop.nix; the launcher inherits Theme.font, so it degrades to Cantarell the same way the bar does — no separate risk, but the larger 17 px search text will show the difference more.
- DPI parity between the 1440p/144 Hz and 1080p/300 Hz monitors is unresolved for a fixed-640 px panel; whether to scale by devicePixelRatio is a taste call the repo owner should make after seeing it on both.

---

## Command palette and keybind editor

### Recommended approach

Build one shared, UI-free model singleton (`Commands.qml` + `commands.json`) and hang three thin consumers off it, rather than one mega-panel: (a) the launcher's `>` prefix mode does search-and-run — the launcher agent only has to call `Commands.search(q)` / `Commands.run(id)`, so no list chrome is duplicated; (b) a dedicated `KeybindEditor.qml` does the rebinding, because key capture needs `WlrKeyboardFocus.Exclusive` plus an empty Hyprland submap to stop the compositor eating Super-combos, and that fights a launcher search field badly enough that folding it in would break both; (c) `Cheatsheet.qml` renders the same catalogue read-only on Super+Slash for the "present but hidden" discoverability the user asked for. Persistence goes through a bash helper (`hypr/scripts/keybind-write`) that rewrites a BEGIN/END-marked generated block inside `hypr/custom/keybinds.conf` (already sourced last, so it wins), emitting `unbind` before every `bind`, then `hyprctl reload`. The trade-off: a process spawn and a full config reload per change instead of in-QML file writes, in exchange for atomic temp+mv writes, a `.bak`, and a repair path (`keybind-write --reset`, `--list`) that works from a TTY when the shell itself is broken — which matters a lot when the thing you just rebound is how you open the shell.

### `C1` &middot; Seed a command catalogue from the 140 existing binds

**Effort:** M &middot; 1-3 h

**Why.** Every other piece here (palette, editor, cheat sheet) reads the same catalogue, so nothing can start until each action has a stable id, a human title and a category.

**Files**

- `hypr/scripts/keybinds-export`
- `quickshell/hyprshell/commands.json`
- `quickshell/hyprshell/README.md`

**Steps**

1. Write hypr/scripts/keybinds-export (bash + python3 heredoc, chmod +x): read hypr/hyprland/keybinds.conf, skip comments, match /^(bind[a-z]*)\s*=\s*(.*)$/ to capture the flag suffix ('', 'e', 'l', 'r', 'm', 'le', 'el') and split the RHS on commas into mods, key, dispatcher, arg (arg = rest-of-line, do NOT split it — 'exec' args contain commas and $()).
2. Expand the two hyprlang variables defined at the top of the file: $shell -> 'qs -c hyprshell ipc call shell' and $gamemode -> '~/.config/hypr/scripts/game-mode', so the exported run string is literally executable.
3. Emit quickshell/hyprshell/commands.json as {"version":1,"commands":[...]} with one object per action: id (dotted, stable, e.g. "shell.quicksettings", "win.close", "ws.switch.1"), title, category, keywords[], icon (freedesktop symbolic name, e.g. "preferences-system-symbolic", resolvable via Quickshell.iconPath()), run{type,...}, bind{flags,mods[],key}, rebindable.
4. Use exactly four run types: {"type":"dispatch","dispatcher":"workspace","arg":"1"} (QML: Hyprland.dispatch), {"type":"exec","cmd":"firefox"} (Quickshell.execDetached(["sh","-c",cmd])), {"type":"ipc","func":"toggleQuickSettings"} (calls the shell.qml IpcHandler in-process, no subprocess), {"type":"internal","func":"openKeybindEditor"}.
5. Set rebindable:false for the 6 pointer binds (bindm Super mouse:272/273, Super mouse:275, Super+Shift+Alt mouse:275/276) and for the mouse_up/mouse_down wheel binds — a key-capture UI cannot express them; keep them in the catalogue so the cheat sheet still shows them.
6. Collapse the three 10-line workspace families (workspace N, movetoworkspace N, movetoworkspacesilent N) into 30 generated entries sharing category "Workspaces" but distinct ids, and hand-write titles for the ~70 unique remaining actions (the export gives you the skeleton; titles are a manual pass).
7. Add categories: Shell, Windows, Workspaces, Apps, Audio, Media, Screenshots, Recording, Session, Game Mode, System. Add commands that have NO bind today (bind:null) so the palette can run them: 'Reload Hyprland', 'Restart hyprshell', 'Open Keyboard Shortcuts', 'Toggle Do Not Disturb'.
8. Verify the export is lossless: hypr/scripts/keybinds-export --check should assert that every non-comment bind line in keybinds.conf produced exactly one catalogue entry and print any dropped line.

**Done when**

- [ ] python3 -c "import json;d=json.load(open('quickshell/hyprshell/commands.json'));print(len(d['commands']))" prints >= 140 and exits 0
- [ ] Every command object has non-empty id, title, category and a run object whose type is one of dispatch/exec/ipc/internal (assert with a python one-liner)
- [ ] ids are unique: jq -r '.commands[].id' commands.json | sort | uniq -d prints nothing
- [ ] hypr/scripts/keybinds-export --check reports 0 dropped bind lines against hypr/hyprland/keybinds.conf
- [ ] bash -n hypr/scripts/keybinds-export passes

**Risks**

- exec args in this config contain commas, $(), || and && (the wf-recorder and wayvnc binds) — a naive comma split corrupts them; the arg must be rest-of-line.
- The catalogue duplicates truth that lives in keybinds.conf; if the user hand-edits keybinds.conf later the catalogue's bind{} goes stale. Mitigate by treating catalogue bind{} as 'the default' only, and always overlaying live state from hyprctl binds -j at runtime (task 3).
- Manual titling of ~70 entries is the real cost here, not the parser.

### `C2` &middot; Write the persistence helper: generated block in hypr/custom/keybinds.conf

**Effort:** M &middot; 1-3 h

**Why.** This is the risky infrastructure that makes rebinds survive a reload, and it must be testable and repairable from a terminal before any QML depends on it.

**Files**

- `hypr/scripts/keybind-write`
- `hypr/custom/keybinds.conf`
- `quickshell/hyprshell/README.md`

**Steps**

1. Write hypr/scripts/keybind-write (bash, chmod +x) with subcommands: `set` (reads a JSON array of overrides on stdin), `--reset`, `--list`, `--dry-run`. Target file: ${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/keybinds.conf.
2. Define the markers exactly: '# >>> hyprshell generated keybinds >>>' and '# <<< hyprshell generated keybinds <<<'. Everything outside the pair is preserved byte-for-byte; if the markers are absent, append them at EOF. Never touch the hand-written example comments already in that file.
3. For each override emit THREE lines in this order: `unbind = <oldMods>, <oldKey>` (kill the default), `unbind = <newMods>, <newKey>` (steal the combo from whatever else owned it), then `<bindFlag> = <newMods>, <newKey>, <dispatcher>, <arg>`. Both unbinds are mandatory — Hyprland registers duplicate binds on the same combo rather than replacing them.
4. Emit mods in Hyprland's canonical spelling joined by '+': SHIFT, CTRL, ALT, SUPER (e.g. `unbind = SUPER+SHIFT, D`). Preserve the original bind flag suffix from the catalogue (bind/binde/bindl/bindr/bindle/bindel) verbatim so repeat/locked semantics survive the rebind.
5. Write atomically: build into $(mktemp) next to the target, cp the current file to keybinds.conf.bak first, then mv the temp over the target. Refuse to write if the temp is 0 bytes.
6. After a successful write run `hyprctl reload` and exit non-zero if it fails, so the QML caller can show a failure toast instead of silently lying.
7. `--reset` truncates the block to just the two markers and reloads; `--list` prints the current block so the user can inspect it from a TTY; `--dry-run` prints the would-be file to stdout without touching disk.
8. Guard the whole thing with `set -euo pipefail` and a flock on ${XDG_RUNTIME_DIR}/hyprshell-keybind.lock so a double-click cannot interleave two rewrites.

**Done when**

- [ ] bash -n hypr/scripts/keybind-write passes and shellcheck reports no errors
- [ ] echo '[{"id":"shell.quicksettings","flags":"","oldMods":["SUPER"],"oldKey":"I","mods":["SUPER","SHIFT"],"key":"I","dispatcher":"exec","arg":"qs -c hyprshell ipc call shell toggleQuickSettings"}]' | hypr/scripts/keybind-write --dry-run emits the unbind/unbind/bind triple between the markers
- [ ] After a real `set`, `hyprctl binds -j | python3 -c "import json,sys;print(len([b for b in json.load(sys.stdin) if b['modmask']==65 and b['key']=='I']))"` prints 1, and the old modmask 64 + key I entry is gone
- [ ] The hand-written comment lines already in hypr/custom/keybinds.conf are byte-identical after a set and after a --reset (diff against a saved copy)
- [ ] hypr/scripts/keybind-write --reset followed by hyprctl reload restores every default bind (bind count back to the pre-override number)

**Risks**

- Whether `unbind` is accepted as a config-file keyword (as opposed to only `hyprctl keyword unbind`) needs a one-line check before building on it — if it is not, the fallback is to have the shell run `hyprctl keyword unbind ...` at startup, which is fragile.
- The custom/ dir is sourced by glob `source = ~/.config/hypr/custom/*.conf`; glob order is alphabetical so general.conf precedes keybinds.conf — fine today, but a future custom/zz-*.conf would win over the generated block.
- hyprctl reload re-runs exec-once? It does not, but it does re-apply monitor and env rules; on this GPU any reload path must be smoke-tested since AQ_NO_ATOMIC=1 / misc:vrr=0 are load-bearing.
- If the user rebinds the combo that opens the shell itself and the write half-fails, they need the TTY path — hence --list and --reset.

### `C3` &middot; Build Commands.qml, the shared catalogue + live-bind model

**Effort:** L &middot; a day or more

**Why.** One singleton reconciles the static catalogue, the live binds from hyprctl, and the user's overrides, so the palette, the editor and the cheat sheet never disagree about what a key does.

**Files**

- `quickshell/hyprshell/Commands.qml`
- `quickshell/hyprshell/qmldir`
- `quickshell/hyprshell/shell.qml`

**Steps**

1. Create quickshell/hyprshell/Commands.qml as `pragma Singleton` + `Singleton {}` (matching Theme.qml/State.qml style) and register it in qmldir: `singleton Commands 1.0 Commands.qml`.
2. Load the catalogue with `Quickshell.Io.FileView { path: Qt.resolvedUrl("commands.json"); watchChanges: true; onFileChanged: reload(); onLoaded: root.parse(text()) }` — same pattern AppMenu.qml already uses for recently-used.xbel.
3. Load live state with `Process { command: ["hyprctl","binds","-j"]; stdout: StdioCollector { onStreamFinished: root.parseBinds(text) } }`, exactly the Process/StdioCollector idiom in Services.qml. Re-run it on startup and whenever Hyprland emits `configreloaded` (subscribe via Quickshell.Hyprland `Hyprland.rawEvent`).
4. Implement modmask <-> mods with this table, which I verified empirically against this repo's own binds on the running compositor: 1=SHIFT, 2=CAPS, 4=CTRL, 8=ALT, 16=MOD2, 32=MOD3, 64=SUPER, 128=MOD5. Checks that passed: modmask 5 == Ctrl+Shift (the Ctrl+Shift,Escape gnome-system-monitor bind), 8 == Alt (Alt,Tab), 65 == Super+Shift, 68 == Ctrl+Super, 72 == Super+Alt.
5. Key the live map by `modmask + ":" + key.toLowerCase()` and match catalogue entries to live binds by mods+key ONLY — do not match on dispatcher. On the box I inspected, all 81 live binds report `dispatcher: "__lua"` with a numeric arg, so dispatcher-based reverse mapping is not safe to rely on.
6. Expose: `property var list` (catalogue, decorated with `.current` = {mods,key} from the live map or null, and `.stale` = true when live disagrees with the catalogue default), `function search(q)` (case-insensitive score over title, category and keywords; exact-prefix beats substring), `function run(id)` (switches on run.type: Hyprland.dispatch / Quickshell.execDetached(["sh","-c",cmd]) / call the shell.qml IpcHandler function directly / internal), `function conflict(mods,key)` returning the colliding command or a raw bind descriptor, and `function applyOverride(cmd,mods,key)` which pipes JSON into hypr/scripts/keybind-write.
7. Persist overrides in a second small file the helper also owns (e.g. ~/.local/state/hyprshell/keybinds.json) so Commands can render 'changed from Super+I' without re-parsing hyprlang, and so --reset has one source to clear.
8. Add IpcHandler functions to shell.qml: `toggleCommandPalette()`, `toggleKeybindEditor()`, `toggleCheatsheet()`, following the existing State.closePanels() + toggle pattern; add the matching bool properties to State.qml.

**Done when**

- [ ] `qs -c hyprshell` starts with no QML warnings on stderr about Commands.qml
- [ ] Commands.list.length equals the number of entries in commands.json, and every entry with rebindable:true has a non-null .current after startup on an unmodified config
- [ ] Commands.search("screen") returns the screenshot and screen-recording commands ahead of unrelated ones
- [ ] Commands.conflict(["SUPER"],"Q") returns the 'Close window' command; Commands.conflict(["SUPER","ALT"],"F13") returns null
- [ ] Running Commands.run("shell.quicksettings") from the palette opens Quick Settings without spawning a subprocess

**Risks**

- The `__lua` dispatcher observed on the inspection box may or may not appear on the target machine — the design tolerates it either way, but if it DOES appear on target, the editor cannot show 'this combo currently runs X' for binds not in the catalogue, only 'this combo is taken'.
- hyprctl binds -j reports `key` as the xkb keysym name resolved on the active layout; on a German layout the names for punctuation keys differ from the config's spelling, so case-insensitive compare is not always enough.
- FileView.watchChanges/onFileChanged property names should be confirmed against the installed Quickshell version; AppMenu.qml only uses reload()/onLoaded/onLoadFailed, so those three are known-good.

### `C4` &middot; Add the '>' command-palette mode to the launcher

**Effort:** M &middot; 1-3 h

**Why.** The user gets searchable access to every desktop action from the launcher they already open, with the current shortcut shown on each row, without a second overlapping panel.

**Files**

- `quickshell/hyprshell/Launcher.qml`
- `quickshell/hyprshell/Commands.qml`
- `quickshell/hyprshell/README.md`

**Steps**

1. Coordinate with the launcher spec: Launcher.qml owns the window, search field, ListView and row chrome; this task only adds a provider. When the query starts with '>', set the model to Commands.search(query.slice(1).trim()) instead of the app model.
2. Render each row as: icon (Quickshell.iconPath(cmd.icon, true) via Quickshell.Widgets IconImage), title in Theme.fg at Theme.fontSize, category in Theme.fgDim at Theme.fontSizeSmall on the same line, and the shortcut right-aligned as key caps.
3. Draw key caps as a Row of Rectangles: radius Theme.radiusSmall, color Theme.card, 1px Theme.border, horizontal padding 6, text in Theme.fgDim at Theme.fontSizeSmall — one cap per modifier plus one for the key, with GNOME-style glyphs for the modifier names (Super, Shift, Ctrl, Alt spelled out, not symbols).
4. Enter runs Commands.run(id) then closes the launcher. Ctrl+Enter (or F2) on a row calls the internal `openKeybindEditor(id)` so rebinding is one keystroke from search — this is the whole 'search commands AND change their shortcuts' loop.
5. Show the palette hint minimally: when the query is empty, a single dimmed line at the bottom of the launcher reading 'Type > for commands' in Theme.fgDim / Theme.fontSizeSmall. Nothing else advertises the mode.
6. Cap the visible result count at ~12 rows and rely on scroll, so the launcher does not resize dramatically between app mode and command mode.
7. Repoint the two existing wofi binds in hypr/hyprland/keybinds.conf (Super,Space and Super,V) at the shell IPC once Launcher.qml lands, and add `bind = Super+Shift, Space, exec, $shell toggleCommandPalette` which opens the launcher pre-seeded with '>'.

**Done when**

- [ ] Typing '>' in the launcher switches to command mode and shows commands with their current shortcuts on the right
- [ ] Typing '>quick' selects 'Quick Settings' as the first result and Enter opens the Quick Settings panel
- [ ] Every rebindable command in the list shows a shortcut or an explicit dimmed 'Unassigned'
- [ ] Ctrl+Enter on a command row closes the launcher and opens KeybindEditor scrolled to that command
- [ ] Super+Shift+Space opens the launcher already in command mode with the '>' consumed

**Risks**

- File ownership collision with the launcher agent — this task must be merged after Launcher.qml exists, and should be written as a diff against it rather than a competing file.
- If the launcher agent chose a different prefix convention (e.g. ':' or '?'), follow theirs; the prefix character is not worth a conflict.

### `C5` &middot; Build KeybindEditor.qml with press-a-combo capture

**Effort:** L &middot; a day or more

**Why.** This is the actual ask — rebinding a shortcut by pressing the new one, with conflicts surfaced before anything is written.

**Files**

- `quickshell/hyprshell/KeybindEditor.qml`
- `quickshell/hyprshell/shell.qml`
- `quickshell/hyprshell/State.qml`
- `quickshell/hyprshell/QuickSettings.qml`
- `hypr/hyprland/keybinds.conf`

**Steps**

1. Create KeybindEditor.qml as a PanelWindow: anchors centred, implicitWidth 720, implicitHeight 560, color "transparent", WlrLayershell.namespace "hyprshell-panel", WlrLayershell.layer WlrLayer.Overlay, and a Rectangle child with Theme.bg / Theme.radius / 1px Theme.border — same skeleton as QuickSettings.qml. Add HyprlandFocusGrab { windows: [win]; active: State.keybindEditorOpen; onCleared: ... } and Escape-to-close.
2. Layout: a search TextField at the top (filters Commands.list by the same Commands.search), a section-header ListView grouped by category, each row = title + key caps + a hover-only 'Change' affordance. Nothing chrome-heavy: no toolbar, no buttons visible until hover, per the user's minimalism note.
3. Capture state: on activating a row set `capturing = true`, switch WlrLayershell.keyboardFocus to WlrKeyboardFocus.Exclusive, forceActiveFocus() onto a focus-scope Item, and blank the row into 'Press new shortcut — Esc to cancel'.
4. Stop Hyprland eating the combo during capture: define an empty submap in hypr/hyprland/keybinds.conf (`submap = __hyprshell_capture` / `bind = , escape, submap, reset` / `submap = reset`) and have the editor call Hyprland.dispatch("submap __hyprshell_capture") on capture start and Hyprland.dispatch("submap reset") on end. Without this, pressing Super+Q during capture kills a window instead of being captured.
5. In Keys.onPressed, ignore bare modifier presses (Qt.Key_Shift/Control/Alt/Meta), build mods from event.modifiers (Qt.ShiftModifier->SHIFT, Qt.ControlModifier->CTRL, Qt.AltModifier->ALT, Qt.MetaModifier->SUPER), map event.key through a Qt.Key_* -> xkb keysym table ('bracketleft', 'apostrophe', 'Page_Down', 'Return', 'minus', 'equal', 'slash'), render the combo live in key caps as the user holds modifiers, and commit on the first non-modifier key.
6. On commit call Commands.conflict(mods,key). If it returns something, show an inline strip in Theme.danger: '<combo> is Close window. Replace / Cancel' with keyboard-only Enter/Escape resolution. Refuse outright (no override) for a captured Escape alone.
7. On accept call Commands.applyOverride(...), which runs hypr/scripts/keybind-write and then hyprctl reload; on success emit a toast, on non-zero exit show 'Could not write shortcut' and leave the row unchanged. Add `signal toast(string text)` to State.qml and a text branch in Osd.qml to render it, so the toast reuses the existing bottom-centre pill instead of a new window.
8. Add a 'Reset all shortcuts' row at the very bottom of the list (dimmed, requires a second click to confirm — reuse the powerConfirm pattern already in QuickSettings.qml) wired to keybind-write --reset. Add `bind = Super+Shift, K, exec, $shell toggleKeybindEditor` and a 'Keyboard Shortcuts' row at the bottom of QuickSettings.qml.

**Done when**

- [ ] Super+Shift+K opens the editor; Escape closes it; clicking outside closes it via the focus grab
- [ ] Selecting a row and pressing Super+Shift+F9 shows 'Super Shift F9' live in key caps and commits
- [ ] After committing, hyprctl binds -j contains an entry with the new modmask+key for that dispatcher and no entry for the old combo, and pressing the new combo actually performs the action
- [ ] Pressing Super+Q while in capture state does NOT close a window (proves the submap grab works)
- [ ] Capturing an already-used combo shows the conflict strip naming the owning command before anything is written
- [ ] After 'Reset all shortcuts', hypr/custom/keybinds.conf's generated block is empty and all defaults are back
- [ ] The change survives `hyprctl reload` and a full Hyprland restart

**Risks**

- Whether an empty Hyprland submap truly forwards all unbound keys to the focused layer-shell client needs verifying before this design is locked; if it does not, capture must fall back to accepting non-conflicting combos only, or to a keyboard-shortcut-free 'pick from a list of modifiers + a key' fallback.
- WlrKeyboardFocus.Exclusive on an overlay layer means a crash mid-capture leaves the session keyboard-captured — add a 15s watchdog Timer that force-exits capture and dispatches 'submap reset'.
- Qt's KeyEvent gives no reliable keysym for layout-dependent punctuation on a German layout; the Qt.Key_* table will need a `code:<n>` fallback using event.nativeScanCode, and the evdev-vs-X11 keycode offset (+8) for Hyprland's `code:` form is unverified.
- hyprctl reload on this GPU is the one operation that must not regress the AQ_NO_ATOMIC / vrr=0 setup — smoke test a reload before and after.

### `C6` &middot; Add the Super+Slash cheat sheet overlay

**Effort:** M &middot; 1-3 h

**Why.** The user wants usability that is there but hidden; a single keystroke that shows every shortcut grouped by category is the cheapest way to make 140 binds discoverable without adding any visible UI.

**Files**

- `quickshell/hyprshell/Cheatsheet.qml`
- `quickshell/hyprshell/shell.qml`
- `quickshell/hyprshell/State.qml`
- `hypr/hyprland/keybinds.conf`

**Steps**

1. Create Cheatsheet.qml as a full-screen PanelWindow (anchors top/bottom/left/right all true, exclusiveZone 0, color "transparent", WlrLayershell.namespace "hyprshell-osd" so it inherits the existing blur layerrule, WlrLayer.Overlay, keyboardFocus OnDemand).
2. Dim the desktop with a full-bleed Rectangle at Qt.rgba(0,0,0,0.35) and centre a card at Theme.bg / Theme.radius / 1px Theme.border, max width ~1100 (fits both the 2560x1440 and 1920x1080 monitors), with a Flow or 3-column GridLayout of category sections.
3. Render each section as a category title in Theme.fgDim + fontSizeSmall + letter-spaced uppercase, then rows of 'key caps ... title' reusing the same key-cap component as the launcher (factor it into a small KeyCaps.qml so all three surfaces render shortcuts identically).
4. Read strictly from Commands.list so overridden shortcuts show their NEW combo automatically — the cheat sheet must never be a second hardcoded list.
5. Close on Escape, on any click, and on release of the trigger key; fade in with a 150ms opacity Behavior using Theme.animMs so it feels like the rest of the shell.
6. Bind it: add `bind = Super, Slash, exec, $shell toggleCheatsheet` AND `bind = Super+Shift, Slash, exec, $shell toggleCheatsheet` to hypr/hyprland/keybinds.conf. On a German layout '/' is Shift+7, so also add `bind = Super, question` as a third alias and verify which one actually fires with `hyprctl binds -j`.
7. Add a single dimmed footer line to the card: 'Super+Shift+K to change shortcuts' — the only place the editor is advertised.

**Done when**

- [ ] Super+/ opens the overlay over any workspace and Escape closes it
- [ ] The overlay lists every category from commands.json and the total row count matches Commands.list.length minus unbound entries
- [ ] Rebinding a shortcut in the editor changes what the cheat sheet shows on the next open, with no restart
- [ ] The overlay renders correctly on both HDMI-A-1 (2560x1440) and DP-1 (1920x1080) without clipping or a scrollbar on the 1080p screen
- [ ] Opening the cheat sheet does not steal focus permanently — the previously focused window is focused again after closing

**Risks**

- Keysym for '/' under a German layout is the main unknown; binding three aliases is cheap insurance but one of them may collide with something.
- A full-screen overlay on the Overlay layer sits above fullscreen games — guard it with `visible: State.cheatsheetOpen && !State.gameMode` so game-mode suppresses it like it suppresses the bar.
- 140 rows in three columns may still overflow 1080p vertically; needs either a scroll container or a two-page split by category.

### Open questions and unverified assumptions

- `bindd = MODS, key, description, dispatcher, params` — I am confident the description-carrying bind variant exists (hyprctl binds -j on this machine exposes `has_description` and `description` fields, which only exist to serve it), but I did NOT verify the argument ORDER (description third, after key). Worth one `hyprctl keyword bindd 'SUPER, F13, test, exec, true'` check before considering a migration of keybinds.conf to bindd — if it works, descriptions could live in the config and the catalogue's titles could be generated instead of hand-written, which would remove the main cost of task 1.
- On the machine I inspected, ALL 81 live binds report `dispatcher: "__lua"` with a numeric `arg` — that session is not this repo's config (81 binds vs the repo's 140). Whether the target machine's `hyprctl binds -j` reports real dispatcher names (`exec`, `workspace`, `killactive`) is unverified. The design deliberately matches on mods+key only so it works either way, but 'what does this unknown combo currently do?' is only answerable if real dispatchers come back.
- Whether `unbind = MOD, KEY` is valid as a keyword inside a sourced .conf file, or only via `hyprctl keyword unbind`. The entire persistence strategy assumes the former. Check with a throwaway line before building task 2.
- Whether two `bind` lines on the same mod+key cause BOTH dispatchers to fire or the later to win. I assumed both fire (hence the mandatory unbind-first), which is the safe assumption either way, but it is not verified on 0.56.2.
- Whether an empty Hyprland submap forwards all unbound keys to the focused layer-shell client. The key-capture UI in task 5 depends on this; if it does not hold, capture needs a different design.
- Whether QML's KeyEvent exposes `nativeScanCode` under Quickshell/Wayland, and if so whether it matches Hyprland's `code:<n>` numbering or is offset by 8. Only matters for the punctuation-key fallback.
- Quickshell version on the target and whether `FileView` supports `watchChanges` / `onFileChanged` / `setText`. Only `path`, `text()`, `reload()`, `onLoaded`, `onLoadFailed` are proven in-repo (AppMenu.qml). The design routes all WRITES through the bash helper partly to avoid depending on FileView write semantics.
- The `qs` binary is not on PATH in the environment I inspected, so I could not confirm the Quickshell version or that `qs -c hyprshell ipc call shell <fn>` behaves as keybinds.conf assumes.
- Hyprland's keysym name for '/' under a German keyboard layout (`slash` vs `question` vs requiring Shift in the modmask). Affects the cheat sheet bind only.
- Whether `hyprctl reload` on this RX 9060 XT is fully safe given AQ_NO_ATOMIC=1 and misc:vrr=0 — reload re-applies env and monitor rules, and the whole rebind flow calls it on every change. Smoke test before shipping.
- Freedesktop symbolic icon names in the catalogue are guesses per category; `Quickshell.iconPath(name, true)` returning empty for a missing name must be handled (fall back to no icon, not a broken image).

---

## Window switching (Alt+Tab)

### Recommended approach

Alt+Tab today is `cyclenext` plus `bringactivetotop` (`hypr/hyprland/keybinds.conf:145-146`).
That switches focus instantly on every press, so there is no overlay, no preview, and no
most-recently-used order: tapping it twice lands you two windows away instead of back where you
started. The fix is the switcher the rest of the shell already implies, an `hyprshell-panel`
overlay listing windows in MRU order, held open while Alt is down and committed on release.

Take the ordering from Hyprland rather than tracking it yourself. `hyprctl clients -j` exposes
`focusHistoryID`, verified on a live 0.56 session: `0` is the focused window and the number grows
going back through the history, so sorting by it gives the exact Alt+Tab order for free, including
across workspaces.

For the key handling, prefer a Hyprland submap over grabbing the keyboard in QML. The submap keeps
the QML side stateless (it only renders and reacts to IPC), and Hyprland's release binds are the
proven way to detect the Alt release. The alternative, a panel with
`WlrKeyboardFocus.Exclusive` handling Tab and Alt release in `Keys.onPressed` / `onReleased`, needs
fewer config lines but takes an exclusive keyboard grab on every Alt+Tab, and a crash or a missed
release event leaves the session with no keyboard. Use it only if the submap route misbehaves.

Scope the list to all workspaces on the focused monitor by default, since that matches how the rest
of the shell treats monitors, and leave a one-line switch in `Theme.qml` or the switcher itself for
whoever wants it per-workspace or global.

### `W1` &middot; Replace cyclenext with a real MRU Alt+Tab switcher overlay

**Effort:** M &middot; 1-3 h

**Why.** The current binding has no overlay and no MRU order, so Alt+Tab cannot do the one thing it
is for: flipping back and forth between the last two windows.

**Files**

- `quickshell/hyprshell/Switcher.qml`
- `quickshell/hyprshell/shell.qml`
- `quickshell/hyprshell/State.qml`
- `hypr/hyprland/keybinds.conf`
- `hypr/hyprland/rules.conf`

**Steps**

1. Add `property bool switcherOpen: false` and `property int switcherIndex: 0` to `State.qml`, and reset both in whatever `closePanels()` helper the other panels use.
2. Create `Switcher.qml` as a centred `PanelWindow` with `WlrLayershell.namespace: "hyprshell-panel"`, `WlrLayershell.layer: WlrLayer.Overlay`, `exclusiveZone: 0`, `color: "transparent"`, `visible: State.switcherOpen`. Leave `anchors` unset so it centres. Keyboard focus stays `None`: the submap owns the keys.
3. Build the model on open: run `Process` with `["hyprctl","clients","-j"]`, parse in `StdioCollector.onStreamFinished`, drop entries where `mapped` is false or `hidden` is true, filter to the focused monitor, then `sort((a,b) => a.focusHistoryID - b.focusHistoryID)`. Refresh only on open, never while the overlay is up, so the order cannot shift under the user's fingers.
4. Render a horizontal `Row` of tiles in a `Rectangle` styled like the other panels (`Theme.bg`, `Theme.radius`, 1px `Theme.border`, `Theme.pad`). Each tile is 96x96: the app icon at 48px via `DesktopEntries.heuristicLookup(client.class)` (the same lookup `Bar.qml:24` already uses, falling back to `initialClass` then a generic icon), and the window title elided under it in `Theme.fgDim`. The selected tile gets a `Theme.card` background at `Theme.radiusSmall` plus a 2px `Theme.accent` border. Show the full title of the selected window in one line below the row so long titles stay readable.
5. Add `next()`, `prev()`, `commit()` and `cancel()` to the `IpcHandler` in `shell.qml` under a new `target: "switcher"`. `next()` opens the overlay if closed and starts at index 1 (the previously focused window, which is what a single Alt+Tab should select), otherwise advances with wraparound. `commit()` runs `Hyprland.dispatch("focuswindow address:" + addr)` and closes; `cancel()` just closes.
6. Wire the submap in `keybinds.conf`, replacing lines 145-146: `bind = ALT, Tab, exec, qs -c hyprshell ipc call switcher next` and `bind = ALT, Tab, submap, switcher`, then a `submap = switcher` block containing next/prev (`ALT SHIFT, Tab`), `bindrt = ALT, Alt_L, exec, qs -c hyprshell ipc call switcher commit` followed by `bindrt = ALT, Alt_L, submap, reset`, plus Escape mapped to cancel and reset. Close with `submap = reset`. Verify the exact release-flag spelling on the target before trusting it (see risks).
7. Add `layerrule = blur on, ignore_alpha 0.4, match:namespace ^hyprshell-panel$` coverage if the existing rule does not already match, and `animation off` for the switcher if the fade reads as lag.

**Done when**

- [ ] Holding Alt and tapping Tab once, then releasing, lands on the previously focused window; doing it again returns to the first. This is the regression the current binding fails.
- [ ] Holding Alt and tapping Tab repeatedly walks back through the history without changing focus until Alt is released.
- [ ] Shift+Tab while held walks the other way, and Escape closes the overlay leaving focus untouched.
- [ ] `hyprctl submap` reports an empty submap after every completed switch, including after Escape. A stuck submap is the failure mode that eats all other keybinds.
- [ ] With one window open, Alt+Tab is a no-op and shows no overlay.
- [ ] Windows on other monitors do not appear in the list.

**Risks**

- The release-bind flags are the fragile part. `bindrt` (release plus transparent) is the widely used spelling for catching a modifier release, but this was not testable here because the dev box runs the Lua config. Confirm on the target with `hyprctl binds -j | jq '.[]|select(.release)'` and fix the flags before anything else.
- Any path that leaves the submap active locks the user out of every other binding. Add an escape hatch such as `bind = , Escape, submap, reset` inside the submap and test it deliberately.
- Sorting by `focusHistoryID` assumes Hyprland keeps it updated for unfocused windows; verified on 0.56, but recheck after a compositor upgrade.
- Spawning `hyprctl` on every Alt+Tab adds a process launch to a latency-sensitive path. If it feels slow, keep a warm list updated from Hyprland's event socket instead.

### `W2` &middot; Add live window thumbnails to the switcher

**Effort:** M &middot; 1-3 h

**Why.** Icons alone cannot tell six terminal windows apart, which is exactly when a switcher matters.

**Files**

- `quickshell/hyprshell/Switcher.qml`

**Steps**

1. Check first whether the installed Quickshell exposes `ScreencopyView` from `Quickshell.Wayland`. If it is missing, stop here and keep W1's icons: no fallback is worth the complexity.
2. Widen the tiles to 192x120 and put a `ScreencopyView` inside each, bound to the matching `ToplevelManager` handle rather than the `hyprctl` entry. Match the two lists by title plus app id, and skip the thumbnail for any window that fails to match.
3. Set `live: false` and capture once when the overlay opens. Live capture for every window is a continuous GPU cost on a path that exists for a few hundred milliseconds.
4. Keep the app icon as a 24px badge in the tile corner, so a window that fails to capture still reads as its app.
5. Cap the row at around eight tiles and let it scroll or compress beyond that, so the overlay never exceeds the monitor width.

**Done when**

- [ ] Six terminal windows are visually distinguishable in the overlay.
- [ ] A window that cannot be captured shows its icon instead of an empty tile, with no QML error in the `qs` log.
- [ ] Opening and closing the switcher fifty times leaves no growth in the shell's memory usage.

**Risks**

- `ScreencopyView` availability in the installed Quickshell build is unverified.
- Capturing a minimised or unmapped window may return nothing or a stale frame; the icon fallback has to cover that case.
- Screencopy needs the portal permission that `hypr/hyprland/rules.conf` and the Hyprland permission system may gate; if captures come back black, check `ecosystem:enforce_permissions` and the screencopy permission entries.

### Open questions and unverified assumptions

- Verified live on Hyprland 0.56: `hyprctl clients -j` includes `focusHistoryID` (0 for the focused window, ascending into the past), plus `class`, `initialClass`, `title`, `address`, `pid`, `monitor`, `mapped`, `hidden`, `floating`, `fullscreen`. Bind objects from `hyprctl binds -j` carry a `release` flag, so release binds exist in this version.
- Verified: `Bar.qml` already uses `ToplevelManager.activeToplevel` and `DesktopEntries.heuristicLookup(appId)`, so W1 reuses an established pattern rather than introducing an API.
- NOT verified: the `bindrt` flag spelling and submap behaviour, because this dev box runs a Lua Hyprland config where `hyprctl dispatch submap` and runtime `keyword` calls are rejected by the non-legacy parser. Everything submap-related must be confirmed on the NixOS target.
- NOT verified: whether `ScreencopyView` exists in the installed Quickshell, and whether it can capture a window that is not currently visible.
- Open decision: whether the list should span all monitors. The spec scopes it to the focused monitor to match the rest of the shell, but nothing in the user's stated preferences settles it.

---

## Claude usage widget and Claude Code

### Recommended approach

Build this as three separable layers so each one degrades to nothing on its own: (1) a plain bash+jq aggregator at hypr/scripts/claude-usage that reads ~/.claude/projects/**/*.jsonl and prints one JSON blob, (2) a ClaudeWidget.qml that is a 6px dot in the bar — 0 opacity when there is nothing to show, 0.35 when transcripts exist, slow-pulsing only while `pgrep -x claude` returns something — and (3) a ClaudePanel.qml opened by clicking it. I verified the transcript schema on this box rather than assuming it: usage lives on `.message.usage` of `.type=="assistant"` rows with input_tokens / output_tokens / cache_creation_input_tokens / cache_read_input_tokens, alongside top-level `.timestamp`, `.cwd`, `.sessionId`, `.gitBranch`, `.version` and `.message.model`. Two things will silently corrupt any naive aggregation and are the main trade-off to respect: rows are written multiple times per API call (80 assistant rows collapsed to 37 unique `.requestId` in one file — you MUST `group_by(.requestId) | map(.[0])`), and `.timestamp` is UTC, so `.timestamp[0:10]` mis-buckets late-evening CEST work by a day; use `sub("\\.[0-9]+Z$";"Z") | fromdateiso8601 | strflocaltime("%Y-%m-%d")`, which I confirmed works in the jq 1.8.2 here (fromdateiso8601 rejects fractional seconds, hence the sub). Do the aggregation yourself in jq rather than depending on ccusage — it is one 40-line script, it has no npm/node runtime cost, and it cannot break on a schema the tool did not anticipate. Also note the brief's suggested keybind is already taken: Super+Shift+C is bound to `hyprpicker -a` at hypr/hyprland/keybinds.conf:33, so use Super+Shift+Return (verified free) instead.

### `K1` &middot; Write hypr/scripts/claude-usage, a jq aggregator over the local transcripts

**Effort:** M &middot; 1-3 h

**Why.** Every other piece in this area needs one trustworthy JSON source, and the raw JSONL has two traps (duplicated rows per requestId, UTC day boundaries) that must be solved exactly once, in one place.

**Files**

- `hypr/scripts/claude-usage`
- `hypr/scripts/claude-prices.json`

**Steps**

1. Create hypr/scripts/claude-usage as a bash script with `set -euo pipefail`; first line of logic: `[ -d "$HOME/.claude/projects" ] || { echo '{"ok":false}'; exit 0; }` so a machine with no Claude Code prints valid JSON and the widget hides itself.
2. Collect input with `find "$HOME/.claude/projects" -name '*.jsonl' -print0 | xargs -0 cat`, piped into `jq -s`. Do NOT glob in fish/sh — there are 75 files across 8 project dirs on this box and shell globbing already failed here once.
3. Dedupe first, before any arithmetic: `[ .[] | select(.type=="assistant" and .message.usage != null and .requestId != null) ] | group_by(.requestId) | map(.[0])`. I measured 80 assistant rows collapsing to 37 unique requestIds in ~/.claude/projects/-home-anon-Dokumente-hyprland/a6da49c2-*.jsonl — skipping this roughly triples every number.
4. Project each row to `{day, proj, session, model, i, o, cw, cr}` where day = `(.timestamp | sub("\\.[0-9]+Z$";"Z") | fromdateiso8601 | strflocaltime("%Y-%m-%d"))` (verified in jq 1.8.2 — plain fromdateiso8601 fails on the millisecond form), proj = `.cwd`, session = `.sessionId`, model = `.message.model`, and the four token counts defaulted with `// 0`.
5. Emit one object: `{ok:true, today:{in,out,cacheWrite,cacheRead,total,reqs}, days:[{day,total,...} for the last 7 local days, zero-filled so the sparkline never has gaps], projects:[{path,name:(path|split("/")|last),total} sorted desc, top 5], models:[{model,total}], session:{id,cwd,total,reqs}}`. Zero-fill by generating the 7 day keys in bash with `date -d "-$n days" +%F` and passing them in via `--argjson days`.
6. For the live session, pick the newest mtime jsonl (`ls -t`) and aggregate only its rows; gate it on `pgrep -x claude >/dev/null` so a stale file is not reported as active. Verified `comm` is exactly `claude` for running CLI sessions, so `pgrep -x claude` is the right matcher — plain `pgrep -f claude` also catches claude-desktop and is wrong.
7. Add optional costing: read hypr/scripts/claude-prices.json (`--slurpfile prices`) mapping model id -> {in,out,cacheWrite,cacheRead} USD-per-million. Ship the file as `{}` so cost is omitted entirely until the user fills it in; never hardcode prices in the script.
8. Support `claude-usage --today` (compact one-line summary for scripting) and bare invocation (full JSON). `chmod +x`.

**Done when**

- [ ] `hypr/scripts/claude-usage | jq -e '.ok'` prints true and the whole output parses as JSON.
- [ ] `.days | length` is exactly 7 and every entry has a `day` key, even for days with zero usage.
- [ ] Summing `.days[].total` for a day matches a hand-run jq over that day's files with the same requestId dedupe (within 0).
- [ ] Running with `HOME=/tmp/emptyhome` prints `{"ok":false}` and exits 0 — no stderr, no non-zero exit.
- [ ] A message written at 01:30 local time is bucketed into the local day, not the previous UTC day (test: `TZ=Europe/Berlin` vs `TZ=UTC` produce different day keys for such a row).

**Risks**

- The `iterations` array inside `.message.usage` suggests a single requestId can cover multiple API iterations; the top-level input_tokens/output_tokens appear to already be the totals for the request, but if a future version reports per-iteration only, summing `.message.usage.iterations[]` would be needed instead. Compare both for one file before committing.
- `<synthetic>` appears as a model value (10 rows across all transcripts) — exclude it from cost and model breakdowns or it pollutes the table.
- ~/.claude/projects grows unbounded; the largest single transcript here is 16 MB. Full re-parse on every poll will get slow — mitigate by caching the result to $XDG_RUNTIME_DIR and only re-running when the newest mtime changed.

### `K2` &middot; Add ClaudeWidget.qml: a near-invisible bar dot that pulses only during a live session

**Effort:** M &middot; 1-3 h

**Why.** This is the 'there but hidden' surface the user asked for — one 6px glyph that costs no visual attention when idle and is the only affordance needed to reach everything else.

**Files**

- `quickshell/hyprshell/ClaudeWidget.qml`
- `quickshell/hyprshell/Bar.qml`
- `quickshell/hyprshell/State.qml`

**Steps**

1. Create ClaudeWidget.qml as an `Item` with `implicitWidth: 14; implicitHeight: Theme.barHeight`, containing one `Rectangle { width: 6; height: 6; radius: 3; anchors.centerIn: parent }`.
2. Hold state as properties: `property var usage: null`, `property bool live: false`, `readonly property bool hasData: usage && usage.ok === true`. Set `visible: hasData` — with no transcripts the widget occupies zero space and shows literally nothing, per the degradation requirement.
3. Drive the data with the repo's existing pattern from Services.qml: `Process { id: usageProc; command: ["sh","-c","\"$HOME/.config/hypr/scripts/claude-usage\""]; stdout: StdioCollector { onStreamFinished: { try { root.usage = JSON.parse(text) } catch(e) { root.usage = null } } } }` wrapped in a `Timer` with `interval: root.live ? 15000 : 120000; repeat: true; triggeredOnStart: true`.
4. Detect a live session with a second Process on a 5 s timer: `["sh","-c","pgrep -x claude >/dev/null && echo 1 || echo 0"]` — `-x` matters, `pgrep -f claude` also matches claude-desktop (confirmed on this box).
5. Colour the dot `Theme.fgDim` at `opacity: 0.35` when idle, `Theme.accent` when `live`. Add the pulse as `SequentialAnimation on opacity { running: root.live; loops: Animation.Infinite; NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine } NumberAnimation { to: 0.4; duration: 1400; easing.type: Easing.InOutSine } }` — slow enough to read as breathing, not blinking. Bind `running` to `live` so it fully stops when no session runs.
6. On hover raise opacity to 1.0 with `Behavior on opacity { NumberAnimation { duration: Theme.animMs } }`, matching StatusPill's hover treatment.
7. Wire into Bar.qml: place it inside the RIGHT area, immediately left of the existing `StatusPill`, by wrapping both in a `Row { spacing: Theme.gap; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }` and moving StatusPill's anchors onto that Row.
8. MouseArea over the whole 14px item: `onClicked: { const next = !State.claudeOpen; State.closePanels(); State.claudeOpen = next }`. Add `property bool claudeOpen: false` to State.qml and reset it inside `State.closePanels()`.

**Done when**

- [ ] With ~/.claude/projects absent or empty, the bar looks byte-identical to today — no gap, no dot, and the `qs -c hyprshell` log is clean.
- [ ] With transcripts present and no `claude` running, the dot is visible but dim and static.
- [ ] Starting `claude` in a terminal makes the dot turn accent-coloured and pulse within 5 s; exiting stops the pulse within 5 s and the dot returns to a steady 0.35 opacity (not stuck mid-fade).
- [ ] The aggregator runs at most once per 2 min when no session is live (check with a `logger` line in the script and `journalctl -f`).

**Risks**

- The `SequentialAnimation on opacity` property-value-source will fight the hover `opacity` binding; if it does, animate a child Rectangle's `scale` or a separate `pulse` property multiplied into opacity instead of animating opacity directly.
- Bar.qml's right side currently anchors StatusPill directly to parent.right; restructuring into a Row must preserve `anchors.verticalCenter` or the pill shifts a pixel or two.
- Polling pgrep every 5 s forever is a small but permanent wakeup; consider 10 s idle / 5 s while the panel is open.

### `K3` &middot; Add ClaudePanel.qml: today's tokens, a 7-day sparkline, top projects, live session

**Effort:** M &middot; 1-3 h

**Why.** This is the 'richness on click' half — everything the user might want about usage in one hyprshell-panel-styled surface, reachable only by deliberately clicking the dot.

**Files**

- `quickshell/hyprshell/ClaudePanel.qml`
- `quickshell/hyprshell/shell.qml`
- `quickshell/hyprshell/State.qml`

**Steps**

1. Copy the panel skeleton from QuickSettings.qml verbatim: `PanelWindow` with `visible: State.claudeOpen`, `anchors { top: true; right: true }`, `margins { top: 6; right: 6 }`, `implicitWidth: 340`, `exclusiveZone: 0`, `color: "transparent"`, `WlrLayershell.namespace: "hyprshell-panel"`, `WlrLayershell.layer: WlrLayer.Overlay`, `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand`, plus the `HyprlandFocusGrab { windows: [win]; active: State.claudeOpen; onCleared: State.claudeOpen = false }` block so click-outside dismisses it.
2. Root visual is `Rectangle { color: Theme.bg; radius: Theme.radius; border.color: Theme.border; border.width: 1 }` — blur comes from the existing hyprshell-panel layerrule, no extra work.
3. Top block: today's total in a large `Text` (font.pixelSize: 28, Theme.fg) formatted with a `fmt(n)` helper returning `n>=1e6 ? (n/1e6).toFixed(1)+"M" : n>=1e3 ? Math.round(n/1e3)+"k" : n`, with a Theme.fgDim caption `"tokens today"`. Below it a single dim line `in / out / cached`. Show a cost line only when `usage.today.costUsd != null`.
4. Sparkline: `import QtQuick.Shapes` then `Shape { ShapePath { strokeColor: Theme.accent; strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap; PathPolyline { path: root.sparkPoints } } }` where `sparkPoints` is a JS-computed array of `Qt.point(i * (w/6), h - (d.total/maxTotal) * h)` over `usage.days`. Guard `maxTotal <= 0` by hiding the Shape. Height 36, full panel width minus padding. If Shapes is unavailable in the Quickshell Qt runtime, fall back to `Canvas { onPaint: ... }` with `requestPaint()` on data change.
5. Under the sparkline, seven weekday initials in Theme.fontSizeSmall / Theme.fgDim so the line is readable without axes.
6. Top projects: a `Repeater { model: root.usage ? root.usage.projects : [] }` of rows — basename in Theme.fg on the left, `fmt(total)` in Theme.fgDim on the right, and a thin `Rectangle` bar behind at `width: parent.width * (total/topTotal)` in `Qt.rgba(1,1,1,0.06)` for a quiet ranked-bar effect.
7. Live session footer: visible only when `usage.session` is non-null — `Row` with a small accent dot, the session cwd basename, and its running token total; hidden entirely otherwise.
8. Instantiate `ClaudePanel {}` in shell.qml next to the other panels, and add `toggleClaude()` to the IpcHandler mirroring `toggleQuickSettings()` so `qs -c hyprshell ipc call shell toggleClaude` works from a keybind.
9. Let the panel poll fast (10 s) while open and the bar widget poll slowly, sharing results through a `State.claudeUsage` property so two aggregator runs never overlap.

**Done when**

- [ ] Clicking the bar dot opens the panel top-right, aligned with QuickSettings' geometry; clicking anywhere else closes it via the focus grab.
- [ ] The sparkline renders 7 connected points with no gaps for days that had zero usage, and does not render at all when every day is zero.
- [ ] With hypr/scripts/claude-prices.json still `{}`, no cost line appears anywhere in the panel.
- [ ] `qs -c hyprshell ipc call shell toggleClaude` opens and closes the panel.
- [ ] Opening the panel with the aggregator script deleted produces no QML error in the qs log.

**Risks**

- `PathPolyline` needs `import QtQuick.Shapes` and on some Qt 6 builds a `preferredRendererType`; if the polyline does not appear, the Canvas fallback is the safe path.
- Two Process instances polling the same script can interleave; sharing via a State property is the fix but adds a singleton dependency the panel must not create a binding loop with.
- Panel height varies with the number of projects — bind `implicitHeight: content.implicitHeight + 24` like QuickSettings does rather than fixing it.

### `K4` &middot; Bind a styled floating Claude Code terminal to Super+Shift+Return, scoped to the focused project

**Effort:** S &middot; under 1 h

**Why.** Launching Claude Code today means opening a terminal and cd-ing by hand; a keybind that lands you in the right directory in a panel-looking window is the single highest-value ergonomic win here.

**Files**

- `hypr/scripts/claude-here`
- `hypr/hyprland/keybinds.conf`
- `hypr/hyprland/rules.conf`
- `kitty/claude.conf`

**Steps**

1. Do NOT use Super+Shift+C — it is already bound to `hyprpicker -a` at hypr/hyprland/keybinds.conf:33. Super+Shift+Return is free (checked against every existing Super+Shift binding), as is Ctrl+Super+C and Super+Slash.
2. Write hypr/scripts/claude-here: resolve the project dir by `pid=$(hyprctl activewindow -j | jq -r '.pid')`, then walk to the deepest descendant (`while c=$(pgrep -P "$pid" | head -1); [ -n "$c" ]; do pid=$c; done`) because a terminal window's own pid keeps the cwd it was launched from, not the shell's. Then `dir=$(readlink -f /proc/$pid/cwd 2>/dev/null)`.
3. Refine to the project root: `git -C "$dir" rev-parse --show-toplevel` if it succeeds, else keep $dir; fall back to `$HOME` unconditionally if anything above is empty or unreadable (Flatpak/xwayland windows will fail the /proc read).
4. Guard on the CLI: `command -v claude >/dev/null || { notify-send 'Claude Code not installed'; exit 0; }`.
5. Exec `kitty --class hyprshell-claude --config "$HOME/.config/kitty/claude.conf" --directory "$dir" -- claude`. The dedicated class is what the windowrule matches on.
6. Create kitty/claude.conf that does `include kitty.conf` first (--config replaces the whole chain, so without this the user loses every kitty setting) then overrides: `background_opacity 0.85`, `background #1e1e1e`, `window_padding_width 14`, `hide_window_decorations yes`, `font_size 11`, `cursor_shape beam`, `remember_window_size no`.
7. Add to hypr/hyprland/rules.conf in the 0.55 syntax: `windowrule = float on, center on, size 60% 70%, match:class ^hyprshell-claude$`. The existing `no_blur on, match:class ^(kitty)$` rule anchors on `^(kitty)$` so the new class keeps blur — verify that after the change rather than assuming.
8. Add `bind = Super+Shift, Return, exec, ~/.config/hypr/scripts/claude-here` to the Apps section of keybinds.conf and a matching .desktop entry so it also appears in wofi.

**Done when**

- [ ] Focusing a kitty window sitting in ~/Dokumente/hyprland/nix-dot and pressing Super+Shift+Return opens a floating, centred, 60%x70% terminal already running `claude` in that repo root.
- [ ] Focusing Firefox opens the same window in $HOME rather than failing.
- [ ] `hyprctl clients | grep -A2 hyprshell-claude` shows `floating: 1`.
- [ ] With `claude` removed from PATH, the keybind produces one notification and no window, exit code 0.
- [ ] The existing `Super, Return` -> plain kitty binding still works unchanged, with the user's normal kitty config.

**Risks**

- Walking `pgrep -P` to the deepest child picks an arbitrary branch when a shell has several children; `head -1` is a heuristic that can land in a subprocess's cwd. Acceptable, but comment it in the script.
- /proc/PID/cwd is unreadable for sandboxed apps — the $HOME fallback must be unconditional, not conditional on readlink succeeding.
- Hyprland 0.55 rule syntax silently drops a malformed rule rather than erroring; confirm the rule took effect via hyprctl after reload.

### `K5` &middot; Make claude-code resolve from nixpkgs, not ~/.local/bin, and pin the widget's dependencies

**Effort:** S &middot; under 1 h

**Why.** packages.nix already lists claude-code but the binary actually on PATH is a user npm install; the widget and launcher scripts will silently target whichever wins, and jq/pgrep must be guaranteed present for the aggregator to work at all.

**Files**

- `nixos/modules/packages.nix`
- `hypr/scripts/claude-usage`
- `hypr/scripts/claude-here`

**Steps**

1. Confirm on the NixOS target that `readlink -f $(command -v claude)` points into /nix/store — on this dev box it resolves to /home/anon/.local/bin/claude, so an npm install shadows the package listed at nixos/modules/packages.nix:10.
2. Pick one owner: either remove the npm install (`rm -rf ~/.local/bin/claude` and the npm-global module dir) or drop `claude-code` from packages.nix. Having both is what causes version drift between the CLI and the transcript schema. Leave claude-desktop's bundled copy at ~/.config/Claude/claude-code/<ver>/claude alone — that is a third, separate install.
3. Verify `jq` is in nixos/modules/packages.nix (the aggregator hard-depends on it) and add it if not; confirm `command -v pgrep` on the target (procps).
4. Give both scripts `#!/usr/bin/env bash` — the user's shell is fish and fish syntax will not work in a script Quickshell spawns via sh — and reference `$HOME/.config/hypr/scripts/...` absolutely, since Process inherits an environment that may lack the interactive PATH.
5. Add `command -v jq >/dev/null || { echo '{"ok":false}'; exit 0; }` at the top of claude-usage so a missing jq degrades to a hidden widget rather than a broken one.
6. Add a comment header to claude-usage stating that no official local quota/limit API is assumed — everything is derived from local JSONL and reports tokens consumed, never remaining allowance.

**Done when**

- [ ] `readlink -f $(command -v claude)` on the NixOS target points where the user intends, and only one user-facing claude install exists.
- [ ] `env -i /bin/sh -c "$HOME/.config/hypr/scripts/claude-usage"` (empty environment) still prints valid JSON.
- [ ] `nixos-rebuild dry-build` succeeds after the packages.nix edit.
- [ ] Grepping both new scripts shows no fish-only syntax and no bare `jq`/`pgrep` call outside a guard.

**Risks**

- Removing the npm claude may break whatever installed it or a workflow that pins that version.
- nixpkgs `claude-code` may lag the npm release; if the transcript schema changes between versions the aggregator's `// 0` defaults keep it from crashing but numbers could under-report silently.

### `K6` &middot; Add a quick-ask input that pipes one question to `claude -p` and shows the answer in a panel

**Effort:** M &middot; 1-3 h

**Why.** Turns a keystroke into a zero-ceremony way to ask one question without opening a session — the most 'hidden utility that is still there' feature in the whole area.

**Files**

- `quickshell/hyprshell/ClaudeAsk.qml`
- `quickshell/hyprshell/shell.qml`
- `quickshell/hyprshell/State.qml`
- `hypr/hyprland/keybinds.conf`

**Steps**

1. Build ClaudeAsk.qml as a centred PanelWindow (leave `anchors` unset so it centres, `WlrLayershell.namespace: "hyprshell-panel"`, `WlrLayershell.layer: WlrLayer.Overlay`, `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` so typing works), width 560, containing one borderless input: a Rectangle in Theme.card wrapping a `TextInput`, Theme.font at fontSize 15, with a Theme.fgDim 'Ask Claude…' placeholder.
2. Trigger it from its own binding rather than a wofi prefix — wofi has no live-prefix hook, so `bind = Super, Slash, exec, qs -c hyprshell ipc call shell toggleClaudeAsk` (Super+Slash verified free) is both simpler and faster. Add `toggleClaudeAsk()` to shell.qml's IpcHandler and `claudeAskOpen` to State.qml.
3. On Enter, run `Process { command: ["claude", "-p", root.question, "--output-format", "json"] }` — `-p/--print` is the non-interactive flag and is confirmed present in this CLI's `--help`, as is `--output-format`. Parse the JSON envelope; if parsing fails, show raw stdout.
4. While running, swap the input for a three-dot pulse in Theme.accent reusing the same slow SequentialAnimation as the bar dot, so the two read as one object.
5. Render the answer in a `Flickable` + `Text` with `wrapMode: Text.WordWrap` and `textFormat: Text.PlainText` — never RichText, the answer is untrusted model output — capped at ~50% of screen height. Esc or click-outside closes.
6. Degrade hard: if `claude` is missing or the process exits non-zero (unauthenticated is the common case — this feature requires the CLI to already be logged in and does not handle auth), close the panel and `notify-send` once. Never render an error surface in the shell.
7. Cap the scope deliberately: one question, one answer, no history, no follow-ups. Anything more belongs in the Super+Shift+Return terminal.

**Done when**

- [ ] Super+Slash opens a centred input that has keyboard focus immediately (typing goes into it, not the window underneath).
- [ ] Typing a question and pressing Enter shows an answer in the panel; Esc closes it and the next open starts empty.
- [ ] With `claude` unavailable or logged out, pressing Enter closes the panel and shows exactly one notification, with no QML errors in the qs log.
- [ ] A question whose answer contains `<b>` displays the literal tag, proving PlainText.

**Risks**

- The `--output-format json` envelope shape for a `-p` run is unverified; run `claude -p 'hi' --output-format json | jq keys` on the target before writing the parser, and fall back to plain text (omit the flag) if it differs.
- WlrKeyboardFocus.Exclusive on an Overlay layer can lock input if the panel fails to close on an error path — always tie visibility to a State property a HyprlandFocusGrab onCleared can reset.
- A long `claude -p` blocks with no cancel; set `running = false` on Esc to kill the Process, or offer an abort after ~30 s.

### Open questions and unverified assumptions

- Verified on this box: transcript rows are `.type=="assistant"` with `.message.usage.{input_tokens,output_tokens,cache_creation_input_tokens,cache_read_input_tokens}` plus top-level `.timestamp` (UTC, millisecond ISO), `.cwd`, `.sessionId`, `.gitBranch`, `.version`, `.requestId`, and `.message.model` (values seen: claude-opus-5, claude-fable-5, claude-fable-5-1, claude-opus-4-8, <synthetic>). 75 jsonl files across 8 project dirs; largest 16 MB.
- Verified: rows are duplicated per API call — 80 assistant rows / 37 unique requestIds in one file. Dedupe by requestId is mandatory. NOT verified whether duplicate rows ever carry *different* usage values (I did not compare them pairwise); if they do, `max_by(.message.usage.output_tokens)` is safer than `.[0]`.
- `.message.usage.iterations[]` exists and mirrored the top-level counts in the single-iteration row I inspected. I did NOT verify whether a multi-iteration request's top-level counts are the sum or only the last iteration. Check one multi-iteration row before trusting per-request totals.
- There is no official local quota/limit API and none is assumed. Everything reports tokens *consumed* from local transcripts; it cannot show remaining allowance, reset windows, or plan limits. `~/.claude.json` (55 KB here) holds config and possibly per-project metadata but I did not parse it — do not build the widget on it.
- ccusage (npm) does this aggregation upstream. UNVERIFIED in nixpkgs — `ccusage` is not on PATH here and I did not search nixpkgs. Treat `pkgs.ccusage` as unconfirmed; if absent the alternatives are `npx ccusage` (runtime network, not acceptable) or the jq script (recommended regardless).
- Verified in jq 1.8.2: `sub("\\.[0-9]+Z$";"Z") | fromdateiso8601 | strflocaltime("%Y-%m-%d")` maps 2026-09-05T23:30Z to 2026-09-06 under TZ=Europe/Berlin. Bare `fromdateiso8601` errors on fractional seconds.
- Verified `pgrep -x claude` matches running CLI sessions (comm is exactly `claude`). Caveat: claude-desktop bundles its own claude-code whose comm is also `claude`, so the dot will pulse for desktop-driven sessions too. To exclude them, filter on `/proc/PID/exe` not resolving under `.config/Claude`.
- Verified keybind conflict: Super+Shift+C is `hyprpicker -a` (hypr/hyprland/keybinds.conf:33). Free: Super+Shift+Return, Super+Slash, Super+Shift+A, Ctrl+Super+C. Taken: Super+A, Super+Q, Super+C (code), Super+Return (kitty), Super+T (foot).
- Verified `claude-code` is at nixos/modules/packages.nix:10, but the `claude` on PATH on this dev box is /home/anon/.local/bin/claude (user npm install). This box is CachyOS, not the NixOS target, so the /nix/store check was inconclusive — re-check on the target.
- Verified `claude --help` lists `-p/--print`, `--output-format`, `--input-format`. I did NOT run `claude -p` to confirm the `--output-format json` envelope shape.
- Quickshell APIs used are all already in this repo: `Process` + `StdioCollector.onStreamFinished`, `Timer`, `PanelWindow`, `WlrLayershell.namespace/layer/keyboardFocus`, `HyprlandFocusGrab`, `Quickshell.execDetached`, `IpcHandler`. NOT used anywhere here and therefore unverified: `Quickshell.Io.FileView` (for watching the live transcript instead of polling) and `Quickshell.clipboardText`.
- QtQuick.Shapes / `PathPolyline` for the sparkline is standard Qt 6 but is imported nowhere in this repo today, so its presence in the installed Quickshell Qt runtime is unverified. Canvas is the fallback.
- RESOLVED 2026-09-06: qmldir lists only singletons (Notifs, Theme, State). Plain components resolve automatically from the same directory, so ClaudeWidget/ClaudePanel/ClaudeAsk need no qmldir entry.

---

## Proton mail, calendar and VPN

### Recommended approach

Recommended path: **protonmail-bridge (headless, systemd user service) + Evolution as the reader + a tiny IMAP poller for the bar badge**, and treat Proton Calendar as read-only. Bridge is the only supported way to get Proton Mail into any Linux client; Evolution wins over Thunderbird because it is GNOME-native (matches "GNOME but better"), its Message-Notification plugin already speaks org.freedesktop.Notifications so new mail lands in the existing Notifs.qml with zero shell code, and evolution-data-server gives you a local calendar/contacts store you can reuse for the clock popover. The one thing Evolution does not give you is a machine-readable unread count, so the shell gets it from a ~40-line python `mail-status` script talking to 127.0.0.1:1143 and writing JSON into $XDG_RUNTIME_DIR — that keeps the bar authoritative and lets it go silent (not stale) when the bridge is down. Trade-off: two IMAP consumers against the local bridge and Evolution's EDS daemons idling in the background, which is heavier than option (c) alone (poller + aerc/himalaya) but far less code and a much better GUI story; if RAM pressure on 16 GB becomes a problem, drop Evolution and keep the poller + `aerc`. For VPN, detect state through NetworkManager (`nmcli -t -f NAME,TYPE,STATE connection show --active`) rather than parsing `protonvpn-cli status` — NM is already polled in Services.qml and the CLI's output format is version-unstable. For Calendar, be blunt: Proton Calendar is E2E encrypted with **no CalDAV and no public API**, bridge does not cover it, so the honest integration is a local ICS/EDS agenda inside the existing notification popover plus a one-click chromium `--app=` window for calendar.proton.me. Secrets: keyring-only, nothing in the repo — the bridge password lives in gnome-keyring and is read with `secret-tool`; sops-nix/agenix would add machinery for a secret that is per-device and non-reproducible anyway.

### `P1` &middot; Run protonmail-bridge headless as a systemd user service

**Effort:** M &middot; 1-3 h

**Why.** Nothing about Proton Mail on Linux works without the bridge exposing local IMAP/SMTP, and it must come up automatically at login without a GUI.

**Files**

- `nixos/modules/proton.nix`
- `nixos/configuration.nix`
- `nixos/modules/desktop.nix`
- `home-manager/home.nix`
- `hypr/hyprland/execs.conf`
- `README.md`

**Steps**

1. Create nixos/modules/proton.nix and add it to the imports list in nixos/configuration.nix; put `protonmail-bridge` in environment.systemPackages there (add `protonmail-bridge-gui` only if you want the GUI for first-time login — the headless package also ships the `--cli` interface).
2. Ensure the user systemd session actually exists under Hyprland: check hypr/hyprland/execs.conf for `dbus-update-activation-environment --systemd --all` / `systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP` and add an exec-once if missing, otherwise `graphical-session.target` never activates and the unit will not start.
3. Prefer the Home Manager module if it exists in your HM pin — `services.protonmail-bridge = { enable = true; nonInteractive = true; logLevel = "info"; };` in home-manager/home.nix. Verify first with `grep -r protonmail-bridge $(nix eval --raw home-manager)` or by searching the HM source under modules/services; if absent, use the fallback in the next step.
4. Fallback unit in home-manager/home.nix: `systemd.user.services.protonmail-bridge = { Unit = { Description = "Proton Mail Bridge"; After = ["graphical-session.target"]; PartOf = ["graphical-session.target"]; }; Service = { Type = "simple"; ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info"; Restart = "on-failure"; RestartSec = 10; }; Install.WantedBy = ["graphical-session.target"]; };` and set `systemd.user.startServices = "sd-switch";`.
5. Make the keyring reliable: gnome-keyring is started in hypr/hyprland/execs.conf with `--components=secrets`, but the login keyring must also be unlocked by PAM — add `security.pam.services.login.enableGnomeKeyring = true;` (and the same for your display/login manager service and for `hyprlock` if you want unlock-on-resume) in nixos/modules/desktop.nix. Without this the bridge starts, finds a locked keychain, and can silently create a new empty vault.
6. One-time manual login (never scripted, never committed): run `protonmail-bridge --cli`, then `login`, then `info`. Record the generated IMAP/SMTP username and password straight into the keyring (see the secrets task) — do not paste them into any file in this repo.
7. Document in README.md: IMAP 127.0.0.1:1143 STARTTLS, SMTP 127.0.0.1:1025 STARTTLS, self-signed certificate, clients must accept it or import the bridge cert (look for it under ~/.config/protonmail/bridge-v3/ — the exact path varies by bridge major version, find it with `find ~/.config/protonmail -name '*.pem'`).

**Done when**

- [ ] `systemctl --user is-active protonmail-bridge` returns `active` after a fresh reboot with no manual intervention.
- [ ] `ss -ltnp | grep -E ':(1143|1025)'` shows both listeners bound to 127.0.0.1 only (never 0.0.0.0).
- [ ] `openssl s_client -starttls imap -connect 127.0.0.1:1143 -quiet </dev/null` completes the STARTTLS handshake.
- [ ] `journalctl --user -u protonmail-bridge -b` contains no keychain/vault errors.
- [ ] `grep -rniE 'bridge.*(pass|pwd)|[A-Za-z0-9_-]{16,}' ` over the repo finds no credential.

**Risks**

- nixpkgs attribute names `protonmail-bridge` / `protonmail-bridge-gui` are asserted from memory — verify with `nix search nixpkgs protonmail` before rebuilding.
- The `--noninteractive` flag and `--log-level` spelling are bridge-version dependent; confirm with `protonmail-bridge --help`.
- If gnome-keyring is not up before the unit starts, the bridge may reset its vault and force a re-login; consider `ExecStartPre` that waits for the org.freedesktop.secrets DBus name.
- Bridge occasionally requires a re-login after a Proton password change or 2FA reset — this is manual, by design, and cannot be automated.

### `P2` &middot; Fix the secrets policy: keyring-only, nothing committed

**Effort:** S &middot; under 1 h

**Why.** The bridge password and any future Proton credential must never reach this repo, which is the user's whole ~/.config and gets shared/synced.

**Files**

- `.gitignore`
- `README.md`
- `nixos/modules/proton.nix`
- `nixos/modules/desktop.nix`

**Steps**

1. Decide explicitly and write it in README.md: **no sops-nix, no agenix**. There is no system-level Proton secret, and the bridge password is per-device and regenerated on re-login, so declarative secret management buys nothing here. Note sops-nix as the future choice if a *system* service ever needs a secret.
2. Add `libsecret` to environment.systemPackages in nixos/modules/desktop.nix so `secret-tool` is available.
3. Store the bridge credential once, manually: `secret-tool store --label='Proton Bridge IMAP' service hyprshell-mail account proton` (it reads the password from stdin, never argv, so it stays out of shell history). Document this exact command in README.md.
4. Consumers read it with `secret-tool lookup service hyprshell-mail account proton` — used by the mail poller task. Note that any systemd user unit doing this needs DBUS_SESSION_BUS_ADDRESS in its environment, which it gets from the imported session environment.
5. Create/extend .gitignore at the repo root with: `*.pem`, `*.key`, `*.token`, `secrets*`, `**/local.conf`, `hypr/custom/local*.conf`, `**/*credentials*`, and `.config/protonmail/`.
6. Add a one-line check to README.md that can be run before pushing: `rg -n -i --hidden -g '!.git' '(password|passwd|api[_-]?key|token|secret)\s*[:=]\s*\S' .` and eyeball the hits.

**Done when**

- [ ] `secret-tool lookup service hyprshell-mail account proton` prints the bridge password for the logged-in user and fails for anyone else.
- [ ] The rg command in README returns no real credential (only comments/option names).
- [ ] `git check-ignore -v .config/protonmail/cert.pem` reports the ignore rule (if the repo is ever git-init'd).

**Risks**

- `secret-tool` fails inside a systemd user unit if the DBus session address was never imported into the systemd environment — same root cause as the bridge unit; fix once for both.
- gnome-keyring is currently started with `--components=secrets` only; if you later want ssh-agent from it, that flag must change.

### `P3` &middot; Set up Evolution as the Proton Mail reader with native desktop notifications

**Effort:** M &middot; 1-3 h

**Why.** Evolution is the GNOME-native client, and its Message Notification plugin already emits org.freedesktop.Notifications, so new-mail popups land in the existing Notifs.qml/NotificationPopups.qml with no shell code at all.

**Files**

- `nixos/modules/proton.nix`
- `nixos/modules/desktop.nix`
- `hypr/hyprland/rules.conf`
- `home-manager/home.nix`
- `README.md`

**Steps**

1. Add `evolution` to environment.systemPackages in nixos/modules/proton.nix and set `services.gnome.evolution-data-server.enable = true;` (EDS also backs the calendar task). `programs.evolution.enable` may also exist as a NixOS option that wires up the plugins path — check `nixos-option programs.evolution` before relying on it.
2. Configure the account manually once (it is stored in EDS/dconf, not in this repo): Receiving = IMAP, server 127.0.0.1, port 1143, encryption STARTTLS, auth PLAIN, username = your @proton.me address, password = the bridge password. Sending = SMTP 127.0.0.1:1025, STARTTLS, same credentials.
3. Accept or import the bridge's self-signed certificate when Evolution prompts; if it refuses, import the bridge cert.pem found under ~/.config/protonmail/ via Edit > Preferences > Certificates > Authorities.
4. Enable the notification plugin: Edit > Preferences > Plugins > Mail Notification, and set the dconf keys declaratively in home-manager/home.nix: `dconf.settings."org/gnome/evolution/plugin/mail-notification" = { notify-new-messages = true; notify-sound-enabled = false; notify-status-notification = false; };` (verify key names with `dconf watch /` while toggling the checkboxes).
5. Set Evolution's mail check interval to 1 minute (Preferences > Mail Accounts > Edit > Receiving Options) so notifications are timely against the local bridge.
6. Add window rules to hypr/hyprland/rules.conf using the new syntax: `windowrule = float on, center on, size 60% 70%, match:title ^(Compose Message|Nachricht verfassen)(.*)$, match:class ^org\.gnome\.Evolution$` and let the main window tile normally.
7. Decide about thunderbird, which is currently in nixos/modules/packages.nix line 45: either remove it (Evolution replaces it) or keep it as a fallback and note why in the file comment.
8. Test end-to-end: send yourself a mail from the Proton web UI and confirm a popup appears in NotificationPopups.qml.

**Done when**

- [ ] A mail sent to the account produces a popup toast from the shell's own notification server within ~60 s, with appName reported as Evolution.
- [ ] The toast is suppressed when State.doNotDisturb or State.gameMode is set (behaviour already implemented in Notifs.qml).
- [ ] Sending a mail from Evolution succeeds through 127.0.0.1:1025.
- [ ] Killing the bridge (`systemctl --user stop protonmail-bridge`) makes Evolution report an offline account rather than hanging the UI.

**Risks**

- Evolution pulls a large GNOME dependency closure and runs several EDS daemons permanently — measurable on 16 GB alongside games; if that is unacceptable, the fallback is `aerc` or `himalaya` plus the poller from the next task.
- Evolution's mail-notification dconf key names are from memory — confirm with `dconf watch /`.
- Evolution can block at startup for ~30 s if the bridge is not yet listening; ordering the bridge before graphical-session helps but does not fully fix it.
- Account configuration is not declarative and will not survive a fresh machine — document the steps in README.md instead of pretending otherwise.

### `P4` &middot; Add a mail-status poller and a Mail.qml singleton feeding the shell

**Effort:** M &middot; 1-3 h

**Why.** No mail client exposes a usable unread count over IPC, so the bar needs its own authoritative, cheap source of truth that goes silent instead of stale when the bridge is down.

**Files**

- `hypr/scripts/mail-status`
- `quickshell/hyprshell/Mail.qml`
- `quickshell/hyprshell/qmldir`
- `home-manager/home.nix`
- `quickshell/hyprshell/README.md`

**Steps**

1. Write hypr/scripts/mail-status as a python3 script (stdlib only: `imaplib`, `ssl`, `json`, `subprocess`): read the password with `subprocess.run(['secret-tool','lookup','service','hyprshell-mail','account','proton'])`, `imaplib.IMAP4('127.0.0.1', 1143)`, `.starttls(ssl_context)` with a context built from the bridge cert (or `ssl._create_unverified_context()` — acceptable because the connection never leaves loopback; say so in a comment), `login()`, `select('INBOX', readonly=True)`, `search(None, 'UNSEEN')`.
2. Print one JSON object on stdout: `{"ok":true,"unread":N,"uids":[...],"latest":{"from":"...","subject":"..."}}`; on any exception print `{"ok":false,"unread":0}` and exit 1. Decode headers with `email.header.decode_header` so UTF-8 subjects render.
3. Diff the UID set against the previous run cached in `$XDG_RUNTIME_DIR/hyprshell/mail-uids.json`, and for genuinely new UIDs call `notify-send -a Mail -i mail-unread-symbolic "<from>" "<subject>"` — this routes through the shell's own notification server so DND/game-mode suppression is inherited for free. Skip this if Evolution is already the notifier, to avoid duplicates: gate it on an env var `HYPRSHELL_MAIL_NOTIFY=1`.
4. Write the JSON atomically to `$XDG_RUNTIME_DIR/hyprshell/mail.json` (`open(tmp,'w')` then `os.replace`) so the shell never reads a half-written file.
5. Add a systemd user service+timer in home-manager/home.nix: `systemd.user.services.hyprshell-mail = { Service = { Type = "oneshot"; ExecStart = "%h/.config/hypr/scripts/mail-status"; }; };` and `systemd.user.timers.hyprshell-mail = { Timer = { OnBootSec = "1m"; OnUnitActiveSec = "60s"; }; Install.WantedBy = ["timers.target"]; };`.
6. Create quickshell/hyprshell/Mail.qml as `pragma Singleton` + `Singleton { ... }` holding `property bool ok`, `property int unread`, `property string latestFrom`, `property string latestSubject`; back it with `FileView { path: Quickshell.env("XDG_RUNTIME_DIR") + "/hyprshell/mail.json"; watchChanges: true; onFileChanged: reload() }` and parse `JSON.parse(text())` in a try/catch. Add a 90 s Timer that flips `ok=false` if the file's data stops updating.
7. Register it in quickshell/hyprshell/qmldir: `singleton Mail 1.0 Mail.qml` (alongside the existing Notifs/Theme/State lines).
8. Add a `function openMail()` to Services.qml: `Quickshell.execDetached(["gtk-launch", "org.gnome.Evolution"])`.

**Done when**

- [ ] `hypr/scripts/mail-status` prints valid JSON in under 2 seconds and exits 0 with the bridge running.
- [ ] `systemctl --user stop protonmail-bridge` then a timer tick makes the JSON `{"ok":false,...}` and Mail.unread reads 0 in the shell (verified with `qs -c hyprshell log` or a temporary Text binding).
- [ ] Marking a mail read in Evolution drops the count within 60 s.
- [ ] The script never appears in `ps` output with a password in argv (`ps auxww | grep -i mail-status`).

**Risks**

- Quickshell's FileView property names (`path`, `watchChanges`, `text()`, `onFileChanged`, `reload()`) are asserted from memory — verify against the installed Quickshell docs/version before writing the QML; the fallback is a `Process` + `StdioCollector` running `cat` on a Timer, which the codebase already uses everywhere.
- `secret-tool` inside a systemd user unit needs the DBus session address imported (see the secrets task).
- Disabling TLS verification on loopback is a deliberate choice — if the machine ever gets untrusted local users this must become real cert pinning.
- Polling every 60 s wakes the CPU; IMAP IDLE via `goimapnotify` would be instant and cheaper but adds a daemon — nixpkgs attribute `goimapnotify` is unverified.

### `P5` &middot; Surface mail in StatusPill and the notification center, invisible at zero

**Effort:** S &middot; under 1 h

**Why.** The point of the count is a glance-level cue that stays completely out of sight until there is actually something to see — the user's stated minimalism rule.

**Files**

- `quickshell/hyprshell/StatusPill.qml`
- `quickshell/hyprshell/NotificationCenter.qml`
- `quickshell/hyprshell/QuickSettings.qml`

**Steps**

1. In StatusPill.qml, inside `Row { id: iconRow }` and before the network StatusIcon, add an Item containing a `StatusIcon { icon: "mail-unread-symbolic"; fallback: "✉" }` and a `Text { text: Mail.unread > 99 ? "99+" : Mail.unread; font.pixelSize: Theme.fontSize - 3; color: Theme.accent }`, with `visible: Mail.ok && Mail.unread > 0` on the wrapper so the pill's implicitWidth animation (already present) collapses cleanly to today's width when there is no mail.
2. Give that wrapper its own `MouseArea { anchors.fill: parent; onClicked: { svc.openMail(); mouse.accepted = true } }` layered above the pill-wide MouseArea so clicking the badge opens the client instead of toggling Quick Settings — verify z-order, the outer MouseArea in StatusPill.qml is a sibling filling `root`.
3. Keep the icon at the same 0.55 opacity as its neighbours when the pill is not hovered/active (it inherits `iconRow.opacity`), so it reads as a hint, not an alert.
4. In NotificationCenter.qml, add a single compact header row above the notification list, `visible: Mail.ok && Mail.unread > 0`, showing `Mail.unread + " unread"` on the left and the latest sender/subject elided on the right, styled with Theme.card / Theme.radiusSmall like the media footer in QuickSettings.qml. Clicking it calls svc.openMail() and closes the panel.
5. Optionally add a `hasMail` term to Clock.qml's `hasUnread` so the existing accent dot next to the clock also covers mail — decide one or the other, not both, to avoid double-signalling.
6. Do not add a mail QsToggle to QuickSettings — mail is status, not a switch; keep the grid at its current six tiles.

**Done when**

- [ ] With `unread == 0` a screenshot of the bar is pixel-identical to the current one.
- [ ] With unread mail, exactly one new glyph plus a small accent number appears, and hovering the pill brightens it with the rest of the row.
- [ ] Clicking the mail badge opens Evolution and does NOT open Quick Settings; clicking anywhere else on the pill still opens Quick Settings.
- [ ] `qs -c hyprshell` starts with no QML warnings about unresolved `Mail`.

**Risks**

- StatusPill.qml has no `svc` in scope today (it uses its own inline Process for network) — either instantiate `Services { id: svc }` there or move the open action into a small helper; note that instantiating a second Services object doubles the nmcli polling, so prefer a direct `Quickshell.execDetached` call in StatusPill.
- Adwaita's `mail-unread-symbolic` name should be confirmed with `gtk4-icon-browser` or `find $(nix eval --raw nixpkgs#adwaita-icon-theme) -name 'mail-unread*'`; the text fallback covers it either way.

### `P6` &middot; Add a Proton VPN toggle driven by NetworkManager state

**Effort:** M &middot; 1-3 h

**Why.** VPN is the one Proton service with a real Linux app and a clean state source, and it belongs in Quick Settings next to Wi-Fi — with a shield in the bar only while it is on.

**Files**

- `nixos/modules/proton.nix`
- `quickshell/hyprshell/Services.qml`
- `quickshell/hyprshell/QuickSettings.qml`
- `quickshell/hyprshell/StatusPill.qml`

**Steps**

1. Add the Proton VPN app to nixos/modules/proton.nix. Verify the attribute first with `nix search nixpkgs protonvpn` — candidates are `protonvpn-gui` (the GTK app, upstream name proton-vpn-gtk-app) and `protonvpn-cli`; also enable `networking.networkmanager.enable` dependencies it needs (it drives NM directly).
2. Extend the existing `pNet` Process in Services.qml rather than adding a new one — change its command to `["sh","-c","nmcli radio wifi; nmcli -t -f TYPE,STATE,CONNECTION device status; echo '@@'; nmcli -t -f NAME,TYPE,STATE connection show --active"]` and split the collected text on a line equal to `@@` inside `parseNet`.
3. In the new second section, set `vpnConnected = true` and `vpnName = <NAME>` for any line whose TYPE is `wireguard` or `vpn` and whose STATE is `activated`, EXCEPT names matching /killswitch|routed/i (Proton leaves a killswitch profile active that is not a real tunnel). Add `property bool vpnConnected` and `property string vpnName` next to the existing wifi properties.
4. Add `function toggleVpn()` to Services.qml: if `vpnConnected`, `Quickshell.execDetached(["nmcli","connection","down","id", vpnName])`; else if `lastVpnName !== ""`, `nmcli connection up id lastVpnName`; else `Quickshell.execDetached(["sh","-c","protonvpn-app >/dev/null 2>&1 &"])`. Persist `lastVpnName` by writing it to `$XDG_RUNTIME_DIR/hyprshell/vpn-last` whenever vpnConnected becomes true. Call `repoll.restart()` after the action, as the other toggles do.
5. Add a QsToggle to the GridLayout in QuickSettings.qml: `icon: "⛨"; label: "VPN"; sublabel: svc.vpnConnected ? svc.vpnName : "Off"; active: svc.vpnConnected; showArrow: true; onClicked: svc.toggleVpn(); onArrowClicked: { State.quickSettingsOpen = false; svc.openVpnApp() }` — the grid is `columns: 2`, so adding one tile makes it 7 items; add an eighth (or move Power Mode) to keep the grid even.
6. In StatusPill.qml add a StatusIcon with `visible: root.vpnConnected`, `icon: "network-vpn-symbolic"`, `fallback: "⛨"`, and parse the same nmcli active-connection list in its existing `netProc` (change its command to a `sh -c` with the same `@@` sentinel). Nothing is drawn when the VPN is off.
7. Verify the killswitch behaviour by hand: connect in the Proton app, then toggle off in Quick Settings, and confirm `ip route` no longer routes via the wg interface and that plain internet still works.

**Done when**

- [ ] Connecting from the Proton VPN app makes the shield appear in StatusPill within one poll interval (≤10 s) and the QsToggle turn accent-coloured with the server name as sublabel.
- [ ] Toggling off in Quick Settings drops the tunnel: `nmcli -t -f NAME,TYPE,STATE connection show --active` no longer lists it and `ip route get 1.1.1.1` goes via the physical interface.
- [ ] With no VPN configured at all, clicking the tile launches the Proton VPN app instead of erroring.
- [ ] With the VPN off, the bar is visually unchanged from today.

**Risks**

- nixpkgs attribute names `protonvpn-gui` / `protonvpn-cli` / `proton-vpn-gtk-app` and the GUI binary name `protonvpn-app` are all asserted from memory — verify all four before writing the nix file.
- Proton's NM profile naming (e.g. `pvpn-wg`, `ProtonVPN <server>`, killswitch profiles) is version-dependent; run `nmcli -t -f NAME,TYPE,STATE connection show --active` while connected and hard-code the observed pattern rather than guessing.
- `nmcli connection down` on a killswitch profile can leave the machine without a route — the name filter must be tested, not assumed.
- StatusPill and Services now parse the same nmcli output twice; consider hoisting network state into a singleton (like Notifs) as a follow-up refactor.

### `P7` &middot; Build a calendar view in the notification popover plus a Proton Calendar web-app window

**Effort:** L &middot; a day or more

**Why.** Proton Calendar is E2E encrypted with no CalDAV and no public API, so the only honest integration is a local read-only agenda in the GNOME-style clock popover next to a one-click button that opens the real web app in its own window.

**Files**

- `quickshell/hyprshell/NotificationCenter.qml`
- `quickshell/hyprshell/Clock.qml`
- `hypr/scripts/webapp`
- `hypr/scripts/agenda`
- `hypr/hyprland/rules.conf`
- `nixos/modules/proton.nix`
- `quickshell/hyprshell/README.md`

**Steps**

1. Write the limitation down first, in quickshell/hyprshell/README.md: protonmail-bridge covers mail only; Proton Calendar has no CalDAV endpoint; the only export path is Proton web UI > Settings > Calendars > Export ICS, which is a manual snapshot, not a sync. Do not build anything that pretends otherwise.
2. Follow GNOME and extend NotificationCenter.qml into a two-column popover instead of creating a new window: notifications on the left (existing list), a month grid + agenda on the right. Build the grid as a `Grid { columns: 7 }` of 42 cells with plain JS Date math, today's cell filled with Theme.accent and radius 16, other-month days at Theme.fgDim, and ‹ › month navigation in the header. Widen the PanelWindow accordingly and keep WlrLayershell.namespace "hyprshell-panel".
3. Write hypr/scripts/agenda: a python3 script (needs `python3.withPackages (ps: [ps.icalendar])` in nixos/modules/proton.nix) that reads every `*.ics` under ~/.local/share/hyprshell/calendars/, expands the next 14 days, and writes `[{"start":"2026-09-06T14:00","summary":"...","allday":false}]` atomically to `$XDG_RUNTIME_DIR/hyprshell/agenda.json`. Run it from a systemd user timer every 15 min plus a path unit on the calendars directory.
4. Consume it in QML with the same FileView pattern as Mail.qml, in a new singleton quickshell/hyprshell/Agenda.qml registered in qmldir; render the next few entries under the month grid as `HH:mm  Summary` rows, and show 'No events' in Theme.fgDim when empty.
5. If Evolution/EDS is installed from the mail task, offer EDS as the alternative source — but note in a comment that Quickshell has no generic DBus binding in QML, so reading org.gnome.Evolution.Dataserver would still go through a `Process` running `gdbus call`, i.e. no simpler than the ICS path.
6. Write hypr/scripts/webapp as a 5-line wrapper: `exec chromium --app="$2" --class="$1" --user-data-dir="$HOME/.local/share/webapps/$1" "$@"` (chromium is already in nixos/modules/packages.nix; add `--ozone-platform=wayland` if NIXOS_OZONE_WL is not set in nixos/modules/environment.nix).
7. Add a footer button in the calendar column: `Quickshell.execDetached(["sh","-c","$HOME/.config/hypr/scripts/webapp proton-calendar https://calendar.proton.me &"])`, and a matching rule in hypr/hyprland/rules.conf using the new syntax: `windowrule = float on, center on, size 1200 820, match:class ^proton-calendar$`.
8. Verify the app_id actually matches: launch the webapp and run `hyprctl clients | grep -A2 class` before committing the regex.

**Done when**

- [ ] Clicking the clock opens one popover showing notifications and a month grid with today highlighted.
- [ ] Dropping a test .ics into ~/.local/share/hyprshell/calendars/ makes its events appear in the agenda list within 15 minutes (or immediately after running hypr/scripts/agenda by hand).
- [ ] The 'Open Proton Calendar' button produces exactly one floating, centered 1200x820 window whose `hyprctl clients` class is `proton-calendar`.
- [ ] The shell process itself makes no network connections (`ss -tp | grep qs` is empty).
- [ ] README states plainly that the agenda is a manual ICS snapshot.

**Risks**

- RRULE/recurrence expansion is the hard part of ICS; scope v1 to non-recurring plus simple DAILY/WEEKLY, or pull in a helper library — nixpkgs attribute `python3Packages.recurring-ical-events` is unverified.
- Exported ICS goes stale the moment an event changes in Proton; this is a hard limitation, not a bug to fix later.
- Chromium `--class` sets the Wayland app_id in recent versions but this has changed historically — verify with hyprctl before writing the window rule. Firefox alternative (`MOZ_APP_REMOTINGNAME=proton-calendar firefox --new-instance --profile ...`) is also unverified.
- Widening NotificationCenter.qml touches a 281-line file that already handles popup grouping — do the calendar column as an additive right-hand ColumnLayout rather than restructuring the existing list.
- This task is at the top of L; if it slips, split the month grid (S) from the ICS agenda pipeline (M) into two tasks.

### Open questions and unverified assumptions

- nixpkgs attribute names asserted from memory and NOT verified (no `nix` binary on this machine to check): `protonmail-bridge`, `protonmail-bridge-gui`, `protonvpn-gui`, `protonvpn-cli`, `proton-vpn-gtk-app`, `evolution`, `goimapnotify`, `python3Packages.icalendar`, `python3Packages.recurring-ical-events`. Run `nix search nixpkgs <name>` for each before writing the nix modules.
- Whether Home Manager ships a `services.protonmail-bridge` module in the pinned HM revision, and whether its options are `nonInteractive` / `logLevel` / `path`. Fallback (a hand-written systemd.user.services entry) is specified in the task.
- Whether NixOS has a `programs.evolution.enable` option in addition to `services.gnome.evolution-data-server.enable` — check with `nixos-option`.
- The bridge's exact CLI flags (`--noninteractive`, `--log-level`, whether a `--keychain` selector is needed on first run) and the on-disk path of its self-signed certificate (bridge-v3 vs newer layout).
- Evolution's mail-notification dconf key names (`org/gnome/evolution/plugin/mail-notification/notify-new-messages` etc.) — confirm with `dconf watch /` while toggling the UI checkbox.
- Proton VPN's NetworkManager profile naming and connection TYPE (`wireguard` vs `vpn`), and whether a persistent killswitch profile shows as `activated` — must be observed with `nmcli -t -f NAME,TYPE,STATE connection show --active` while connected, not guessed.
- The Proton VPN GUI executable name (`protonvpn-app`? `protonvpn`?) — resolve with `command -v` after installing.
- Quickshell's `FileView` API surface (`path`, `watchChanges`, `text()`, `reload()`, `onFileChanged`, and whether `JsonAdapter` is the better fit) for the installed Quickshell version. The whole codebase currently uses Process+StdioCollector, which is the guaranteed-working fallback.
- Whether Quickshell exposes any generic DBus client in QML — I believe it does not (only the Services.* wrappers: Pipewire, Mpris, SystemTray, UPower, Notifications), which is why EDS integration is specified through a `gdbus`/`busctl` Process. Verify before choosing EDS over ICS files.
- Whether chromium's `--class` reliably sets the Wayland app_id in the pinned version, and whether `NIXOS_OZONE_WL` is already set in nixos/modules/environment.nix (not read during this pass).
- Whether the Hyprland session currently imports its environment into systemd (`dbus-update-activation-environment` / `systemctl --user import-environment` in hypr/hyprland/execs.conf) — only `gnome-keyring-daemon --start --components=secrets` was observed there. Every systemd user unit in these tasks depends on this.

---

## Lockdown mode

### Recommended approach

Build lockdown in two layers and ship them in that order. Layer 1 (tasks 1-3, 5) is entirely local and reversible: an unprivileged bash toggle that mirrors game-mode exactly, a shell IPC/visual state so the mode is impossible to forget it is on, and a small NixOS module that grants exactly the privileges the toggle needs via ONE root helper script with a single sudo NOPASSWD entry (not a scattered list of NOPASSWD binaries — `sudo nft ...` NOPASSWD is effectively root anyway). Layer 2 (task 4) is the network: I recommend transparent Tor routing via `services.tor` TransPort/DNSPort plus an nftables `output` kill-switch, because the alternative (torsocks/per-app proxy) leaks by construction — anything that ignores the proxy env goes out in the clear, which is the opposite of "alles auf uboot". But gate it behind an explicit `lockdown on --net=tor` flag and keep `--net=deny` (firewall default-deny, no torification) as the default until the fail-closed harness has been tested, because a botched output-chain policy on a machine you reach over SSH is a self-lockout, and a botched *nat* chain silently leaks. The load-bearing trade-off: transparent Tor is the only shape that can actually fail closed, and it costs you Tor Browser (do not run TB in transparent mode — Tor-over-Tor), most VoIP/UDP, and LAN convenience. Non-negotiable: write the honest threat model (task 6) in the same PR as task 1, not later — this is a hardening MODE on a persistent ZFS install, not Tails, and the README has to say so before anyone relies on it.

### `D1` &middot; Write hypr/scripts/lockdown, the local (no-network) core

**Effort:** M &middot; 1-3 h

**Why.** A single reversible toggle that shuts off microphone, camera, radios, clipboard history and background sync and makes the mode visually unmistakable — this is a hardening MODE on a persistent NixOS install with a normal disk, MAC address and browser, NOT an amnesic Tails equivalent, and it must not be trusted past that.

**Files**

- `hypr/scripts/lockdown`
- `hypr/hyprland/keybinds.conf`

**Steps**

1. Copy the structural skeleton of hypr/scripts/lockdown from hypr/scripts/game-mode verbatim: `#!/usr/bin/env bash`, `set -euo pipefail`, `have()`, `log()`, `notify()` (notify-send -a 'Lockdown'), `hc()`, state helpers `state_get`/`state_write`/`is_on`, and `main()` dispatching on|off|toggle|status [-q]. STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr-lockdown.state" so it dies with the session; every external tool guarded by `have`, every call suffixed `|| true`.
2. In state_write, record the values needed to restore: `bt_blocked=` (from `rfkill list bluetooth | grep -c 'Soft blocked: yes'`), `wwan_blocked=`, `cam_modules=` (space-separated list of camera modules actually loaded, from `lsmod | grep -E '^(uvcvideo|gspca_main|v4l2loopback)'`), `mic_sources=` (source ids that were unmuted), `net_mode=`, `started=$(date +%s)`.
3. Devices, in `harden_devices()`: mic — `wpctl set-mute @DEFAULT_SOURCE@ 1` plus a loop over every source id parsed out of `wpctl status` (`wpctl set-mute "$id" 1`); camera — for each module in cam_modules `sudo -n modprobe -r "$m"` (skip and log if `fuser /dev/video*` shows it busy); radios — `rfkill block bluetooth` and `rfkill block wwan` (record prior state first); location/sensors — `systemctl --user stop gammastep.service; pkill -x gammastep; sudo -n systemctl stop geoclue.service iio-sensor-proxy.service`. `restore_devices()` is the exact inverse using the state file, never a blanket unblock.
4. Traces, in `wipe_traces()`: `wl-copy --clear; wl-copy --primary --clear`; `cliphist wipe`; stop the two watchers started in hypr/hyprland/execs.conf with `pkill -f 'wl-paste .*cliphist store'` and restart both detached with `setsid -f` on `off`; `systemctl --user stop syncthing.service`; `sudo -n systemctl stop ollama`; `pkill -x wayvnc; pkill -x uxplay; pkill -x rustdesk`.
5. Visual state, in `mark_visible()`: `hyprctl --batch "keyword general:col.active_border rgba(e01b24ff) rgba(e01b24aa) 45deg; keyword general:border_size 2; keyword decoration:dim_inactive 1"`. Restore with `hc reload` on `off`, the same trick game-mode's cmd_off already relies on.
6. Add `shell_ipc()` copied from game-mode but calling `qs -c "$SHELL_CFG" ipc call shell setLockdown "$v"` (task 2 adds that function; until then the `|| true` makes it a no-op).
7. Install an `trap 'log "interrupted; restoring"; cmd_off >/dev/null 2>&1 || true' EXIT INT TERM HUP` around the body of cmd_on so a half-applied lockdown never survives a Ctrl-C, and clear it (`trap - EXIT ...`) once cmd_on completes.
8. Wire keybinds in hypr/hyprland/keybinds.conf next to the existing `$gamemode` block: `$lockdown = ~/.config/hypr/scripts/lockdown` and `bind = Super+Shift, L, exec, $lockdown toggle` (Super,L is likely already the lock binding — check the Session section before claiming the key), then `chmod +x hypr/scripts/lockdown`.

**Done when**

- [ ] `shellcheck hypr/scripts/lockdown` and `bash -n hypr/scripts/lockdown` are clean.
- [ ] After `lockdown on`: `wpctl get-volume @DEFAULT_SOURCE@` contains [MUTED]; `rfkill list bluetooth` shows `Soft blocked: yes`; `lsmod | grep uvcvideo` is empty; `cliphist list` is empty; `pgrep -f 'wl-paste.*cliphist'` returns nothing; `hyprctl getoption general:col.active_border` shows the e01b24 value.
- [ ] `lockdown status` prints `on` and dumps the state file; `lockdown status -q` exits 0 on and 1 off (same contract hypridle already uses for game-mode).
- [ ] After `lockdown off`: Bluetooth is unblocked ONLY if it was unblocked before, uvcvideo is loaded again, both cliphist watchers are running, `hyprctl getoption general:col.active_border` is back to 3584e4.
- [ ] Running `lockdown on` twice is a no-op with a log line, and `lockdown off` with no state file still runs `hyprctl reload` + `shell_ipc off` (the game-mode cmd_off contract).

**Risks**

- `modprobe -r uvcvideo` fails if any app holds /dev/video0; the script must log and continue rather than abort under `set -e`.
- Blanket `rfkill block bluetooth` kills a Bluetooth keyboard/mouse — on this desktop that is a real lockout path; consider skipping the block when an input device is on the BT bus.
- Muting PipeWire sources is enforced by the daemon, not the hardware: any app with raw ALSA access, or a restarted wireplumber, can undo it. Say this in the header comment.
- Killing the cliphist watchers means clipboard history silently stops recording; if `off` is never reached (crash) the user loses history until relogin.

### `D2` &middot; Add setLockdown IPC + persistent shield indicator to hyprshell

**Effort:** M &middot; 1-3 h

**Why.** The script currently calls an IPC function that does not exist, and a privacy mode you cannot see at a glance is a privacy mode you will forget to turn off.

**Files**

- `quickshell/hyprshell/shell.qml`
- `quickshell/hyprshell/State.qml`
- `quickshell/hyprshell/QuickSettings.qml`
- `quickshell/hyprshell/Services.qml`
- `quickshell/hyprshell/StatusPill.qml`
- `quickshell/hyprshell/NotificationPopups.qml`

**Steps**

1. State.qml: add `property bool lockdown: false` next to `gameMode`, and `property bool hideNotificationBodies: false`.
2. shell.qml: inside the existing `IpcHandler { target: "shell" }`, add `function setLockdown(on: bool): void { State.lockdown = on; State.doNotDisturb = on; State.hideNotificationBodies = on; State.closePanels(); }` — mirror setGameMode, but do NOT hide the bar (unlike game mode, the whole point is that the indicator stays visible).
3. Services.qml: add `function toggleLockdown() { Quickshell.execDetached(["sh", "-c", "\"$HOME/.config/hypr/scripts/lockdown\" toggle"]) }`, copied from the existing toggleGameMode at Services.qml:165.
4. QuickSettings.qml: add a `QsToggle { icon: "⛨"; label: "Lockdown"; sublabel: State.lockdown ? "On" : "Off"; active: State.lockdown; onClicked: svc.toggleLockdown() }` to the GridLayout of toggles, directly after the Game Mode tile.
5. StatusPill.qml: prepend a shield Text/Rectangle that is `visible: State.lockdown`, `color: Theme.danger`, with a 1px `Theme.danger` border on the pill while on — no new colour tokens, reuse Theme.danger so it stays in the Adwaita palette.
6. NotificationPopups.qml: when `State.hideNotificationBodies` is true, render the app name only and replace the body text with a fixed string (e.g. "Content hidden"); do not merely set opacity, the text must not reach the surface.
7. Bar.qml needs no change (it already keys off State.barVisible); confirm the Theme.danger border does not shift barHeight.
8. Verify with `qs -c hyprshell ipc call shell setLockdown true` from a terminal while the shell runs, then `... false`.

**Done when**

- [ ] `qs -c hyprshell ipc call shell setLockdown true` returns 0 and the shield appears in the status pill on both monitors within a frame.
- [ ] The Lockdown tile in Quick Settings reflects the true state after toggling from the keybind (not just from the tile), because the script drives the IPC.
- [ ] With lockdown on, a `notify-send 'Bank' 'balance 1234'` popup shows no body text.
- [ ] `qs -c hyprshell ipc call shell` lists setLockdown among the callable functions.
- [ ] Turning lockdown off restores notification bodies and clears doNotDisturb.

**Risks**

- State.doNotDisturb is user-settable from the DND tile; setLockdown(false) will clobber a DND the user had set manually before entering lockdown — store and restore the prior value if that matters.
- If the shell restarts while lockdown is on, State.lockdown resets to false and the indicator lies; consider having Bar.qml poll `lockdown status -q` once at startup via a Process.

### `D3` &middot; Create nixos/modules/lockdown.nix with a single root helper and one sudo rule

**Effort:** M &middot; 1-3 h

**Why.** Everything privileged the toggle needs (module unload, unit stop, nft, USB authorization) must be declared once, in Nix, behind a fixed-argv helper — granting `sudo -n nft` NOPASSWD would hand the user's session unrestricted root.

**Files**

- `nixos/modules/lockdown.nix`
- `nixos/configuration.nix`
- `nixos/modules/packages.nix`

**Steps**

1. Create nixos/modules/lockdown.nix and add `./modules/lockdown.nix` to the imports list in nixos/configuration.nix (after ./modules/gaming.nix, so the pattern reads as game-mode's counterpart).
2. Define the helper with `pkgs.writeShellApplication { name = "lockdown-helper"; runtimeInputs = [ pkgs.kmod pkgs.util-linux pkgs.nftables pkgs.systemd ]; text = ...; }` and put it in `environment.systemPackages`. It takes ONE fixed subcommand argument — `net-on|net-off|devices-on|devices-off|usb-lock|usb-unlock|status` — and validates it with a `case` whose default is `exit 2`. No argv is passed through to nft or modprobe.
3. `devices-on` does: `modprobe -r uvcvideo || true`, `systemctl stop geoclue.service iio-sensor-proxy.service ollama.service sshd.service sshd.socket || true`. `devices-off` reverses it. `usb-lock` does `for f in /sys/bus/usb/devices/usb*/authorized_default; do echo 0 > "$f"; done` and `usb-unlock` writes 1.
4. Grant exactly one sudo rule, in the style already used at nixos/modules/gaming.nix:86: `security.sudo.extraRules = [{ users = ["beba"]; commands = [{ command = "/run/current-system/sw/bin/lockdown-helper"; options = ["NOPASSWD"]; }]; }];` — note this must be `lib.mkAfter`-merged or simply a second list entry, since gaming.nix already sets security.sudo.extraRules and NixOS merges lists.
5. Add the runtime dependencies the script needs to `environment.systemPackages` here rather than packages.nix: `tor`, `nftables`, `torsocks`, `util-linux` (provides rfkill), `kmod`, `wireplumber` (provides wpctl), `libnotify`. `tor` and `tor-browser` are already in packages.nix:21,24 — do not duplicate.
6. Ship the nftables ruleset as a file, not a heredoc: `environment.etc."lockdown/lockdown.nft".source = ./lockdown.nft;` so the helper's only nft invocation is the fixed `nft -f /etc/lockdown/lockdown.nft`.
7. In hypr/scripts/lockdown, replace every `sudo -n systemctl ...` / `sudo -n modprobe ...` with `sudo -n lockdown-helper devices-on` / `devices-off`, keeping the `have sudo && sudo -n true` guard game-mode uses so the script still works (degraded) without the module.
8. Verify with `nixos-rebuild dry-build` and `sudo -n lockdown-helper status` as beba.

**Done when**

- [ ] `sudo nixos-rebuild dry-build` completes without evaluation errors and the merged `security.sudo.extraRules` still contains gaming.nix's renice/ollama entries.
- [ ] As beba, `sudo -n lockdown-helper status` runs with no password prompt; `sudo -n lockdown-helper rm -rf /` exits 2 without doing anything.
- [ ] `sudo -n nft list ruleset` still prompts for a password (i.e. no blanket nft NOPASSWD was introduced).
- [ ] `command -v rfkill wpctl nft tor torsocks` all resolve after a rebuild.
- [ ] /etc/lockdown/lockdown.nft exists and `sudo nft -c -f /etc/lockdown/lockdown.nft` reports no syntax error.

**Risks**

- A NOPASSWD helper is still a privilege boundary: if any subcommand ever grows an argument taken from the caller, it becomes a root shell. Keep the case statement argument-free.
- `usb-lock` blocks ALL newly plugged USB devices including a replugged keyboard — document it and keep it behind an explicit `--usb-lock` flag, never the default.
- Stopping sshd inside lockdown will drop a remote session mid-command; guard with a check for an active SSH session ($SSH_CONNECTION) and refuse.
- rfkill's provenance moved between nixpkgs revisions; confirm it comes from util-linux on this snapshot before relying on the path.

### `D4` &middot; Transparent Tor routing with a fail-closed nftables kill-switch

**Effort:** L &middot; a day or more

**Why.** Torsocks and per-app proxies leak by construction — anything that ignores the proxy talks in the clear — so the only shape that can honestly claim 'no plaintext leaves this box' is a default-drop output chain plus a nat redirect into Tor's TransPort/DNSPort.

**Files**

- `nixos/modules/lockdown.nix`
- `nixos/lockdown.nft`
- `hypr/scripts/lockdown`

**Steps**

1. In nixos/modules/lockdown.nix enable the daemon: `services.tor.enable = true; services.tor.client.enable = true;` and set `services.tor.settings` with `TransPort`, `DNSPort` (9040 / 9053), `VirtualAddrNetworkIPv4 = "10.192.0.0/10"`, `AutomapHostsOnResolve = true`. VERIFY the exact submodule shape of TransPort/DNSPort against `man configuration.nix` or search.nixos.org first — it may want `[{ addr = "127.0.0.1"; port = 9040; }]` or a bare int depending on the snapshot; do not guess.
2. Write nixos/lockdown.nft as ONE atomic file so `nft -f` applies filter and nat together or not at all. Shape: `table inet lockdown { chain out { type filter hook output priority filter; policy drop; ct state established,related accept; oifname "lo" accept; meta skuid "tor" accept; } }`, `table ip lockdown_nat { chain out { type nat hook output priority dstnat; meta skuid "tor" return; ip daddr 127.0.0.0/8 return; meta l4proto tcp redirect to :9040; udp dport 53 redirect to :9053; } }`, plus `table ip6 lockdown6 { chain out { type filter hook output priority filter; policy drop; oifname "lo" accept; } }` — Tor's TransPort does not carry IPv6, so v6 must be dropped, not routed.
3. Fail-closed harness in the helper's `net-on`: `nft -c -f /etc/lockdown/lockdown.nft` first (syntax/kernel check), then `nft -f /etc/lockdown/lockdown.nft`, then `systemctl start tor && systemctl is-active tor`. If ANY step returns non-zero, run `nmcli networking off` (or `ip link set <dev> down` for every non-lo link) and `notify-send -u critical`, then exit 1 — never leave the machine online with a partial ruleset.
4. Verify Tor is actually carrying traffic BEFORE declaring the mode on: poll `curl -s --max-time 20 https://check.torproject.org/api/ip` for up to 60 s and require `"IsTor":true`; on failure, tear down to the deny state rather than the direct state.
5. `net-off` deletes only our tables (`nft delete table inet lockdown; nft delete table ip lockdown_nat; nft delete table ip6 lockdown6`), each `|| true`, then `systemctl stop tor` — it must not flush the ruleset, which would wipe NixOS's own firewall.
6. In hypr/scripts/lockdown add `--net=deny|tor|keep` (default `deny`, which only calls `net-off` + relies on the firewall task) and record the chosen mode in the state file so `off` reverses the right thing.
7. Handle the Tor Browser conflict explicitly: refuse to start with `--net=tor` if `pgrep -f tor-browser` matches, with a message saying Tor-over-Tor is not supported; document that in transparent mode you use a normal hardened browser instead.
8. Test end to end: from a second machine or a tty, `dig +short example.com`, `curl https://example.com`, `ping 1.1.1.1`, and `sudo tcpdump -ni <iface> 'port 53 or udp'` — DNS must appear only on loopback:9053, ICMP must be dropped.

**Done when**

- [ ] With `--net=tor` on: `curl -s https://check.torproject.org/api/ip` returns `"IsTor":true`; `ping -c1 1.1.1.1` fails; `dig @8.8.8.8 example.com` times out; `tcpdump -ni <iface> port 53` captures nothing during a browser session.
- [ ] `nft list ruleset` shows the three lockdown tables while on and none of them after off, while NixOS's own nixos-fw table is untouched in both states.
- [ ] Deliberately corrupting /etc/lockdown/lockdown.nft (e.g. a bad chain name) makes `lockdown on --net=tor` end with networking DOWN and a critical notification, never with networking up and unfiltered.
- [ ] Stopping tor while lockdown is on leaves the machine with no connectivity (kill-switch holds), not with direct connectivity.
- [ ] After `lockdown off`, ordinary browsing and DNS work again and `curl check.torproject.org/api/ip` reports IsTor:false.

**Risks**

- `networking.nftables.enable = true` switches NixOS's firewall backend systemwide from iptables-nft to native nftables; if you do NOT enable it, our `nft -f` tables coexist with iptables-nft rules and the interaction order is subtle. Decide deliberately and test both firewall and lockdown after the switch.
- A default-drop output chain locks out an in-progress SSH session and can break `nixos-rebuild` (no substituter access) — always test from a physical console with a known-good rollback generation.
- Tor is not anonymity for logged-in accounts: torifying a session that then opens a signed-in browser deanonymises it immediately. This belongs in the docs task.
- UDP other than DNS is silently dropped: VoIP, WireGuard, NTP, mDNS and some game traffic all break. syncthing (services.syncthing, currently enabled) will fail loudly.
- Tor exit nodes are blocked or captcha-walled by a large fraction of the web; expect the session to feel broken in ways unrelated to the config.

### `D5` &middot; Session hardening: lock, idle, firewall default-deny, optional USB freeze

**Effort:** M &middot; 1-3 h

**Why.** A privacy mode that leaves the screen unlocked for three minutes and port 22 open to the LAN is theatre; these are the cheap, high-certainty wins.

**Files**

- `hypr/hypridle-lockdown.conf`
- `hypr/scripts/lockdown`
- `hypr/hypridle.conf`
- `nixos/modules/lockdown.nix`

**Steps**

1. Create hypr/hypridle-lockdown.conf as a copy of hypr/hypridle.conf with timeouts 60 / 90 / 300 (lock / dpms / suspend) and WITHOUT the `$gm ||` game-mode escape on the lock listener — lockdown must never inhibit locking.
2. In cmd_on, swap the idle profile: `pkill -x hypridle; setsid -f hypridle -c "$HOME/.config/hypr/hypridle-lockdown.conf"`. CONFIRM hypridle accepts `-c` on this version (`hypridle --help`); if it does not, fall back to symlinking ~/.config/hypr/hypridle.conf to the lockdown copy and restarting, and restore the symlink in cmd_off.
3. In cmd_on, lock immediately once the mode is applied: `loginctl lock-session` (hypridle's `lock_cmd` handles the rest); make this suppressible with `--no-lock` for testing.
4. Firewall default-deny in nixos/modules/lockdown.nix: assert the baseline is `networking.firewall.enable = true;` with `allowedTCPPorts = [];` and `allowedUDPPorts = [];`, and note that services.openssh (nixos/modules/services.nix:9) opens 22 by default — the helper's `devices-on` already stops sshd.socket, which is what actually closes it at runtime.
5. Add the optional `--usb-lock` flag calling `sudo -n lockdown-helper usb-lock` / `usb-unlock`, off by default, with a notify-send warning that replugged input devices will not enumerate.
6. Consider `systemctl --user stop xdg-desktop-portal-hyprland.service` to kill ScreenCast, but document honestly that it is dbus-activated and will restart on the next portal request — this reduces casual screen capture, it does not prevent it.
7. In cmd_off, restore: `pkill -x hypridle; setsid -f hypridle` (default config), `usb-unlock` if it was set, restart sshd only if state says it was running.

**Done when**

- [ ] With lockdown on, the session locks after ~60 s idle even though `game-mode status -q` semantics are unrelated; `pgrep -af hypridle` shows the lockdown config path.
- [ ] `ss -ltn` shows no listener reachable from the LAN while on (sshd stopped); `nmap` from another host on the LAN finds no open TCP port.
- [ ] `lockdown on --usb-lock` then plugging a USB stick produces no /dev/sd* and no udisks notification; `lockdown off` restores enumeration.
- [ ] After `lockdown off`, `pgrep -af hypridle` shows the default hypr/hypridle.conf timeouts (180/240/540) and sshd is back only if it was up before.
- [ ] `hypridle -c hypr/hypridle-lockdown.conf --help`-style verification confirms the flag exists, or the symlink fallback is what shipped.

**Risks**

- hypridle's `-c` flag existence is unverified; the symlink fallback mutates a tracked config file, which is ugly in a dotfiles repo and can be left dangling if the script dies before the trap fires.
- Immediate `loginctl lock-session` on toggle makes the mode annoying to test; keep --no-lock.
- Stopping sshd while the toggle was invoked over SSH kills the invocation mid-way and leaves a half-applied state — the EXIT trap from task 1 will then partially undo it over a dead connection.
- USB authorized_default=0 also blocks the internal hub's re-enumeration after a suspend/resume cycle on some boards.

### `D6` &middot; Write the lockdown threat model and 'what this does NOT protect against'

**Effort:** S &middot; under 1 h

**Why.** The single highest-risk failure of this feature is someone believing it is Tails; the honest limits have to ship in the same change as the code, not as a follow-up.

**Files**

- `hypr/scripts/README.md`
- `nixos/modules/lockdown.nix`

**Steps**

1. Write a LOCKDOWN section in hypr/scripts/README.md (create it if absent; the repo already uses per-directory README.md conventions in home-manager/.config/nvim) with three parts: what it does, what it cannot do, and how to verify each claim yourself.
2. 'Does NOT protect against' list, each with one clause of why: persistent disk (ZFS root + persistent /home — everything written during lockdown survives, unlike Tails' amnesia; ZFS snapshots may retain it even after deletion); MAC address (unchanged; the AP and LAN still see the same hardware identity — mention `networking.networkmanager.wifi.macAddress = "random"` as a separate opt-in); browser fingerprint (your normal Firefox/Chromium profile is uniquely identifiable no matter what carries the packets); logged-in sessions and cookies (torifying an authenticated session deanonymises it instantly); firmware/UEFI/microcode and the GPU; kernel and compositor exploits (a local root escape defeats every user-space toggle here); traffic correlation and timing attacks against Tor; the PipeWire mute being a software policy, not a hardware switch; anything already exfiltrated before the toggle.
3. 'Does protect against' list, deliberately narrow: casual local observers of the screen/notifications, apps that opportunistically use the mic/camera, LAN-visible services, clipboard history exposure, ISP-visible plaintext destinations and DNS (only in --net=tor), background sync uploading while you work.
4. Document the exact verification commands so the claims are falsifiable: `curl -s https://check.torproject.org/api/ip`, `sudo tcpdump -ni <iface> port 53`, `wpctl get-volume @DEFAULT_SOURCE@`, `lsmod | grep uvcvideo`, `rfkill list`, `nft list ruleset`, `ss -ltnp`.
5. Add a compressed version of the same warning as a header comment block in hypr/scripts/lockdown and a `# NOTE:` in nixos/modules/lockdown.nix, so nobody reading only the code misses it.
6. Document the recovery path in one paragraph: if the toggle dies mid-apply, `sudo lockdown-helper net-off && sudo lockdown-helper devices-off && rm -f $XDG_RUNTIME_DIR/hypr-lockdown.state && hyprctl reload` returns the machine to normal.
7. Cross-link it from the game-mode docs so the pair reads as two halves of one idea.

**Done when**

- [ ] README.md contains the phrase that this is not Tails and is not amnesic, in the first paragraph, not buried.
- [ ] Every 'does protect' claim has a paste-able verification command next to it.
- [ ] The recovery paragraph, run verbatim from a tty on a machine in lockdown, restores normal networking and devices.
- [ ] `hypr/scripts/lockdown --help` output points at the README path.

**Risks**

- Docs drift the moment the script grows a flag; keep the flag list in one place (the usage() heredoc) and have the README reference it rather than duplicate it.

### `D7` &middot; Add `lockdown check` — a self-audit that verifies the mode is actually on

**Effort:** M &middot; 1-3 h

**Why.** Every layer of this feature fails silently (a mute that wireplumber undid, an nft table that never loaded, a Tor daemon that never bootstrapped), so the toggle needs a subcommand that proves its own claims instead of trusting its state file.

**Files**

- `hypr/scripts/lockdown`

**Steps**

1. Add a `check` subcommand to main()'s case, running a list of named probes and printing `PASS`/`FAIL`/`SKIP` per line, exiting non-zero if any probe FAILs.
2. Probes, each guarded by `have`: mic — `wpctl get-volume @DEFAULT_SOURCE@ | grep -q MUTED`; camera — `! lsmod | grep -q '^uvcvideo'`; bluetooth — `rfkill list bluetooth | grep -q 'Soft blocked: yes'`; clipboard — `[ -z "$(cliphist list 2>/dev/null)" ]`; watchers — `! pgrep -f 'wl-paste .*cliphist' >/dev/null`.
3. Network probes only when state says net_mode=tor: `nft list table inet lockdown >/dev/null 2>&1`; `systemctl is-active tor`; `curl -s --max-time 15 https://check.torproject.org/api/ip | grep -q '"IsTor":true'`; and a negative control — `curl -s --max-time 5 --interface <iface> ...` or `ping -c1 -W2 1.1.1.1` MUST fail.
4. Add a `--json` flag emitting one object so the shell (Services.qml) can consume it later and turn the bar shield red-vs-amber for full-vs-partial lockdown.
5. Have cmd_on call `cmd_check` at the end and downgrade the notification text to 'Lockdown ON (partial — N checks failed)' when anything fails, so the visual state never overstates the protection.
6. Make `check` safe to run when lockdown is off: it then verifies the inverse (nothing blocked) and exits 0, so it doubles as a 'did off actually restore everything' test.
7. Document the probes in the README table from the docs task so each protection claim maps to exactly one probe.

**Done when**

- [ ] `lockdown on && lockdown check` exits 0 with all PASS on a working machine.
- [ ] Manually undoing one protection (`rfkill unblock bluetooth`) makes `lockdown check` exit non-zero and name the bluetooth probe.
- [ ] `lockdown off && lockdown check` exits 0 and reports the inverse state.
- [ ] `lockdown check --json` emits valid JSON (`jq . ` accepts it).
- [ ] The notification after `lockdown on` says 'partial' when a probe fails.

**Risks**

- The Tor probe makes a network request to a third party, which is itself a fingerprintable signal and adds up to 15 s to every toggle — make it opt-out with `--no-net-check`.
- The negative-control ping probe will FAIL-as-expected on networks that block ICMP anyway, giving a false PASS; pair it with a TCP connect attempt to a known-open port.

### Open questions and unverified assumptions

- Exact type of `services.tor.settings.TransPort` / `DNSPort` in this nixpkgs-unstable snapshot — it may be a list of `{ addr; port; }` submodules, a list of ints, or a plain string. I did not verify; check `search.nixos.org/options?query=services.tor.settings` or `nixos-option services.tor.settings` before writing the module. Likewise `services.tor.client.enable` vs the older `services.tor.client.socksListenAddress` spelling.
- Whether `hypridle` accepts `-c <config>` on the version in this snapshot. The symlink-swap fallback in task 5 exists because I could not confirm it.
- Whether `rfkill` is provided by `pkgs.util-linux` here (it has moved between a standalone `rfkill` package and util-linux across nixpkgs revisions).
- Whether this machine has a webcam at all, and if so whether its module is `uvcvideo` — it is a desktop Ryzen box; the camera step may be a permanent SKIP. Run `lsmod | grep -E 'uvcvideo|videodev'` and `ls /dev/video*` first.
- Whether `geoclue2` or `iio-sensor-proxy` are running: neither `services.geoclue2.enable` nor any sensor service appears in nixos/modules/*.nix, so those `systemctl stop` calls are probably no-ops. gammastep (hypr/hyprland/execs.conf) is the only real location consumer and it may already be using a static lat/lon from ~/.config/gammastep/config.ini, which I did not read.
- Interaction between `networking.nftables.enable` and NixOS's default iptables-nft firewall backend, and whether our `nft -f` tables in the `output` hook take precedence over nixos-fw as intended. This needs an actual test, not a reading of the manual.
- Whether `qs -c hyprshell ipc call shell <fn>` exits non-zero when the shell is not running — game-mode already assumes it can be ignored (`|| true`), and I kept that assumption.
- Whether `Super+Shift+L` is free; I only read the first 40 lines of hypr/hyprland/keybinds.conf and did not see the Session section's lock binding. Check before claiming the key, and check hypr/custom/keybinds.conf too since it is sourced last and wins.
- Whether `wpctl status` output format on this WirePlumber version is stable enough to parse source ids out of; `pw-dump | jq` is the robust alternative if it is not.
- Whether the user reaches this machine over SSH at all (services.openssh.enable = true in nixos/modules/services.nix). If yes, the default-drop output chain and the sshd stop are both self-lockout risks and task 5's SSH guard becomes mandatory rather than optional.
- Whether ZFS snapshots/auto-snapshot are configured — this changes how strongly the docs must warn that 'wiped' clipboard and files may still be recoverable. services.zfs.autoScrub is on but I saw no autoSnapshot.

---

## Neovim and the LEARN.md tutorial

### Recommended approach

Keep lazy.nvim; do not migrate to nixvim. This config has ~65 plugins including avante.nvim, mcphub.nvim, lectic and claudecode.nvim — several are not in nixpkgs or lag badly, and a nixvim rewrite would be a multi-day port of a working setup for a reproducibility win the user can get 80% of by simply making the committed lazy-lock.json authoritative (bootstrap.lua currently points `lockfile` at `stdpath("data")`, so the lockfile in the repo is dead paper and pins nothing). The real leverage is elsewhere and it is mostly deletion: `lua/neotex/deprecated/` is 30 files with **zero** inbound requires (verified with grep) and includes a 42 KB nvim-tree.lua; the `<leader>m` "mail" group registers 12 Himalaya commands for a plugin that is not in lazy-lock.json at all, so those keys error on press; `<leader>l` is claimed twice (nvim-lint's `keys = {"<leader>l"}` vs the LaTeX group); two `docs/MAPPINGS.md` headers point at a file that does not exist. That last one is the whole argument for the user's tutorial being machine-generated: this config has already proven it rots hand-written keymap docs. So: prune first (Task 1, one hour, unblocks everything), then build LEARN.md around a generator that walks the which-key spec (Task 2), then the health check that tells you which of the ~15 external binaries conform/nvim-lint/vimtex silently need (Task 3). The main trade-off to accept consciously: dropping mason (Task 4) in favour of nixpkgs-provided language servers is the right call on NixOS — mason ships dynamically-linked prebuilt binaries that do not run without an FHS wrapper — but it means every new language server is a rebuild instead of an `:MasonInstall`.

### `N1` &middot; Delete deprecated/ and the dead Himalaya keymaps

**Effort:** S &middot; under 1 h

**Why.** 30 dead files (~150 KB) with zero inbound requires, plus a 12-entry mail keymap group for a plugin that isn't installed, must go before any tutorial can be truthful about what the config does.

**Files**

- `home-manager/.config/nvim/lua/neotex/deprecated/`
- `home-manager/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/editor/linting.lua`
- `home-manager/.config/nvim/lua/neotex/config/keymaps.lua`
- `home-manager/.config/nvim/lua/neotex/util/notifications.lua`
- `home-manager/.config/nvim/lua/neotex/config/notifications.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/editor/telescope.lua`
- `home-manager/.config/nvim/test.md`

**Steps**

1. Confirm the tree is orphaned: `rg -n 'neotex\.deprecated' --glob '*.lua' home-manager/.config/nvim` must print nothing (it currently returns 0 hits). Then `rm -rf home-manager/.config/nvim/lua/neotex/deprecated` and `rm home-manager/.config/nvim/test.md`.
2. Delete the whole MAIL group in which-key.lua (the `wk.add` block starting at the `-- MAIL group` comment, ~line 547, through the himalaya-list / himalaya-email / mail-compose FileType blocks, ~line 619). None of `HimalayaToggle`, `HimalayaSyncInbox`, `HimalayaWrite` etc. exist — there is no himalaya plugin in lazy-lock.json.
3. Strip remaining himalaya references from the other three files: `rg -n himalaya --glob '*.lua'` hits lua/neotex/config/notifications.lua, lua/neotex/util/notifications.lua and lua/neotex/plugins/editor/telescope.lua — remove the dead notification categories and telescope picker entries.
4. Fix the `<leader>l` collision: linting.lua declares `keys = { { "<leader>l", function() require('lint').try_lint() end } }` which lazy.nvim registers globally, while which-key.lua uses `<leader>l` as the buffer-local LaTeX group (line 334). Move linting to `<leader>il` inside the existing `<leader>i` (lsp) group and delete the `keys` table from the lazy spec.
5. Delete the two stale doc pointers — the `📖 COMPLETE DOCUMENTATION: See docs/MAPPINGS.md` headers at the top of lua/neotex/config/keymaps.lua and lua/neotex/plugins/editor/which-key.lua. That file does not exist anywhere in the repo; Task 2 replaces it with LEARN.md.
6. Launch once with `nvim --headless '+lua vim.cmd("messages")' +qa` and confirm no load errors, then open a .tex buffer and press `<leader>l` to confirm the LaTeX group appears rather than the linter firing.

**Done when**

- [ ] `rg -ni 'deprecated|himalaya' --glob '*.lua' home-manager/.config/nvim` returns zero matches
- [ ] `test -d home-manager/.config/nvim/lua/neotex/deprecated` is false
- [ ] `nvim --headless +qa` exits 0 with no notification output
- [ ] In a .tex buffer `<leader>l` opens the LaTeX which-key group; in a .lua buffer `<leader>il` runs the linter
- [ ] Config directory shrinks by roughly 150 KB (`du -sh` before/after)

**Risks**

- lua/neotex/deprecated/after/ may contain ftplugin files that Neovim picks up via runtimepath rather than via require — check `ls lua/neotex/deprecated/after/` before deleting, and confirm the rtp does not include that subtree
- Some notification category constants may be referenced by string key elsewhere; grep for the exact category names, not just 'himalaya', before deleting them

### `N2` &middot; Write LEARN.md with a :Learn command and a GENERATED keymap reference

**Effort:** L &middot; a day or more

**Why.** The user wants one file explaining every feature, and this config has already proven it rots hand-written keymap docs (two headers cite a docs/MAPPINGS.md that never existed).

**Files**

- `home-manager/.config/nvim/LEARN.md`
- `home-manager/.config/nvim/lua/neotex/util/keymap_export.lua`
- `home-manager/.config/nvim/lua/neotex/util/learn.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- `home-manager/.config/nvim/lua/neotex/config/init.lua`

**Steps**

1. Make the which-key spec introspectable first: in which-key.lua, hoist every `wk.add({...})` argument into a module-level table (`M.spec = { global = {...}, filetype = { tex = {...}, ipynb = {...}, lean = {...} } }`) and have `config` iterate `M.spec` calling `wk.add`. Behaviour is identical; the difference is that a second consumer can now read the same table. Do NOT try to read which-key's internal tree — `require('which-key.state')` and `require('which-key.tree')` are private and change between v3 point releases.
2. Write lua/neotex/util/keymap_export.lua with `M.markdown()` returning a string and `M.write(path)` writing it. It requires `neotex.plugins.editor.which-key`, walks `M.spec`, and emits one markdown table per group: `| Key | Action | Scope |`, where group entries (`group = "find"`) become `###` headings, `desc` becomes Action, and a `buffer = 0` entry or a `cond` function becomes Scope = the filetype rather than `global`.
3. In the same module add a second pass over real mappings that which-key never sees: for mode in `{'n','v','x','i','t'}` call `vim.api.nvim_get_keymap(mode)`, keep entries with a non-empty `desc`, and emit a `## Non-leader keymaps` table (this catches `<C-p>`, `<C-t>`, `<C-s>`, `<Tab>`/`<S-Tab>`, `Y`, `E`, `m` from config/keymaps.lua, which are documented today only in an ASCII comment block).
4. Bracket the generated region in LEARN.md with `<!-- BEGIN GENERATED KEYMAPS -->` / `<!-- END GENERATED KEYMAPS -->` and have `M.write` replace only what is between the markers, so the prose above survives regeneration. Add a `:LearnRegen` user command calling it, and run it from CI/rebuild via `nvim --headless "+lua require('neotex.util.keymap_export').write()" +qa`.
5. Hand-write the prose sections above the generated block, as a progressive tutorial not an API dump: (1) Day 1 survival — modes, `<Space>` as leader, `timeoutlen=100` means which-key pops almost instantly, `<leader>w` write all / `<leader>q` save+quit / `<leader>d` save+delete buffer; (2) Discovery — press `<Space>` and wait, `<leader>fk` for the keymap picker, `:Learn`; (3) Navigation — telescope (`<C-p>` files, `<leader>ff` grep, `<leader>fb` buffers, `<leader>u` undo tree, telescope-bibtex `<leader>fc` citations), treesitter text objects, neo-tree `<leader>e`, bufferline `<Tab>`/`<S-Tab>`; (4) Editing — nvim-surround `<leader>s`, autopairs, autolist, yanky `<leader>y` + `<leader>fy` history; (5) LSP + blink.cmp — `<leader>i` group, what completion sources are live; (6) Git — gitsigns hunks, git-conflict, `<leader>g`; (7) AI — the real bindings: `<leader>ha` AvanteAsk, `<leader>hc` AvanteChat, `<leader>ht` toggle, `<leader>hs` edit selection, `<leader>ho` ClaudeCode, `<leader>hb` add buffer, `<leader>hr` add dir, `<leader>hx` MCPHub, `<leader>hm` model, `<leader>hp` prompt, `<leader>hl` Lectic on file, `<leader>hn` new lectic file, `<leader>hL` submit selection — and explain that avante_mcp.with_mcp() boots MCPHub before each Avante command; (8) LaTeX (`<leader>l` vimtex: lc compile, le errors, lv view, la annotate, lb bibexport), Jupyter (`<leader>j` notebook-navigator + iron.nvim REPL), Lean (`<leader>al` infoview); (9) Sessions `<leader>S`; (10) the generated reference.
6. Write lua/neotex/util/learn.lua: `M.open()` reads `vim.fn.stdpath('config')..'/LEARN.md'` into a scratch buffer (`nvim_create_buf(false, true)`), sets `bo.filetype = 'markdown'`, `bo.modifiable = false`, opens it with `nvim_open_win` at 0.85x0.85 with `border = 'rounded'`, and maps buffer-local `q` and `<Esc>` to close. Register `vim.api.nvim_create_user_command('Learn', M.open, {})` from config/init.lua, and add `{ "<leader>?", "<cmd>Learn<CR>", desc = "learn this config", icon = "󰋗" }` to the which-key spec — a single discoverable key, hidden until you press leader, which is exactly the user's stated aesthetic.

**Done when**

- [ ] `nvim --headless "+lua require('neotex.util.keymap_export').write()" +qa` followed immediately by a second run produces a byte-identical LEARN.md (idempotent)
- [ ] Adding a throwaway entry to the which-key spec and regenerating makes it appear in the table; removing it makes it disappear — verified once by hand
- [ ] Every `<leader>` group visible in `:WhichKey` has a corresponding `###` section in the generated block, and no section exists for a group that was deleted
- [ ] `:Learn` opens a floating window rendering LEARN.md, `q` closes it, and the underlying buffer list is unchanged afterwards
- [ ] The prose sections above the marker survive a regeneration unmodified (`git diff` touches only lines between the markers)

**Risks**

- render-markdown.nvim may not attach to a scratch buffer with no file name — if the markdown renders raw, either give the buffer a real name via `nvim_buf_set_name` or accept plain text with `conceallevel=2` and a `set wrap linebreak`
- Hoisting the which-key spec into `M.spec` changes a 763-line file; do it mechanically and diff `:WhichKey` output before/after, ideally after Task 6 has split the file
- Filetype-conditional entries use `cond = function() ... end` closures, which the generator cannot evaluate — read the intent from the sibling `pattern` in the FileType autocmd instead, or add an explicit `ft = 'tex'` field to each spec entry while hoisting

### `N3` &middot; Add a :checkhealth neotex module for external dependencies

**Effort:** M &middot; 1-3 h

**Why.** conform, nvim-lint, vimtex, telescope and the AI plugins all silently no-op when their external binary is missing, and there is currently no way to find out which of ~15 tools are absent.

**Files**

- `home-manager/.config/nvim/lua/neotex/health.lua`
- `home-manager/.config/nvim/lua/neotex/util/keymap_export.lua`

**Steps**

1. Create lua/neotex/health.lua returning `{ check = function() ... end }` — `:checkhealth neotex` resolves `lua/neotex/health.lua` on the runtimepath automatically, no registration needed.
2. Section 'core': `vim.health.start('neotex: core')`, assert `vim.fn.has('nvim-0.11') == 1` (Task 4 depends on it), report `vim.version()`, and report whether `vim.g.mapleader == ' '`.
3. Section 'external tools': loop a table of `{ bin, why }` pairs calling `vim.fn.executable(bin) == 1` → `vim.health.ok` / `vim.health.warn` with the why-string. Cover: rg and fd (telescope live_grep and find_files), git and lazygit, node and npm (mcp-hub, markdown-preview), latexmk / texlab / biber / latexindent (vimtex + conform tex), stylua, prettier, eslint_d, black, isort, alejandra, shfmt, clang_format — every formatter named in plugins/editor/formatting.lua.
4. Section 'providers': check `vim.g.python3_host_prog` is set and executable (init.lua probes ~/.venvs/nvim, /run/current-system/sw/bin, /usr/bin), then verify pynvim with `vim.fn.system({vim.g.python3_host_prog, '-c', 'import pynvim'})` and check `v:shell_error`. Warn on each of perl/ruby/node providers that is enabled but unused.
5. Section 'plugins': `local st = require('lazy').stats()` — report `st.count` total and list any spec whose `_.loaded == nil` that was expected at startup; separately check `vim.fn.exists(':MCPHub')` and `vim.g.mcp_hub_path` since init.lua has a whole manual-registration fallback path for MCPHub that indicates this has failed before.
6. Section 'treesitter': compare `require('nvim-treesitter.info').installed_parsers()` against the `ensure_installed` list in plugins/editor/treesitter.lua and warn per missing parser.
7. Add `<leader>ah` (or fold into the `<leader>i` group) → `<cmd>checkhealth neotex<CR>`, and mention `:checkhealth neotex` in the LEARN.md Day-1 section.

**Done when**

- [ ] `nvim --headless '+checkhealth neotex' '+w! /tmp/health.txt' +qa` writes a report containing all six section headers and exits 0
- [ ] Temporarily renaming `rg` off PATH turns the telescope line from OK to WARN with an actionable message
- [ ] Every formatter listed in plugins/editor/formatting.lua `formatters_by_ft` appears in the external-tools table (cross-check by grep, not by eye)

**Risks**

- `require('nvim-treesitter.info')` moved in the nvim-treesitter `main` branch rewrite — if the config is pinned to `master` this works; guard it in pcall either way
- Shelling out to python for the pynvim import adds ~100 ms to checkhealth; acceptable since it is on demand only

### `N4` &middot; Modernise LSP to vim.lsp.config/enable and drop mason on NixOS

**Effort:** M &middot; 1-3 h

**Why.** lspconfig.lua is a hand-rolled FileType autocmd with an if/elseif chain for three servers and an empty on_attach, so no LSP keymaps are ever bound — and mason downloads dynamically-linked binaries that do not run on NixOS.

**Files**

- `home-manager/.config/nvim/lua/neotex/plugins/lsp/lspconfig.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/lsp/mason.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/lsp/init.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- `home-manager/home.nix`

**Steps**

1. Verify the Neovim version first — `nvim --version` — because `vim.lsp.config()` / `vim.lsp.enable()` require 0.11+. If the machine is on 0.10, stop and do only the on_attach half of this task.
2. Rewrite lspconfig.lua: set shared capabilities once with `vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities()) })`, then per-server `vim.lsp.config('lua_ls', { settings = { Lua = { diagnostics = { globals = {'vim'} }, workspace = { library = vim.api.nvim_get_runtime_file('', true) } } } })` and the existing texlab settings block (build.onSave, chktex off, diagnosticsDelay 300), then a single `vim.lsp.enable({ 'lua_ls', 'texlab', 'pyright', 'nixd' })`. nvim-lspconfig 2.x ships `lsp/<name>.lua` files that supply filetypes/root markers, so the manual filetype→server table and the FileType autocmd both disappear.
3. Replace the empty `on_attach` with an `LspAttach` autocmd that binds buffer-local keys and registers them with which-key under the existing `<leader>i` group: definition `vim.lsp.buf.definition`, references, rename, code_action, hover, `vim.diagnostic.open_float`, and `vim.lsp.buf.format`. Note Neovim 0.11 already provides `grn`/`gra`/`grr`/`gri` and `K` by default — bind only what those defaults miss, and document both sets in LEARN.md.
4. Delete plugins/lsp/mason.lua (mason.nvim, mason-lspconfig.nvim, mason-tool-installer.nvim) and remove its require from plugins/lsp/init.lua. Mason's prebuilt binaries need an FHS environment; on NixOS they fail with a missing dynamic loader.
5. Add the servers and tools to the home-manager package list instead: `lua-language-server`, `texlab`, `pyright`, `nixd`, `stylua`, `alejandra`, `shfmt`, `black`, `isort`, `ripgrep`, `fd`, `lazygit` in home-manager/home.nix `home.packages`. Rebuild, then run `:checkhealth neotex` from Task 3 to confirm each one resolves.
6. Keep `vim.diagnostic.config` as-is (the signs table and `update_in_insert = false` are good) but add `virtual_text = { current_line = true }` or `virtual_lines` — a 0.11 feature that fits the 'there but not shouting' aesthetic better than always-on virtual text.

**Done when**

- [ ] Opening a .lua file attaches lua_ls (`:lua =vim.lsp.get_clients()[1].name`) with no FileType-autocmd indirection
- [ ] `grep -rn 'lspconfig\[' home-manager/.config/nvim` returns nothing
- [ ] `:Lazy` lists no mason plugins and `~/.local/share/nvim/mason` can be deleted without breaking anything
- [ ] `<leader>i` in a code buffer shows working rename/references/code-action entries, and pressing rename actually renames
- [ ] `:checkhealth neotex` reports all four language servers present

**Risks**

- I have not confirmed the installed Neovim version — `nvim` was not on PATH in this sandbox — so the vim.lsp.config path is contingent on 0.11+
- `vim.lsp.config('*', ...)` wildcard support and nvim-lspconfig's `lsp/` directory both arrived in specific releases; if the pinned lspconfig commit in lazy-lock.json predates that, either bump it or keep per-server capabilities
- pyright from nixpkgs vs mason may resolve a different Python environment; verify against the venv that vim.g.python3_host_prog points at
- nixd vs nil_ls is a real choice — nixd gives flake-aware completion but needs an expression to evaluate options

### `N5` &middot; Set a startup-time budget and cut eager loads

**Effort:** M &middot; 1-3 h

**Why.** util/init.lua eagerly requires a 53 KB optimize.lua on every start, lazy.nvim's update checker is enabled, and no unused providers are disabled — all measurable, all avoidable.

**Files**

- `home-manager/.config/nvim/lua/neotex/bootstrap.lua`
- `home-manager/.config/nvim/lua/neotex/util/init.lua`
- `home-manager/.config/nvim/lua/neotex/config/options.lua`
- `home-manager/.config/nvim/init.lua`

**Steps**

1. Take a baseline you can compare against: `nvim --startuptime /tmp/st-before.log +q && tail -1 /tmp/st-before.log`, and open `:Lazy profile` to record the three slowest plugin load times. Write both numbers into the task before changing anything.
2. Stop loading optimize.lua at startup: in lua/neotex/util/init.lua remove `"optimize"` from the `_load_submodules` list and instead expose it behind a user command — `vim.api.nvim_create_user_command('Optimize', function() require('neotex.util.optimize').report() end, {})`. Same for `lectic_extras` if nothing needs it before a lectic buffer exists. Note that `M.setup` also flattens every function of every submodule into the `neotex.util` namespace, which forces all of them to be resolved eagerly — the flattening is the cost, not the modules.
3. Turn off the lazy.nvim update checker in both `require('lazy').setup` option tables in bootstrap.lua: `checker = { enabled = false }`. It currently runs on every launch. Keep `change_detection.notify = false`.
4. Disable unused providers in config/options.lua next to the existing `vim.g.loaded_*` block: `vim.g.loaded_perl_provider = 0`, `vim.g.loaded_ruby_provider = 0`. Leave the node provider alone until you confirm markdown-preview.nvim and mcphub.nvim do not use it (they ship their own node processes, but verify with `:checkhealth provider` before flipping it).
5. Add `performance.rtp.disabled_plugins = { 'gzip', 'tarPlugin', 'zipPlugin', 'tohtml', 'tutor', 'netrwPlugin', 'matchit', 'matchparen', 'rplugin', 'spellfile' }` to the lazy setup opts — options.lua sets the `vim.g.loaded_*` flags but lazy's rtp reset is the mechanism that actually keeps them off the runtimepath.
6. Audit the eager specs: `rg -n 'event = \{? ?"BufReadPre' home-manager/.config/nvim/lua/neotex/plugins` — conform.nvim, nvim-lint and nvim-lspconfig all load on BufReadPre, which for a config whose purpose is editing files is effectively eager. Move conform to `cmd = 'ConformInfo'` plus `keys` plus a `BufWritePre` autocmd that requires it lazily, and nvim-lint to a `BufWritePost` autocmd.
7. Re-measure with `nvim --startuptime /tmp/st-after.log +q` and record the delta in the commit message.

**Done when**

- [ ] `nvim --startuptime` total for `nvim` with no file drops measurably versus the recorded baseline; set the target at under 120 ms and state the actual number
- [ ] `:Lazy profile` shows optimize.lua no longer in the startup path, and `:Optimize` still opens its floating report
- [ ] `nvim --headless '+lua print(vim.g.loaded_perl_provider)' +qa` prints 0
- [ ] No network access at startup (verify the checker is off by watching `:Lazy` no longer showing pending-update counts on launch)

**Risks**

- util/init.lua's function-flattening means other modules may call `require('neotex.util').some_optimize_function()` — grep for each exported name of optimize.lua before removing it from the submodule list
- Moving conform off BufReadPre can break `vim.g.autoformat`-driven format-on-save if the autocmd is registered inside conform's own config function; re-test saving a .lua and a .py file
- optimize.lua uses the deprecated `vim.api.nvim_buf_set_option`, which will warn or fail on newer Neovim — fix it to `vim.bo[buf].modifiable` while you are in there

### `N6` &middot; Split which-key.lua into per-group modules

**Effort:** M &middot; 1-3 h

**Why.** 763 lines / 47 KB in one file, roughly 200 of them a hand-maintained ASCII table that is already wrong, makes both editing and machine-generation harder than they need to be.

**Files**

- `home-manager/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/init.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/actions.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/find.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/git.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/ai.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/lsp.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/latex.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/jupyter.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/text.lua`
- `home-manager/.config/nvim/lua/neotex/config/whichkey/misc.lua`

**Steps**

1. Capture a before-snapshot to diff against: `nvim --headless "+lua local o={} for _,m in ipairs(vim.api.nvim_get_keymap('n')) do if m.lhs:match('^ ') then o[#o+1]=m.lhs..'\t'..(m.desc or '') end end table.sort(o) vim.fn.writefile(o,'/tmp/wk-before.txt')" +qa`.
2. Create lua/neotex/config/whichkey/ and give each module the same shape: `return { global = { ...specs }, filetype = { tex = { ...specs } } }` — one file per top-level group, mirroring the existing `-- FIND group` / `-- GIT group` comment sections which already mark clean boundaries.
3. Write whichkey/init.lua to require each module, concatenate `global` into one list and call `wk.add` once, then register one FileType autocmd per filetype key that calls `wk.add` with `buffer = 0` entries — replacing the current pattern of many separate `wk.add` calls and inline autocmds.
4. Reduce plugins/editor/which-key.lua to the lazy spec only: the `folke/which-key.nvim` entry, its `opts` (preset, delay, icon config), and `config = function() require('neotex.config.whichkey').setup() end`. Target under 60 lines.
5. Delete the ~200-line ASCII reference comment block at the top of the old file. Its content is Task 2's job now; keeping both guarantees they diverge again.
6. Re-run the snapshot command into /tmp/wk-after.txt and `diff` the two — it must be empty. Then regenerate LEARN.md and confirm that diff is empty too.

**Done when**

- [ ] `diff /tmp/wk-before.txt /tmp/wk-after.txt` is empty
- [ ] `wc -l lua/neotex/plugins/editor/which-key.lua` is under 60
- [ ] No file in lua/neotex/config/whichkey/ exceeds 120 lines
- [ ] `:WhichKey` shows the identical set of groups and icons as before the split
- [ ] Regenerating LEARN.md after the split produces no diff versus before the split

**Risks**

- Several groups use `group = function() ... end` plus `cond = function() ... end` for filetype-conditional display — these closures must move verbatim, and the ordering of `wk.add` calls matters when two specs claim the same prefix
- If Task 2 is done first, the hoisting work overlaps; do Task 6 before Task 2's hoisting step, or accept doing the hoist twice

### `N7` &middot; Make the committed lazy-lock.json actually authoritative

**Effort:** M &middot; 1-3 h

**Why.** bootstrap.lua sets `lockfile = vim.fn.stdpath('data')..'/lazy-lock.json'`, so the lockfile checked into the repo pins nothing and the config is not reproducible across a rebuild or a second machine.

**Files**

- `home-manager/.config/nvim/lua/neotex/bootstrap.lua`
- `home-manager/.config/nvim/lazy-lock.json`
- `home-manager/home.nix`
- `nixos/modules/packages.nix`

**Steps**

1. Decide the config-directory strategy first. Today `home.file."nvim".source = ./.config/nvim` (home.nix line 185) copies the config into the Nix store read-only, so `:Lazy sync` cannot write the lockfile back into the repo even if the path were right. Switch to `home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "/home/beba/Dokumente/hyprland/nix-dot/home-manager/.config/nvim";` so the live config is the repo working tree and lockfile writes land in git.
2. Remove both `lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json"` lines from bootstrap.lua (they appear in both the legacy and the current `require('lazy').setup` option tables). lazy.nvim's default is `stdpath('config')/lazy-lock.json`, which is now the repo file.
3. Delete the `validate_lockfile()` step and its entry in `M.init`'s step list — it rewrites a malformed lockfile into a placeholder, which is precisely the behaviour you do not want once the lockfile is authoritative. Let a corrupt lockfile be a visible error instead.
4. Run `:Lazy restore` once to pin the installed plugin set to the committed revisions, then `git diff lazy-lock.json` to see what actually moved.
5. Deduplicate the neovim package: it is installed both in home-manager/home.nix `home.packages` (line 31) and nixos/modules/packages.nix (line 13). Keep the home-manager one (it travels with the config) and drop the system one, or vice versa — but pick one.
6. Document the resulting workflow in LEARN.md: plugin updates are `:Lazy update` followed by committing lazy-lock.json; system tools are a nixos-rebuild. Explicitly note this is a two-source-of-truth setup and that is the accepted trade-off.

**Done when**

- [ ] `readlink ~/.config/nvim` resolves into the repo working tree, not /nix/store
- [ ] After `:Lazy update`, `git status` in the repo shows lazy-lock.json modified
- [ ] A fresh `rm -rf ~/.local/share/nvim/lazy && nvim` installs exactly the revisions in the committed lockfile (spot-check three plugins with `git -C ~/.local/share/nvim/lazy/<plugin> rev-parse HEAD`)
- [ ] `which -a nvim` returns a single path

**Risks**

- mkOutOfStoreSymlink hardcodes an absolute path, so the flake stops being portable to another user or checkout location — acceptable for a personal dotfiles repo, but it is a real regression in purity
- Editing the config live means a syntax error breaks Neovim immediately with no rebuild gate; that is usually what people want from a Neovim config, but it is a change in failure mode
- The nix-store copy currently in place may have diverged from the repo; diff them before switching

### `N8` &middot; Consolidate the completion stack onto blink.cmp

**Effort:** M &middot; 1-3 h

**Why.** lazy-lock.json pins nvim-cmp, cmp-nvim-lsp, cmp_luasnip, cmp-vimtex AND blink.cmp with blink.compat — two full completion engines, of which one should be dead weight.

**Files**

- `home-manager/.config/nvim/lua/neotex/plugins/lsp/blink-cmp.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/text/vimtex.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/text/lean.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/tools/mini.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/ai/avante.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/tools/autolist/util/integration.lua`

**Steps**

1. Find every owner: `rg -n 'nvim-cmp|cmp-nvim-lsp|cmp_luasnip|cmp-vimtex|blink\.compat|require\(.cmp.\)' home-manager/.config/nvim/lua` — current hits are avante.lua, blink-cmp.lua, lean.lua, mini.lua and autolist/util/integration.lua. Determine for each whether it lists nvim-cmp as a lazy dependency (harmless to drop) or actually calls `require('cmp')` (must be ported).
2. For each real `require('cmp')` call site, replace with the blink equivalent: `require('blink.cmp').is_visible()` / `.hide()` / `.get_lsp_capabilities()`. avante.nvim and lean.nvim both declare nvim-cmp as an optional dependency and work fine with blink when it is absent — remove them from the `dependencies` lists rather than porting anything.
3. Keep exactly one bridge if cmp-vimtex is genuinely needed for `\cite{`/`\ref{}` completion: register it in blink-cmp.lua as `sources.providers.vimtex = { name = 'vimtex', module = 'blink.compat.source' }` and add `'vimtex'` to `sources.default` for the tex filetype only. Otherwise drop cmp-vimtex too and rely on texlab's LSP completion, which already handles citations from the .bib files vimtex knows about.
4. Remove the now-unused specs so lazy prunes them, then `:Lazy clean`.
5. Test the two paths that matter: in a .lua file confirm LSP + snippet completion still shows, and in a .tex file with a bibliography confirm typing `\cite{` still offers citation candidates.
6. Record in LEARN.md which completion engine is authoritative and what the keys are — this is exactly the kind of ambiguity a reader of the config would otherwise have to reverse-engineer.

**Done when**

- [ ] `:Lazy` lists blink.cmp and no nvim-cmp / cmp-* plugins (or only blink.compat + cmp-vimtex if the bridge is kept, with a comment saying why)
- [ ] Completion works in lua, python, nix and tex buffers after the change
- [ ] `\cite{` in a .tex file with a .bib still produces candidates
- [ ] lazy-lock.json shrinks by the removed entries and is committed

**Risks**

- cmp-vimtex has no blink-native equivalent, so dropping it may lose the pretty citation formatting even if texlab covers the raw keys — test before deciding
- avante.nvim's own input UI may hard-require cmp in some code paths; if it does, keep nvim-cmp but confine it to avante's dependency list and document that
- This is the task most likely to produce a subtle regression noticed days later; do it last and on its own commit

### `N9` &middot; Gate formatters and linters on binary availability

**Effort:** S &middot; under 1 h

**Why.** conform.nvim names 12 external formatters and nvim-lint more, and when one is missing the format simply does nothing with no message — the worst possible failure mode.

**Files**

- `home-manager/.config/nvim/lua/neotex/plugins/editor/formatting.lua`
- `home-manager/.config/nvim/lua/neotex/plugins/editor/linting.lua`
- `home-manager/home.nix`

**Steps**

1. List what formatting.lua actually demands: stylua, eslint_d, prettier, isort, black, clang_format, shfmt, alejandra, latexindent. Check each with `vim.fn.executable()` on the target machine (or via Task 3's health check) and note which are absent.
2. Add every one you intend to keep to `home.packages` in home-manager/home.nix. nixpkgs attribute names to verify before committing: `stylua`, `alejandra`, `shfmt`, `black`, `isort`, `clang-tools` (provides clang-format), `nodePackages.prettier`, and latexindent which ships inside the TeX Live distribution rather than standalone.
3. Prune what you will not install rather than leaving it declared — if there is no C/C++ or Vue work on this machine, delete those `formatters_by_ft` entries. A shorter honest list beats a long aspirational one.
4. Make failure visible: set conform's `notify_on_error = true` and add `format_on_save = function(bufnr) if not vim.g.autoformat then return end return { timeout_ms = 1000, lsp_format = 'fallback' } end`, so a missing formatter falls back to LSP formatting instead of silently doing nothing.
5. Do the same audit for linting.lua — it already has an `is_executable` helper, so extend it to emit a one-time `vim.notify` at WARN level naming the missing linter instead of quietly skipping.
6. Verify with the Task 3 health check that every remaining declared tool resolves.

**Done when**

- [ ] `:ConformInfo` in a .lua, .py, .nix and .md buffer shows the formatter as available, not 'not found'
- [ ] Saving a .nix file reformats it with alejandra; saving a .py file runs isort then black
- [ ] Every tool named in formatters_by_ft appears in home.packages, and `:checkhealth neotex` reports zero missing formatters
- [ ] Deliberately removing one from PATH now produces a visible notification on save rather than silence

**Risks**

- `prettier` may need to be `nodePackages.prettier` and `eslint_d` may not exist as a top-level nixpkgs attribute — verify both with `nix search nixpkgs` before editing home.nix
- latexindent needs Perl modules that the minimal TeX Live sets do not pull in; if it fails, texlab's own formatting is the fallback
- alejandra vs nixfmt-rfc-style is a style choice — alejandra is what the config already declares, so keep it unless the user prefers otherwise

### Open questions and unverified assumptions

- Neovim version on the target machine is unverified — `nvim --version` produced no output in this sandbox, so `vim.lsp.config()` / `vim.lsp.enable()` (Task 4) and `vim.diagnostic.config{virtual_lines}` are contingent on 0.11+. Check before starting Task 4.
- which-key.nvim v3 has no documented public API for enumerating registered mappings. `require('which-key.state')` and `require('which-key.tree')` exist but are internal and unstable. Task 2's generator therefore reads the config's own spec table rather than which-key's — do not switch it to the internal API even if it looks convenient.
- nixpkgs attribute names I did not verify: `eslint_d`, `prettier` vs `nodePackages.prettier`, `clang-tools` vs `clang_format`, `nixd` vs `nil`, and whether `latexindent` is standalone or only inside texlive. Run `nix search nixpkgs <name>` for each before editing home.nix.
- Whether mason is actually failing on this machine or has been working via some FHS wrapper — I inferred the NixOS incompatibility from the platform, I did not observe a failure. Confirm with `:Mason` and try installing one package before deleting the module.
- Whether `lua/neotex/deprecated/after/` is on the runtimepath. Grep found zero `require` references to the deprecated tree, but an `after/` directory can be sourced by path rather than by require. `ls` it before `rm -rf`.
- Whether markdown-preview.nvim or mcphub.nvim use Neovim's node provider (`vim.g.loaded_node_provider`) as opposed to spawning their own node. Run `:checkhealth provider` before disabling it in Task 5.
- Whether render-markdown.nvim attaches to an unnamed scratch buffer, which decides whether `:Learn` renders prettily or as plain markdown text (Task 2).
- The current startup time is unmeasured — Task 5's 120 ms target is a proposal, not a measured delta. Take the `nvim --startuptime` baseline first and adjust.
- avante.nvim's dependency on nvim-cmp may be hard rather than optional in the pinned revision; Task 8 assumes optional. Test in a scratch checkout before pruning.

