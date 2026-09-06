#!/usr/bin/env python3
"""A minimal com.canonical.dbusmenu producer, so the client can be exercised
end to end without a real Qt/KDE application.

Exports File > New / Open / --- / Quit and Edit > Copy (disabled) / Paste /
Word Wrap (checkable, on) / Hidden (visible=false). Labels deliberately mix
GTK "_" and Qt "&" mnemonics.

Every Event() is appended as one JSON object per line to --record, so a test
can assert that an activation actually arrived.

org.example.MockControl.Touch() bumps the revision and emits LayoutUpdated,
which is how `menu-client watch` gets tested.
"""

import argparse
import json
import os
import signal
import sys

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

IFACE = "com.canonical.dbusmenu"
CONTROL_IFACE = "org.example.MockControl"

S = dbus.String
B = dbus.Boolean
I = dbus.Int32


def props(**kwargs):
    return dbus.Dictionary(kwargs, signature="sv")


def shortcut(*parts):
    return dbus.Array([dbus.Array([S(p) for p in parts], signature="s")],
                      signature="as")


SUBMENU = props(**{"children-display": S("submenu")})

# id -> (properties, [child ids])
ITEMS = {
    0:  (SUBMENU, [1, 6]),
    1:  (props(label=S("_File"), **{"children-display": S("submenu")}),
         [2, 3, 4, 5]),
    2:  (props(label=S("_New"), shortcut=shortcut("Control", "N")), []),
    3:  (props(label=S("&Open")), []),
    4:  (props(type=S("separator")), []),
    5:  (props(label=S("_Quit"), shortcut=shortcut("Control", "Q")), []),
    6:  (props(label=S("_Edit"), **{"children-display": S("submenu")}),
         [7, 8, 9, 10]),
    7:  (props(label=S("_Copy"), enabled=B(False)), []),
    8:  (props(label=S("_Paste")), []),
    9:  (props(label=S("Word &Wrap"), **{"toggle-type": S("checkmark"),
                                         "toggle-state": I(1)}), []),
    10: (props(label=S("Hi&dden"), visible=B(False)), []),
}


class MockMenu(dbus.service.Object):
    def __init__(self, bus_name, path, record):
        super().__init__(bus_name, path)
        self.record = record
        self.revision = dbus.UInt32(1)

    # -- layout ----------------------------------------------------------
    def _layout(self, item_id, depth, names):
        item_props, children = ITEMS[item_id]
        if names:
            wanted = {str(n) for n in names}
            item_props = dbus.Dictionary(
                {k: v for k, v in item_props.items() if str(k) in wanted},
                signature="sv")
        if depth == 0:
            kids = []
        else:
            next_depth = -1 if depth < 0 else depth - 1
            kids = [self._layout(c, next_depth, names) for c in children]
        return dbus.Struct(
            (I(item_id), item_props, dbus.Array(kids, signature="v")),
            signature="ia{sv}av", variant_level=1)

    @dbus.service.method(IFACE, in_signature="iias", out_signature="u(ia{sv}av)")
    def GetLayout(self, parentId, recursionDepth, propertyNames):
        parent = int(parentId)
        if parent not in ITEMS:
            raise dbus.DBusException(f"no such item: {parent}")
        return (self.revision,
                self._layout(parent, int(recursionDepth), propertyNames))

    @dbus.service.method(IFACE, in_signature="aias", out_signature="a(ia{sv})")
    def GetGroupProperties(self, ids, propertyNames):
        wanted = [int(i) for i in ids] or list(ITEMS)
        return dbus.Array(
            [dbus.Struct((I(i), ITEMS[i][0]), signature="ia{sv}")
             for i in wanted if i in ITEMS],
            signature="(ia{sv})")

    @dbus.service.method(IFACE, in_signature="is", out_signature="v")
    def GetProperty(self, id, name):
        item = ITEMS.get(int(id))
        if not item or str(name) not in item[0]:
            raise dbus.DBusException(f"no property {name} on item {id}")
        return item[0][str(name)]

    # -- interaction -----------------------------------------------------
    def _log(self, entry):
        if not self.record:
            return
        with open(self.record, "a") as fh:
            fh.write(json.dumps(entry) + "\n")
            fh.flush()

    @dbus.service.method(IFACE, in_signature="isvu", out_signature="")
    def Event(self, id, eventId, data, timestamp):
        entry = {"id": str(int(id)), "event": str(eventId),
                 "timestamp": int(timestamp)}
        self._log(entry)
        print(f"EVENT {entry['event']} id={entry['id']}", flush=True)

    @dbus.service.method(IFACE, in_signature="a(isvu)", out_signature="ai")
    def EventGroup(self, events):
        for item_id, event_id, data, timestamp in events:
            self.Event(item_id, event_id, data, timestamp)
        return dbus.Array([], signature="i")

    @dbus.service.method(IFACE, in_signature="i", out_signature="b")
    def AboutToShow(self, id):
        # Everything is already in the layout, so nothing needs re-fetching.
        return dbus.Boolean(False)

    @dbus.service.method(IFACE, in_signature="ai", out_signature="aiai")
    def AboutToShowGroup(self, ids):
        return (dbus.Array([], signature="i"), dbus.Array([], signature="i"))

    # -- properties ------------------------------------------------------
    PROPERTIES = {
        "Version": dbus.UInt32(4),
        "TextDirection": S("ltr"),
        "Status": S("normal"),
        "IconThemePath": dbus.Array([], signature="s"),
    }

    @dbus.service.method("org.freedesktop.DBus.Properties",
                         in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        if str(interface) != IFACE or str(prop) not in self.PROPERTIES:
            raise dbus.DBusException(f"no property {interface}.{prop}")
        return self.PROPERTIES[str(prop)]

    @dbus.service.method("org.freedesktop.DBus.Properties",
                         in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        if str(interface) != IFACE:
            return dbus.Dictionary({}, signature="sv")
        return dbus.Dictionary(self.PROPERTIES, signature="sv")

    # -- signals ---------------------------------------------------------
    @dbus.service.signal(IFACE, signature="ui")
    def LayoutUpdated(self, revision, parent):
        pass

    @dbus.service.signal(IFACE, signature="a(ia{sv})a(ias)")
    def ItemsPropertiesUpdated(self, updatedProps, removedProps):
        pass

    @dbus.service.method(CONTROL_IFACE, in_signature="", out_signature="u")
    def Touch(self):
        """Test hook: pretend the menu changed."""
        self.revision = dbus.UInt32(int(self.revision) + 1)
        self.LayoutUpdated(self.revision, I(0))
        return self.revision


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bus-name", default="org.example.MockDBusMenu")
    ap.add_argument("--path", default="/MenuBar")
    ap.add_argument("--record", default=os.environ.get("MOCK_RECORD"))
    args = ap.parse_args()

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(args.bus_name, bus, do_not_queue=True)
    MockMenu(name, args.path, args.record)

    loop = GLib.MainLoop()
    try:
        from gi.repository import GLibUnix
        add_signal = GLibUnix.signal_add
    except ImportError:
        add_signal = GLib.unix_signal_add
    for sig in (signal.SIGINT, signal.SIGTERM):
        add_signal(GLib.PRIORITY_HIGH, sig, lambda *_: loop.quit())
    print(f"READY {args.bus_name} {args.path}", flush=True)
    loop.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
