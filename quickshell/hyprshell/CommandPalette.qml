import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Searchable list of every command the shell knows about.
// The model lives in the Commands singleton, which merges the live
// `hyprctl binds -j` output with the user's own ~/.config/hyprshell/commands.json,
// so this file only draws and never persists anything itself.
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

    property string mode: "search"     // search | rename | capture | edit
    property string capturePreview: ""
    property string query: ""
    property int sel: 0

    // "Super+Shift+P" in the store, "Super + Shift + P" on screen.
    function shortcutLabel(c) { return Commands.shortcutText(c.shortcut); }

    readonly property var filtered: Commands.search(query)

    onFilteredChanged: sel = 0

    onVisibleChanged: {
        if (visible) {
            query = ""; sel = 0; mode = "search"; capturePreview = "";
            Commands.refresh();
            input.forceActiveFocus();
        } else {
            // Never leave the session in the capture submap, and never leave the
            // editor sheet up - it drives a submap of its own while recording.
            mode = "search";
            captureGrab(false);
        }
    }

    // Hyprland consumes its own keybinds before the focused surface sees them, so
    // an exclusive grab is not enough to record Super+G as a shortcut - game mode
    // would fire instead. Switching into a submap with nothing bound but Escape
    // lets every combination fall through to this window.
    //
    // Leaving the submap must be belt and braces: a stuck submap means a session
    // with no keybindings at all. It is reset when capture ends, when the mode
    // changes, when the palette closes, and Escape is bound inside the submap
    // itself as a last resort.
    function captureGrab(on) {
        Quickshell.execDetached(["hyprctl", "dispatch", "submap",
                                 on ? "hyprshell-capture" : "reset"]);
    }

    onModeChanged: captureGrab(mode === "capture")

    // Open the editor sheet on a row, or on nothing to create a command. The
    // fields are filled before the sheet is shown: focus cannot be given to an
    // item that is still hidden, so the sheet takes it when it appears.
    function openEditor(cmd) {
        editor.open(cmd || null, cmd ? "" : query.trim());
        mode = "edit";
    }

    function startRename() {
        const c = filtered[sel];
        if (!c) return;
        renameField.text = c.name;
        mode = "rename";
        renameField.forceActiveFocus();
        renameField.selectAll();
    }

    function confirm() {
        if (mode === "rename") {
            const c = filtered[sel];
            if (c) Commands.setName(c.id, renameField.text);
            mode = "search";
            input.forceActiveFocus();
            return;
        }
        // Nothing matched: Enter offers to turn the search text into a command.
        if (mode === "search") {
            if (filtered.length === 0 && query.trim() !== "") openEditor(null);
            else runSelected();
        }
    }

    function runSelected() {
        const c = filtered[sel];
        ShellState.paletteOpen = false;
        if (c) Commands.run(c.id);
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
            visible: win.mode !== "edit"

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
                            const name = Commands.keyNameOf(event.key, event.text);
                            win.capturePreview = mods.concat([name]).join(" + ");
                            const c = win.filtered[win.sel];
                            if (c && mods.length > 0) Commands.rebind(c.id, mods, name);
                            win.mode = "search";
                            ShellState.paletteOpen = false;
                            event.accepted = true; return;
                        }
                        if (event.key === Qt.Key_F2 && win.mode === "search") {
                            win.startRename(); event.accepted = true; return;
                        }
                        if (event.key === Qt.Key_E && (event.modifiers & Qt.ControlModifier)
                            && win.mode === "search" && win.filtered[win.sel]) {
                            win.openEditor(win.filtered[win.sel]);
                            event.accepted = true; return;
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

                    // Declared before the row so the edit button, which is part
                    // of the row, sits on top of it and gets its own clicks.
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: win.sel = index
                        onClicked: win.runSelected()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        Rectangle {
                            // Store-only commands can be unbound; then there is
                            // no pill rather than an empty one.
                            visible: shortcut.text !== ""
                            implicitWidth: shortcut.implicitWidth + 16
                            implicitHeight: 22
                            radius: 6
                            color: index === win.sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.07)
                            Text {
                                id: shortcut
                                anchors.centerIn: parent
                                text: win.shortcutLabel(modelData)
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: index === win.sel ? Theme.fg : Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }

                        // Hover affordance. Hovering a row also selects it, so
                        // "hovered" and "selected" are the same row.
                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 22
                            radius: 6
                            visible: index === win.sel
                            color: editHover.containsMouse ? Theme.cardHover : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "\u270e"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                            }
                            MouseArea {
                                id: editHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.openEditor(modelData)
                            }
                        }
                    }
                }
            }

            // ---- create ----
            // The way to an empty editor: search for something that does not
            // exist yet, then make it.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radiusSmall
                visible: win.mode === "search" && win.filtered.length === 0
                         && win.query.trim() !== ""
                color: Theme.card
                border.width: 1
                border.color: Theme.accent

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Create command “" + win.query.trim() + "” …"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.openEditor(null)
                }
            }

            // ---- footer ----
            Text {
                Layout.fillWidth: true
                text: win.filtered.length + " of " + Commands.list.length +
                      " commands   ·   Enter run   ·   F2 rename   ·   Ctrl+E edit"
                      + "   ·   Ctrl+R rebind   ·   Esc close"
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }

        // ---- editor sheet ----
        // Drawn over the search column rather than in a window of its own: this
        // window already holds the exclusive keyboard grab that recording a
        // shortcut needs, and a second surface would have to fight it for focus.
        CommandEditor {
            id: editor
            anchors.fill: parent
            anchors.margins: Theme.pad
            visible: win.mode === "edit"
            onClosed: {
                win.mode = "search";
                Commands.refresh();
                input.forceActiveFocus();
            }
        }
    }
}
