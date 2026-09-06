"""Shared plumbing: bus access, DBus->python conversion, label cleanup,
protocol detection and the normalised-node contract.

The normalised node -- this is the contract the Quickshell bar consumes:

    {"id":        <string>,        # opaque, round-trips back to `activate`
     "label":     <string>,        # mnemonic markers stripped
     "enabled":   <bool>,
     "visible":   <bool>,
     "checked":   <bool|null>,     # null = not a checkable item
     "separator": <bool>,
     "shortcut":  <string|null>,
     "children":  [<node>, ...]}

Every key is always present. `fetch()` returns a single root node whose
`children` are the top-level menus; the root itself carries id "0" (dbusmenu)
or "gtknode:root" (gtk) and an empty label.
"""

import xml.etree.ElementTree as ET

try:
    import dbus
except ImportError:  # pragma: no cover - environment problem, not logic
    raise SystemExit(
        "menu-client needs python-dbus (and python-gobject for `watch`).\n"
        "Install with: sudo pacman -S --needed python-dbus python-gobject"
    )

DBUSMENU_IFACE = "com.canonical.dbusmenu"
GTK_MENUS_IFACE = "org.gtk.Menus"
GTK_ACTIONS_IFACE = "org.gtk.Actions"

CALL_TIMEOUT = 10.0


class MenuError(Exception):
    """Base class. `exit_code` is what the CLI returns."""

    exit_code = 1


class ServiceGone(MenuError):
    exit_code = 2


class UnsupportedProtocol(MenuError):
    exit_code = 3


class BadNodeId(MenuError):
    exit_code = 4


_MAINLOOP_READY = False


def enable_mainloop():
    """Must be called before `bus()` if signals are needed (i.e. `watch`)."""
    global _MAINLOOP_READY
    if not _MAINLOOP_READY:
        from dbus.mainloop.glib import DBusGMainLoop

        DBusGMainLoop(set_as_default=True)
        _MAINLOOP_READY = True


_BUS = None


def bus():
    global _BUS
    if _BUS is None:
        try:
            _BUS = dbus.SessionBus()
        except dbus.DBusException as exc:
            raise MenuError(f"cannot connect to the session bus: {exc}") from exc
    return _BUS


# --------------------------------------------------------------------------
# DBus value handling
# --------------------------------------------------------------------------

