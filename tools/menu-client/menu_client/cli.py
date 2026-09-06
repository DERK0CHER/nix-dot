"""menu-client CLI.

Exit codes:
    0  success
    1  generic failure (bad arguments, DBus call refused, ...)
    2  the bus name has no owner / went away mid-call
    3  the object speaks none of com.canonical.dbusmenu, org.gtk.Menus,
       org.gtk.Actions
    4  the node id is malformed or not activatable
"""

import argparse
import json
import sys

from . import core, gtkactions, resolve
from .core import MenuError


def _common(parser):
    parser.add_argument("bus_name", metavar="BUS-NAME",
                        help="e.g. :1.42 or org.example.App")
    parser.add_argument("object_path", metavar="OBJECT-PATH",
                        help="e.g. /MenuBar or /org/gtk/Application/anonymous/"
                             "menus/menubar")
    parser.add_argument("--protocol",
                        choices=("dbusmenu", "gtk", "gtkactions"),
                        help="skip auto-detection and force a protocol")
    parser.add_argument("--gtk-actions-path", action="append", metavar="[PREFIX=]PATH",
                        help="org.gtk.Actions object path; repeatable, and may "
                             "be prefixed (app=/org/gtk/Application/anonymous). "
                             "Ignored for com.canonical.dbusmenu.")


def build_parser():
    parser = argparse.ArgumentParser(
        prog="menu-client",
        description="Read an application's exported DBus menu as one "
                    "normalised JSON tree, and activate entries in it.")
    sub = parser.add_subparsers(dest="command", required=True)

    dump = sub.add_parser("dump", help="print the normalised JSON tree")
    _common(dump)
    dump.add_argument("--indent", type=int, default=2,
                      help="JSON indent; 0 for one compact line (default: 2)")
    dump.add_argument("--no-about-to-show", action="store_true",
                      help="do not send AboutToShow for lazily-populated "
                           "submenus (com.canonical.dbusmenu only)")

    act = sub.add_parser("activate", help="activate one entry by id")
    _common(act)
    act.add_argument("node_id", metavar="ID",
                     help="the `id` field of a node from `dump`")

    wat = sub.add_parser("watch", help="print one JSON line per menu change")
    _common(wat)

    own = sub.add_parser(
        "owner",
        help="find the menu object a process exports, by pid")
    own.add_argument("pid", metavar="PID", type=int,
                     help="process id, e.g. from `hyprctl activewindow -j`")
    own.add_argument("--indent", type=int, default=0,
                     help="JSON indent; 0 for one compact line (default: 0)")

    return parser


def _kwargs(args):
    return {
        "gtk_actions_paths": getattr(args, "gtk_actions_path", None),
        "about_to_show": not getattr(args, "no_about_to_show", False),
    }


def cmd_dump(args):
    _proto, backend = resolve(args.bus_name, args.object_path, args.protocol)
    tree = backend.fetch(args.bus_name, args.object_path, **_kwargs(args))
    if args.indent > 0:
        json.dump(tree, sys.stdout, indent=args.indent, ensure_ascii=False)
    else:
        json.dump(tree, sys.stdout, separators=(",", ":"), ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


def cmd_activate(args):
    _proto, backend = resolve(args.bus_name, args.object_path, args.protocol)
    backend.activate(args.bus_name, args.object_path, args.node_id,
                     **_kwargs(args))
    return 0


def cmd_watch(args):
    core.enable_mainloop()
    from gi.repository import GLib

    proto, backend = resolve(args.bus_name, args.object_path, args.protocol)
    loop = GLib.MainLoop()

    def emit(payload):
        payload = dict(payload)
        payload.setdefault("protocol", proto)
        print(json.dumps(payload, separators=(",", ":"), ensure_ascii=False),
              flush=True)

    backend.watch(args.bus_name, args.object_path, emit, **_kwargs(args))

    def owner_changed(_name, _old, new_owner):
        if not str(new_owner):
            emit({"event": "service-gone"})
            loop.quit()

    core.bus().add_signal_receiver(
        owner_changed, signal_name="NameOwnerChanged",
        dbus_interface="org.freedesktop.DBus",
        bus_name="org.freedesktop.DBus", arg0=args.bus_name)

    emit({"event": "watching"})
    try:
        loop.run()
    except KeyboardInterrupt:
        return 0
    return 0


def cmd_owner(args):
    """{"service","path","protocol"} for the pid, or {} if it exports none.

    Always exit 0: "this window has no menu" is the common case, not an error,
    and the shell reads stdout rather than the exit code.
    """
    info = gtkactions.owner_info(args.pid)
    if args.indent > 0:
        json.dump(info, sys.stdout, indent=args.indent, ensure_ascii=False)
    else:
        json.dump(info, sys.stdout, separators=(",", ":"), ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


COMMANDS = {"dump": cmd_dump, "activate": cmd_activate, "watch": cmd_watch,
            "owner": cmd_owner}


def main(argv=None):
    args = build_parser().parse_args(argv)
    try:
        return COMMANDS[args.command](args)
    except MenuError as exc:
        print(f"menu-client: {exc}", file=sys.stderr)
        return exc.exit_code
    except BrokenPipeError:
        return 0
    except KeyboardInterrupt:
        return 130
