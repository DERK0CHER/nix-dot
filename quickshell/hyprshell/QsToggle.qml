import QtQuick
import QtQuick.Layouts

// GNOME 45 style quick-settings pill
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property bool showArrow: false

    signal clicked()
    signal arrowClicked()

    Layout.fillWidth: true
    Layout.preferredWidth: 100
    implicitHeight: 48
    height: 48
    radius: 24
    color: active ? Theme.accent
                  : (hover.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Theme.card)
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: root.showArrow ? 8 : 16
        spacing: 10

        Text {
            text: root.icon
            visible: root.icon !== ""
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                visible: root.sublabel !== ""
                text: root.sublabel
                elide: Text.ElideRight
                color: root.active ? Qt.rgba(1, 1, 1, 0.8) : Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }

        Rectangle {
            visible: root.showArrow
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 16
            color: arrowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Text {
                anchors.centerIn: parent
                text: "›"
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 18
            }
            MouseArea {
                id: arrowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.arrowClicked()
            }
        }
    }
}
