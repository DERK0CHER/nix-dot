import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Toast popups, top-right below the bar, max 3, 6 s auto-hide (critical stays)
PanelWindow {
    id: win

    property var items: []

    visible: items.length > 0
    anchors { top: true; right: true }
    margins { top: 6; right: 6 }
    implicitWidth: 360
    implicitHeight: Math.max(1, col.implicitHeight)
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "hyprshell-notif"
    WlrLayershell.layer: WlrLayer.Overlay
    // only the toasts themselves take input
    mask: Region { item: col }

    Connections {
        target: Notifs
        function onPopup(n) {
            const critical = n.urgency === NotificationUrgency.Critical
            if (!critical && (ShellState.doNotDisturb || ShellState.gameMode)) return
            win.add(n)
        }
    }

    function add(n) {
        let l = items.slice()
        l.unshift(n)
        while (l.length > 3) l.pop()
        items = l
    }
    function remove(n) {
        items = items.filter(x => x !== n)
    }

    ColumnLayout {
        id: col
        anchors { top: parent.top; right: parent.right }
        width: 360
        spacing: 6

        Repeater {
            model: win.items
            delegate: Rectangle {
                id: toast
                required property var modelData
                readonly property var n: modelData

                Layout.fillWidth: true
                implicitHeight: tCol.implicitHeight + 24
                radius: Theme.radius
                color: Theme.bg
                border.width: 1
                border.color: n.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.border

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                Timer {
                    interval: 6000
                    running: toast.n.urgency !== NotificationUrgency.Critical && !hoverArea.containsMouse
                    onTriggered: win.remove(toast.n)
                }
                Connections {
                    target: toast.n
                    ignoreUnknownSignals: true
                    function onClosed(reason) { win.remove(toast.n) }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (toast.n.actions.length > 0) toast.n.actions[0].invoke()
                        win.remove(toast.n)
                    }
                }

                ColumnLayout {
                    id: tCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 8

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
                                source: toast.n.image !== "" ? toast.n.image : Quickshell.iconPath(toast.n.appIcon, true)
                                visible: source !== ""
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: !icon.visible
                                radius: 16
                                color: Theme.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: toast.n.appName.length > 0 ? toast.n.appName.charAt(0).toUpperCase() : "!"
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
                                Text {
                                    Layout.fillWidth: true
                                    text: toast.n.summary
                                    elide: Text.ElideRight
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                    font.weight: Font.DemiBold
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
                                        onClicked: toast.n.dismiss()
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: toast.n.body !== ""
                                text: toast.n.body
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                color: Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        visible: toast.n.actions.length > 0
                        spacing: 6
                        Repeater {
                            model: toast.n.actions
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
                                    onClicked: { modelData.invoke(); win.remove(toast.n) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
