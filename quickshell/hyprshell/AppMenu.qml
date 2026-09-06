import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

// Active-app menu (GNOME/macOS style) below the app name in the bar.
// Sections: app actions (.desktop), window, files.
PanelWindow {
    id: root

    property bool open: false
    property var entry: null       // DesktopEntry or null
    property var toplevel: null    // Toplevel or null
    property string appName: "Desktop"

    readonly property string appIconPath: {
        if (root.entry && root.entry.icon)
            return Quickshell.iconPath(root.entry.icon, true);
        if (root.toplevel && root.toplevel.appId)
            return Quickshell.iconPath(root.toplevel.appId, true);
        return "";
    }
    readonly property var actions: root.entry && root.entry.actions ? root.entry.actions : []
    readonly property string home: Quickshell.env("HOME")

    visible: open
    anchors {
        top: true
        left: true
    }
    margins {
        top: Theme.gap
        left: Theme.gap
    }
    exclusiveZone: 0
    implicitWidth: 300
    implicitHeight: column.implicitHeight + Theme.gap * 2
    color: "transparent"

    WlrLayershell.namespace: "hyprshell-panel"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: State.appMenuOpen = false
    }

    function close() {
        State.appMenuOpen = false;
    }

    function run(cmd) {
        root.close();
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function dispatch(cmd) {
        root.close();
        Hyprland.dispatch(cmd);
    }

    // ---- recent files ----
    property var recentFiles: []

    FileView {
        id: recentView
        path: root.home + "/.local/share/recently-used.xbel"
        onLoaded: root.parseRecent(recentView.text())
        onLoadFailed: root.recentFiles = []
    }

    onOpenChanged: {
        if (open)
            recentView.reload();
    }

    function parseRecent(text) {
        const re = /<bookmark\s+href="([^"]+)"[^>]*modified="([^"]+)"/g;
        const found = [];
        let m;
        while ((m = re.exec(text)) !== null) {
            const href = m[1];
            let name = href;
            try {
                name = decodeURIComponent(href.split("/").pop());
            } catch (e) {}
            found.push({ href: href, name: name, modified: m[2] });
        }
        found.sort((a, b) => (a.modified < b.modified ? 1 : a.modified > b.modified ? -1 : 0));
        root.recentFiles = found.slice(0, 6);
    }

    // ---- components ----
    component SectionLabel: Text {
        width: parent.width
        leftPadding: Theme.pad
        topPadding: Theme.gap
        bottomPadding: 2
        text: ""
        font.family: Theme.font
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
        color: Theme.fgDim
    }

    component MenuItem: Rectangle {
        id: mi
        property string label: ""
        property string icon: ""
        property string iconSource: ""
        property bool danger: false
        signal triggered()

        width: parent.width
        height: 36
        radius: Theme.radiusSmall
        color: ma.containsMouse ? Theme.card : "transparent"

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Theme.pad
            spacing: Theme.pad - 2

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                visible: source !== ""
                implicitSize: 16
                source: mi.iconSource !== "" ? mi.iconSource : (mi.icon !== "" ? Quickshell.iconPath(mi.icon, true) : "")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: mi.label
                width: mi.width - Theme.pad * 3 - 16
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: mi.danger ? Theme.danger : Theme.fg
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mi.triggered()
        }
    }

    component Separator: Rectangle {
        width: parent.width - Theme.pad * 2
        anchors.horizontalCenter: parent.horizontalCenter
        height: 1
        color: Theme.border
    }

    // ---- surface ----
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.close()

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.gap
                spacing: 2

                // Header
                Item {
                    width: parent.width
                    height: 48

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.pad
                        spacing: Theme.pad

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 32
                            source: root.appIconPath
                            visible: root.appIconPath !== ""
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: root.appName
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                font.weight: Font.Bold
                                color: Theme.fg
                            }

                            Text {
                                width: 300 - Theme.pad * 4 - 32
                                text: root.toplevel ? root.toplevel.title : ""
                                visible: text !== ""
                                elide: Text.ElideRight
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.fgDim
                            }
                        }
                    }
                }

                Separator {}

                // Actions
                SectionLabel {
                    visible: root.entry !== null
                    text: "Actions"
                }

                MenuItem {
                    visible: root.entry !== null
                    label: "New window"
                    icon: "window-new-symbolic"
                    onTriggered: {
                        root.close();
                        if (root.entry)
                            root.entry.execute();
                    }
                }

                Repeater {
                    model: root.actions

                    MenuItem {
                        required property var modelData
                        label: modelData.name
                        icon: modelData.icon || ""
                        onTriggered: {
                            root.close();
                            modelData.execute();
                        }
                    }
                }

                Separator { visible: root.entry !== null }

                // Window
                SectionLabel {
                    visible: root.toplevel !== null
                    text: "Window"
                }

                MenuItem {
                    visible: root.toplevel !== null
                    label: "Float / Tile"
                    icon: "view-restore-symbolic"
                    onTriggered: root.dispatch("togglefloating")
                }

                MenuItem {
                    visible: root.toplevel !== null
                    label: "Fullscreen"
                    icon: "view-fullscreen-symbolic"
                    onTriggered: root.dispatch("fullscreen 0")
                }

                MenuItem {
                    visible: root.toplevel !== null
                    label: "Pin (all workspaces)"
                    icon: "view-pin-symbolic"
                    onTriggered: root.dispatch("pin")
                }

                // Move to workspace 1-5
                Item {
                    visible: root.toplevel !== null
                    width: parent.width
                    height: 36

                    Text {
                        id: moveLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.pad
                        text: "Move to"
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        color: Theme.fg
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.pad
                        spacing: 4

                        Repeater {
                            model: [1, 2, 3, 4, 5]

                            Rectangle {
                                required property var modelData
                                width: 28
                                height: 28
                                radius: Theme.radiusSmall
                                color: wsMa.containsMouse ? Theme.accent : Theme.card

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                    color: Theme.fg
                                }

                                MouseArea {
                                    id: wsMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.dispatch("movetoworkspace " + parent.modelData)
                                }
                            }
                        }
                    }
                }

                MenuItem {
                    visible: root.toplevel !== null
                    label: "Close"
                    icon: "window-close-symbolic"
                    onTriggered: root.dispatch("killactive")
                }

                MenuItem {
                    visible: root.toplevel !== null
                    label: "Force close"
                    icon: "process-stop-symbolic"
                    danger: true
                    onTriggered: root.run("pid=$(hyprctl activewindow -j | sed -n 's/.*\"pid\": *\\([0-9]*\\).*/\\1/p'); [ -n \"$pid\" ] && kill -9 \"$pid\"")
                }

                Separator { visible: root.toplevel !== null }

                // Files
                SectionLabel { text: "Files" }

                MenuItem {
                    label: "Open home folder"
                    icon: "folder-symbolic"
                    onTriggered: root.run("xdg-open \"$HOME\"")
                }

                MenuItem {
                    label: "Screenshot window"
                    icon: "camera-photo-symbolic"
                    onTriggered: root.run("sleep 0.3; hyprshot -m window --clipboard-only")
                }

                SectionLabel {
                    visible: root.recentFiles.length > 0
                    text: "Recent"
                }

                Repeater {
                    model: root.recentFiles

                    MenuItem {
                        required property var modelData
                        label: modelData.name
                        icon: "document-open-recent-symbolic"
                        onTriggered: root.run("xdg-open '" + modelData.href.replace(/'/g, "'\\''") + "'")
                    }
                }
            }
        }
    }
}
