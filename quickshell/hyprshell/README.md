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
NotificationPopups.qml, Osd.qml, Commands.qml, CommandPalette.qml, CommandEditor.qml.
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

## Editing from the palette

`CommandEditor.qml` is the editor sheet. It is an `Item` drawn over the palette,
not a window of its own: the palette already holds an exclusive keyboard grab, and
a second surface would only fight it for focus — which is also what lets the sheet
record shortcuts.

Reaching it:

- **Ctrl+E** on the selected row, or the ✎ button that appears on it (hovering a
  row selects it, so "hovered" and "selected" are the same row);
- searching for something that does not exist yet shows a **Create command "…"**
  row — click it or press Enter — which opens the sheet empty with the search text
  as the name. That is the only way to an empty sheet, and it is deliberate: an
  always-visible "new" button in a list of 140 bindings is noise.

The sheet is name, exec (a `Shell` / `hyprctl` selector and the fields that type
needs) and shortcut, with Save, Cancel and a destructive button that needs a second
click within three seconds before it does anything. For a user command that button
is **Delete**; for a discovered binding it is **Reset overrides**, because the
binding itself is your Hyprland config's, not the palette's, to remove — resetting
drops the name and exec overrides and the row goes back to what `hyprctl binds -j`
says.

Nothing in the sheet touches a file: it calls `Commands.saveCommand` and
`Commands.deleteCommand`, which own both the JSON store and the generated config.

## Shortcuts

**Recording.** Press *Record* and the next combination is captured. Hyprland
consumes its own binds before the focused surface ever sees them, so an exclusive
keyboard grab is not enough — pressing Super+G while recording used to fire game
mode. The palette therefore switches Hyprland into the empty `hyprshell-capture`
submap (defined at the end of `hypr/hyprland/keybinds.conf`) and back with
`submap reset`. A stuck submap is a session with no keybindings at all, so the
reset is belt and braces: when recording ends, when the sheet is hidden, when the
palette closes, and `escape` is bound inside the submap itself as a last resort.

**Conflicts.** Before a shortcut can be saved, the combination is checked against
the whole merged model — live Hyprland bindings and other user commands alike. If
it is taken the sheet names the command that owns it and Save stays disabled until
you either *Overwrite* (the old binding is unbound) or *Pick another*.

**Where bindings go.** Both of these live in `hypr/custom/keybinds.conf`, which
`hyprland.conf` sources last and on every start, so they win and they survive a
Hyprland restart. Nothing outside the two marked blocks is ever touched:

| Block | Written how | For |
|-------|-------------|-----|
| `# BEGIN hyprshell rebinds` | appended to | discovered bindings: one `unbind` of the old combo, one `bind` of the new. Hyprland stays the source of truth, a later pair simply wins, and `hyprctl binds -j` is re-read afterwards. |
| `# BEGIN hyprshell user commands` | regenerated in full from the store | commands the palette owns. A line appears, changes and disappears with its entry, so it can never go stale. |

Every generated `bind` is preceded by an `unbind` of the same combination:
Hyprland fires *all* bindings on a key, so without it a combo that another line
already claims would run both actions.

A user command's shortcut is stored in `commands.json` — it has to be, because the
generated block is rebuilt from the store and that is the only place that knows
the combo. The live binding that results is then hidden from the list, so the
command is one row and not two. Clearing a shortcut removes the entry's line and
with it the binding.

Editing the *exec* of a discovered binding rewrites its `bind` line too, so the
key runs what the palette says it runs. Before this the two could disagree.

### API

`Commands` exposes `list`, `search(query)`, `run(id)`, `upsert(cmd)`, `remove(id)`,
`setName(id, name)`, `saveCommand(id, cmd, mods, key)`, `deleteCommand(id)`,
`rebind(id, mods, key)`, `conflicts(mods, key, excludeId)`, `newId(name)`, plus
`refresh()` (re-read the live bindings), `byId(id)`, `parseShortcut(s)` and
`keyNameOf(qtKey, text)`.

- `search(q)` requires every whitespace-separated term to match somewhere in the
  shortcut, name, technical spelling or description. There is no ranking: the order
  is the config's order, which is the order people memorise.
- `setName(id, "")` deletes an override and the binding goes back to its technical
  spelling.
- `saveCommand()` is the editor's one entry point — it writes the store entry
  (pass `null` to leave the store alone) and makes the shortcut real, in one write
  and one `hyprctl reload`. An empty `key` clears the shortcut. `rebind()` is just
  `saveCommand(id, null, mods, key)`, which is the palette's Ctrl+R.
- Because a discovered binding's id follows its key combination, a rebind carries
  any rename or exec override over to the new id.

Caveats worth knowing:

- Hand-editing a `shortcut` into `commands.json` changes what the palette *shows*
  but does not install a binding: the generated block is written when the editor
  saves, not when the store reloads. Open the command and press Save to make it
  real.
- *Reset overrides* on a discovered binding drops the store entry; it does not
  undo lines already written into `hypr/custom/keybinds.conf`. Delete those by
  hand if you want the original binding back.
- One combination can carry several dispatchers (Alt+Tab is `cyclenext` *and*
  `bringactivetotop`). Unbinding removes all of them, so rebinding one of a pair
  takes its sibling with it.
- The reserved `dbus` and `menu` exec types survive a round-trip through the file
  but not through the editor, which only knows `shell` and `hyprctl`.
