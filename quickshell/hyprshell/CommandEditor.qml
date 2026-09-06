import QtQuick
import QtQuick.Layouts
import Quickshell

// The command editor, drawn as a sheet on top of the palette.
//
// It is an Item and not a window of its own on purpose: the palette already
// holds an exclusive keyboard grab, and a second surface would have to fight it
// for focus - which is also what makes shortcut recording work here at all.
//
// Nothing in this file touches a file. Everything goes through
// Commands.saveCommand / Commands.deleteCommand, which own both the JSON store
// and the generated Hyprland bind block.
FocusScope {
    id: ed

    signal closed()

    // The row being edited (an entry of Commands.list), or null for a new one.
    property var command: null

    // ---- form state -------------------------------------------------------
    property string execType: "shell"       // shell | hyprctl
    property var mods: []                   // ["Super","Shift"]
    property string key: ""                 // "G"; "" means no shortcut
    property bool recording: false
    property string recordPreview: ""
    property var conflictRows: []
    property bool overwrite: false          // the user said "use it anyway"
    property bool confirmDelete: false

    readonly property bool isNew: command === null
    readonly property bool isUser: isNew || command.source === "user"
    readonly property string shortcutLabel: key === "" ? "" : mods.concat([key]).join(" + ")

    // ---- validation -------------------------------------------------------
    readonly property string problem: {
        if (nameField.text.trim() === "") return "A name is required";
        if (execType === "shell" && cmdField.text.trim() === "") return "A shell command is required";
        if (execType === "hyprctl" && dispField.text.trim() === "") return "A dispatcher is required";
        if (recording) return "Finish recording the shortcut first";
        if (conflictRows.length > 0 && !overwrite) return "That shortcut is already taken";
        return "";
    }

    // ---- opening ----------------------------------------------------------
    function open(cmd: var, seedName: string): void {
        command = cmd || null;
        recording = false; recordPreview = "";
        conflictRows = []; overwrite = false; confirmDelete = false;
        const e = cmd ? cmd.exec : null;
        execType = (e && e.type === "hyprctl") ? "hyprctl" : "shell";
        nameField.text = cmd ? cmd.name : (seedName || "");
        dispField.text = (e && e.type === "hyprctl") ? (e.dispatcher || "") : "";
        argField.text  = (e && e.type === "hyprctl") ? (e.arg || "") : "";
        cmdField.text  = (e && e.type === "shell") ? (e.command || "") : "";
        const p = cmd ? Commands.parseShortcut(cmd.shortcut) : null;
        mods = p ? p.mods : [];
        key = p ? p.key : "";
    }

    function cancel(): void {
        recording = false;      // resets the submap, see onRecordingChanged
        closed();
    }

    // ---- recording --------------------------------------------------------
    // Same trick the palette uses: Hyprland consumes its own binds before the
    // focused surface sees them, so recording Super+G would fire game mode. An
    // empty submap lets every combination fall through to this window.
    //
    // A stuck submap is a session with no keybindings at all, so the reset is
    // belt and braces: here, when the sheet is hidden, when the palette closes,
    // and Escape is bound inside the submap itself as the last resort.
    onRecordingChanged: {
        Quickshell.execDetached(["hyprctl", "dispatch", "submap",
                                 recording ? "hyprshell-capture" : "reset"]);
        if (recording) recorder.forceActiveFocus();
        else nameField.field.forceActiveFocus();
    }

    // Focus follows the sheet rather than open(): the palette fills the fields
    // first and shows the sheet after, and forcing focus on a hidden item does
    // nothing. Hiding it always leaves the capture submap.
    onVisibleChanged: {
        if (visible) {
            nameField.field.forceActiveFocus();
            nameField.field.selectAll();
        } else {
            recording = false;
        }
    }

    function startRecording(): void { recordPreview = ""; recording = true; }

    function checkConflicts(): void {
        overwrite = false;
        conflictRows = Commands.conflicts(mods, key, command ? command.id : "");
    }

    function clearShortcut(): void {
        mods = []; key = ""; recordPreview = "";
        conflictRows = []; overwrite = false;
    }

    Item {
        id: recorder
        width: 0; height: 0

        Keys.onPressed: (event) => {
            const m = [];
            if (event.modifiers & Qt.MetaModifier)    m.push("Super");
            if (event.modifiers & Qt.ControlModifier) m.push("Ctrl");
            if (event.modifiers & Qt.AltModifier)     m.push("Alt");
            if (event.modifiers & Qt.ShiftModifier)   m.push("Shift");
            // A modifier on its own is not a shortcut; show it building up.
            const bare = [Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Control,
                          Qt.Key_Alt, Qt.Key_Shift, Qt.Key_Meta, Qt.Key_AltGr];
            if (bare.indexOf(event.key) !== -1) {
                ed.recordPreview = m.concat(["…"]).join(" + ");
                event.accepted = true; return;
            }
            if (event.key === Qt.Key_Escape) {
                ed.recording = false; ed.recordPreview = "";
                event.accepted = true; return;
            }
            ed.mods = m;
            ed.key = Commands.keyNameOf(event.key, event.text);
            ed.recording = false;
            ed.checkConflicts();
            event.accepted = true;
        }
    }

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: ed.confirmDelete = false
    }

    // ---- saving -----------------------------------------------------------
    function save(): void {
        if (problem !== "") return;
        const name = nameField.text.trim();
        const exec = execType === "hyprctl"
            ? ({ "type": "hyprctl", "dispatcher": dispField.text.trim(), "arg": argField.text })
            : ({ "type": "shell", "command": cmdField.text.trim() });
        const id = command ? command.id : Commands.newId(name);
        const entry = { "id": id, "name": name,
                        "source": command ? command.source : "user" };

        if (entry.source === "user") {
            entry.exec = exec;
        } else if (Commands.detailOf(exec) !== Commands.detailOf(Commands.execOfBind(command.bind))) {
            // Only store an exec for a discovered binding when it really differs
            // from what Hyprland has - a plain rename stays a one-line override.
            entry.exec = exec;
        }
        if (Commands.saveCommand(id, entry, mods, key)) closed();
    }

    function removeNow(): void {
        if (!command) { cancel(); return; }
        if (!confirmDelete) { confirmDelete = true; confirmTimer.restart(); return; }
        confirmTimer.stop();
        Commands.deleteCommand(command.id);
        closed();
    }

    Keys.onEscapePressed: ed.cancel()

    // ---- building blocks --------------------------------------------------
    component EdField: Rectangle {
        property alias text: fi.text
        property alias hint: ph.text
        property alias field: fi
        signal accepted()

        Layout.fillWidth: true
        implicitHeight: 30
        radius: Theme.radiusSmall
        color: Theme.dark ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(1, 1, 1, 0.75)
        border.width: 1
        border.color: fi.activeFocus ? Theme.accent : Theme.border

        TextInput {
            id: fi
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            onAccepted: parent.accepted()
        }
        Text {
            id: ph
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            visible: fi.text === ""
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    // Two of these are the exec-type selector. It knows nothing about the sheet:
    // an inline component is its own type and cannot reach the file's ids.
    component EdSegment: Rectangle {
        id: sg
        property alias label: st.text
        property bool checked: false
        signal picked()

        width: (parent.width - 2) / 2
        height: parent.height
        radius: Theme.radiusSmall - 2
        color: sg.checked ? Theme.accent : "transparent"
        Text {
            id: st
            anchors.centerIn: parent
            color: sg.checked ? "#ffffff" : Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sg.picked()
        }
    }

    component EdLabel: Text {
        Layout.preferredWidth: 88
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    component EdButton: Rectangle {
        id: btn
        property alias label: t.text
        property color tint: Theme.fg
        property bool primary: false
        signal clicked()

        implicitWidth: t.implicitWidth + 28
        implicitHeight: 30
        radius: Theme.radiusSmall
        opacity: btn.enabled ? 1 : 0.4
        color: btn.primary ? btn.tint
                           : (ma.containsMouse ? Theme.cardHover : Theme.card)
        Text {
            id: t
            anchors.centerIn: parent
            color: btn.primary ? "#ffffff" : btn.tint
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // ---- the sheet --------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: ed.isNew ? "New command"
                           : (ed.isUser ? "Edit command" : "Edit binding")
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            font.weight: Font.DemiBold
        }

        // ---- group: what it is and what it runs ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: group1.implicitHeight + 2 * Theme.pad
            radius: Theme.radius
            color: Theme.card

            ColumnLayout {
                id: group1
                anchors.fill: parent
                anchors.margins: Theme.pad
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    EdLabel { text: "Name" }
                    EdField {
                        id: nameField
                        hint: "What this does, in human words"
                        onAccepted: ed.save()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    EdLabel { text: "Runs" }
                    Rectangle {
                        implicitWidth: 170
                        implicitHeight: 28
                        radius: Theme.radiusSmall
                        color: Theme.dark ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(1, 1, 1, 0.75)
                        Row {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2
                            EdSegment {
                                label: "Shell"
                                checked: ed.execType === "shell"
                                onPicked: ed.execType = "shell"
                            }
                            EdSegment {
                                label: "hyprctl"
                                checked: ed.execType === "hyprctl"
                                onPicked: ed.execType = "hyprctl"
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: ed.execType === "shell"
                    EdLabel { text: "Command" }
                    EdField {
                        id: cmdField
                        hint: "kitty -e htop"
                        onAccepted: ed.save()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: ed.execType === "hyprctl"
                    EdLabel { text: "Dispatcher" }
                    EdField {
                        id: dispField
                        hint: "workspace"
                        onAccepted: ed.save()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: ed.execType === "hyprctl"
                    EdLabel { text: "Argument" }
                    EdField {
                        id: argField
                        hint: "optional"
                        onAccepted: ed.save()
                    }
                }
            }
        }

        // ---- group: the shortcut ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: group2.implicitHeight + 2 * Theme.pad
            radius: Theme.radius
            color: Theme.card

            RowLayout {
                id: group2
                anchors.fill: parent
                anchors.margins: Theme.pad
                spacing: 12

                EdLabel { text: "Shortcut" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: Theme.radiusSmall
                    color: ed.recording ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                        : (Theme.dark ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(1, 1, 1, 0.75))
                    border.width: 1
                    border.color: ed.recording ? Theme.accent : Theme.border
                    Text {
                        anchors.centerIn: parent
                        text: ed.recording
                              ? (ed.recordPreview !== "" ? ed.recordPreview
                                                         : "Press the shortcut…  (Esc cancels)")
                              : (ed.shortcutLabel !== "" ? ed.shortcutLabel : "No shortcut")
                        color: ed.shortcutLabel === "" && !ed.recording ? Theme.fgDim : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.DemiBold
                    }
                }

                EdButton {
                    label: ed.recording ? "Recording…" : "Record"
                    tint: Theme.accent
                    primary: ed.recording
                    onClicked: ed.recording ? ed.recording = false : ed.startRecording()
                }

                EdButton {
                    label: "Clear"
                    enabled: ed.key !== "" && !ed.recording
                    onClicked: ed.clearShortcut()
                }
            }
        }

        // ---- conflict ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: Theme.radius
            visible: ed.conflictRows.length > 0
            color: ed.overwrite ? Qt.rgba(58 / 255, 148 / 255, 74 / 255, 0.16)
                                : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.16)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.pad
                anchors.rightMargin: Theme.pad
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: ed.conflictRows.length === 0 ? ""
                          : (ed.overwrite
                             ? ed.shortcutLabel + " will be taken from “"
                               + ed.conflictRows[0].name + "”"
                             : ed.shortcutLabel + " already runs “"
                               + ed.conflictRows[0].name + "”"
                               + (ed.conflictRows.length > 1
                                  ? " (+" + (ed.conflictRows.length - 1) + " more)" : ""))
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }

                EdButton {
                    label: "Overwrite"
                    tint: Theme.danger
                    visible: !ed.overwrite
                    onClicked: ed.overwrite = true
                }
                EdButton {
                    label: "Pick another"
                    visible: !ed.overwrite
                    onClicked: ed.startRecording()
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ---- buttons ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            EdButton {
                label: ed.confirmDelete
                       ? "Click again to confirm"
                       : (ed.isUser ? "Delete" : "Reset overrides")
                tint: Theme.danger
                visible: !ed.isNew && (ed.isUser || ed.command.overridden)
                onClicked: ed.removeNow()
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: ed.problem !== "" ? ed.problem
                                        : (ed.isUser ? "" : "Changes are written to your Hyprland config")
                color: ed.problem !== "" ? Theme.danger : Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                horizontalAlignment: Text.AlignRight
            }

            EdButton {
                label: "Cancel"
                onClicked: ed.cancel()
            }
            EdButton {
                label: "Save"
                tint: Theme.accent
                primary: true
                enabled: ed.problem === ""
                onClicked: ed.save()
            }
        }
    }
}
