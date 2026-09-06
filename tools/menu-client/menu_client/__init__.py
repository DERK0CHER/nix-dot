"""One normalised menu tree from either com.canonical.dbusmenu or
org.gtk.Menus. See core.py for the node contract."""

from . import core, dbusmenu, gtkmenu
from .core import (BadNodeId, MenuError, ServiceGone, UnsupportedProtocol,
                   strip_mnemonics)

__all__ = ["fetch", "activate", "watch", "resolve", "strip_mnemonics",
           "MenuError", "ServiceGone", "UnsupportedProtocol", "BadNodeId"]

BACKENDS = {"dbusmenu": dbusmenu, "gtk": gtkmenu}


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
