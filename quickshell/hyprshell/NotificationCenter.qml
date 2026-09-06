import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications

PanelWindow {
    id: win

    visible: ShellState.notificationsOpen
    anchors { top: true }
    margins { top: 6 }
    implicitWidth: 380
    implicitHeight: col.implicitHeight + 24
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "hyprshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property int unread: Notifs.count

    HyprlandFocusGrab {
        windows: [win]
        active: ShellState.notificationsOpen
        onCleared: ShellState.notificationsOpen = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.radius
        border.width: 1
        border.color: Theme.border
        focus: true
        Keys.onPressed: e => { if (e.key === Qt.Key_Escape) { ShellState.notificationsOpen = false; e.accepted = true } }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 12

            // header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: "Notifications"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: dndText.implicitWidth + 20
                    implicitHeight: 26
                    radius: 13
                    color: ShellState.doNotDisturb ? Theme.accent : (dndMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Theme.card)
                    Text {
                        id: dndText
                        anchors.centerIn: parent
                        text: "Do Not Disturb"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.doNotDisturb = !ShellState.doNotDisturb
                    }
                }
                Rectangle {
                    visible: Notifs.count > 0
                    implicitWidth: clearText.implicitWidth + 20
                    implicitHeight: 26
                    radius: 13
                    color: clearMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Theme.card
                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            // empty state
            Text {
                visible: Notifs.count === 0
                Layout.fillWidth: true
                Layout.topMargin: 24
                Layout.bottomMargin: 24
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            ListView {
                id: list
                visible: Notifs.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(560, contentHeight)
                clip: true
                spacing: 6
                model: Notifs.list
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property var n: modelData

                    width: ListView.view.width
                    implicitHeight: cardCol.implicitHeight + 20
                    radius: Theme.radiusSmall
                    color: cardMouse.containsMouse ? Qt.rgba(1,1,1,0.09) : Theme.card
                    border.width: n.urgency === NotificationUrgency.Critical ? 1 : 0
                    border.color: Theme.danger

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (n.actions.length > 0) n.actions[0].invoke()
                            n.dismiss()
                        }
                    }

                    ColumnLayout {
                        id: cardCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignTop
                                IconImage {
                                    id: icon
                                    anchors.fill: parent
                                    source: n.image !== "" ? n.image : Quickshell.iconPath(n.appIcon, true)
                                    visible: source !== ""
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !icon.visible
                                    radius: 16
                                    color: Theme.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: n.appName.length > 0 ? n.appName.charAt(0).toUpperCase() : "!"
                                        color: "white"
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text {
                                        Layout.fillWidth: true
                                        text: n.summary
                                        elide: Text.ElideRight
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: Notifs.timeOf(n)
                                        color: Theme.fgDim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 2
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        radius: 11
                                        color: closeMouse.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: Theme.fgDim
                                            font.family: Theme.font
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: closeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: n.dismiss()
                                        }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: n.body !== ""
                                    text: n.body
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    color: Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                }
                                Text {
                                    visible: n.appName !== ""
                                    text: n.appName
                                    color: Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            visible: n.actions.length > 0
                            spacing: 6
                            Repeater {
                                model: n.actions
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitWidth: aText.implicitWidth + 20
                                    implicitHeight: 26
                                    radius: 13
                                    color: aMouse.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.10)
                                    Text {
                                        id: aText
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                    }
                                    MouseArea {
                                        id: aMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
