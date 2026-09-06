import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

// MRU Alt+Tab overlay. This file only draws and reacts: the keys are global
// Hyprland binds in hypr/hyprland/keybinds.conf driving the four IPC calls on
// shell.qml's `switcher` target. Nothing here takes keyboard focus - Hyprland
// consumes its own binds before any surface sees them, so a QML key handler
// could never see the Tab presses anyway.
PanelWindow {
    id: win

    // The window list, MRU order. Read once per open (see refresh()) and never
    // while the overlay is up: re-reading would reshuffle the tiles under the
    // user's fingers mid-press.
    property var clients: []

    // With zero or one window there is nothing to switch to, so no overlay.
    visible: ShellState.switcherOpen && clients.length > 1
    color: "transparent"

    // Follow the focused monitor. Without this Quickshell picks a default
    // screen, so on a two-monitor desk the overlay opens on the one you are not
    // looking at and Alt+Tab reads as doing nothing. (CommandPalette.qml does
    // the same.)
    readonly property var focusedScreen: {
        const fm = Hyprland.focusedMonitor;
        if (!fm)
            return null;
        const list = Quickshell.screens;
        for (let i = 0; i < list.length; i++)
            if (list[i].name === fm.name)
                return list[i];
        return null;
    }
    screen: focusedScreen

    exclusiveZone: 0
    WlrLayershell.namespace: "hyprshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property int tileW: 192
    readonly property int tileH: 132
    readonly property int rowWidth: clients.length > 0
        ? clients.length * tileW + (clients.length - 1) * Theme.gap
        : tileW
    readonly property int maxWidth: (screen ? screen.width : 1920) - 80
    readonly property int viewWidth: Math.min(rowWidth, maxWidth - Theme.pad * 2)

    implicitWidth: viewWidth + Theme.pad * 2
    implicitHeight: tileH + Theme.gap + 20 + Theme.pad * 2

    readonly property var selected: clients[ShellState.switcherIndex] || null

    // The overlay is closed by the Alt-release bind. If that ever fails to
    // arrive it would otherwise sit on screen forever, so give up on it.
    Timer {
        id: watchdog
        interval: 10000
        running: ShellState.switcherOpen
        onTriggered: ShellState.switcherOpen = false
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: win.load(text)
        }
    }

    function refresh(): void {
        win.clients = [];
        ShellState.switcherCount = 0;
        clientsProc.running = true;
    }

    function load(text) {
        let all = [];
        try {
            all = JSON.parse(text);
        } catch (e) {
            all = [];
        }
        // hyprctl reports `monitor` as the monitor id, which is what
        // Hyprland.focusedMonitor.id carries.
        const fm = Hyprland.focusedMonitor;
        const mon = fm ? fm.id : -1;
        // Every window on every monitor and workspace. Scoping this to the
        // focused output hid half the session: with one window per screen the
        // switcher had nothing to show, which reads as "it only catches apps".
        // The monitor is still available as a grouping hint, not a filter.
        const list = all.filter(c => c && c.mapped && !c.hidden);
        // focusHistoryID: 0 is the focused window, ascending walks back through
        // the focus history, so this is the MRU order for free.
        list.sort((a, b) => a.focusHistoryID - b.focusHistoryID);

        // Thumbnails need a wayland toplevel handle, which hyprctl knows nothing
        // about, so pair the two lists on title + app id. Anything that fails to
        // pair simply keeps its icon.
        const tops = ToplevelManager.toplevels ? ToplevelManager.toplevels.values : [];
        for (let i = 0; i < list.length; i++) {
            const c = list[i];
            c.toplevel = null;
            for (let j = 0; j < tops.length; j++) {
                const t = tops[j];
                if (!t)
                    continue;
                const sameApp = (t.appId || "") === (c["class"] || "")
                             || (t.appId || "") === (c.initialClass || "");
                if (sameApp && (t.title || "") === (c.title || "")) {
                    c.toplevel = t;
                    break;
                }
            }
        }

        win.clients = list;
        ShellState.switcherCount = list.length;
        if (list.length > 0) {
            const n = list.length;
            ShellState.switcherIndex = (ShellState.switcherIndex % n + n) % n;
        }
    }

    function commit(): void {
        const c = win.selected;
        if (c && c.address)
            Hyprland.dispatch("focuswindow address:" + c.address);
    }

    // Close the highlighted window without leaving the switcher, so Alt can stay
    // held and several windows closed in a row. The list is pruned locally
    // rather than re-read: hyprctl would still report the window for a moment
    // after closewindow, and the tile would flicker back.
    function closeSelected(): void {
        const c = win.selected;
        if (!c || !c.address)
            return;
        Hyprland.dispatch("closewindow address:" + c.address);

        const rest = win.clients.filter(x => x.address !== c.address);
        win.clients = rest;
        ShellState.switcherCount = rest.length;
        if (rest.length === 0) {
            ShellState.switcherOpen = false;
            return;
        }
        // Keep the highlight where it was; clamp when the last tile went.
        if (ShellState.switcherIndex >= rest.length)
            ShellState.switcherIndex = rest.length - 1;
    }

    function iconFor(c) {
        if (!c)
            return "";
        let e = c["class"] ? DesktopEntries.heuristicLookup(c["class"]) : null;
        if (!e && c.initialClass)
            e = DesktopEntries.heuristicLookup(c.initialClass);
        if (e && e.icon) {
            const p = Quickshell.iconPath(e.icon, true);
            if (p)
                return p;
        }
        const direct = Quickshell.iconPath(c["class"] || "", true);
        return direct ? direct : Quickshell.iconPath("application-x-executable", true);
    }

    function labelFor(c) {
        if (!c)
            return "";
        return c.title || c["class"] || c.initialClass || "";
    }

    // The workspace a window sits on, shown in parentheses. Quiet by design:
    // it is the answer to "where did that window go", which only matters once
    // you are already looking for it.
    function wsFor(c) {
        if (!c || !c.workspace)
            return "";
        const n = c.workspace.name;
        return (n === undefined || n === null || n === "") ? "" : "(" + n + ")";
    }

    // Move the highlighted window to a workspace without leaving the switcher,
    // so Alt can stay held. The window keeps its place in the row and only its
    // workspace label changes - re-reading from hyprctl here would reorder the
    // list under the user's fingers.
    function moveSelected(ws): void {
        const c = win.selected;
        if (!c || !c.address || !ws)
            return;
        Hyprland.dispatch("movetoworkspacesilent " + ws + ",address:" + c.address);
        const copy = win.clients.slice();
        const i = ShellState.switcherIndex;
        if (copy[i]) {
            const w = JSON.parse(JSON.stringify(copy[i]));
            w.workspace = { id: parseInt(ws), name: ws };
            copy[i] = w;
            win.clients = copy;
        }
    }

    Connections {
        target: ShellState

        function onSwitcherOpenChanged(): void {
            if (ShellState.switcherOpen) {
                win.refresh();
                watchdog.restart();
            } else {
                win.clients = [];
                ShellState.switcherCount = 0;
            }
        }

        function onSwitcherIndexChanged(): void {
            if (ShellState.switcherOpen)
                watchdog.restart();
        }

        function onSwitcherCommit(): void {
            win.commit();
        }

        function onSwitcherClose(): void {
            win.closeSelected();
        }

        function onSwitcherMove(ws: string): void {
            win.moveSelected(ws);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.radius
        border.color: Theme.border
        border.width: 1
        clip: true

        Column {
            anchors.centerIn: parent
            spacing: Theme.gap

            // More windows than fit on the monitor: slide the row so the
            // selected tile stays visible instead of letting it run off the edge.
            Item {
                id: viewport
                width: win.viewWidth
                height: win.tileH
                clip: true

                Row {
                    id: tiles
                    x: win.rowWidth <= viewport.width ? 0
                       : Math.max(Math.min(0, viewport.width / 2
                                  - (ShellState.switcherIndex + 0.5) * (win.tileW + Theme.gap)),
                                  viewport.width - win.rowWidth)
                    spacing: Theme.gap

                    Repeater {
                        model: win.clients

                        delegate: Rectangle {
                            id: tileRect
                            required property var modelData
                            required property int index

                            readonly property bool current: index === ShellState.switcherIndex

                            width: win.tileW
                            height: win.tileH
                            radius: Theme.radiusSmall
                            color: current ? Theme.card : "transparent"
                            border.width: current ? 2 : 0
                            border.color: Theme.accent

                            Column {
                                anchors.centerIn: parent
                                width: win.tileW - 12
                                spacing: 4

                                Item {
                                    width: parent.width
                                    height: 92

                                    // Captured once when the overlay opens: live
                                    // capture of every window would be a continuous
                                    // GPU cost on a path that lives for a few
                                    // hundred milliseconds.
                                    ScreencopyView {
                                        id: thumb
                                        anchors.centerIn: parent
                                        live: false
                                        captureSource: tileRect.modelData.toplevel || null
                                        readonly property real ar: thumb.sourceSize.height > 0
                                            ? thumb.sourceSize.width / thumb.sourceSize.height
                                            : 16 / 9
                                        width: Math.min(parent.width, parent.height * ar)
                                        height: width / Math.max(ar, 0.01)
                                        visible: thumb.hasContent
                                    }

                                    // No handle, or a window that could not be
                                    // captured: the icon still says which app it is.
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 48
                                        visible: !thumb.hasContent
                                        source: win.iconFor(tileRect.modelData)
                                    }

                                    // ...and it stays as a badge when there is a
                                    // thumbnail, because six terminals look alike.
                                    IconImage {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        implicitSize: 24
                                        visible: thumb.hasContent
                                        source: win.iconFor(tileRect.modelData)
                                    }
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: win.labelFor(tileRect.modelData)
                                    color: tileRect.current ? Theme.fg : Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                }

                                // Which workspace this window is on. Deliberately
                                // the quietest thing on the tile - you only look
                                // for it once you have lost a window.
                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: win.wsFor(tileRect.modelData)
                                    visible: text !== ""
                                    color: Theme.fgDim
                                    opacity: tileRect.current ? 0.9 : 0.5
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // Tiles elide long titles, so the selection gets one readable line.
            Text {
                width: win.implicitWidth - Theme.pad * 2
                horizontalAlignment: Text.AlignHCenter
                text: win.labelFor(win.selected)
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }
        }
    }
}
