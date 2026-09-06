import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Bottom-center OSD pill for volume / brightness changes
PanelWindow {
    id: win

    property bool show: false
    property string kind: "volume"     // "volume" | "brightness"
    property real value: 0
    property bool muted: false
    property bool ready: false

    visible: show
    anchors { bottom: true }
    margins { bottom: 48 }
    implicitWidth: 260
    implicitHeight: 56
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "hyprshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    // click-through
    mask: Region {}

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // ignore the initial volume sync right after startup
    Timer { interval: 1500; running: true; onTriggered: win.ready = true }

    Timer {
        id: hide
        interval: 1500
        onTriggered: win.show = false
    }

    Connections {
        target: (win.sink && win.sink.audio) ? win.sink.audio : null
        ignoreUnknownSignals: true
        function onVolumeChanged() { if (win.ready) win.showVolume() }
        function onMutedChanged() { if (win.ready) win.showVolume() }
    }

    function pop() {
        show = true
        hide.restart()
    }
    function showVolume() {
        if (!(sink && sink.audio)) return
        kind = "volume"
        value = sink.audio.volume
        muted = sink.audio.muted
        pop()
    }
    function showBrightness(p) {
        kind = "brightness"
        value = Math.max(0, Math.min(100, p)) / 100
        muted = false
        pop()
    }

    // qs -c hyprshell ipc call osd brightness 40   /   qs -c hyprshell ipc call osd volume
    IpcHandler {
        target: "osd"
        function brightness(p: int): void { win.showBrightness(p) }
        function volume(): void { win.showVolume() }
    }

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        opacity: win.show ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Text {
                text: win.kind === "brightness" ? "☼" : (win.muted ? "♪̸" : "♪")
                color: win.muted ? Theme.fgDim : Theme.fg
                font.family: Theme.font
                font.pixelSize: 18
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.18)
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, win.value))
                    height: parent.height
                    radius: 2
                    color: win.muted ? Theme.fgDim : Theme.accent
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }
            Text {
                text: Math.round(win.value * 100)
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 28
            }
        }
    }
}
