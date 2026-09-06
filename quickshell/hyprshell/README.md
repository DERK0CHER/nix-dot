# hyprshell (Quickshell)

GNOME-like top bar, app menu, quick settings and notification center for Hyprland.

Run: `qs -c hyprshell` (config dir `~/.config/quickshell/hyprshell`, entry `shell.qml`).

IPC (bound to Super+I / N / A / B / G / Space in hypr/hyprland/binds.conf):

    qs -c hyprshell ipc call shell toggleQuickSettings
    qs -c hyprshell ipc call shell toggleNotifications
    qs -c hyprshell ipc call shell toggleAppMenu
    qs -c hyprshell ipc call shell toggleBar
    qs -c hyprshell ipc call shell setGameMode true|false
    qs -c hyprshell ipc call shell toggleLauncher

Files: shell.qml (root + IPC), State.qml / Theme.qml (singletons), Bar.qml, Workspaces.qml,
AppMenu.qml, Clock.qml, StatusPill.qml, QuickSettings.qml, NotificationCenter.qml,
NotificationPopups.qml, Osd.qml. Layer namespaces: hyprshell-bar, hyprshell-panel, hyprshell-osd, hyprshell-notif.
