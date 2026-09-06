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

    // Alt+Tab switcher. The `switcher` submap owns the keys and drives these
    // through shell.qml's IPC handler; Switcher.qml owns the window list and
    // reports its length back as switcherCount so wraparound works.
    property bool switcherOpen: false
    property int switcherIndex: 0
    property int switcherCount: 0
    signal switcherCommit
    signal switcherClose
    signal switcherMove(string ws)

    // Optional extras (other components may set these).
    property int unreadCount: 0

    // Advance the switcher selection, opening it on the first press. A single
    // Alt+Tab must land on index 1 - the previously focused window - so that
    // tapping it twice returns you where you started.
    function switcherStep(step: int): void {
        if (!switcherOpen) {
            switcherIndex = 1;
            switcherOpen = true;
            return;
        }
        const n = switcherCount;
        // The list arrives asynchronously; before it does just accumulate and
        // let Switcher.load() wrap the index once the count is known.
        if (n <= 0) {
            switcherIndex = switcherIndex + step;
            return;
        }
        switcherIndex = ((switcherIndex + step) % n + n) % n;
    }

    function closePanels(): void {
        quickSettingsOpen = false;
        notificationsOpen = false;
        appMenuOpen = false;
        paletteOpen = false;
        switcherOpen = false;
        switcherIndex = 0;
    }
}
