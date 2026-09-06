"""org.gtk.Menus + org.gtk.Actions backend (GTK3/GTK4 apps).

The menu model and the action state live in two different places, and often at
two different object paths: org.gtk.Menus at e.g.
/org/gtk/Application/anonymous/menus/menubar, org.gtk.Actions at
/org/gtk/Application/anonymous (the "app." namespace) and at
/org/gtk/Application/anonymous/window/1 (the "win." namespace). We are handed
only the menu path, so the action objects are discovered by walking up to the
ancestors and, if that finds no window group, one bounded sweep downwards.
`--gtk-actions-path` overrides the guess.

Node ids:
    gtk:ACTION                     activatable, no target
    gtk:ACTION?sig=S&target=JSON   activatable, with a target (S restores the
                                   original scalar DBus type)
    gtknode:GROUP/MENU/INDEX       structural (submenu parent, label-only item)
    gtksep:GROUP/MENU/INDEX        separator synthesised between sections
Only "gtk:" ids can be activated.
"""

import json

import dbus

from . import core
from .core import (GTK_ACTIONS_IFACE, GTK_MENUS_IFACE, BadNodeId, MenuError,
                   ServiceGone)

MAX_SUBSCRIBE_ROUNDS = 16
MAX_DISCOVERY_NODES = 48
KNOWN_PREFIXES = ("app", "win", "unity")


# --------------------------------------------------------------------------
# ids
# --------------------------------------------------------------------------

def encode_id(action, target, sig):
    if target is None:
        return f"gtk:{action}"
    payload = json.dumps(target, separators=(",", ":"), sort_keys=True)
    return f"gtk:{action}?sig={sig}&target={payload}"


def decode_id(node_id):
    """-> (action, target, sig). Raises BadNodeId for non-activatable ids."""
    if not node_id.startswith("gtk:"):
        raise BadNodeId(
            f"{node_id!r} is not an activatable org.gtk.Menus id "
            "(activatable ids start with 'gtk:'; 'gtknode:'/'gtksep:' ids are "
            "structural and carry no action)")
    rest = node_id[4:]
    action, sep, query = rest.partition("?")
    if not action:
        raise BadNodeId(f"{node_id!r} carries no action name")
    if not sep:
        return action, None, ""
    sig_part, has_target, target_json = query.partition("&target=")
    sig = sig_part[4:] if sig_part.startswith("sig=") else ""
    if not has_target:
        return action, None, sig
    try:
        return action, json.loads(target_json), sig
    except ValueError as exc:
        raise BadNodeId(f"{node_id!r} has an unparseable target: {exc}") from None


def _split_action(action):
    prefix, dot, bare = action.partition(".")
    if dot and prefix in KNOWN_PREFIXES:
        return prefix, bare
    return "", action


# --------------------------------------------------------------------------
# org.gtk.Actions
# --------------------------------------------------------------------------

def _ancestors(path):
    out = [path]
    cur = path.rstrip("/")
    while "/" in cur[1:]:
        cur = cur.rsplit("/", 1)[0] or "/"
        out.append(cur)
        if cur == "/":
            break
    if "/" not in out:
        out.append("/")
    return out


class Actions:
    """Resolved org.gtk.Actions objects plus a cached DescribeAll per path."""

    def __init__(self, name, paths, default):
        self.name = name
        self.paths = paths          # prefix -> object path
        self.default = default      # object path or None
        self._described = {}

    def path_for(self, prefix):
        return self.paths.get(prefix) or self.default

    def describe(self, path):
        if path not in self._described:
            try:
                obj = core.bus().get_object(self.name, path, introspect=False)
                raw = obj.DescribeAll(dbus_interface=GTK_ACTIONS_IFACE,
                                      timeout=core.CALL_TIMEOUT)
                self._described[path] = {str(k): core.py(v)
                                         for k, v in raw.items()}
            except dbus.DBusException:
                self._described[path] = None
        return self._described[path]

    def lookup(self, action):
        """-> (found, enabled, state_value_or_None, key_to_activate)."""
        prefix, bare = _split_action(action)
        path = self.path_for(prefix)
        if path is None:
            return False, None, None, bare
        described = self.describe(path)
        if described is None:
            return False, None, None, bare
        for key in (bare, action):
            entry = described.get(key)
            if entry is None:
                continue
            enabled = bool(entry[0])
            state = entry[2] if len(entry) > 2 else []
            value = state[0] if state else None
            return True, enabled, value, key
        return False, None, None, bare


