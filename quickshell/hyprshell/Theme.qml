pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Adwaita / GNOME HIG palette. Colours are NOT hardcoded here: the accent and
// the light/dark choice are read from GNOME's own settings, so Settings ->
// Appearance drives the bar, the panels and the palette the same way it drives
// GTK apps. Blur is added by Hyprland via layerrules on the hyprshell-* layers.
Singleton {
    id: root

    // ---- what GNOME tells us -------------------------------------------
    property string colorScheme: "prefer-dark"     // prefer-dark | prefer-light | default
    property string accentName: "blue"

    readonly property bool dark: colorScheme !== "prefer-light"

    // libadwaita accent colours (GNOME 47+). Same nine names the Settings
    // panel offers, so whatever the user picks there lands here.
    readonly property var accentMap: ({
        "blue":   "#3584e4", "teal":   "#2190a4", "green":  "#3a944a",
        "yellow": "#c88800", "orange": "#ed5b00", "red":    "#e62d42",
        "pink":   "#d56199", "purple": "#9141ac", "slate":  "#6f8396"
    })

    readonly property color accent: accentMap[accentName] || accentMap["blue"]

    // ---- palette --------------------------------------------------------
    readonly property string font: "Adwaita Sans"
    readonly property var fontFallbacks: ["Cantarell", "Inter", "sans-serif"]
    readonly property int fontSize: 13
    readonly property int fontSizeSmall: 11

    // Translucent so the Hyprland blur shows through; the solid variants are
    // libadwaita's window_bg_color for each scheme.
    readonly property color bg:       dark ? Qt.rgba(30 / 255, 30 / 255, 30 / 255, 0.72)
                                           : Qt.rgba(250 / 255, 250 / 255, 251 / 255, 0.78)
    readonly property color bgSolid:  dark ? "#242424" : "#fafafb"
    readonly property color card:     dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color cardHover:dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color border:   dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color fg:       dark ? "#ffffff" : "#1e1e1e"
    readonly property color fgDim:    dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.55)
    readonly property color danger:   "#e62d42"
    readonly property color success:  "#3a944a"

    readonly property int radius: 12
    readonly property int radiusSmall: 8
    readonly property int barHeight: 32
    readonly property int pad: 12
    readonly property int gap: 6
    readonly property int animMs: 150

    // ---- reading GNOME's settings ---------------------------------------
    // One read at startup...
    Process {
        id: readTheme
        running: true
        command: ["sh", "-c",
            "printf '%s\\n%s\\n' " +
            "\"$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)\" " +
            "\"$(gsettings get org.gnome.desktop.interface accent-color 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const strip = s => (s || "").replace(/^'|'$/g, "").trim();
                if (lines.length > 0 && strip(lines[0]) !== "") root.colorScheme = strip(lines[0]);
                if (lines.length > 1 && strip(lines[1]) !== "") root.accentName  = strip(lines[1]);
            }
        }
    }

    // ...then follow changes live, so picking a colour in GNOME Settings
    // recolours the bar without restarting anything.
    Process {
        id: watchTheme
        running: true
        command: ["gsettings", "monitor", "org.gnome.desktop.interface"]
        stdout: SplitParser {
            onRead: line => {
                // lines look like:  color-scheme: 'prefer-dark'
                const m = /^\s*([a-z-]+):\s*'?([^']*)'?\s*$/.exec(line);
                if (!m) return;
                if (m[1] === "color-scheme")  root.colorScheme = m[2].trim();
                if (m[1] === "accent-color")  root.accentName  = m[2].trim();
            }
        }
    }

    // Deliberately no per-monitor scaling: this tree drives a 3440x1440 160 Hz
    // ultrawide and a 1920x1080 secondary, and Wayland already hands each
    // output its own scale. Sizes above are logical pixels and stay put.
}
