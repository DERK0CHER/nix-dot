"""org.gtk.Actions-only backend (GTK4/libadwaita apps).

GTK4/libadwaita applications -- Nautilus, GNOME Text Editor, GNOME Calculator
-- have no `GtkMenuBar`, so they export **nothing** on `org.gtk.Menus`. They do
export `org.gtk.Actions`, both on the application object
(`/org/gnome/Nautilus`, the `app.` namespace) and on each window object
(`/org/gnome/Nautilus/window/1`, the `win.` namespace). Those actions are
exactly the entries of the hamburger menu, and `Activate()` fires them.

What the protocol does *not* give us is a label or any grouping: `DescribeAll`
answers `{name: (enabled, parameter-signature, state)}` and nothing else. This
module supplies both:

* **Labels** come from a per-app override table in `tools/menu-client/labels/`
  when one exists, otherwise from a mechanical de-slugger
  (`new-window` -> "New Window").
* **Grouping** comes from the same table's `menus` list, otherwise from a
  heuristic: split `app.` from `win.`, then lift keyword clusters (`tab-*`,
  `go-*`, ...) out into their own menus.

Reading and activation are deliberately *not* reimplemented -- the object-path
discovery (`resolve_actions`), the id codec (`encode_id`/`decode_id`) and
`activate()` are the ones `gtkmenu` already uses, so an id minted here is the
same shape as an id minted there and round-trips through the same code.

Ids, unchanged from the org.gtk.Menus backend:

    gtk:app.new-window                    activatable, no target
    gtk:win.view?sig=s&target="grid"      activatable, with a string target
    gtknode:menu/2                        structural (a synthesised menu)
    gtksep:menu/2/3                       separator inside a synthesised menu
"""

import json
import os
import re
import xml.etree.ElementTree as ET

import dbus

from . import core, gtkmenu
from .core import GTK_ACTIONS_IFACE, MenuError, ServiceGone
from .gtkmenu import KNOWN_PREFIXES, encode_id, resolve_actions
from .gtkmenu import _split_action as split_action

# Namespaces we read, in menu-bar order. Anything else an override or
# --gtk-actions-path introduced is appended after these.
NAMESPACE_ORDER = ("app", "win")

NAMESPACE_TITLES = {"app": "Application", "win": "Window", "": "Actions"}


# --------------------------------------------------------------------------
# Which actions belong in a menu at all
# --------------------------------------------------------------------------
#
# `DescribeAll` hands back every action the app has registered, including ones
# no human would ever pick off a menu bar. Three rules, all cheap and all
# explainable (see README, "Which actions are shown"):
#
#  1. A non-empty parameter signature other than "s" means the action needs an
#     argument we cannot invent -- `go-to-tab` wants an int32 tab index. Drop.
#  2. A "s" parameter is kept only when an override table supplies the target
#     (`"win.view=grid"`). A bare string action fired with no target is a menu
#     entry that silently does nothing, which is worse than not showing it.
#  3. Names that are obviously internal: shorter than two characters (the
#     single-letter `i` action Nautilus exports is the canonical example), a
#     leading underscore, or anything that is not a plain action-ish token.

ACCEPTED_SIGS = ("", "s")

_ACTION_NAME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9._-]*$")

INTERNAL_PREFIXES = ("_", "gtk-", "internal-", "priv-", "debug-")


def is_internal(bare):
    if len(bare) < 2:
        return True
    if not _ACTION_NAME_RE.match(bare):
        return True
    return bare.startswith(INTERNAL_PREFIXES)


# --------------------------------------------------------------------------
# Mechanical labels
# --------------------------------------------------------------------------

ACRONYMS = {
    "cd": "CD", "cpu": "CPU", "css": "CSS", "csv": "CSV", "dns": "DNS",
    "dvd": "DVD", "ftp": "FTP", "gpu": "GPU", "html": "HTML", "http": "HTTP",
    "https": "HTTPS", "id": "ID", "ip": "IP", "json": "JSON", "ok": "OK",
    "os": "OS", "pc": "PC", "pdf": "PDF", "ram": "RAM", "smb": "SMB",
    "sql": "SQL", "ssh": "SSH", "svg": "SVG", "tv": "TV", "ui": "UI",
    "uri": "URI", "url": "URL", "usb": "USB", "vpn": "VPN", "xml": "XML",
}

