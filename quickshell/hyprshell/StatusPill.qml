import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

// One quiet pill on the right: tray (collapsed to "···"), network, volume, battery.
// Dim by default, bright on hover, click -> Quick Settings.
Item {
    id: root

    readonly property bool hovered: mouse.containsMouse
    readonly property bool active: hovered || ShellState.quickSettingsOpen

    // ---- network ----
    // Polled once per shell in Host.qml, not once per screen: this component is
    // instantiated by every Bar, and with two monitors the old per-pill Timer
    // fired two nmcli processes every 10 s.
    readonly property string netKind: Host.netKind   // "ethernet" | "wifi" | "none" | "" (unknown)
    readonly property string netIcon: netKind === "ethernet" ? "network-wired-symbolic"
                                    : netKind === "wifi" ? "network-wireless-symbolic"
                                    : "network-offline-symbolic"

    // ---- audio ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    readonly property real volume: root.sink && root.sink.audio ? root.sink.audio.volume : 0
    readonly property bool muted: root.sink && root.sink.audio ? root.sink.audio.muted : false
    readonly property string volIcon: (muted || volume <= 0) ? "audio-volume-muted-symbolic"
                                    : volume < 0.34 ? "audio-volume-low-symbolic"
                                    : volume < 0.67 ? "audio-volume-medium-symbolic"
                                    : "audio-volume-high-symbolic"

    // ---- battery ----
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat ? (bat.isLaptopBattery && bat.isPresent) : false
    readonly property string batIcon: {
        if (!root.hasBattery)
            return "";
        const pct = Math.max(0, Math.min(100, Math.round((root.bat.percentage || 0) * 100)));
        const level = Math.round(pct / 10) * 10;
        const charging = root.bat.state === UPowerDeviceState.Charging || root.bat.state === UPowerDeviceState.FullyCharged;
        return "battery-level-" + level + (charging ? "-charging" : "") + "-symbolic";
    }

    // ---- icon helper: Adwaita symbolic icon, forced white, text fallback ----
    component StatusIcon: Item {
        id: si
        property string icon: ""
        property string fallback: "•"
        readonly property string path: icon !== "" ? Quickshell.iconPath(icon, true) : ""
        implicitWidth: 16
        implicitHeight: 16

        IconImage {
            anchors.fill: parent
            source: si.path
            visible: si.path !== ""
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 1.0
            }
        }

        Text {
            anchors.centerIn: parent
            visible: si.path === ""
            text: si.fallback
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: Theme.fg
        }
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.barHeight

    Rectangle {
        id: pill
        anchors.centerIn: parent
        height: 24
        radius: 12
        implicitWidth: iconRow.implicitWidth + Theme.pad * 2
        color: root.active ? Theme.card : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
        // No Behavior here on purpose. The pill's width is bound to iconRow, whose
        // trayArea is already animated; animating it a second time (with different
        // easing) made the pill's left edge lag the tray reveal, so every icon to the
        // right of the tray visibly drifted and settled. One animation, in one place.

        Row {
            id: iconRow
            anchors.centerIn: parent
            spacing: Theme.pad - 2
            opacity: root.active ? 1.0 : 0.55
            Behavior on opacity { NumberAnimation { duration: Theme.animMs } }

            // System tray: "···" collapsed, icons on hover.
            Item {
                id: trayArea
                anchors.verticalCenter: parent.verticalCenter
                visible: SystemTray.items.values.length > 0
                implicitHeight: 16
                implicitWidth: root.hovered ? trayRow.implicitWidth : dotsText.implicitWidth
                Behavior on implicitWidth { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }

                Text {
                    id: dotsText
                    anchors.centerIn: parent
                    visible: !root.hovered
                    text: "···"
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Bold
                    color: Theme.fg
                }

                Row {
                    id: trayRow
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.hovered
                    spacing: Theme.gap

                    Repeater {
                        model: SystemTray.items

                        Item {
                            id: trayItem
                            required property var modelData
                            width: 16
                            height: 16

                            IconImage {
                                anchors.fill: parent
                                source: trayItem.modelData.icon
                            }

                            QsMenuAnchor {
                                id: trayMenu
                                menu: trayItem.modelData.menu
                                anchor.item: trayItem
                                anchor.edges: Edges.Bottom
                                anchor.gravity: Edges.Bottom
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: mouseEvent => {
                                    const item = trayItem.modelData;
                                    if (mouseEvent.button === Qt.RightButton) {
                                        if (item.hasMenu)
                                            trayMenu.open();
                                        else
                                            item.secondaryActivate();
                                    } else if (mouseEvent.button === Qt.MiddleButton) {
                                        item.secondaryActivate();
                                    } else {
                                        if (item.onlyMenu && item.hasMenu)
                                            trayMenu.open();
                                        else
                                            item.activate();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // GPU load. Vendor-aware (Host.qml): NVIDIA via nvidia-smi, AMD via
            // amdgpu sysfs. If the vendor tool is missing the whole item is
            // gone - no zeros, no error text.
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: Host.gpuAvailable && Host.gpuUtil >= 0
                text: Host.gpuLabel
                font.family: Theme.font
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.fg
            }

            StatusIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.netKind !== ""
                icon: root.netIcon
                fallback: root.netKind === "none" ? "⊘" : "⇅"
            }

            StatusIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: root.volIcon
                fallback: root.muted ? "🔇" : "🔊"
            }

            StatusIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasBattery
                icon: root.batIcon
                fallback: "🔋"
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            const next = !ShellState.quickSettingsOpen;
            ShellState.closePanels();
            ShellState.quickSettingsOpen = next;
        }
        onWheel: wheel => {
            if (!root.sink || !root.sink.audio)
                return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }
}
