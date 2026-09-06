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
    CommandPalette {}
    NotificationCenter {}
    NotificationPopups {}
    Osd {}

    // qs -c hyprshell ipc call shell <function> [args]
    IpcHandler {
        target: "shell"

        function toggleQuickSettings(): void {
            const next = !ShellState.quickSettingsOpen;
            ShellState.closePanels();
            ShellState.quickSettingsOpen = next;
        }

        function togglePalette(): void {
            const next = !ShellState.paletteOpen;
            ShellState.closePanels();
            ShellState.paletteOpen = next;
        }

        function toggleNotifications(): void {
            const next = !ShellState.notificationsOpen;
            ShellState.closePanels();
            ShellState.notificationsOpen = next;
        }

        function toggleAppMenu(): void {
            const next = !ShellState.appMenuOpen;
            ShellState.closePanels();
            ShellState.appMenuOpen = next;
        }

        function toggleBar(): void {
            ShellState.barVisible = !ShellState.barVisible;
        }

        function setGameMode(on: bool): void {
            ShellState.gameMode = on;
            ShellState.barVisible = !on;
            ShellState.doNotDisturb = on;
            ShellState.closePanels();
        }

        function toggleLauncher(): void {
            ShellState.closePanels();
            Quickshell.execDetached(["sh", "-c", "pkill -x wofi || wofi --show drun"]);
        }
    }
}