# Action names common enough across GTK apps that the de-slugged form would
# read wrong or terse. Per-app niceties belong in labels/<bus-name>.json.
GENERIC_LABELS = {
    "about": "About",
    "close": "Close",
    "copy": "Copy",
    "cut": "Cut",
    "find": "Find…",
    "find-replace": "Find and Replace…",
    "fullscreen": "Full Screen",
    "go-back": "Back",
    "go-forward": "Forward",
    "go-home": "Home",
    "go-up": "Up",
    "help": "Help",
    "new-tab": "New Tab",
    "new-window": "New Window",
    "open": "Open…",
    "paste": "Paste",
    "preferences": "Preferences",
    "print": "Print…",
    "properties": "Properties",
    "quit": "Quit",
    "redo": "Redo",
    "refresh": "Refresh",
    "reload": "Reload",
    "save": "Save",
    "save-as": "Save As…",
    "select-all": "Select All",
    "shortcuts": "Keyboard Shortcuts",
    "undo": "Undo",
    "zoom-in": "Zoom In",
    "zoom-normal": "Normal Size",
    "zoom-out": "Zoom Out",
}

_CAMEL = re.compile(r"(?<=[a-z0-9])(?=[A-Z])")


def mechanical_label(action):
    """`win.tab-move-right` -> "Tab Move Right". Never returns "".

    Strips a leading `app.`/`win.`/`unity.`, splits on -, _, . and camelCase
    boundaries, upper-cases known acronyms and title-cases the rest.
    """
    _prefix, bare = split_action(action)
    bare = bare.strip()
    if bare in GENERIC_LABELS:
        return GENERIC_LABELS[bare]
    words = [w for w in re.split(r"[-_.\s]+", _CAMEL.sub("-", bare)) if w]
    out = []
    for word in words:
        low = word.lower()
        if low in ACRONYMS:
            out.append(ACRONYMS[low])
        elif word.isupper() and len(word) > 1:
            out.append(word)
        else:
            out.append(low[:1].upper() + low[1:])
    return " ".join(out) or bare or action


# --------------------------------------------------------------------------
# Heuristic grouping, used when there is no override table
# --------------------------------------------------------------------------
#
# Keyword -> menu title, first match wins. The keyword must appear as a whole
# hyphen-separated token of the action name, so "tab" matches `new-tab`,
# `tab-move-left` and `close-other-tabs` (plural is folded) but not `table`.

KEYWORD_GROUPS = (
    ("tab", "Tabs"),
    ("bookmark", "Bookmarks"),
    ("go", "Go"),
    ("zoom", "View"),
    ("sidebar", "View"),
    ("view", "View"),
    ("search", "Search"),
    ("find", "Search"),
    ("undo", "Edit"),
    ("redo", "Edit"),
    ("copy", "Edit"),
    ("cut", "Edit"),
    ("paste", "Edit"),
    ("about", "Help"),
    ("help", "Help"),
    ("shortcuts", "Help"),
)

# A cluster smaller than this is not worth its own menu; its members fall back
# into the namespace menu.
MIN_CLUSTER = 2

# Menu-bar order. Titles that are not listed sort after everything named here,
# alphabetically.
MENU_RANK = {
    "Application": 0, "File": 1, "Edit": 2, "View": 3, "Go": 4, "Tabs": 5,
    "Bookmarks": 6, "Search": 7, "Window": 8, "Help": 9,
}


def _tokens(bare):
    raw = [t for t in re.split(r"[-_.]+", _CAMEL.sub("-", bare.lower())) if t]
    out = set(raw)
    for token in raw:  # fold a trailing plural: "tabs" also matches "tab"
        if len(token) > 3 and token.endswith("s"):
            out.add(token[:-1])
    return out


def keyword_group(bare):
    tokens = _tokens(bare)
    for keyword, title in KEYWORD_GROUPS:
        if keyword in tokens:
            return title
    return None


# --------------------------------------------------------------------------
# Override tables: labels/<bus-name>.json
# --------------------------------------------------------------------------

