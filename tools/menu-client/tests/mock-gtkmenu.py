#!/usr/bin/env python3
"""A minimal org.gtk.Menus + org.gtk.Actions producer.

Mirrors the shape a GTK3 app exports: the menu model lives at
/org/gtk/mock/menus/menubar, the action group at the ancestor path
/org/gtk/mock, so the client's action-path discovery is exercised too.

The Edit menu deliberately sits in subscription group 1, which forces the
client to call Start() a second time for the referenced group.

Every Activate() is appended as one JSON object per line to --record.
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

MENUS_IFACE = "org.gtk.Menus"
ACTIONS_IFACE = "org.gtk.Actions"

S = dbus.String


def item(**kwargs):
    return dbus.Dictionary(kwargs, signature="sv")


def ref(group, menu):
    return dbus.Struct((dbus.UInt32(group), dbus.UInt32(menu)),
                       signature="uu", variant_level=1)


# (group, menu) -> items. Group 0 menu 0 is the menubar root.
MENUS = {
    (0, 0): [
        item(label=S("_File"), **{":submenu": ref(0, 1)}),
        item(label=S("_Edit"), **{":submenu": ref(1, 0)}),
    ],
    (0, 1): [                                   # File: two sections
        item(**{":section": ref(0, 2)}),
        item(**{":section": ref(0, 3)}),
    ],
    (0, 2): [
        item(label=S("_New"), action=S("app.new"), accel=S("<Control>n")),
        item(label=S("&Open"), action=S("app.open")),
    ],
    (0, 3): [
        item(label=S("_Quit"), action=S("app.quit"), accel=S("<Control>q")),
    ],
    (1, 0): [                                   # Edit, in another group
        item(label=S("_Copy"), action=S("win.copy")),
        item(label=S("_Paste"), action=S("win.paste")),
        item(label=S("Word _Wrap"), action=S("win.wrap")),
        item(label=S("_List view"), action=S("win.view"),
             target=S("list")),
        item(label=S("_Grid view"), action=S("win.view"),
             target=S("grid")),
    ],
}

# name -> (enabled, parameter signature, state)
ACTIONS = {
    "new":   (True, "", []),
    "open":  (True, "", []),
    "quit":  (True, "", []),
    "copy":  (False, "", []),                   # disabled
    "paste": (True, "", []),
    "wrap":  (True, "", [dbus.Boolean(True)]),  # checkable, on
    "view":  (True, "s", [S("list")]),          # radio, "list" selected
}


def describe(name):
    enabled, param_sig, state = ACTIONS[name]
    return dbus.Struct(
        (dbus.Boolean(enabled), dbus.Signature(param_sig),
         dbus.Array(state, signature="v")),
        signature="bgav")


class MockMenus(dbus.service.Object):
    @dbus.service.method(MENUS_IFACE, in_signature="au",
                         out_signature="a(uuaa{sv})")
    def Start(self, groups):
        wanted = {int(g) for g in groups}
        return dbus.Array(
            [dbus.Struct((dbus.UInt32(g), dbus.UInt32(m),
                          dbus.Array(items, signature="a{sv}")),
                         signature="uuaa{sv}")
             for (g, m), items in sorted(MENUS.items()) if g in wanted],
            signature="(uuaa{sv})")

    @dbus.service.method(MENUS_IFACE, in_signature="au", out_signature="")
    def End(self, groups):
        pass

    @dbus.service.signal(MENUS_IFACE, signature="a(uuuuaa{sv})")
    def Changed(self, changes):
        pass


class MockActions(dbus.service.Object):
    def __init__(self, bus_name, path, record):
        super().__init__(bus_name, path)
        self.record = record

    @dbus.service.method(ACTIONS_IFACE, in_signature="", out_signature="as")
    def List(self):
        return dbus.Array([S(n) for n in ACTIONS], signature="s")

    @dbus.service.method(ACTIONS_IFACE, in_signature="s", out_signature="bgav")
    def Describe(self, action_name):
        name = str(action_name)
        if name not in ACTIONS:
            raise dbus.DBusException(f"no such action: {name}")
        return describe(name)

    @dbus.service.method(ACTIONS_IFACE, in_signature="",
                         out_signature="a{s(bgav)}")
    def DescribeAll(self):
        return dbus.Dictionary({S(n): describe(n) for n in ACTIONS},
                               signature="s(bgav)")

    @dbus.service.method(ACTIONS_IFACE, in_signature="sava{sv}",
                         out_signature="")
    def Activate(self, action_name, parameter, platform_data):
        params = [str(p) if isinstance(p, dbus.String) else
                  (bool(p) if isinstance(p, dbus.Boolean) else
                   (int(p) if isinstance(p, int) else str(p)))
                  for p in parameter]
        entry = {"action": str(action_name), "params": params}
        if self.record:
            with open(self.record, "a") as fh:
                fh.write(json.dumps(entry) + "\n")
                fh.flush()
        print(f"ACTIVATE {entry['action']} params={entry['params']}", flush=True)

    @dbus.service.method(ACTIONS_IFACE, in_signature="sva{sv}",
                         out_signature="")
    def SetState(self, action_name, value, platform_data):
        pass

    @dbus.service.signal(ACTIONS_IFACE,
                         signature="asa{sb}a{sv}a{s(bgav)}")
    def Changed(self, removed, enabled_changed, state_changed, added):
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bus-name", default="org.example.MockGtkMenu")
    ap.add_argument("--menus-path", default="/org/gtk/mock/menus/menubar")
    ap.add_argument("--actions-path", default="/org/gtk/mock")
    ap.add_argument("--record", default=os.environ.get("MOCK_RECORD"))
    args = ap.parse_args()

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(args.bus_name, bus, do_not_queue=True)
    MockMenus(name, args.menus_path)
    MockActions(name, args.actions_path, args.record)

    loop = GLib.MainLoop()
    try:
        from gi.repository import GLibUnix
        add_signal = GLibUnix.signal_add
    except ImportError:
        add_signal = GLib.unix_signal_add
    for sig in (signal.SIGINT, signal.SIGTERM):
        add_signal(GLib.PRIORITY_HIGH, sig, lambda *_: loop.quit())
    print(f"READY {args.bus_name} {args.menus_path}", flush=True)
    loop.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
