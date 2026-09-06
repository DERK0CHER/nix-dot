"""One normalised menu tree from com.canonical.dbusmenu, org.gtk.Menus, or --
for GTK4/libadwaita apps that export no menu at all -- a tree synthesised from
org.gtk.Actions. See core.py for the node contract."""

from . import core, dbusmenu, gtkactions, gtkmenu
from .core import (BadNodeId, MenuError, ServiceGone, UnsupportedProtocol,
                   strip_mnemonics)

__all__ = ["fetch", "activate", "watch", "resolve", "strip_mnemonics",
           "MenuError", "ServiceGone", "UnsupportedProtocol", "BadNodeId"]

BACKENDS = {"dbusmenu": dbusmenu, "gtk": gtkmenu, "gtkactions": gtkactions}


def resolve(name, path, protocol=None):
    """-> (protocol_name, backend_module)."""
    proto = protocol or core.detect(name, path)
    try:
        return proto, BACKENDS[proto]
    except KeyError:
        raise MenuError(
            f"unknown protocol {proto!r} (expected one of "
            f"{', '.join(sorted(BACKENDS))})") from None


def fetch(name, path, protocol=None, **kwargs):
    """Normalised root node for the menu exported at (name, path)."""
    _proto, backend = resolve(name, path, protocol)
    return backend.fetch(name, path, **kwargs)


def activate(name, path, node_id, protocol=None, **kwargs):
    _proto, backend = resolve(name, path, protocol)
    return backend.activate(name, path, node_id, **kwargs)


def watch(name, path, on_change, protocol=None, **kwargs):
    _proto, backend = resolve(name, path, protocol)
    return backend.watch(name, path, on_change, **kwargs)
