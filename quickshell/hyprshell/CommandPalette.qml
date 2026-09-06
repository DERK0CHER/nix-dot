import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Searchable list of every key binding Hyprland currently has.
// The source of truth is `hyprctl binds -j`, read fresh on every open, so this
// can never drift out of sync with the config the way a hand-written list would.
PanelWindow {
    id: win

    visible: ShellState.paletteOpen
    color: "transparent"

    // Follow the focused monitor. Without this Quickshell picks a default screen,
    // so on a two-monitor desk the palette opens on the one you are not looking at
    // and reads as "the shortcut does nothing".
    readonly property var focusedScreen: {
        const fm = Hyprland.focusedMonitor;
        if (!fm) return null;
        const list = Quickshell.screens;
        for (let i = 0; i < list.length; i++)
            if (list[i].name === fm.name) return list[i];
        return null;
    }
    screen: focusedScreen
    exclusiveZone: 0
    implicitWidth: 720
    implicitHeight: 460

    WlrLayershell.namespace: "hyprshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.paletteOpen ? WlrKeyboardFocus.Exclusive
                                                        : WlrKeyboardFocus.None

    // Safety net for the exclusive keyboard grab below: any click outside
    // releases it. Without this, a palette left open by a stray IPC call swallows
    // every key on the system, Super included - which is exactly what happened.
    HyprlandFocusGrab {
        windows: [win]
        active: ShellState.paletteOpen
        onCleared: ShellState.paletteOpen = false
    }

    property var allBinds: []
    property var labels: ({})          // "modmask|key" -> human name
    property string mode: "search"     // search | rename | capture
    property string capturePreview: ""

    readonly property string labelPath: (Quickshell.env("HOME") || "") + "/.local/state/hyprshell/bind-labels.json"
    readonly property string overridePath: (Quickshell.env("HOME") || "") + "/.config/hypr/custom/keybinds.conf"

    function bindKey(b) { return b.modmask + "|" + (b.key || ("code:" + b.keycode)); }
    function labelFor(b) { return labels[bindKey(b)] || ""; }

    Process {
        id: loadLabels
        command: ["sh", "-c", "cat \"$HOME/.local/state/hyprshell/bind-labels.json\" 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: { try { win.labels = JSON.parse(text) || ({}) } catch (e) { win.labels = ({}) } }
        }
    }

    Process { id: saveLabels }
    function persistLabels() {
        const json = JSON.stringify(labels);
        saveLabels.command = ["sh", "-c",
            "mkdir -p \"$HOME/.local/state/hyprshell\" && cat > \"$HOME/.local/state/hyprshell/bind-labels.json\" <<'HYPRSHELL_EOF'\n" +
            json + "\nHYPRSHELL_EOF"];
        saveLabels.running = true;
    }

    Process { id: saveBind }
    // Rebinds go into hypr/custom/keybinds.conf, which hyprland.conf sources last,
    // inside a marked block so anything hand-written in that file survives.
    function persistRebind(b, mods, key) {
        const oldCombo = modsToText(b.modmask).join("+") + ", " + (b.key || "");
        const newCombo = mods.join("+") + ", " + key;
        const arg = (b.arg || "").trim();
        const line = "bind = " + newCombo + ", " + b.dispatcher + (arg ? ", " + arg : "");
        const unbind = "unbind = " + oldCombo;
        saveBind.command = ["sh", "-c",
            'f="$HOME/.config/hypr/custom/keybinds.conf"; mkdir -p "$(dirname "$f")"; touch "$f"; ' +
            'grep -q "BEGIN hyprshell rebinds" "$f" || printf "\n# BEGIN hyprshell rebinds - generated, edit above this line\n# END hyprshell rebinds\n" >> "$f"; ' +
            "awk -v u=\"" + unbind + "\" -v l=\"" + line + "\" '" +
            '/# END hyprshell rebinds/ { print u; print l } { print }' +
            "' \"$f\" > \"$f.tmp\" && mv \"$f.tmp\" \"$f\" && hyprctl reload >/dev/null 2>&1 && " +
            "notify-send -a hyprshell 'Shortcut changed' \"" + newCombo.replace(/"/g, "") + "\""];
        saveBind.running = true;
    }
    property string query: ""
    property int sel: 0

    // modmask is a bitfield; these four are the ones this config uses.
    function modsToText(m) {
        const parts = [];
        if (m & 64) parts.push("Super");
        if (m & 4)  parts.push("Ctrl");
        if (m & 8)  parts.push("Alt");
        if (m & 1)  parts.push("Shift");
        return parts;
    }

    function bindLabel(b) {
        const key = (b.key && b.key !== "") ? b.key : (b.keycode ? "code:" + b.keycode : "?");
        return modsToText(b.modmask).concat([key]).join(" + ");
    }

    // "exec, foo --bar" reads better than "exec foo --bar" in a list of actions.
    function actionLabel(b) {
        const d = b.dispatcher || "";
        const a = (b.arg || "").trim();
        return a === "" ? d : d + "  " + a;
    }

    readonly property var filtered: {
        const q = query.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < allBinds.length; i++) {
            const b = allBinds[i];
            if (q === "") { out.push(b); continue; }
            const hay = (bindLabel(b) + " " + actionLabel(b) + " " + labelFor(b) + " " + (b.description || "")).toLowerCase();
            // every whitespace-separated term must match somewhere
            const terms = q.split(/\s+/);
            let ok = true;
            for (let t = 0; t < terms.length; t++) if (hay.indexOf(terms[t]) === -1) { ok = false; break; }
            if (ok) out.push(b);
        }
        return out;
    }

    onFilteredChanged: sel = 0

    Process {
        id: loadBinds
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = JSON.parse(text);
                    // Submap binds would run in a mode the user is not in; hide them.
                    win.allBinds = raw.filter(b => !b.submap || b.submap === "");
                } catch (e) {
                    win.allBinds = [];
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            query = ""; sel = 0; mode = "search"; capturePreview = "";
            loadBinds.running = true;
            loadLabels.running = true;
            input.forceActiveFocus();
        }
    }

    // Qt key enum -> the name Hyprland expects in a bind line.
    function keyName(event) {
        if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z)
            return String.fromCharCode("A".charCodeAt(0) + (event.key - Qt.Key_A));
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9)
            return String.fromCharCode("0".charCodeAt(0) + (event.key - Qt.Key_0));
        const map = {};
        map[Qt.Key_Space]  = "Space";  map[Qt.Key_Return] = "Return";
        map[Qt.Key_Tab]    = "Tab";    map[Qt.Key_Left]   = "Left";
        map[Qt.Key_Right]  = "Right";  map[Qt.Key_Up]     = "Up";
        map[Qt.Key_Down]   = "Down";   map[Qt.Key_Delete] = "Delete";
        map[Qt.Key_Home]   = "Home";   map[Qt.Key_End]    = "End";
        return map[event.key] || (event.text ? event.text.toUpperCase() : "?");
    }

    function startRename() {
        const b = filtered[sel];
        if (!b) return;
        renameField.text = labelFor(b) || actionLabel(b);
        mode = "rename";
        renameField.forceActiveFocus();
        renameField.selectAll();
    }

    function confirm() {
        if (mode === "rename") {
            const b = filtered[sel];
            if (b) {
                const copy = JSON.parse(JSON.stringify(labels));
                const t = renameField.text.trim();
                if (t === "") delete copy[bindKey(b)]; else copy[bindKey(b)] = t;
                labels = copy;
                persistLabels();
            }
            mode = "search";
            input.forceActiveFocus();
            return;
        }
        if (mode === "search") runSelected();
    }

    function runSelected() {
        const b = filtered[sel];
        ShellState.paletteOpen = false;
        if (!b) return;
        const arg = (b.arg || "");
        Quickshell.execDetached(["hyprctl", "dispatch", b.dispatcher, arg]);
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.radius
        border.color: Theme.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.pad
            spacing: Theme.gap

            // ---- search ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 19
                color: Theme.card

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    selectByMouse: true
                    onTextChanged: win.query = text

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search shortcuts and actions"
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 1
                        visible: input.text === ""
                    }

                    Keys.onEscapePressed: {
                        if (win.mode !== "search") { win.mode = "search"; win.capturePreview = "" }
                        else ShellState.paletteOpen = false
                    }
                    Keys.onReturnPressed: win.confirm()
                    Keys.onEnterPressed: win.confirm()
                    Keys.onDownPressed: if (win.mode === "search" && win.sel < win.filtered.length - 1) win.sel++
                    Keys.onUpPressed:   if (win.mode === "search" && win.sel > 0) win.sel--

                    // F2 = rename, Ctrl+R = rebind. In capture mode every other key
                    // press is the new shortcut rather than input.
                    Keys.onPressed: (event) => {
                        if (win.mode === "capture") {
                            const mods = [];
                            if (event.modifiers & Qt.MetaModifier)    mods.push("Super");
                            if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl");
                            if (event.modifiers & Qt.AltModifier)     mods.push("Alt");
                            if (event.modifiers & Qt.ShiftModifier)   mods.push("Shift");
                            const bare = [Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Control,
                                          Qt.Key_Alt, Qt.Key_Shift, Qt.Key_Meta];
                            if (bare.indexOf(event.key) !== -1) {
                                win.capturePreview = mods.concat(["…"]).join(" + ");
                                event.accepted = true; return;
                            }
                            if (event.key === Qt.Key_Escape) return;   // handled above
                            const name = win.keyName(event);
                            win.capturePreview = mods.concat([name]).join(" + ");
                            const b = win.filtered[win.sel];
                            if (b && mods.length > 0) win.persistRebind(b, mods, name);
                            win.mode = "search";
                            ShellState.paletteOpen = false;
                            event.accepted = true; return;
                        }
                        if (event.key === Qt.Key_F2 && win.mode === "search") {
                            win.startRename(); event.accepted = true; return;
                        }
                        if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)
                            && win.mode === "search") {
                            win.mode = "capture"; win.capturePreview = "";
                            event.accepted = true; return;
                        }
                    }
                }
            }

            // ---- rename field / capture hint ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radiusSmall
                visible: win.mode !== "search"
                color: win.mode === "capture" ? Qt.rgba(53/255, 132/255, 228/255, 0.18) : Theme.card
                border.width: 1
                border.color: win.mode === "capture" ? Theme.accent : "transparent"

                TextInput {
                    id: renameField
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    visible: win.mode === "rename"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    selectByMouse: true
                    Keys.onEscapePressed: { win.mode = "search"; input.forceActiveFocus() }
                    Keys.onReturnPressed: win.confirm()
                    Keys.onEnterPressed: win.confirm()
                }

                Text {
                    anchors.centerIn: parent
                    visible: win.mode === "capture"
                    text: win.capturePreview !== "" ? win.capturePreview
                                                    : "Press the new shortcut…  (Esc cancels)"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.DemiBold
                }
            }

            // ---- results ----
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: win.filtered
                currentIndex: win.sel
                highlightMoveDuration: 90
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 34
                    radius: Theme.radiusSmall
                    color: index === win.sel ? Theme.card : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        Rectangle {
                            implicitWidth: shortcut.implicitWidth + 16
                            implicitHeight: 22
                            radius: 6
                            color: index === win.sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.07)
                            Text {
                                id: shortcut
                                anchors.centerIn: parent
                                text: win.bindLabel(modelData)
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: win.labelFor(modelData) !== "" ? win.labelFor(modelData)
                                                                : win.actionLabel(modelData)
                            color: index === win.sel ? Theme.fg : Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: win.sel = index
                        onClicked: win.runSelected()
                    }
                }
            }

            // ---- footer ----
            Text {
                Layout.fillWidth: true
                text: win.filtered.length + " of " + win.allBinds.length +
                      " bindings   ·   Enter run   ·   F2 rename   ·   Ctrl+R rebind   ·   Esc close"
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }
}
