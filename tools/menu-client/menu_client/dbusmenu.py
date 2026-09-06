"""com.canonical.dbusmenu backend (Qt/KDE apps, appmenu-gtk-module exports).

Node ids are the protocol's own int32 item ids rendered as decimal strings, so
they round-trip straight back into Event().
"""

import time

import dbus

from . import core
from .core import DBUSMENU_IFACE, MenuError, ServiceGone, BadNodeId

# toggle-state values per spec: 0 off, 1 on, anything else indeterminate.
_TOGGLE_TYPES = ("checkmark", "radio")


def _iface(name, path):
    obj = core.bus().get_object(name, path, introspect=False)
    return dbus.Interface(obj, DBUSMENU_IFACE)


def _get_layout(iface):
    try:
        revision, layout = iface.GetLayout(
            dbus.Int32(0), dbus.Int32(-1), dbus.Array([], signature="s"),
            timeout=core.CALL_TIMEOUT)
    except dbus.DBusException as exc:
        if core._is_gone(exc):
            raise ServiceGone(f"service disappeared: {exc}") from exc
        raise MenuError(f"GetLayout failed: {exc}") from exc
    return int(revision), core.py(layout)


def _lazy_ids(raw, out):
    """Ids that claim a submenu but shipped no children -- those need
    AboutToShow before the app will populate them."""
    item_id, props, children = raw
    if props.get("children-display") == "submenu" and not children:
        out.append(int(item_id))
    for child in children:
        _lazy_ids(child, out)
    return out


def _shortcut(value):
    """dbusmenu `shortcut` is aas: a list of key sequences, each a list of
    parts. Rendered as "Control+Q", multiple sequences joined with ", ".
    Modifier spelling is passed through as the app sent it."""
    if not value:
        return None
    sequences = []
    for seq in value:
        if isinstance(seq, (list, tuple)):
            parts = [str(p) for p in seq if str(p)]
            if parts:
                sequences.append("+".join(parts))
        elif seq:
            sequences.append(str(seq))
    return ", ".join(sequences) if sequences else None


def _node(raw):
    item_id, props, children = raw
    props = props if isinstance(props, dict) else {}

    separator = props.get("type") == "separator"
    toggle_type = props.get("toggle-type") or ""
    checked = None
    if toggle_type in _TOGGLE_TYPES:
        state = props.get("toggle-state", -1)
        if state == 1:
            checked = True
        elif state == 0:
            checked = False
        # anything else (-1) stays None: indeterminate

    return core.node(
        node_id=int(item_id),
        label=core.strip_mnemonics(props.get("label") or ""),
        enabled=props.get("enabled", True),
        visible=props.get("visible", True),
        checked=checked,
        separator=separator,
        shortcut=_shortcut(props.get("shortcut")),
        children=[_node(c) for c in children],
    )


def fetch(name, path, about_to_show=True, **_ignored):
    iface = _iface(name, path)
    _revision, layout = _get_layout(iface)

    if about_to_show:
        pending = _lazy_ids(layout, [])
        needs_refetch = False
        for item_id in pending:
            try:
                if bool(iface.AboutToShow(dbus.Int32(item_id),
                                          timeout=core.CALL_TIMEOUT)):
                    needs_refetch = True
            except dbus.DBusException:
                # Optional in practice; a refusal is not fatal.
                pass
        if needs_refetch:
            _revision, layout = _get_layout(iface)

    return _node(layout)


def activate(name, path, node_id, **_ignored):
    try:
        item_id = int(str(node_id).strip())
    except ValueError:
        raise BadNodeId(
            f"{node_id!r} is not a com.canonical.dbusmenu id "
            "(expected a decimal integer)") from None

    iface = _iface(name, path)
    # Best effort: tell the app the item is about to be shown. Some apps only
    # populate/refresh state on this call. Failure is not fatal.
    try:
        iface.AboutToShow(dbus.Int32(item_id), timeout=core.CALL_TIMEOUT)
    except dbus.DBusException:
        pass

    try:
        # The third argument is a VARIANT in the spec's (isvu) signature, not a
        # plain string. Without variant_level the call goes out as "issu" and a
        # real Qt app rejects it with UnknownMethod - the mocks accept both,
        # which is why the test suite never caught this.
        iface.Event(dbus.Int32(item_id), dbus.String("clicked"),
                    dbus.String("", variant_level=1),
                    dbus.UInt32(int(time.time())),
                    timeout=core.CALL_TIMEOUT)
    except dbus.DBusException as exc:
        if core._is_gone(exc):
            raise ServiceGone(f"service disappeared: {exc}") from exc
        raise MenuError(f"Event(clicked) failed for id {item_id}: {exc}") from exc


def watch(name, path, on_change, **_ignored):
    """Register signal handlers. Caller runs the main loop."""
    b = core.bus()

    def layout_updated(revision, parent):
        on_change({"event": "layout-updated",
                   "revision": int(revision),
                   "parent": str(int(parent))})

    def props_updated(updated, removed):
        on_change({"event": "properties-updated",
                   "updated": [str(int(entry[0])) for entry in updated],
                   "removed": [str(int(entry[0])) for entry in removed]})

    b.add_signal_receiver(layout_updated, signal_name="LayoutUpdated",
                          dbus_interface=DBUSMENU_IFACE,
                          bus_name=name, path=path)
    b.add_signal_receiver(props_updated, signal_name="ItemsPropertiesUpdated",
                          dbus_interface=DBUSMENU_IFACE,
                          bus_name=name, path=path)
