# hypr-appmenu

Phase A1 of the global-menu project: a Hyprland plugin that implements the
`org_kde_kwin_appmenu` Wayland protocol and exposes the resulting
window → DBus-menu mapping to userspace.

Apps that support a global menu (Qt/KDE apps, GTK apps via
`appmenu-gtk-module`, Electron apps via their Wayland appmenu support) bind
`org_kde_kwin_appmenu_manager`, call `create(surface)` for their toplevel, and
then `set_address(service_name, object_path)` to say "the
`com.canonical.dbusmenu` export for this window lives at *this* bus name and
*this* object path". Hyprland does not implement the protocol, so the global is
never advertised and those apps silently keep their menus in-window.

This plugin advertises the global, records the addresses, resolves each record's
`wl_surface` to a Hyprland window, and hands the mapping out over `hyprctl`.
It does **not** talk to DBus and it does **not** render anything — that is a
later phase's job.

## Build

```sh
cd plugins/hypr-appmenu
make
```

Produces `hypr-appmenu.so` in this directory.

Requirements (all already present on `cachy`): `g++`, `pkg-config`, the Hyprland
plugin headers (`pkg-config --cflags hyprland`), `hyprwayland-scanner`, and
`qt6-wayland` for the protocol XML.

A plain Makefile is used deliberately: neither cmake nor meson is installed on
this machine, and `make` is also what `hyprpm` invokes, so the same build works
if this is ever turned into an hyprpm plugin.

### Generated protocol bindings

`src/protocols/appmenu.{hpp,cpp}` are **generated at build time** by the
Makefile, not committed:

```
hyprwayland-scanner /usr/share/qt6/wayland/protocols/appmenu/appmenu.xml src/protocols
```

Reasons for generating rather than committing:

* The generated code must match the `hyprwayland-scanner` that the installed
  Hyprland was built with. Since the `.so` has to be rebuilt on every Hyprland
  update anyway (see the ABI caveat), regenerating costs nothing and can never
  drift out of sync.
* The XML is LGPL-2.1 code owned by the KDE project; keeping only the path to
  the system copy avoids vendoring it into the dotfiles repo.

`src/protocols/` is therefore in `.gitignore`. Override the XML location with
`make PROTO_XML=/path/to/appmenu.xml` if it ever moves.

## Load

```sh
hyprctl plugin load $PWD/hypr-appmenu.so
hyprctl plugin unload $PWD/hypr-appmenu.so
```

The path must be absolute. To load it at every startup, add to
`hypr/hyprland/execs.conf` (or a `hypr/custom/*.conf` override):

```
exec-once = hyprctl plugin load /home/anon/.config/plugins/hypr-appmenu/hypr-appmenu.so
```

Clients only see the global if they connect **after** the plugin is loaded, so
apps already running when you load it will not register their menus until they
are restarted.

## Query interface

The plugin registers an `appmenu` hyprctl command. Output is always JSON,
whether or not `-j` is passed.

List every window that has announced a menu:

```sh
$ hyprctl appmenu
[{"address": "0x5f0c1e2a3b40", "service": ":1.142", "path": "/MenuBar"}, ...]
```

Look one up by window address (the same `address` field `hyprctl clients -j`
and `hyprctl activewindow -j` report):

```sh
$ hyprctl appmenu 0x5f0c1e2a3b40
{"address": "0x5f0c1e2a3b40", "service": ":1.142", "path": "/MenuBar"}
```

An unknown address returns `{}`.

Only records that (a) have received a `set_address` and (b) currently resolve to
a live window are listed. A client that created the appmenu object but never set
an address, or whose window is not mapped yet, is intentionally invisible.

No file is written anywhere — the `$XDG_RUNTIME_DIR/hypr-appmenu.json` fallback
described in the task was not needed, because `HyprlandAPI::registerHyprCtlCommand`
exists and works in 0.56.

## ABI caveat — read this before every Hyprland update

**Hyprland plugins have no ABI stability. This `.so` is valid only for the exact
Hyprland build it was compiled against.**

It was built against:

```
Hyprland 0.56.2, commit efb50993780079460b0cbed1363e2166a2de1d9f
aquamarine 0.15.0, hyprutils 0.14.1, hyprlang 0.6.8, hyprgraphics 0.5.1, hyprcursor 0.1.13
```

