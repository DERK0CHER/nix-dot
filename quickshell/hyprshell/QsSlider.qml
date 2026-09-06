import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// icon + Adwaita styled slider, value 0..1
RowLayout {
    id: root

    property string icon: ""
    property real value: 0
    property bool dimmed: false

    signal moved(real value)
    signal iconClicked()

    Layout.fillWidth: true
    spacing: 10

    Rectangle {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 14
        color: iconMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
        Text {
            anchors.centerIn: parent
            text: root.icon
            color: root.dimmed ? Theme.fgDim : Theme.fg
            font.family: Theme.font
            font.pixelSize: 16
        }
        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Slider {
        id: s
        Layout.fillWidth: true
        implicitHeight: 24
        from: 0
        to: 1
        stepSize: 0.01
        onMoved: root.moved(s.value)

        Component.onCompleted: s.value = root.value
        Connections {
            target: root
            function onValueChanged() { if (!s.pressed) s.value = root.value }
        }

        background: Rectangle {
            x: s.leftPadding
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: s.availableWidth
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.18)
            Rectangle {
                width: s.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }

        handle: Rectangle {
            x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: 20
            height: 20
            radius: 10
            color: s.pressed ? "#e6e6e6" : "#ffffff"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.25)
        }
    }
}
