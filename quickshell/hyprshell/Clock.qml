import QtQuick
import Quickshell

// GNOME-style center clock. Click toggles the notification center.
Item {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property bool hasUnread: ShellState.unreadCount > 0 && !ShellState.doNotDisturb

    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.barHeight

    Rectangle {
        id: pill
        anchors.centerIn: parent
        height: 24
        radius: 12
        implicitWidth: label.implicitWidth + Theme.pad * 2 + (dot.visible ? 10 : 0)
        color: mouse.containsMouse || ShellState.notificationsOpen ? Theme.card : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animMs } }

        Row {
            anchors.centerIn: parent
            spacing: 4

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.fg
            }

            Rectangle {
                id: dot
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasUnread
                width: 6
                height: 6
                radius: 3
                color: Theme.accent
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            const next = !ShellState.notificationsOpen;
            ShellState.closePanels();
            ShellState.notificationsOpen = next;
        }
    }
}
