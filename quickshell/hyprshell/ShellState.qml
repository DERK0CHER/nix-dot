pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool barVisible: true
    property bool quickSettingsOpen: false
    property bool notificationsOpen: false
    property bool appMenuOpen: false
    property bool gameMode: false
    property bool doNotDisturb: false
    property bool paletteOpen: false

    // Optional extras (other components may set these).
    property int unreadCount: 0

    function closePanels(): void {
        quickSettingsOpen = false;
        notificationsOpen = false;
        appMenuOpen = false;
        paletteOpen = false;
    }
}
