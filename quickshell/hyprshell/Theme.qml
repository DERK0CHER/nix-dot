pragma Singleton
import QtQuick
import Quickshell

// Adwaita / GNOME HIG palette with transparency. Blur is added by Hyprland
// via layerrules on the hyprshell-* namespaces.
Singleton {
    id: root

    readonly property string font: "Adwaita Sans"
    readonly property var fontFallbacks: ["Cantarell", "Inter", "sans-serif"]
    readonly property int fontSize: 13
    readonly property int fontSizeSmall: 11

    readonly property color bg: Qt.rgba(30 / 255, 30 / 255, 30 / 255, 0.72)
    readonly property color bgSolid: "#242424"
    readonly property color card: Qt.rgba(1, 1, 1, 0.06)
    readonly property color cardHover: Qt.rgba(1, 1, 1, 0.10)
    readonly property color border: Qt.rgba(1, 1, 1, 0.10)
    readonly property color fg: "#ffffff"
    readonly property color fgDim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color accent: "#3584e4"
    readonly property color danger: "#e01b24"
    readonly property color success: "#33d17a"

    readonly property int radius: 12
    readonly property int radiusSmall: 8
    readonly property int barHeight: 32
    readonly property int pad: 12
    readonly property int gap: 6
    readonly property int animMs: 150
}
