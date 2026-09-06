import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // One bar per monitor.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // Written by the panels agent (same directory).
    QuickSettings {}
    NotificationCenter {}
    NotificationPopups {}
    Osd {}

    // qs -c hyprshell ipc call shell <function> [args]
    IpcHandler {
        target: "shell"

        function toggleQuickSettings(): void {
            const next = !State.quickSettingsOpen;
            State.closePanels();
            State.quickSettingsOpen = next;
        }

        function toggleNotifications(): void {
            const next = !State.notificationsOpen;
            State.closePanels();
            State.notificationsOpen = next;
        }

        function toggleAppMenu(): void {
            const next = !State.appMenuOpen;
            State.closePanels();
            State.appMenuOpen = next;
        }

        function toggleBar(): void {
            State.barVisible = !State.barVisible;
        }

        function setGameMode(on: bool): void {
            State.gameMode = on;
            State.barVisible = !on;
            State.doNotDisturb = on;
            State.closePanels();
        }

        function toggleLauncher(): void {
            State.closePanels();
            Quickshell.execDetached(["sh", "-c", "pkill -x wofi || wofi --show drun"]);
        }
    }
}
