# hyprshell (Quickshell)

GNOME-like top bar, app menu, quick settings and notification center for Hyprland.

Run: `qs -c hyprshell` (config dir `~/.config/quickshell/hyprshell`, entry `shell.qml`).

IPC (bound to Super+I / N / A / B / G / Space in hypr/hyprland/binds.conf):

    qs -c hyprshell ipc call shell toggleQuickSettings
    qs -c hyprshell ipc call shell toggleNotifications
    qs -c hyprshell ipc call shell toggleAppMenu
    qs -c hyprshell ipc call shell toggleBar
    qs -c hyprshell ipc call shell setGameMode true|false
    qs -c hyprshell ipc call shell toggleLauncher

Files: shell.qml (root + IPC), State.qml / Theme.qml (singletons), Bar.qml, Workspaces.qml,
AppMenu.qml, Clock.qml, StatusPill.qml, QuickSettings.qml, NotificationCenter.qml,
NotificationPopups.qml, Osd.qml, Commands.qml, CommandPalette.qml.
Layer namespaces: hyprshell-bar, hyprshell-panel, hyprshell-osd, hyprshell-notif.

## The command store

`Commands.qml` is the single model behind the command palette. It merges two
sources into one list:

- **live bindings** from `hyprctl binds -j` — the source of truth for what keys
  actually do right now, so the list cannot drift from the Hyprland config;
- **the store**, `~/.config/hyprshell/commands.json` — the user's own commands,
  plus name and shortcut overrides for the discovered bindings.

The store lives under `~/.config/hyprshell/`, *not* in this repo: it is per-machine
user data, and the shell writes to it (F2 rename), so it is not something to track.
The file is created on first write; if it is missing everything still works and the
palette simply shows the bindings as Hyprland spells them.

### Why JSON and not TOML

QML has `JSON.parse` in the box. Reading TOML from QML would mean shipping a TOML
parser as QML/JS source and maintaining it, which is a dependency in all but name —
and Quickshell's own `FileView` already has a JSON adapter. JSON it is.

### Schema

```json
{
  "version": 1,
  "commands": [
    {
      "id": "user.htop",
      "name": "System monitor",
      "exec": { "type": "shell", "command": "kitty -e htop" },
      "shortcut": null,
      "source": "user"
    },
    {
      "id": "hypr:64|i",
      "name": "Quick Settings",
      "source": "hyprland"
    }
  ]
}
```

| Field | Required | Meaning |
|-------|----------|---------|
| `id` | yes | Stable identifier. For a discovered binding it is `hypr:<modmask>\|<key>` with the key lower-cased (`hypr:64\|i` is Super+I); for your own commands, anything you like — a dotted name such as `user.htop` reads well. |
| | | One combo can carry several dispatchers (this config binds Alt+Tab to both `cyclenext` and `bringactivetotop`), so the second and later bindings on a combo get a `#2`, `#3` suffix — `hypr:8\|tab` and `hypr:8\|tab#2`. Without that they would share an id and `run()` would pick the wrong one. |
| `name` | yes | What the action *does*, in human words — not how it is spelled technically. This is what the palette shows. |
| `exec` | see below | What to run. |
| `shortcut` | no | `"Super+Shift+P"`, or `null` for explicitly unbound. **Omitting the field is not the same as `null`**: omitted means "inherit whatever Hyprland has bound", `null` means "show this as unbound". |
| `source` | no, defaults `"user"` | `"user"` = a command that exists only in this file. `"hyprland"` = an override for a discovered binding. |

`exec` types:

| Type | Fields | Runs |
|------|--------|------|
| `hyprctl` | `dispatcher` (required), `arg` | `hyprctl dispatch <dispatcher> <arg>` |
| `shell` | `command` (required) | `sh -c <command>` |
| `dbus` | reserved | not implemented — accepted and preserved, `run()` warns and does nothing |
| `menu` | reserved, for the global-menu work | same |

`exec` is required for `source: "user"` entries. A `source: "hyprland"` entry may
omit it and inherit the binding's own dispatcher and argument — that is what a
plain rename looks like, and it is the smallest useful entry in the file.

### Merge rules

- Every live binding becomes a row, in config order. Submap bindings are hidden.
- A store entry whose `id` matches a live binding **overrides that binding's name
  and shortcut** rather than adding a second row.
- Store entries with `source: "user"` and no matching binding are appended as
  their own rows.
- A `source: "hyprland"` entry whose binding no longer exists is *dormant*: it stays
  in the file (so the rename comes back if the binding does) but is not a row,
  because an override of nothing is not a command.

### Hot reload

The store is watched with `FileView { watchChanges: true; onFileChanged: reload() }`.
Edit `~/.config/hyprshell/commands.json` in any editor and the palette updates
without restarting the shell. Verified against Quickshell 0.3.1 for truncating
writes, atomic temp+rename saves, and delete-then-recreate.

Bad input never takes the file down with it:

- an entry that fails validation is dropped with a `console.warn` naming its index
  and id, and the rest of the file still loads;
- a duplicate `id` keeps the first entry and warns;
- if the whole file is not valid JSON — which is what an editor shows mid-save —
  the last good store is kept and a warning is logged, so the palette does not
  blank out while you type.

Live bindings are re-read from `hyprctl binds -j` every time the palette opens.

### Migration from bind-labels.json

Before the store, renames lived in `~/.local/state/hyprshell/bind-labels.json` as a
flat `"<modmask>|<key>" -> label` map. The new id for a binding is `hypr:` plus that
same key, so migration is a pure rename and cannot lose an entry — not even for a
binding that no longer exists (it becomes a dormant override).

It runs once, automatically, after the first store load, and then renames the old
file to `bind-labels.json.migrated` — that rename is both the "already done" marker
and the backup. An id already present in `commands.json` is never overwritten by the
migration.

### API

`Commands` exposes `list`, `search(query)`, `run(id)`, `upsert(cmd)`, `remove(id)`,
`setName(id, name)`, plus `refresh()` (re-read the live bindings), `byId(id)` and
`rebind(id, mods, key)`.

- `search(q)` requires every whitespace-separated term to match somewhere in the
  shortcut, name, technical spelling or description. There is no ranking: the order
  is the config's order, which is the order people memorise.
- `setName(id, "")` deletes an override and the binding goes back to its technical
  spelling.
- `rebind()` writes into the `# BEGIN hyprshell rebinds` block of
  `hypr/custom/keybinds.conf` (sourced last, so it wins) and runs `hyprctl reload`.
  It deliberately does **not** cache the new shortcut in the store: Hyprland stays
  the source of truth for what is bound, so the palette can never claim a shortcut
  the compositor does not have. Because a binding's id follows its key combination,
  a rebind carries any rename over to the new id.

Known gaps in this phase: a `shortcut` on a `source: "user"` command is descriptive
only — the store does not yet install key bindings for commands that Hyprland does
not already know about, and `rebind()` only works on discovered bindings.
