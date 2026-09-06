pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The focused window's exported application menu, as one JSON tree.
//
// Two out-of-process steps, both cheap (~100 ms together on this machine):
//
//   1. `hyprctl appmenu <address>`  -> the hypr-appmenu plugin answers with the
//      DBus (service, object path) the window published over
//      org_kde_kwin_appmenu, or `{}` if it never published one.
//   2. `menu-client dump <service> <path> --indent 0` -> the whole menu as the
//      single JSON node contract documented in tools/menu-client/README.md.
//
// The address comes from Quickshell's Hyprland.activeToplevel, which reports it
// WITHOUT the 0x prefix while the plugin's hyprctl command insists on it - hence
// the normalisation below. Results are cached per window address so alt-tabbing
// back to an app you already opened is instant; the cached tree is published
// immediately and a fresh fetch then overwrites it in the background.
Singleton {
    id: root

    // ---- published state -------------------------------------------------

    // Root node of the menu, or null when the focused window has no menu.
    property var tree: null
    property string service: ""
    property string objectPath: ""

    // The top-level menus (File, Edit, ...), already filtered.
    readonly property var menus: {
        const t = root.tree;
        if (!t || !t.children)
            return [];
        return t.children.filter(n => n && n.visible && !n.separator);
    }

    readonly property bool hasMenu: root.menus.length > 0

    // ---- the focused window ----------------------------------------------

    readonly property string address: {
        const t = Hyprland.activeToplevel;
        if (!t || !t.address || t.address === "")
            return "";
        const a = "" + t.address;
        return a.startsWith("0x") ? a : "0x" + a;
    }

    onAddressChanged: root.request()

    // ---- where menu-client lives -----------------------------------------
    //
    // ~/.config/quickshell is a symlink into the dotfiles checkout, so the tool
    // sits two directories up from this file - but only once the symlink is
    // resolved, which is what `readlink -f` is for. $HYPRSHELL_MENU_CLIENT
    // overrides, and a menu-client on PATH is the last resort.
    property string clientPath: ""

    readonly property string shellDir: {
        let d = "" + Qt.resolvedUrl(".");
        if (d.startsWith("file://"))
            d = d.slice(7);
        while (d.endsWith("/"))
            d = d.slice(0, -1);
        return d;
    }

    Process {
        id: pWhich
        running: true
        command: ["sh", "-c",
            "for p in \"$HYPRSHELL_MENU_CLIENT\" " +
            "\"" + root.shellDir + "/../../tools/menu-client/menu-client\" " +
            "\"$HOME/Dokumente/hyprland/nix-dot/tools/menu-client/menu-client\" " +
            "\"$(command -v menu-client 2>/dev/null)\"; do " +
            "[ -n \"$p\" ] && [ -x \"$p\" ] && { readlink -f -- \"$p\"; exit 0; }; " +
            "done; exit 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p === "") {
                    console.warn("AppMenuSource: no menu-client found; the global menu stays empty");
                    return;
                }
                root.clientPath = p;
                root.request();
            }
        }
    }

    // ---- fetch pipeline ---------------------------------------------------
    //
    // stage 0 idle, 1 waiting on hyprctl, 2 waiting on menu-client. Focus can
    // change while a fetch is in flight, so the in-flight address is remembered
    // and a late result for a window that is no longer focused only updates the
    // cache, never the published tree.
    property var cache: ({})
    property int stage: 0
    property string inFlight: ""
    property string wantAddr: ""
    property bool dirty: false
    property string pendingService: ""
    property string pendingPath: ""

    function request(): void {
        const a = root.address;
        root.wantAddr = a;
        const c = root.cache[a];
        if (c) {
            root.service = c.service;
            root.objectPath = c.objectPath;
            root.tree = c.tree;
        } else {
            root.service = "";
            root.objectPath = "";
            root.tree = null;
        }
        root.start();
    }

    // Re-read the menu for the window that is focused right now.
    function refresh(): void {
        root.start();
    }

    function start(): void {
        if (root.stage !== 0) {
            root.dirty = true;
            return;
        }
        const a = root.wantAddr;
        if (a === "" || root.clientPath === "") {
            root.finish(a, "", "", null);
            return;
        }
        root.inFlight = a;
        root.stage = 1;
        pLookup.command = ["hyprctl", "appmenu", a];
        pLookup.running = true;
    }

    function finish(a, svc, pth, t): void {
        root.stage = 0;
        if (a !== "")
            root.cache[a] = { "service": svc, "objectPath": pth, "tree": t };
        if (a === root.wantAddr) {
            root.service = svc;
            root.objectPath = pth;
            root.tree = t;
        }
        if (root.dirty || root.wantAddr !== a) {
            root.dirty = false;
            root.start();
        }
    }

    Process {
        id: pLookup
        stdout: StdioCollector {
            onStreamFinished: {
                const a = root.inFlight;
                let svc = "";
                let pth = "";
                try {
                    const o = JSON.parse(text);
                    if (o && o.service && o.path) {
                        svc = "" + o.service;
                        pth = "" + o.path;
                    }
                } catch (e) {
                    // `{}` for a window with no menu is valid JSON; anything else
                    // means the plugin is not loaded. Both mean "no menu".
                }
                if (svc === "" || pth === "") {
                    root.finish(a, "", "", null);
                    return;
                }
                root.stage = 2;
                root.pendingService = svc;
                root.pendingPath = pth;
                pDump.command = [root.clientPath, "dump", svc, pth, "--indent", "0"];
                pDump.running = true;
            }
        }
    }

    Process {
        id: pDump
        stdout: StdioCollector {
            onStreamFinished: {
                const a = root.inFlight;
                let t = null;
                try {
                    const o = JSON.parse(text);
                    if (o && o.children)
                        t = o;
                } catch (e) {
                    console.warn("AppMenuSource: menu-client dump is not JSON for", a);
                }
                root.finish(a, root.pendingService, root.pendingPath, t);
            }
        }
    }

    // If a helper never closes its stdout the pipeline would wedge on stage 1/2
    // and the bar would keep showing a stale menu forever. Unstick it; the next
    // focus change retries.
    Timer {
        interval: 4000
        repeat: true
        running: root.stage !== 0
        onTriggered: {
            if (root.stage !== 0) {
                console.warn("AppMenuSource: fetch timed out at stage", root.stage);
                root.stage = 0;
            }
        }
    }

    // ---- activation -------------------------------------------------------

    // Fires the entry and re-reads the menu shortly after, because activating a
    // checkable entry flips a state the dump has already snapshotted.
    //
    // Deliberately a Process and not execDetached: menu-client reports a failed
    // activation through its exit code and stderr, and a menu entry that quietly
    // does nothing is the single most confusing way for this to break.
    function activate(id): bool {
        if (root.clientPath === "" || root.service === "" || root.objectPath === "")
            return false;
        pActivate.running = false;
        pActivate.command = [root.clientPath, "activate", root.service, root.objectPath, "" + id];
        pActivate.running = true;
        reFetch.restart();
        return true;
    }

    Process {
        id: pActivate
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn("AppMenuSource: menu-client:", text.trim());
            }
        }
    }

    Timer {
        id: reFetch
        interval: 500
        onTriggered: root.refresh()
    }
}