LABELS_ENV = "MENU_CLIENT_LABELS"


def label_dirs():
    """Search path for override tables, most specific first."""
    dirs = []
    env = os.environ.get(LABELS_ENV, "")
    dirs.extend(p for p in env.split(os.pathsep) if p)
    xdg = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    dirs.append(os.path.join(xdg, "menu-client", "labels"))
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dirs.append(os.path.join(here, "labels"))
    return dirs


_PATH_TAIL = re.compile(r"/(window|menus)(/.*)?$")


def table_candidates(name, path):
    """Table basenames to look for, best first.

    The bus name as given (`org.gnome.Nautilus`), then every well-known name
    the same connection owns (so `:1.670` still finds the table), then a name
    derived from the object path as a last resort.
    """
    out = []

    def add(candidate):
        if (candidate and candidate not in out and "/" not in candidate
                and not candidate.startswith(":")
                and candidate not in (".", "..")):
            out.append(candidate)

    add(name)
    if name.startswith(":"):
        for well_known in names_owned_by(name):
            add(well_known)
    if path:
        add(_PATH_TAIL.sub("", path).strip("/").replace("/", "."))
    return out


def load_table(candidates):
    """First matching labels/<candidate>.json as a dict, or None."""
    for candidate in candidates:
        for directory in label_dirs():
            filename = os.path.join(directory, candidate + ".json")
            if not os.path.isfile(filename):
                continue
            try:
                with open(filename, encoding="utf-8") as handle:
                    data = json.load(handle)
            except (OSError, ValueError) as exc:
                raise MenuError(
                    f"label table {filename} is unreadable: {exc}") from exc
            if not isinstance(data, dict):
                raise MenuError(
                    f"label table {filename} must contain a JSON object")
            data = dict(data)
            data["_source"] = filename
            return data
    return None


# --------------------------------------------------------------------------
# Reading org.gtk.Actions
# --------------------------------------------------------------------------

def _entry(prefix, bare, described_value):
    enabled = bool(described_value[0])
    sig = str(described_value[1]) if len(described_value) > 1 else ""
    state_list = described_value[2] if len(described_value) > 2 else []
    state = state_list[0] if state_list else None
    return {
        "prefix": prefix,
        "bare": bare,
        "action": f"{prefix}.{bare}" if prefix else bare,
        "enabled": enabled,
        "sig": sig,
        "state": state,
    }


def collect(actions):
    """Every usable action across the resolved org.gtk.Actions objects.

    Returns a list of entry dicts in menu-bar-ish order: `app.` first, then
    `win.`, alphabetical within each. Actions filtered out by `is_internal` or
    by an unusable parameter signature never appear.
    """
    prefixes = list(NAMESPACE_ORDER)
    prefixes += [p for p in sorted(actions.paths) if p not in prefixes]

    out = []
    seen_paths = set()
    for prefix in prefixes:
        path = actions.paths.get(prefix)
        if path is None or path in seen_paths:
            continue
        seen_paths.add(path)
        described = actions.describe(path)
        if not described:
            continue
        for bare in sorted(described):
            if is_internal(bare):
                continue
            entry = _entry(prefix, bare, described[bare])
            if entry["sig"] not in ACCEPTED_SIGS:
                continue
            out.append(entry)
    return out


def _leaf(entry, label, target=None):
    sig = "s" if target is not None else ""
    checked = None
    state = entry["state"]
    if target is not None:
        if state is not None:
            checked = state == target
    elif isinstance(state, bool):
        checked = state
    return core.node(
        node_id=encode_id(entry["action"], target, sig),
        label=label,
        enabled=entry["enabled"],
        # org.gtk.Actions has no visibility flag at all.
        visible=True,
        checked=checked,
        separator=False,
        # GTK exposes accelerators through GtkApplication, not over this
        # interface. Nothing to report, so the contract's null.
        shortcut=None,
    )


