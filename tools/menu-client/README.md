# menu-client

Reads an application's exported menu over DBus and normalises it into **one
JSON tree**, whichever of the two menu protocols the application speaks.

Phase A1 (`tools/appmenu-probe/registrar-stub.py`) answers *who* exports a menu
and *where*. This is the next step: given that `(bus name, object path)`, read
the menu and activate entries in it. The JSON tree is the contract the
Quickshell bar (`quickshell/hyprshell/`) will consume.

Two protocols are supported and auto-detected:

| Protocol | Spoken by | Read via | Activated via |
|---|---|---|---|
| `com.canonical.dbusmenu` | Qt/KDE apps, GTK apps going through `appmenu-gtk-module` | `GetLayout(0, -1, [])` | `Event(id, "clicked", …)` |
| `org.gtk.Menus` + `org.gtk.Actions` | GTK3/GTK4 apps exporting natively | `Menus.Start([groups])` + `Actions.DescribeAll()` | `Actions.Activate(name, params, {})` |

> **Read this first:** no application on this machine exports a menu, so
> **nothing here has ever been run against a real Qt or GTK application.**
> Everything is verified against the mock producers in `tests/` only. See
> [What is verified, and what is not](#what-is-verified-and-what-is-not).

## Requirements

`python3`, `python-dbus`, and `python-gobject` (the latter for `watch` and for
the mocks). All three are already installed here. Nothing is installed, built,
or vendored; the tool runs straight from the checkout.

`libdbusmenu` is **not** used and not needed — this talks raw DBus.

## Usage

```sh
./menu-client dump      <bus-name> <object-path>        # JSON tree on stdout
./menu-client activate  <bus-name> <object-path> <id>   # exit 0 on success
./menu-client watch     <bus-name> <object-path>        # one JSON line per change
```

```sh
# A Qt/KDE app, as reported by the registrar stub
./menu-client dump :1.42 /MenuBar

# A GTK app exporting natively
./menu-client dump :1.51 /org/gtk/Application/anonymous/menus/menubar

# Round-trip: take an id straight out of the dump and fire it
./menu-client activate :1.42 /MenuBar 12
```

Flags:

| Flag | Meaning |
|---|---|
| `--indent N` | `dump` only. JSON indent; `--indent 0` emits one compact line. Default 2. |
| `--protocol dbusmenu\|gtk` | Skip auto-detection. |
| `--gtk-actions-path [PREFIX=]PATH` | Point at the `org.gtk.Actions` object explicitly. Repeatable; `app=/org/gtk/Application/anonymous`, `win=/org/gtk/Application/anonymous/window/1`. Ignored for dbusmenu. |
| `--no-about-to-show` | dbusmenu only. Do not send `AboutToShow` for submenus that shipped no children. |

Exit codes:

| Code | Meaning |
|---|---|
| 0 | success |
| 1 | generic failure (bad arguments, DBus call refused, …) |
| 2 | the bus name has no owner, or the service went away mid-call |
| 3 | the object speaks neither protocol |
| 4 | the node id is malformed or refers to a non-activatable node |

Errors go to stderr prefixed with `menu-client:`; stdout carries only JSON.

## The JSON contract

`dump` prints **one root node**. Every node has exactly these eight keys, always
present, never omitted:

```json
{
  "id":        "<string>",
  "label":     "<string>",
  "enabled":   true,
  "visible":   true,
  "checked":   null,
  "separator": false,
  "shortcut":  null,
  "children":  []
}
```

| Key | Type | Meaning |
|---|---|---|
| `id` | string | Opaque token that round-trips back into `activate`. Never empty. Format differs per protocol (below) — **treat it as opaque**. |
| `label` | string | Display text, mnemonic markers already stripped. `""` for separators and for the root. |
| `enabled` | bool | False renders greyed out and must not be activated. |
| `visible` | bool | False means the app asked for the item to be hidden. Nodes are **not** filtered out of the tree — the consumer decides. Always `true` on the GTK path (the protocol has no such flag). |
| `checked` | bool or null | `null` when the item is not checkable at all. `true`/`false` for checkboxes and for the selected/unselected state of a radio item. |
| `separator` | bool | True for separator rules. Such nodes carry an empty label and no children. |
| `shortcut` | string or null | Accelerator as the app spelled it. dbusmenu: `"Control+Q"` (multiple sequences joined with `", "`). GTK: the raw `accel` attribute, e.g. `"<Control>q"`. **Not normalised between the two.** |
| `children` | array | Child nodes; `[]` for leaves. Submenu nesting is arbitrarily deep. |

The **root node** is a real node, not a bare array. Its `label` is `""` and its
`children` are the top-level menus (File, Edit, …). Its `id` is `"0"` on the
dbusmenu path and `"gtknode:root"` on the GTK path; neither is activatable in
any meaningful sense.

### id formats

Opaque to the consumer, but documented so the round-trip is auditable:

- **dbusmenu** — the protocol's own int32 item id as a decimal string: `"0"`,
  `"12"`. Fed straight back into `Event(id, "clicked", "", <now>)`.
- **GTK** — one of:
  - `gtk:app.quit` — activatable, no target
  - `gtk:win.view?sig=s&target="grid"` — activatable, with a target. `sig` is
    the single-character DBus signature of the original target so the type is
    restored on activation; `target` is JSON.
  - `gtknode:0/0/1` — structural (a submenu parent, or a label-only item). Not
    activatable; `activate` exits 4.
  - `gtksep:0/1/1` — a separator synthesised between two GMenu sections. Not
    activatable.

### Consumer notes for the Quickshell side

- **Do not use `id` as a list key.** dbusmenu ids are unique within a menu, but
  GTK ids are derived from the action name, so two entries invoking the same
  action with the same target collapse to the same id. Key QML models by tree
  path (index chain) instead.
- `dump` is a snapshot. `watch` tells you *that* something changed, not what —
  re-run `dump` and rebuild.
- Filtering is the consumer's job: skip `visible: false`, grey out
  `enabled: false`, render `separator: true` as a rule, render
  `checked != null` with a checkbox/radio indicator.
- `--indent 0` gives one line per dump, which is the cheaper thing to parse
  from JS.

### Labels

Mnemonic markers are stripped from every label: GTK's `_File` and Qt's `&File`
both become `File`. A doubled marker is an escaped literal, so `R&&D` → `R&D`
and `my__file` → `my_file`.

Known limitation: a label containing an *undoubled* underscore between word
characters loses it (`my_file.txt` → `myfile.txt`). Producers are supposed to
double such underscores; not all of them do. This is the same ambiguity GTK
itself has, and it cannot be resolved without knowing whether the producer
intended a mnemonic.

## Running the tests

```sh
./tests/run.sh          # exits 0 on success, non-zero on any failed assertion
```

It re-execs itself inside a private session bus via `dbus-run-session`, so it
never touches your real session and needs no running desktop. It starts each
mock, dumps, asserts, activates, checks that the mock recorded the activation,
and tears everything down.

Current result on this machine: **PASS**, 18 assertions.

```
== com.canonical.dbusmenu
  ok    mock producer owns org.example.MockDBusMenu
  ok    dump exited 0
  ok    dbusmenu JSON matches the contract
  ok    id for File > Quit read back from the dump: 5
  ok    activate File > Quit (exit 0)
  ok    mock recorded Event(id=5, "clicked")
  ok    activate with a malformed id (exit 4)

== watch
  ok    watch printed a line when the menu changed

== error paths
  ok    dump against a bus name nobody owns (exit 2)
  ok    dump against an object speaking neither protocol (exit 3)

== org.gtk.Menus + org.gtk.Actions
  ok    mock producer owns org.example.MockGtkMenu
  ok    dump exited 0
  ok    gtk JSON matches the contract
  ok    activate File > Quit (exit 0)
  ok    activate Edit > Grid view (action with a target) (exit 0)
  ok    mock recorded Activate("quit") and Activate("view", ["grid"])
  ok    activate a structural (non-actionable) gtk id (exit 4)

PASS
```

The suite was checked against injected regressions (disabling mnemonic
stripping in the client; disabling activation recording in the mock) and fails
with a non-zero exit in both cases, so it is not a rubber stamp.

### The mocks

Both can be run by hand against a scratch bus:

```sh
dbus-run-session -- sh -c '
  python3 tests/mock-dbusmenu.py --record /tmp/events.jsonl & sleep 1
  ./menu-client dump org.example.MockDBusMenu /MenuBar'
```

- `tests/mock-dbusmenu.py` — `com.canonical.dbusmenu` on
  `org.example.MockDBusMenu` at `/MenuBar`. File > New / Open / --- / Quit and
  Edit > Copy *(disabled)* / Paste / Word Wrap *(checkable, on)* / Hidden
  *(visible=false)*. Labels deliberately mix `_` and `&` mnemonics, and New/Quit
  carry shortcuts. `org.example.MockControl.Touch()` bumps the revision and
  emits `LayoutUpdated`, which is how `watch` is tested.
- `tests/mock-gtkmenu.py` — `org.gtk.Menus` at
  `/org/gtk/mock/menus/menubar` plus `org.gtk.Actions` at the ancestor path
  `/org/gtk/mock`, on `org.example.MockGtkMenu`. File is built from two GMenu
  *sections* (so the synthesised separator is exercised), and Edit deliberately
  lives in **subscription group 1** so the client has to follow the reference
  and call `Start()` a second time. Actions cover disabled (`copy`), boolean
  state (`wrap`), and a radio pair with targets (`view` = `"list"`/`"grid"`).

Both append one JSON object per line to `--record`, which is how the tests
assert that an activation really arrived.

## What is verified, and what is not

### Verified against the mocks

- Protocol auto-detection via `Introspect`, for both protocols.
- dbusmenu: `GetLayout(0, -1, [])` parsing — nesting, `label`, `enabled`,
  `visible`, `type: separator`, `toggle-type`/`toggle-state`, `shortcut`.
- dbusmenu: `Event(id, "clicked", …)` round-trip from a dumped id, confirmed by
  the mock's record.
- dbusmenu: `watch` reporting `LayoutUpdated`.
- GTK: transitive `Start()` subscription across groups, `:submenu` nesting,
  `:section` flattening with synthesised separators, `accel` pass-through.
- GTK: `DescribeAll()` mapping to `enabled`, boolean state to `checked`, and
  radio state-vs-target to `checked`.
- GTK: `Activate()` round-trip for a bare action and for an action with a
  string target, confirmed by the mock's record.
- GTK: action-object discovery by walking **up** to an ancestor path.
- Contract shape: all eight keys present with the right types on every node,
  ids non-empty strings and unique within these trees, no mnemonic markers left.
- Error paths: exit 2 for an unowned bus name, exit 3 for an object speaking
  neither protocol, exit 4 for a malformed or non-activatable id.
- `watch` noticing the producer disappear (`service-gone`), on both paths.

### NOT verified — no real producer exists on this machine

Treat every item below as *written to spec but never executed against the real
thing*.

1. **Any real Qt/KDE application.** Untested end to end.
2. **Any real GTK application.** Untested end to end.
3. **GTK action-path discovery in its realistic shape.** Real GTK apps split the
   namespaces across two objects — `app.` at
   `/org/gtk/Application/anonymous` and `win.` at
   `…/window/N`. The mock puts both on one object, so only the ancestor walk is
   exercised; the downward sweep that looks for `…/window/N` and the
   prefix→path mapping are **not**. This is the single most likely thing to
   break first. `--gtk-actions-path win=/…/window/1` is the escape hatch.
4. **Lazily populated dbusmenu submenus.** `AboutToShow` is sent for submenus
   that arrive with no children, and the layout is re-fetched if the app says
   an update is needed. The mock always answers `false`, so the re-fetch branch
   never runs. Many real Qt apps do populate lazily.
5. **The detection fallback probe.** When `Introspect` returns nothing useful,
   the client probes `GetLayout` and then `Start`/`End`. Both mocks introspect
   correctly, so only the introspection path is exercised.
6. **GTK change signals.** `org.gtk.Menus.Changed` and
   `org.gtk.Actions.Changed` handlers are registered and their payloads
   decoded, but the GTK mock never emits them. Only the dbusmenu
   `LayoutUpdated` path is proven. `ItemsPropertiesUpdated` is likewise
   registered but never emitted.
7. **Non-scalar GTK action targets.** Only scalar targets (string, the integer
   types, bool, double, object path, signature) round-trip with their exact
   DBus type. A tuple/array/dict target degrades to a best-effort guess and may
   be rejected by the app. Rare in practice; not exercised.
8. **`Event` semantics beyond `clicked`.** Some apps expect `opened`/`closed`
   events on the parent chain before a click registers. `activate` sends a
   best-effort `AboutToShow` on the item and then `clicked`, nothing else.

### Deliberately not implemented

- **Icons.** `icon-name` / `icon-data` (dbusmenu) and `icon` (GTK) are not read
  and there is no icon field in the contract. Add both together when the bar
  needs them.
- **Registrar lookup.** This tool takes `(bus name, object path)` as given;
  finding them for a window is `tools/appmenu-probe/`'s job.
- **`dbusmenu` extras** — `disposition`, `Status`, `TextDirection`,
  `IconThemePath`, and `children-display` values other than `submenu`.
- **Shortcut normalisation.** The two protocols spell accelerators differently
  and both are passed through verbatim.
- **Caching / a long-lived daemon.** Every command is a one-shot connection.

## Layout

```
tools/menu-client/
├── menu-client               entry point (runs from the checkout)
├── menu_client/
│   ├── __init__.py           fetch/activate/watch, dispatch on detected protocol
│   ├── core.py               bus, DBus↔python conversion, labels, detection, node shape
│   ├── dbusmenu.py           com.canonical.dbusmenu backend
│   ├── gtkmenu.py            org.gtk.Menus + org.gtk.Actions backend
│   └── cli.py                argument parsing, exit codes
└── tests/
    ├── mock-dbusmenu.py      mock com.canonical.dbusmenu producer
    ├── mock-gtkmenu.py       mock org.gtk.Menus + org.gtk.Actions producer
    └── run.sh                end-to-end suite
```
