import QtQuick
import Quickshell
import Quickshell.Hyprland

// GNOME-esque workspace dots: active = accent pill carrying its number,
// others = dim dots. Hovering reveals the numbers of the inactive ones too.
// The active number is always shown: a pill without it tells you the position
// but not which workspace you are actually on, which is the one thing the
// indicator exists to answer.
Item {
    id: root

    property var screen
    readonly property var monitor: Hyprland.monitorFor(root.screen)
    readonly property bool hovered: hoverArea.containsMouse

    readonly property var workspaces: {
        const mon = root.monitor;
        const all = Hyprland.workspaces.values;
        return all.filter(ws => ws.id > 0 && (!mon || !ws.monitor || ws.monitor.name === mon.name))
                  .sort((a, b) => a.id - b.id);
    }

    implicitWidth: dots.implicitWidth + Theme.pad
    implicitHeight: Theme.barHeight

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y < 0)
                Hyprland.dispatch("workspace m+1");
            else if (wheel.angleDelta.y > 0)
                Hyprland.dispatch("workspace m-1");
        }
    }

    Row {
        id: dots
        anchors.centerIn: parent
        spacing: Theme.gap

        Repeater {
            model: root.workspaces

            Rectangle {
                id: dot
                required property var modelData
                readonly property bool isActive: modelData.active

                anchors.verticalCenter: parent.verticalCenter
                width: root.hovered ? 20 : (isActive ? 20 : 6)
                height: (root.hovered || isActive) ? 16 : 6
                radius: height / 2
                color: isActive ? Theme.accent : (modelData.urgent ? Theme.danger : Theme.fgDim)

                Behavior on width { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.animMs } }

                Text {
                    anchors.centerIn: parent
                    visible: root.hovered || dot.isActive
                    text: dot.modelData.id
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: dot.isActive ? Theme.fg : Theme.bgSolid
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Hyprland.dispatch("workspace " + dot.modelData.id)
                }
            }
        }
    }
}
