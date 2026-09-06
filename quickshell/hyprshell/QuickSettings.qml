import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// GNOME 45 style Quick Settings panel (top-right)
PanelWindow {
    id: win

    visible: State.quickSettingsOpen
    anchors { top: true; right: true }
    margins { top: 6; right: 6 }
    implicitWidth: 360
    implicitHeight: content.implicitHeight + 24
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "hyprshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool powerOpen: false
    property string powerConfirm: ""
    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    Services {
        id: svc
        pollFast: State.quickSettingsOpen
    }

    HyprlandFocusGrab {
        windows: [win]
        active: State.quickSettingsOpen
        onCleared: State.quickSettingsOpen = false
    }

    onVisibleChanged: {
        if (visible) svc.refresh()
        powerOpen = false
        powerConfirm = ""
    }

    function powerAction(name) {
        if (powerConfirm === name) {
            powerConfirm = ""
            State.quickSettingsOpen = false
            if (name === "suspend") svc.suspend()
            else if (name === "reboot") svc.reboot()
            else if (name === "poweroff") svc.poweroff()
        } else {
            powerConfirm = name
        }
    }

    component IconButton: Rectangle {
        id: ib
        property string icon: ""
        property bool active: false
        signal clicked()
        implicitWidth: 36
        implicitHeight: 36
        radius: 18
        color: active ? Theme.accent : (ibMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Theme.card)
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: ib.icon
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 16
        }
        MouseArea {
            id: ibMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ib.clicked()
        }
    }

    component PowerButton: Rectangle {
        id: pb
        property string label: ""
        property string name: ""
        property bool danger: false
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 18
        color: win.powerConfirm === name ? (danger ? Theme.danger : Theme.accent)
                                         : (pbMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Theme.card)
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: win.powerConfirm === pb.name ? "Confirm?" : pb.label
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
        MouseArea {
            id: pbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.powerAction(pb.name)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: Theme.radius
        border.width: 1
        border.color: Theme.border
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) { State.quickSettingsOpen = false; e.accepted = true }
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 12

            // ---- header ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "B"
                        color: "white"
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                }
                Text {
                    text: "beba"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }

                IconButton { icon: "⚿"; onClicked: { State.quickSettingsOpen = false; svc.lock() } }
                IconButton { icon: "⚙"; onClicked: { State.quickSettingsOpen = false; svc.openSettings() } }
                IconButton {
                    icon: "⏻"
                    active: win.powerOpen
                    onClicked: { win.powerOpen = !win.powerOpen; win.powerConfirm = "" }
                }
            }

            // ---- inline power row ----
            RowLayout {
                Layout.fillWidth: true
                visible: win.powerOpen
                spacing: 6
                PowerButton { label: "Suspend"; name: "suspend" }
                PowerButton { label: "Restart"; name: "reboot" }
                PowerButton { label: "Power Off"; name: "poweroff"; danger: true }
            }

            // ---- sliders ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                QsSlider {
                    icon: svc.muted ? "♪̸" : "♪"
                    dimmed: svc.muted
                    value: svc.volume
                    onMoved: v => svc.setVolume(v)
                    onIconClicked: svc.toggleMute()
                }
                QsSlider {
                    visible: svc.brightness >= 0
                    icon: "☼"
                    value: Math.max(0, svc.brightness) / 100
                    onMoved: v => svc.setBrightness(v * 100)
                }
            }

            // ---- toggles ----
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 6
                rowSpacing: 6

                QsToggle {
                    icon: "≋"
                    label: "Wi-Fi"
                    sublabel: !svc.wifiEnabled ? "Off" : (svc.wifiConnected ? svc.wifiSsid : (svc.ethConnected ? "Wired" : "Not connected"))
                    active: svc.wifiEnabled
                    onClicked: svc.toggleWifi()
                }
                QsToggle {
                    icon: "ᛒ"
                    label: "Bluetooth"
                    sublabel: svc.btPowered ? "On" : "Off"
                    active: svc.btPowered
                    onClicked: svc.toggleBluetooth()
                }
                QsToggle {
                    icon: "☾"
                    label: "Night Light"
                    sublabel: svc.nightLight ? "On" : "Off"
                    active: svc.nightLight
                    onClicked: svc.toggleNightLight()
                }
                QsToggle {
                    icon: "⊘"
                    label: "Do Not Disturb"
                    active: State.doNotDisturb
                    onClicked: State.doNotDisturb = !State.doNotDisturb
                }
                QsToggle {
                    icon: "⚡"
                    label: "Game Mode"
                    sublabel: State.gameMode ? "On" : "Off"
                    active: State.gameMode
                    onClicked: svc.toggleGameMode()
                }
                QsToggle {
                    icon: "◐"
                    label: "Power Mode"
                    sublabel: svc.profile === "power-saver" ? "Power Saver"
                            : (svc.profile === "performance" ? "Performance" : "Balanced")
                    active: svc.profile === "performance"
                    onClicked: svc.cycleProfile()
                }
            }

            // ---- media footer ----
            Rectangle {
                Layout.fillWidth: true
                visible: win.player !== null
                implicitHeight: 40
                radius: Theme.radiusSmall
                color: Theme.card

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 6
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: win.player ? (win.player.trackTitle !== "" ? win.player.trackTitle : win.player.identity)
                                         + (win.player && win.player.trackArtist !== "" ? "  ·  " + win.player.trackArtist : "")
                                         : ""
                        elide: Text.ElideRight
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    IconButton {
                        implicitWidth: 30
                        implicitHeight: 30
                        color: "transparent"
                        icon: (win.player && win.player.isPlaying) ? "❚❚" : "▶"
                        onClicked: if (win.player && win.player.canTogglePlaying) win.player.togglePlaying()
                    }
                    IconButton {
                        implicitWidth: 30
                        implicitHeight: 30
                        color: "transparent"
                        icon: "⏭"
                        onClicked: if (win.player && win.player.canGoNext) win.player.next()
                    }
                }
            }
        }
    }
}