def resolve_actions(name, menu_path, overrides=None):
    paths, default = {}, None

    for spec in overrides or []:
        prefix, eq, path = spec.partition("=")
        if eq:
            paths[prefix] = path
        else:
            paths.setdefault("", spec)
            default = default or spec
    if default is None and paths:
        default = next(iter(paths.values()))

    found = []
    for path in _ancestors(menu_path):
        if GTK_ACTIONS_IFACE in core.interfaces_at(name, path):
            found.append(path)

    # No window group among the ancestors: sweep downwards once from the
    # highest ancestor that had actions (that is where /window/N usually sits).
    if found and not any("/window" in p for p in found):
        queue, seen, budget = [found[-1]], set(found), MAX_DISCOVERY_NODES
        while queue and budget > 0:
            current = queue.pop(0)
            for child in core.child_paths(name, current):
                budget -= 1
                if budget <= 0 or child in seen:
                    continue
                seen.add(child)
                queue.append(child)
                if GTK_ACTIONS_IFACE in core.interfaces_at(name, child):
                    found.append(child)

    for path in found:
        prefix = "win" if "/window" in path else "app"
        paths.setdefault(prefix, path)
        if default is None:
            default = path
    return Actions(name, paths, default)


# --------------------------------------------------------------------------
# org.gtk.Menus
# --------------------------------------------------------------------------

def _menus_iface(name, path):
    obj = core.bus().get_object(name, path, introspect=False)
    return dbus.Interface(obj, GTK_MENUS_IFACE)


def _ref(value):
    return (int(value[0]), int(value[1]))


def _subscribe(iface):
    """Start() every group the menu references, transitively. Returns
    {(group, menu): [raw item dict, ...]} plus the set of groups subscribed."""
    collected, subscribed, pending = {}, set(), {0}

    for _ in range(MAX_SUBSCRIBE_ROUNDS):
        groups = sorted(pending - subscribed)
        if not groups:
            break
        try:
            result = iface.Start(dbus.Array(groups, signature="u"),
                                 timeout=core.CALL_TIMEOUT)
        except dbus.DBusException as exc:
            if core._is_gone(exc):
                raise ServiceGone(f"service disappeared: {exc}") from exc
            raise MenuError(f"org.gtk.Menus.Start failed: {exc}") from exc
        subscribed.update(groups)
        for entry in result:
            collected[(int(entry[0]), int(entry[1]))] = list(entry[2])

        pending = set()
        for items in collected.values():
            for item in items:
                for key in (":section", ":submenu"):
                    if key in item:
                        group = _ref(item[key])[0]
                        if group not in subscribed:
                            pending.add(group)
    return collected, subscribed


def _item_node(item, ref, index, actions):
    label = core.strip_mnemonics(core.py(item.get("label")) or "")
    action = core.py(item.get("action"))
    accel = core.py(item.get("accel"))

    raw_target = item.get("target")
    target = None if raw_target is None else core.py(raw_target)
    sig = "" if raw_target is None else core.scalar_signature(raw_target)

    enabled, checked = True, None
    if action:
        node_id = encode_id(action, target, sig)
        found, act_enabled, state, _key = actions.lookup(action)
        if found:
            enabled = act_enabled
            if state is not None:
                if target is not None:
                    checked = state == target
                elif isinstance(state, bool):
                    checked = state
        elif actions.default is not None:
            # The action group exists but does not carry this action: GTK
            # renders such an item insensitive.
            enabled = False
    else:
        node_id = f"gtknode:{ref[0]}/{ref[1]}/{index}"

    return core.node(
        node_id=node_id,
        label=label,
        enabled=enabled,
        # org.gtk.Menus has no per-item visibility flag; hidden items are
        # simply absent from the model.
        visible=True,
        checked=checked,
        separator=False,
        shortcut=accel or None,
        children=[],
    )


