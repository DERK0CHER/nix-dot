import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Plain (non-singleton) service object. Instantiate as:  Services { id: svc }
Scope {
    id: svc

    // poll every 5 s while a panel is open, otherwise every 30 s
    property bool pollFast: false

    // network
    property bool wifiEnabled: false
    property bool wifiConnected: false
    property string wifiSsid: ""
    property bool ethConnected: false
    // bluetooth
    property bool btPowered: false
    // brightness in percent, -1 = no backlight device
    property int brightness: -1
    // power-profiles-daemon
    property string profile: "balanced"
    readonly property var profiles: ["balanced", "performance", "power-saver"]
    // gammastep running
    property bool nightLight: false

    // GPU: vendor-aware, probed once per shell in Host.qml (singleton), not
    // once per Services instance. AMD reads amdgpu sysfs, NVIDIA shells out to
    // nvidia-smi, Intel has no readout. gpuAvailable is the only gate the UI
    // needs: when the vendor tool is missing the whole readout disappears
    // instead of showing zeros.
    readonly property string gpuVendor: Host.gpuVendor
    readonly property bool gpuAvailable: Host.gpuAvailable
    readonly property int gpuUtil: Host.gpuUtil
    readonly property int gpuTemp: Host.gpuTemp
    readonly property int gpuMemUsed: Host.gpuMemUsed
    readonly property int gpuMemTotal: Host.gpuMemTotal
    readonly property int gpuMemPercent: Host.gpuMemPercent

    // audio (Pipewire)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Timer {
        id: poll
        interval: svc.pollFast ? 5000 : 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: svc.refresh()
    }

    // delayed re-poll after a toggle so the UI reflects the real state
    Timer {
        id: repoll
        interval: 1200
        repeat: false
        onTriggered: svc.refresh()
    }

    function refresh() {
        pNet.running = true
        pBt.running = true
        pBr.running = true
        pProf.running = true
        pNl.running = true
    }

    Process {
        id: pNet
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f TYPE,STATE,CONNECTION device status"]
        stdout: StdioCollector { onStreamFinished: svc.parseNet(text) }
    }

    Process {
        id: pBt
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: svc.btPowered = text.trim() === "yes" }
    }

    Process {
        id: pBr
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | head -n1"]
        stdout: StdioCollector { onStreamFinished: svc.parseBrightness(text) }
    }

    Process {
        id: pProf
        command: ["sh", "-c", "powerprofilesctl get 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t !== "") svc.profile = t
            }
        }
    }

    Process {
        id: pNl
        command: ["sh", "-c", "pgrep -x gammastep >/dev/null && echo on || echo off"]
        stdout: StdioCollector { onStreamFinished: svc.nightLight = text.trim() === "on" }
    }

    function parseNet(t) {
        const lines = t.trim().split("\n")
        let wifiOn = false, wifiConn = false, ssid = "", eth = false
        for (let i = 0; i < lines.length; i++) {
            const l = lines[i].trim()
            if (i === 0) { wifiOn = (l === "enabled"); continue }
            const p = l.split(":")
            if (p.length < 2) continue
            const type = p[0], state = p[1]
            const conn = p.slice(2).join(":")
            if (type === "wifi" && state.indexOf("connected") === 0) { wifiConn = true; ssid = conn }
            if (type === "ethernet" && state.indexOf("connected") === 0) eth = true
        }
        wifiEnabled = wifiOn
        wifiConnected = wifiConn
        wifiSsid = ssid
        ethConnected = eth
    }

    function parseBrightness(t) {
        // "<device>,backlight,255,100%,255" - device name is vendor specific
        // (amdgpu_bl1, nvidia_wmi_ec_backlight, intel_backlight, ...). A desktop
        // usually has no backlight device at all -> empty output -> -1.
        const p = t.trim().split(",")
        if (p.length >= 4) {
            const v = parseInt(p[3].replace("%", ""))
            brightness = isNaN(v) ? -1 : v
        } else {
            brightness = -1
        }
    }

    // ---- actions ----
    function setVolume(v) {
        if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v))
    }
    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    }
    function setBrightness(p) {
        const v = Math.max(1, Math.min(100, Math.round(p)))
        brightness = v
        Quickshell.execDetached(["brightnessctl", "-q", "s", v + "%"])
    }
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"])
        wifiEnabled = !wifiEnabled
        repoll.restart()
    }
    function toggleBluetooth() {
        Quickshell.execDetached(["bluetoothctl", "power", btPowered ? "off" : "on"])
        btPowered = !btPowered
        repoll.restart()
    }
    function setProfile(name) {
        Quickshell.execDetached(["powerprofilesctl", "set", name])
        profile = name
        repoll.restart()
    }
    function cycleProfile() {
        const i = profiles.indexOf(profile)
        setProfile(profiles[(i + 1) % profiles.length])
    }
    function toggleNightLight() {
        if (nightLight) {
            Quickshell.execDetached(["sh", "-c", "pkill -x gammastep; sleep 0.3; gammastep -x -m wayland >/dev/null 2>&1"])
        } else {
            Quickshell.execDetached(["sh", "-c", "setsid gammastep -m wayland -P -l 0:0 -t 4000:4000 >/dev/null 2>&1 &"])
        }
        nightLight = !nightLight
        repoll.restart()
    }
    function toggleGameMode() {
        Quickshell.execDetached(["sh", "-c", "\"$HOME/.config/hypr/scripts/game-mode\" toggle"])
    }
    function openSettings() {
        Quickshell.execDetached(["sh", "-c", "XDG_CURRENT_DESKTOP=gnome gnome-control-center >/dev/null 2>&1 &"])
    }
    function lock()     { Quickshell.execDetached(["loginctl", "lock-session"]) }
    function suspend()  { Quickshell.execDetached(["systemctl", "suspend"]) }
    function reboot()   { Quickshell.execDetached(["systemctl", "reboot"]) }
    function poweroff() { Quickshell.execDetached(["systemctl", "poweroff"]) }
}