def _label_for(table, entry, target):
    labels = (table or {}).get("labels") or {}
    keys = []
    if target is not None:
        keys.append(f"{entry['action']}={target}")
        keys.append(f"{entry['bare']}={target}")
    keys.append(entry["action"])
    keys.append(entry["bare"])
    for key in keys:
        value = labels.get(key)
        if isinstance(value, str) and value:
            return value
    if target is not None:
        return f"{mechanical_label(entry['action'])}: {mechanical_label(target)}"
    return mechanical_label(entry["action"])


def _index(entries):
    by_action, by_bare = {}, {}
    for entry in entries:
        by_action[entry["action"]] = entry
        by_bare.setdefault(entry["bare"], []).append(entry)
    return by_action, by_bare


def _resolve_spec(spec, by_action, by_bare):
    """`"win.view=grid"` -> (entry, "grid"). Unknown or ambiguous -> (None, _)."""
    if not isinstance(spec, str):
        return None, None
    action, has_target, target = spec.partition("=")
    action = action.strip()
    target = target if has_target else None
    entry = by_action.get(action)
    if entry is None:
        candidates = by_bare.get(action) or []
        # A bare name that exists in both namespaces is ambiguous; make the
        # user write the prefix rather than guessing wrong.
        entry = candidates[0] if len(candidates) == 1 else None
    return entry, target


def _tidy(children, menu_index):
    """Drop leading, trailing and doubled separators; renumber their ids."""
    out = []
    for child in children:
        if child["separator"]:
            if not out or out[-1]["separator"]:
                continue
        out.append(child)
    while out and out[-1]["separator"]:
        out.pop()
    for i, child in enumerate(out):
        if child["separator"]:
            child["id"] = f"gtksep:menu/{menu_index}/{i}"
    return out


def _menu(index, title, children):
    return core.node(node_id=f"gtknode:menu/{index}", label=title,
                     children=children)


def build_from_table(entries, table):
    """(menus, actions_consumed). Menus listed in the table, in table order."""
    by_action, by_bare = _index(entries)
    hidden = set()
    for spec in table.get("hide") or []:
        entry, _target = _resolve_spec(spec, by_action, by_bare)
        if entry is not None:
            hidden.add(entry["action"])
        else:  # a bare, ambiguous name in `hide` hides every match
            for candidate in by_bare.get(str(spec).partition("=")[0], []):
                hidden.add(candidate["action"])

    menus, used, used_ids = [], set(hidden), set()
    for spec in table.get("menus") or []:
        if not isinstance(spec, dict):
            continue
        title = spec.get("label") or spec.get("title") or ""
        children = []
        for item in spec.get("items") or []:
            if item in ("-", "", "|", "separator"):
                children.append(core.node(node_id="gtksep:pending",
                                          separator=True))
                continue
            entry, target = _resolve_spec(item, by_action, by_bare)
            if entry is None or entry["action"] in hidden:
                continue
            if target is None and entry["sig"] == "s":
                continue  # needs an argument the table did not supply
            node = _leaf(entry, _label_for(table, entry, target), target)
            if node["id"] in used_ids:
                continue
            used_ids.add(node["id"])
            used.add(entry["action"])
            children.append(node)
        children = _tidy(children, len(menus))
        if children:
            menus.append(_menu(len(menus), title, children))
    return menus, used


def build_heuristic(entries, table, start_index=0):
    """Namespace split first, then keyword clusters lifted out of it."""
    buckets = []          # ordered [title, [nodes]]
    index_of = {}

    def bucket(title):
        if title not in index_of:
            index_of[title] = len(buckets)
            buckets.append([title, []])
        return buckets[index_of[title]][1]

    for prefix in list(NAMESPACE_ORDER) + sorted(
            {e["prefix"] for e in entries} - set(NAMESPACE_ORDER)):
        mine = [e for e in entries if e["prefix"] == prefix]
        if not mine:
            continue
        clusters = {}
        for entry in mine:
            title = keyword_group(entry["bare"])
            if title:
                clusters.setdefault(title, []).append(entry)
        clusters = {t: v for t, v in clusters.items() if len(v) >= MIN_CLUSTER}
        clustered = {e["action"] for v in clusters.values() for e in v}

        chunks = list(clusters.items())
        leftovers = [e for e in mine if e["action"] not in clustered]
        if leftovers:
            chunks.append((NAMESPACE_TITLES.get(prefix,
                                                mechanical_label(prefix)),
                           leftovers))
        for title, members in chunks:
            target_list = bucket(title)
            if target_list:
                # Two namespaces landed in one menu: rule them apart.
                target_list.append(core.node(node_id="gtksep:pending",
                                             separator=True))
            for entry in members:
                if entry["sig"] == "s":
                    continue  # no target available outside a table
                target_list.append(
                    _leaf(entry, _label_for(table, entry, None), None))

    buckets.sort(key=lambda b: (MENU_RANK.get(b[0], len(MENU_RANK)), b[0]))
    menus = []
    for title, children in buckets:
        children = _tidy(children, start_index + len(menus))
        if children:
            menus.append(_menu(start_index + len(menus), title, children))
    return menus