def py(value):
    """Recursively convert dbus-python types to plain JSON-able python.

    Order matters: dbus.Boolean subclasses int, dbus.String subclasses str,
    dbus.Struct subclasses tuple, dbus.Array subclasses list.
    """
    if isinstance(value, dbus.ByteArray):
        return bytes(value).decode("utf-8", "replace")
    if isinstance(value, dbus.Boolean):
        return bool(value)
    if isinstance(value, dbus.Byte):
        return int(value)
    if isinstance(value, (dbus.Int16, dbus.UInt16, dbus.Int32, dbus.UInt32,
                          dbus.Int64, dbus.UInt64)):
        return int(value)
    if isinstance(value, dbus.Double):
        return float(value)
    if isinstance(value, (dbus.ObjectPath, dbus.Signature, dbus.String)):
        return str(value)
    if isinstance(value, dbus.Dictionary):
        return {py(k): py(v) for k, v in value.items()}
    if isinstance(value, dbus.Struct):
        return tuple(py(v) for v in value)
    if isinstance(value, dbus.Array):
        return [py(v) for v in value]
    if isinstance(value, dict):
        return {py(k): py(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [py(v) for v in value]
    return value


_SCALAR_SIGS = (
    (dbus.Boolean, "b"), (dbus.Byte, "y"),
    (dbus.Int16, "n"), (dbus.UInt16, "q"),
    (dbus.Int32, "i"), (dbus.UInt32, "u"),
    (dbus.Int64, "x"), (dbus.UInt64, "t"),
    (dbus.Double, "d"),
    (dbus.ObjectPath, "o"), (dbus.Signature, "g"), (dbus.String, "s"),
)

_SIG_TO_DBUS = {
    "b": dbus.Boolean, "y": dbus.Byte,
    "n": dbus.Int16, "q": dbus.UInt16,
    "i": dbus.Int32, "u": dbus.UInt32,
    "x": dbus.Int64, "t": dbus.UInt64,
    "d": dbus.Double,
    "o": dbus.ObjectPath, "g": dbus.Signature, "s": dbus.String,
}


def scalar_signature(value):
    """Single-character DBus signature for a scalar, or "" if not a scalar."""
    for cls, sig in _SCALAR_SIGS:
        if isinstance(value, cls):
            return sig
    return ""


def to_dbus(value, sig=""):
    """Best-effort python -> dbus. `sig` (from scalar_signature) restores the
    original numeric/string type so GTK action targets round-trip."""
    if sig in _SIG_TO_DBUS:
        try:
            return _SIG_TO_DBUS[sig](value)
        except (TypeError, ValueError):
            pass
    if isinstance(value, bool):
        return dbus.Boolean(value)
    if isinstance(value, int):
        return dbus.Int32(value)
    if isinstance(value, float):
        return dbus.Double(value)
    if isinstance(value, str):
        return dbus.String(value)
    if isinstance(value, list):
        return dbus.Array([to_dbus(v) for v in value], signature="v")
    if isinstance(value, dict):
        return dbus.Dictionary(
            {dbus.String(k): to_dbus(v) for k, v in value.items()},
            signature="sv")
    return dbus.String(str(value))


# --------------------------------------------------------------------------
# Labels
# --------------------------------------------------------------------------

def strip_mnemonics(label):
    """Remove GTK ("_File") and Qt ("&File") mnemonic markers.

    A doubled marker is an escaped literal ("__" -> "_", "&&" -> "&"). A single
    marker is dropped when it precedes an alphanumeric character, which is the
    only place an accelerator letter can sit. Everything else is left alone.

    Caveat: a label that legitimately contains an undoubled "_" between word
    characters (e.g. "my_file.txt") loses it. Producers are supposed to double
    such underscores; not all of them do.
    """
    if not label:
        return ""
    out = []
    i = 0
    n = len(label)
    while i < n:
        ch = label[i]
        if ch in "_&":
            if i + 1 < n and label[i + 1] == ch:
                out.append(ch)
                i += 2
                continue
            if i + 1 < n and label[i + 1].isalnum():
                i += 1
                continue
        out.append(ch)
        i += 1
    return "".join(out)


def node(node_id, label="", enabled=True, visible=True, checked=None,
         separator=False, shortcut=None, children=None):
    """Build a contract-shaped node. Keeps key order stable for readable diffs."""
    return {
        "id": str(node_id),
        "label": label,
        "enabled": bool(enabled),
        "visible": bool(visible),
        "checked": checked,
        "separator": bool(separator),
        "shortcut": shortcut,
        "children": children if children is not None else [],
    }


# --------------------------------------------------------------------------
# Detection
# --------------------------------------------------------------------------

def _is_gone(exc):
    return exc.get_dbus_name() in (
        "org.freedesktop.DBus.Error.ServiceUnknown",
        "org.freedesktop.DBus.Error.NameHasNoOwner",
    )


def require_owner(name):
    try:
        owned = bool(bus().name_has_owner(name))
    except dbus.DBusException as exc:
        raise MenuError(f"session bus query failed: {exc}") from exc
    if not owned:
        raise ServiceGone(f"no process owns bus name {name!r}")


def interfaces_at(name, path):
    """Interface names implemented at `path`, via Introspectable. Empty set if
    the object refuses to introspect (some toolkits do)."""
    try:
        obj = bus().get_object(name, path, introspect=False)
        xml = obj.Introspect(
            dbus_interface="org.freedesktop.DBus.Introspectable",
            timeout=CALL_TIMEOUT)
    except dbus.DBusException as exc:
        if _is_gone(exc):
            raise ServiceGone(
                f"bus name {name!r} disappeared while introspecting") from exc
        return set()
    try:
        root = ET.fromstring(str(xml))
    except ET.ParseError:
        return set()
    return {el.get("name") for el in root.findall("interface") if el.get("name")}


def child_paths(name, path):
    """Child object node names under `path` (from Introspect)."""
    try:
        obj = bus().get_object(name, path, introspect=False)
        xml = obj.Introspect(
            dbus_interface="org.freedesktop.DBus.Introspectable",
            timeout=CALL_TIMEOUT)
        root = ET.fromstring(str(xml))
    except (dbus.DBusException, ET.ParseError):
        return []
    base = path.rstrip("/")
    return [f"{base}/{el.get('name')}"
            for el in root.findall("node") if el.get("name")]


def detect(name, path):
    """Return "dbusmenu" or "gtk". Introspection first, then a live probe for
    objects that do not advertise themselves."""
    require_owner(name)
    ifaces = interfaces_at(name, path)
    if DBUSMENU_IFACE in ifaces:
        return "dbusmenu"
    if GTK_MENUS_IFACE in ifaces:
        return "gtk"

    obj = bus().get_object(name, path, introspect=False)
    try:
        obj.GetLayout(0, 0, dbus.Array([], signature="s"),
                      dbus_interface=DBUSMENU_IFACE, timeout=CALL_TIMEOUT)
        return "dbusmenu"
    except dbus.DBusException as exc:
        if _is_gone(exc):
            raise ServiceGone(f"bus name {name!r} disappeared") from exc
    try:
        obj.Start(dbus.Array([0], signature="u"),
                  dbus_interface=GTK_MENUS_IFACE, timeout=CALL_TIMEOUT)
        try:
            obj.End(dbus.Array([0], signature="u"),
                    dbus_interface=GTK_MENUS_IFACE, timeout=CALL_TIMEOUT)
        except dbus.DBusException:
            pass
        return "gtk"
    except dbus.DBusException as exc:
        if _is_gone(exc):
            raise ServiceGone(f"bus name {name!r} disappeared") from exc

    raise UnsupportedProtocol(
        f"{name} {path} implements neither {DBUSMENU_IFACE} nor "
        f"{GTK_MENUS_IFACE}"
        + (f" (interfaces seen: {', '.join(sorted(ifaces))})" if ifaces else ""))
