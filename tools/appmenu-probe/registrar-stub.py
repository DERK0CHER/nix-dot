#!/usr/bin/env python3
"""Minimal com.canonical.AppMenu.Registrar, used to answer one question:

does any application on this machine export its menu over DBus at all?

KDE/Qt apps (via plasma-integration) and GTK3 apps (via appmenu-gtk-module)
register their menu with this well-known name. If nothing registers while this
stub owns the name, there is no menu producer here and a compositor-side
protocol implementation would have nothing to talk to.

Prints one line per registration and keeps a JSON map in
$XDG_RUNTIME_DIR/appmenu-registrar.json so other tools can read it.
"""
import json, os, signal, sys

try:
    from pydbus import SessionBus            # noqa: F401
    HAVE = "pydbus"
except ImportError:
    try:
        import dbus, dbus.service            # noqa: F401
        from dbus.mainloop.glib import DBusGMainLoop
        HAVE = "dbus-python"
    except ImportError:
        HAVE = None

STATE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
                     "appmenu-registrar.json")

if HAVE is None:
    sys.exit("needs python-dbus (or python-pydbus). "
             "Install with: sudo pacman -S --needed python-dbus python-gobject")

if HAVE == "dbus-python":
    import dbus, dbus.service
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib

    registry = {}

    def dump():
        with open(STATE, "w") as fh:
            json.dump(registry, fh, indent=2)

    class Registrar(dbus.service.Object):
        @dbus.service.method("com.canonical.AppMenu.Registrar",
                             in_signature="uo", sender_keyword="sender")
        def RegisterWindow(self, windowId, menuObjectPath, sender=None):
            registry[str(windowId)] = {"service": str(sender),
                                       "path": str(menuObjectPath)}
            dump()
            print(f"REGISTER window={windowId} service={sender} "
                  f"path={menuObjectPath}", flush=True)

        @dbus.service.method("com.canonical.AppMenu.Registrar", in_signature="u")
        def UnregisterWindow(self, windowId):
            registry.pop(str(windowId), None)
            dump()
            print(f"UNREGISTER window={windowId}", flush=True)

        @dbus.service.method("com.canonical.AppMenu.Registrar",
                             in_signature="u", out_signature="so")
        def GetMenuForWindow(self, windowId):
            e = registry.get(str(windowId))
            if not e:
                raise dbus.DBusException("no menu for that window")
            return (e["service"], e["path"])

        @dbus.service.method("com.canonical.AppMenu.Registrar",
                             out_signature="a(uso)")
        def GetMenus(self):
            return [(int(w), e["service"], e["path"])
                    for w, e in registry.items()]

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName("com.canonical.AppMenu.Registrar", bus,
                                do_not_queue=True)
    Registrar(bus, "/com/canonical/AppMenu/Registrar")
    dump()
    print("registrar listening on com.canonical.AppMenu.Registrar "
          f"(state: {STATE})", flush=True)
    loop = GLib.MainLoop()
    signal.signal(signal.SIGINT, lambda *_: loop.quit())
    signal.signal(signal.SIGTERM, lambda *_: loop.quit())
    loop.run()
