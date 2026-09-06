pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Host facts that are the SAME for every monitor and every panel, so they are
// probed exactly once per shell instance instead of once per screen.
//
//  * GPU vendor detection (nvidia / amd / intel / unknown) -> vendor-aware
//    telemetry.  Nothing here is required: if the vendor's tool is missing the
//    readout goes away completely, it never shows zeros or an error.
//  * Network kind, shared by every Bar's StatusPill (2 monitors used to mean
//    2 nmcli processes every 10 s).
Singleton {
    id: root

    // ---- GPU vendor -------------------------------------------------------
    // "nvidia" | "amd" | "intel" | "unknown". Detected once at startup.
    property string gpuVendor: "unknown"
    readonly property bool gpuVendorKnown: gpuVendor !== "unknown"

    // ---- GPU telemetry ----------------------------------------------------
    // gpuAvailable is the single gate for the UI: false => draw nothing.
    property bool gpuAvailable: false
    property int gpuUtil: -1        // percent
    property int gpuTemp: -1        // degrees C, -1 = unknown
    property int gpuMemUsed: -1     // MiB, -1 = unknown
    property int gpuMemTotal: -1    // MiB, -1 = unknown
    readonly property int gpuMemPercent: (gpuMemTotal > 0 && gpuMemUsed >= 0)
                                         ? Math.round(gpuMemUsed * 100 / gpuMemTotal) : -1
    readonly property string gpuLabel: gpuUtil >= 0 ? ("GPU " + gpuUtil + "%") : ""

    // Give up permanently after this many useless polls (missing nvidia-smi,
    // sysfs without the counters, ...). nvidia-smi is a heavyweight launch and
    // this is a 6-core desktop; we do not spawn it forever for nothing.
    property int gpuFailures: 0
    readonly property bool gpuGaveUp: gpuFailures >= 3

    // 5 s while a panel is open, 30 s otherwise.
    readonly property bool pollFast: ShellState.quickSettingsOpen || ShellState.notificationsOpen || ShellState.appMenuOpen

    // ---- shared network state (used by StatusPill on every monitor) -------
    property string netKind: ""     // "ethernet" | "wifi" | "none" | "" (unknown)

    // ---- vendor detection -------------------------------------------------
    Process {
        id: pVendor
        running: true
        // lspci first; if it is not installed fall back to the DRM drivers.
        command: ["sh", "-c",
            "lspci -nn 2>/dev/null | grep -iE 'vga|3d' || " +
            "cat /sys/class/drm/card*/device/uevent 2>/dev/null | grep -i '^DRIVER=' || true"]
        stdout: StdioCollector { onStreamFinished: root.parseVendor(text) }
    }

    function parseVendor(t) {
        const s = (t || "").toLowerCase();
        // NVIDIA wins on a hybrid box; this machine (i5-9400F) has no iGPU anyway.
        if (s.indexOf("nvidia") >= 0)
            root.gpuVendor = "nvidia";
        else if (s.indexOf("amd") >= 0 || s.indexOf("ati ") >= 0 || s.indexOf("radeon") >= 0 || s.indexOf("amdgpu") >= 0)
            root.gpuVendor = "amd";
        else if (s.indexOf("intel") >= 0 || s.indexOf("i915") >= 0 || /driver=xe\b/.test(s))
            root.gpuVendor = "intel";
        else
            root.gpuVendor = "unknown";
        // gpuPoll starts itself (triggeredOnStart) as soon as the vendor is known.
    }

    // ---- vendor-aware telemetry ------------------------------------------
    readonly property var gpuCommand: {
        if (gpuVendor === "nvidia")
            // one line: "23, 47, 1234, 6144"
            return ["sh", "-c",
                "command -v nvidia-smi >/dev/null 2>&1 && " +
                "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total " +
                "--format=csv,noheader,nounits 2>/dev/null | head -n1 || true"];
        if (gpuVendor === "amd")
            // amdgpu sysfs, normalised to the same CSV shape as nvidia-smi.
            return ["sh", "-c",
                "for d in /sys/class/drm/card*/device; do " +
                "[ -r \"$d/gpu_busy_percent\" ] || continue; " +
                "u=$(cat \"$d/gpu_busy_percent\" 2>/dev/null); " +
                "t=$(cat \"$d\"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1); " +
                "mu=$(cat \"$d/mem_info_vram_used\" 2>/dev/null); " +
                "mt=$(cat \"$d/mem_info_vram_total\" 2>/dev/null); " +
                "[ -n \"$t\" ] && t=$((t/1000)) || t=-1; " +
                "[ -n \"$mu\" ] && mu=$((mu/1048576)) || mu=-1; " +
                "[ -n \"$mt\" ] && mt=$((mt/1048576)) || mt=-1; " +
                "echo \"$u, $t, $mu, $mt\"; break; done"];
        // Intel has no cheap, universally present busy counter (i915 needs
        // intel_gpu_top with CAP_PERFMON) -> no readout, by design.
        return ["sh", "-c", "true"];
    }

    Process {
        id: pGpu
        command: root.gpuCommand
        stdout: StdioCollector { onStreamFinished: root.parseGpu(text) }
    }

    Timer {
        id: gpuPoll
        interval: root.pollFast ? 5000 : 30000
        repeat: true
        triggeredOnStart: true
        running: root.gpuVendorKnown && !root.gpuGaveUp
        onTriggered: {
            if (!root.gpuVendorKnown || root.gpuGaveUp)
                return;
            if (pGpu.running)   // never stack nvidia-smi launches
                return;
            pGpu.running = true;
        }
    }

    function clearGpu() {
        gpuAvailable = false;
        gpuUtil = -1;
        gpuTemp = -1;
        gpuMemUsed = -1;
        gpuMemTotal = -1;
    }

    function parseGpu(t) {
        const line = (t || "").trim().split("\n")[0] || "";
        const p = line.split(",");
        const num = function (s) {
            const v = parseInt((s || "").trim(), 10);
            return isNaN(v) ? -1 : v;   // nvidia-smi prints [N/A] on some fields
        };
        const util = p.length >= 1 ? num(p[0]) : -1;
        if (util < 0 || util > 100) {
            // missing tool / unreadable sysfs -> hide the readout entirely
            root.gpuFailures += 1;
            root.clearGpu();
            return;
        }
        root.gpuFailures = 0;
        root.gpuUtil = util;
        root.gpuTemp = p.length >= 2 ? num(p[1]) : -1;
        root.gpuMemUsed = p.length >= 3 ? num(p[2]) : -1;
        root.gpuMemTotal = p.length >= 4 ? num(p[3]) : -1;
        root.gpuAvailable = true;
    }

    // ---- shared network poll ---------------------------------------------
    Process {
        id: pNetKind
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "dev"]
        stdout: StdioCollector { onStreamFinished: root.parseNet(text) }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!pNetKind.running) pNetKind.running = true
    }

    function parseNet(text) {
        const lines = (text || "").split("\n");
        let kind = "none";
        for (const l of lines) {
            const parts = l.split(":");
            if (parts.length < 2)
                continue;
            const type = parts[0];
            const state = parts[1];
            if (state.indexOf("connected") === 0 || state.indexOf("verbunden") === 0) {
                if (type === "ethernet") {
                    kind = "ethernet";
                    break;
                }
                if (type === "wifi")
                    kind = "wifi";
            }
        }
        root.netKind = kind;
    }
}