def build(entries, table):
    if table and table.get("menus"):
        menus, used = build_from_table(entries, table)
        rest = [e for e in entries if e["action"] not in used]
        # Anything the table forgot still shows up rather than vanishing.
        menus.extend(build_heuristic(rest, table, start_index=len(menus)))
        return menus
    return build_heuristic(entries, table)


# --------------------------------------------------------------------------
# Backend entry points
# --------------------------------------------------------------------------

def fetch(name, path, gtk_actions_paths=None, **_ignored):
    actions = resolve_actions(name, path, gtk_actions_paths)
    if actions.default is None:
        raise MenuError(
            f"no {GTK_ACTIONS_IFACE} object found for {name} near {path}; "
            "pass --gtk-actions-path")
    entries = collect(actions)
    table = load_table(table_candidates(name, path))
    return core.node(node_id="gtknode:root", children=build(entries, table))


def activate(name, path, node_id, gtk_actions_paths=None, **kwargs):
    """Identical to the org.gtk.Menus backend -- same ids, same Activate()."""
    return gtkmenu.activate(name, path, node_id,
                            gtk_actions_paths=gtk_actions_paths, **kwargs)


def watch(name, path, on_change, gtk_actions_paths=None, **_ignored):
    bus = core.bus()

    def actions_changed(removed, enabled_changed, state_changed, added):
        on_change({"event": "actions-changed",
                   "removed": [str(x) for x in removed],
                   "enabled": [str(x) for x in enabled_changed],
                   "state": [str(x) for x in state_changed],
                   "added": [str(x) for x in added]})

    actions = resolve_actions(name, path, gtk_actions_paths)
    paths = set(actions.paths.values())
    if actions.default:
        paths.add(actions.default)
    for actions_path in sorted(paths):
        bus.add_signal_receiver(actions_changed, signal_name="Changed",
                                dbus_interface=GTK_ACTIONS_IFACE,
                                bus_name=name, path=actions_path)


# --------------------------------------------------------------------------
# Finding the menu object for a process
# --------------------------------------------------------------------------
#
# GTK apps do not speak org_kde_kwin_appmenu, so the Hyprland plugin has no
# (service, path) for them and the shell has nothing to look up. All it has is
# the window's pid. This maps pid -> (bus name, object path, protocol).

MENU_IFACES = (core.DBUSMENU_IFACE, core.GTK_MENUS_IFACE, GTK_ACTIONS_IFACE)

SWEEP_BUDGET = 48

_SKIP_NAME_PREFIXES = ("org.freedesktop.DBus",)


def _dbus_daemon():
    return core.bus().get_object("org.freedesktop.DBus",
                                 "/org/freedesktop/DBus", introspect=False)


def names_owned_by(owner):
    """Well-known names whose owner is `owner` (a unique name like ":1.670")."""
    try:
        daemon = _dbus_daemon()
        names = [str(n) for n in daemon.ListNames(
            dbus_interface="org.freedesktop.DBus", timeout=core.CALL_TIMEOUT)]
    except dbus.DBusException:
        return []
    out = []
    for candidate in names:
        if candidate.startswith(":") or candidate.startswith(_SKIP_NAME_PREFIXES):
            continue
        try:
            if str(daemon.GetNameOwner(
                    candidate, dbus_interface="org.freedesktop.DBus",
                    timeout=core.CALL_TIMEOUT)) == owner:
                out.append(candidate)
        except dbus.DBusException:
            continue
    return out


