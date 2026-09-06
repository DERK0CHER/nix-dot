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
    Switcher {}

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

    // qs -c hyprshell ipc call switcher <next|prev|commit|cancel>
    // Driven entirely by the `switcher` submap in keybinds.conf: Hyprland
    // consumes its own binds before any surface sees them, so a held-Alt
    // switcher cannot be built out of QML key handlers.
    IpcHandler {
        target: "switcher"

        function next(): void {
            ShellState.switcherStep(1);
        }

        function prev(): void {
            ShellState.switcherStep(-1);
        }

        function commit(): void {
            if (!ShellState.switcherOpen)
                return;
            ShellState.switcherCommit();
            ShellState.switcherOpen = false;
        }

        function cancel(): void {
            ShellState.switcherOpen = false;
        }

        // Alt+Q while the overlay is up. Bound globally like the others, so it
        // must be a no-op when the switcher is closed - otherwise Alt+Q would
        // silently close windows at any time.
        function close(): void {
            if (!ShellState.switcherOpen)
                return;
            ShellState.switcherClose();
        }

        // Alt+1..0 while the overlay is up. Same no-op-when-closed rule as
        // close(): these are global binds, and silently relocating windows
        // outside the switcher would be worse than useless.
        function moveTo(ws: string): void {
            if (!ShellState.switcherOpen)
                return;
            ShellState.switcherMove(ws);
        }
    }
}
