import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// GNOME-style top bar: workspaces + active app (left), clock (center), status pill (right).
PanelWindow {
    id: root

    property var modelData
    screen: modelData

    readonly property var hyprMonitor: Hyprland.monitorFor(root.screen)
    readonly property bool focusedHere: {
        const fm = Hyprland.focusedMonitor;
        return !fm || !root.hyprMonitor || fm.name === root.hyprMonitor.name;
    }

    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property var activeEntry: {
        const t = root.activeToplevel;
        if (!t || !t.appId)
            return null;
        return DesktopEntries.heuristicLookup(t.appId);
    }
    readonly property string appName: {
        const t = root.activeToplevel;
        if (!t)
            return "Desktop";
        if (root.activeEntry && root.activeEntry.name)
            return root.activeEntry.name;
        return t.appId || t.title || "Desktop";
    }

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: State.barVisible ? Theme.barHeight : 0
    visible: State.barVisible
    color: "transparent"

    WlrLayershell.namespace: "hyprshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: Theme.bg

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.border
        }
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Theme.gap
        anchors.rightMargin: Theme.gap

        // LEFT
        Row {
            id: leftRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap

            Workspaces {
                screen: root.screen
                anchors.verticalCenter: parent.verticalCenter
            }

            // Active app name -> app menu
            Rectangle {
                id: appButton
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                radius: 12
                implicitWidth: appRow.implicitWidth + Theme.pad * 2
                color: appMouse.containsMouse || State.appMenuOpen ? Theme.card : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animMs } }

                Row {
                    id: appRow
                    anchors.centerIn: parent
                    spacing: Theme.gap

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        // elide only bites once a width is set, and the width is
                        // a fraction of THIS monitor, never a pixel constant:
                        // the bar spans 3440 px on the ultrawide and 1920 px on
                        // the secondary. Keeps a long window title from growing
                        // into the centred clock; on the ultrawide it never bites.
                        width: Math.min(implicitWidth, Math.max(160, root.width * 0.22))
                        text: root.appName
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                        color: Theme.fg
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const next = !State.appMenuOpen;
                        State.closePanels();
                        State.appMenuOpen = next;
                    }
                }
            }
        }

        // CENTER
        Clock {
            anchors.centerIn: parent
        }

        // RIGHT
        StatusPill {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // App menu popup (only on the focused monitor).
    AppMenu {
        screen: root.screen
        open: State.appMenuOpen && root.focusedHere && State.barVisible
        entry: root.activeEntry
        toplevel: root.activeToplevel
        appName: root.appName
    }
}