def names_for_pid(pid):
    """Bus names owned by `pid`; well-known names first, unique names last."""
    try:
        daemon = _dbus_daemon()
        names = [str(n) for n in daemon.ListNames(
            dbus_interface="org.freedesktop.DBus", timeout=core.CALL_TIMEOUT)]
    except dbus.DBusException as exc:
        raise MenuError(f"cannot list bus names: {exc}") from exc

    well_known, unique = [], []
    for name in names:
        if name.startswith(_SKIP_NAME_PREFIXES):
            continue
        try:
            owner_pid = int(daemon.GetConnectionUnixProcessID(
                name, dbus_interface="org.freedesktop.DBus",
                timeout=core.CALL_TIMEOUT))
        except (dbus.DBusException, ValueError, TypeError):
            continue
        if owner_pid != int(pid):
            continue
        (unique if name.startswith(":") else well_known).append(name)
    return well_known + unique


def candidate_paths(name):
    """Where a menu object plausibly sits for an app owning `name`."""
    out = []
    if not name.startswith(":"):
        # GApplication's own rule: the app id with . -> / and - -> _.
        base = "/" + name.replace(".", "/").replace("-", "_")
        out += [base + "/menus/menubar", base]
    out += ["/org/gtk/Application/anonymous/menus/menubar",
            "/org/gtk/Application/anonymous",
            "/MenuBar", "/com/canonical/menu/MenuBar"]
    seen, unique = set(), []
    for path in out:
        if path not in seen:
            seen.add(path)
            unique.append(path)
    return unique


def _introspect(name, path):
    """(interfaces, child paths) in one round trip."""
    try:
        obj = core.bus().get_object(name, path, introspect=False)
        xml = obj.Introspect(
            dbus_interface="org.freedesktop.DBus.Introspectable",
            timeout=core.CALL_TIMEOUT)
        root = ET.fromstring(str(xml))
    except (dbus.DBusException, ET.ParseError):
        return set(), []
    base = path.rstrip("/")
    ifaces = {el.get("name") for el in root.findall("interface") if el.get("name")}
    children = [f"{base}/{el.get('name')}"
                for el in root.findall("node") if el.get("name")]
    return ifaces, children


def _protocol_of(ifaces):
    if core.DBUSMENU_IFACE in ifaces:
        return "dbusmenu"
    if core.GTK_MENUS_IFACE in ifaces:
        return "gtk"
    if GTK_ACTIONS_IFACE in ifaces:
        return "gtkactions"
    return None


def find_menu_object(pid):
    """-> (bus name, object path, protocol) for `pid`, or None.

    A real menu (`com.canonical.dbusmenu` or `org.gtk.Menus`) always wins over
    a bare `org.gtk.Actions` object, even if the actions object is found first.
    """
    fallback = None
    for name in names_for_pid(pid):
        hit_here = False
        for path in candidate_paths(name):
            ifaces, _children = _introspect(name, path)
            protocol = _protocol_of(ifaces)
            if protocol in ("dbusmenu", "gtk"):
                return name, path, protocol
            if protocol == "gtkactions":
                hit_here = True
                if fallback is None:
                    fallback = (name, path, protocol)
        if hit_here:
            continue
        # Nothing at the usual addresses: walk the object tree once.
        queue, seen, budget = ["/"], {"/"}, SWEEP_BUDGET
        while queue and budget > 0:
            current = queue.pop(0)
            budget -= 1
            ifaces, children = _introspect(name, current)
            protocol = _protocol_of(ifaces)
            if protocol in ("dbusmenu", "gtk"):
                return name, current, protocol
            if protocol == "gtkactions" and fallback is None:
                fallback = (name, current, protocol)
            for child in children:
                if child not in seen:
                    seen.add(child)
                    queue.append(child)
    return fallback


def owner_info(pid):
    """JSON-able answer for `menu-client owner PID`. `{}` when nothing found."""
    try:
        found = find_menu_object(pid)
    except ServiceGone:
        return {}
    if not found:
        return {}
    name, path, protocol = found
    return {"service": name, "path": path, "protocol": protocol}