def _build(collected, ref, seen, actions):
    items = collected.get(ref) or []
    out = []
    after_section = False

    for index, item in enumerate(items):
        if ":section" in item:
            sub = _ref(item[":section"])
            kids = [] if sub in seen else _build(collected, sub,
                                                 seen | {ref}, actions)
            if not kids:
                continue
            if out and not out[-1]["separator"]:
                out.append(core.node(
                    node_id=f"gtksep:{ref[0]}/{ref[1]}/{index}", separator=True))
            out.extend(kids)
            after_section = True
            continue

        node = _item_node(item, ref, index, actions)
        if ":submenu" in item:
            sub = _ref(item[":submenu"])
            if sub not in seen:
                node["children"] = _build(collected, sub, seen | {ref}, actions)
        if after_section and out and not out[-1]["separator"]:
            out.append(core.node(
                node_id=f"gtksep:{ref[0]}/{ref[1]}/{index}i", separator=True))
        after_section = False
        out.append(node)

    return out


def fetch(name, path, gtk_actions_paths=None, keep_subscription=False,
          **_ignored):
    iface = _menus_iface(name, path)
    collected, subscribed = _subscribe(iface)
    actions = resolve_actions(name, path, gtk_actions_paths)

    children = _build(collected, (0, 0), set(), actions)

    if not keep_subscription and subscribed:
        try:
            iface.End(dbus.Array(sorted(subscribed), signature="u"),
                      timeout=core.CALL_TIMEOUT)
        except dbus.DBusException:
            pass

    return core.node(node_id="gtknode:root", children=children)


def activate(name, path, node_id, gtk_actions_paths=None, **_ignored):
    action, target, sig = decode_id(node_id)
    actions = resolve_actions(name, path, gtk_actions_paths)

    prefix, bare = _split_action(action)
    actions_path = actions.path_for(prefix)
    if actions_path is None:
        raise MenuError(
            f"no {GTK_ACTIONS_IFACE} object found for {name} near {path}; "
            "pass --gtk-actions-path")

    _found, _enabled, _state, key = actions.lookup(action)

    params = dbus.Array([], signature="v")
    if target is not None:
        params = dbus.Array([core.to_dbus(target, sig)], signature="v")

    try:
        obj = core.bus().get_object(name, actions_path, introspect=False)
        obj.Activate(dbus.String(key), params,
                     dbus.Dictionary({}, signature="sv"),
                     dbus_interface=GTK_ACTIONS_IFACE,
                     timeout=core.CALL_TIMEOUT)
    except dbus.DBusException as exc:
        if core._is_gone(exc):
            raise ServiceGone(f"service disappeared: {exc}") from exc
        raise MenuError(
            f"org.gtk.Actions.Activate({key!r}) at {actions_path} "
            f"failed: {exc}") from exc


def watch(name, path, on_change, gtk_actions_paths=None, **_ignored):
    b = core.bus()

    def menus_changed(changes):
        on_change({"event": "menus-changed", "count": len(changes)})

    def actions_changed(removed, enabled_changed, state_changed, added):
        on_change({"event": "actions-changed",
                   "removed": [str(x) for x in removed],
                   "enabled": [str(x) for x in enabled_changed],
                   "state": [str(x) for x in state_changed],
                   "added": [str(x) for x in added]})

    b.add_signal_receiver(menus_changed, signal_name="Changed",
                          dbus_interface=GTK_MENUS_IFACE,
                          bus_name=name, path=path)

    actions = resolve_actions(name, path, gtk_actions_paths)
    for actions_path in set(actions.paths.values()) | (
            {actions.default} if actions.default else set()):
        b.add_signal_receiver(actions_changed, signal_name="Changed",
                              dbus_interface=GTK_ACTIONS_IFACE,
                              bus_name=name, path=actions_path)

    # Keep the model subscribed so the app keeps emitting Changed.
    try:
        _subscribe(_menus_iface(name, path))
    except MenuError:
        pass