Any `pacman -Syu` that bumps `hyprland` — or any of those `hypr*` libraries —
invalidates the binary. Hyprland compares the plugin's compiled-in hash against
its own and refuses to load a mismatched plugin, so the failure mode is a
rejected load rather than a crash, but you get no global menu until you rebuild:

```sh
cd ~/.config/plugins/hypr-appmenu && make clean && make
```

Consider wiring that into the update routine. The plugin must also be built with
the same compiler as Hyprland (both are GCC here) and with `--no-gnu-unique`,
which the Makefile already passes.

## Design notes

| File | What it does |
|---|---|
| `src/protocols/appmenu.{hpp,cpp}` | generated wire bindings (`COrgKdeKwinAppmenuManager`, `COrgKdeKwinAppmenu`) |
| `src/AppmenuProtocol.{hpp,cpp}` | `CAppmenuProtocol : IWaylandProtocol` + one `CAppmenuEntry` per live appmenu object |
| `src/main.cpp` | plugin entry points, hyprctl command registration |

The structure follows Hyprland's own in-tree protocols
(`/usr/include/hyprland/src/protocols/FocusGrab.hpp` was the model): a protocol
object owning a vector of manager resources and a vector of per-object records,
with `bindManager` creating manager resources and `setOnDestroy` handlers
erasing them.

**surface → window** is resolved lazily, on every query, by walking
`Desktop::windowState()->windows()` and comparing `w->resource()` against the
stored `WP<CWLSurfaceResource>`. It is not cached, because clients create the
appmenu object during surface setup — usually before the window exists — and
caching would just mean a stale nullptr forever.

**Cleanup** happens on three paths:

1. `org_kde_kwin_appmenu.release()` (the protocol's destructor request) → the
   record is erased immediately.
2. The client destroying the resource without `release` → the generated
   `setOnDestroy` handler erases the record.
3. The `wl_surface` dying under a still-live appmenu object → a listener on
   `CWLSurfaceResource::m_events.destroy` drops the surface reference, and the
   now-orphaned record is erased by `pruneDead()` at the next safe point (the
   next `create` or the next query). It is deliberately *not* erased from inside
   the destroy listener, since that would free the listener while it is running.

## Known caveats / things that were not verified

Building was the goal here; the plugin has **never been loaded** into a running
compositor, by explicit instruction. Everything below is therefore reasoned from
headers, not observed:

* **hyprctl prefix matching.** The command is registered with `exact = false`
  so that `appmenu <address>` reaches the same handler. The matching rule for
  non-exact commands lives in `HyprCtl.cpp`, which is not part of the installed
  headers, so the assumption "non-exact means `request.starts_with(name)` and
  the handler receives the full request line" is unverified. What *was* verified
  is that `hyprctl appmenu`, `hyprctl appmenu 0xdeadbeef` and `hyprctl -j appmenu`
  all reach the compositor (they currently answer `unknown request`), so the
  client side forwards fine. The handler additionally tolerates a surviving
  `j/` format prefix. If `exact = false` turns out to behave differently, the fix
  is to register a second exact command or to parse `request` differently — the
  plugin side needs no other changes.
* **JSON field order and `-j` behaviour.** Output is hand-built, not produced by
  Hyprland's own JSON writer, so it ignores `eHyprCtlOutputFormat` entirely.
* **`escapeJSONStrings`** is used on all three fields. DBus names and object
  paths cannot legally contain quotes or backslashes, so this is belt-and-braces.
* **XWayland windows** cannot use this protocol at all (it is Wayland-only); KDE
  handles X11 global menus through `_KDE_NET_WM_APPMENU_*` window properties,
  which this plugin does not touch.
* **Resource-lifetime pattern.** Erasing a record from inside its own
  `setOnDestroy` / `setRelease` handler frees the `std::function` that is
  currently executing. This is what Hyprland's own protocol implementations do
  throughout, so it is matched here for consistency, but it is technically UB
  and worth remembering if a crash ever points at this file.
* Symbol resolution was checked statically (`nm -D` on `hypr-appmenu.so` against
  `/usr/bin/Hyprland`): `IWaylandProtocol`'s ctor/dtor, `CWLSurfaceResource::fromResource`,
  `Desktop::windowState`, `Desktop::CWindowState::windows`, `escapeJSONStrings`
  and the `HyprlandAPI` C entry points all resolve against the installed binary.
  That rules out a load-time "undefined symbol" failure, nothing more.
