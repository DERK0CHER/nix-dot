pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Single NotificationServer for the whole shell.
// NotificationCenter and NotificationPopups both read Notifs.server / Notifs.list.
Singleton {
    id: root

    property alias server: server
    // id -> arrival timestamp (ms)
    property var times: ({})
    // newest first
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: server.trackedNotifications.values.length

    // emitted for notifications that should show a popup toast
    signal popup(var n)

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true
            root.times[n.id] = Date.now()
            const critical = n.urgency === NotificationUrgency.Critical
            const fromGameMode = (n.appName || "") === "Game mode"
            // Same rule as the popups: game mode blocks everything except its
            // own leave-confirmation. Notifications are still tracked, so the
            // notification centre has them waiting afterwards.
            if (ShellState.gameMode) {
                if (fromGameMode) root.popup(n)
            } else if (critical || !ShellState.doNotDisturb) {
                root.popup(n)
            }
        }
    }

    function timeOf(n) {
        const t = times[n.id]
        if (!t) return ""
        return Qt.formatTime(new Date(t), "HH:mm")
    }

    function clearAll() {
        const l = server.trackedNotifications.values.slice()
        for (let i = 0; i < l.length; i++) l[i].dismiss()
    }
}
