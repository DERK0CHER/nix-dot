import QtQuick
import Quickshell.Hyprland

// The focused application's own menu bar, rendered in the panel's left area.
//
// AppMenuSource holds the tree; this file owns the interaction: which menu is
// open, which row is selected, and where each dropdown sits. A dropdown is a
// MenuPopup layer surface, and instead of a recursive component there is a
// fixed ladder of `maxLevels` of them driven by `stack` - menus deeper than
// that simply do not open, which is a far cheaper failure than a component
// that can instantiate itself.
//
// Nothing in the model is keyed by the node `id`: GTK ids are derived from the
// action name, so two entries can share one (see tools/menu-client/README.md).
// A menu is addressed by its *tree path* - a chain of indices into the filtered
// child lists - and QML's Repeaters key by list position only.
Item {
    id: root

    property var barScreen: null
    property var barWindow: null
    // Only the bar on the focused monitor may open a dropdown.
    property bool active: true
    property real maxWidth: 600

    readonly property int maxLevels: 5

    readonly property var menus: AppMenuSource.menus

    // One entry per open level: { path: [...], x, y }. x/y are in the popup's
    // own coordinate space (screen x, y measured from the bottom of the bar).
    property var stack: []
    // Selected row index per open level, -1 for none.
    property var sels: []

    readonly property bool open: root.stack.length > 0
    readonly property int openIndex: root.open ? root.stack[0].path[0] : -1

    implicitWidth: Math.min(chips.implicitWidth, Math.max(0, root.maxWidth))
    implicitHeight: 24
    clip: true

    // ---- tree navigation --------------------------------------------------

    // Invisible nodes are reported by menu-client, not dropped, so filtering is
    // this side's job. Separator runs left behind by that filtering, and leading
    // or trailing rules, are collapsed here too.
    function childrenOf(node) {
        if (!node || !node.children)
            return [];
        const out = [];
        for (let i = 0; i < node.children.length; i++) {
            const n = node.children[i];
            if (!n || !n.visible)
                continue;
            if (n.separator && (out.length === 0 || out[out.length - 1].separator))
                continue;
            out.push(n);
        }
        while (out.length > 0 && out[out.length - 1].separator)
            out.pop();
        return out;
    }

    function nodeAt(path) {
        let list = root.menus;
        let node = null;
        for (let k = 0; k < path.length; k++) {
            node = list[path[k]];
            if (!node)
                return null;
            list = root.childrenOf(node);
        }
        return node;
    }

    function nodesAt(path) {
        const n = root.nodeAt(path);
        return n ? root.childrenOf(n) : [];
    }

    function currentNode(level) {
        if (level < 0 || level >= root.stack.length)
            return null;
        const i = (level < root.sels.length) ? root.sels[level] : -1;
        if (i < 0)
            return null;
        return root.nodesAt(root.stack[level].path)[i] || null;
    }

    // ---- opening and closing ----------------------------------------------

    function popupAt(level) {
        switch (level) {
        case 0: return p0;
        case 1: return p1;
        case 2: return p2;
        case 3: return p3;
        case 4: return p4;
        }
        return null;
    }

    function closeAll(): void {
        root.stack = [];
        root.sels = [];
    }

    function closeTo(level): void {
        if (root.stack.length <= level + 1)
            return;
        root.stack = root.stack.slice(0, level + 1);
        root.sels = root.sels.slice(0, level + 1);
    }

    function openTop(i): void {
        if (!root.active || i < 0 || i >= root.menus.length)
            return;
        const item = chipRepeater.itemAt(i);
        if (!item)
            return;
        const p = item.mapToItem(null, 0, 0);
        root.stack = [{ "path": [i], "x": Math.round(p.x), "y": 0 }];
        root.sels = [-1];
    }

    function toggleTop(i): void {
        if (root.openIndex === i)
            root.closeAll();
        else
            root.openTop(i);
    }

    function moveTop(dir): void {
        const n = root.menus.length;
        if (n === 0)
            return;
        let i = root.openIndex;
        i = (i < 0) ? 0 : (i + dir + n) % n;
        root.openTop(i);
    }

    function openSub(level, index): void {
        if (level + 1 >= root.maxLevels)
            return;
        const parent = root.popupAt(level);
        if (!parent)
            return;
        const g = parent.subGeom(index);
        const st = root.stack.slice(0, level + 1);
        st.push({ "path": root.stack[level].path.concat([index]), "x": g.x, "y": g.y });
        const se = root.sels.slice(0, level + 1);
        se.push(-1);
        root.stack = st;
        root.sels = se;
    }

    function setSel(level, i): void {
        const s = root.sels.slice(0, level + 1);
        while (s.length <= level)
            s.push(-1);
        s[level] = i;
        root.sels = s;
    }

    // ---- pointer ----------------------------------------------------------

    function hoverRow(level, index): void {
        if (level >= root.stack.length)
            return;
        const n = root.nodesAt(root.stack[level].path)[index];
        if (!n || n.separator || !n.enabled) {
            root.setSel(level, -1);
            root.closeTo(level);
            return;
        }
        root.setSel(level, index);
        if (n.children && n.children.length > 0)
            root.openSub(level, index);
        else
            root.closeTo(level);
    }

    function clickRow(level, index): void {
        if (level >= root.stack.length)
            return;
        const n = root.nodesAt(root.stack[level].path)[index];
        if (!n || n.separator || !n.enabled)
            return;
        if (n.children && n.children.length > 0) {
            root.setSel(level, index);
            root.openSub(level, index);
            return;
        }
        root.trigger(n);
    }

    function trigger(n): void {
        AppMenuSource.activate(n.id);
        root.closeAll();
    }

    // ---- keyboard ---------------------------------------------------------

    function step(level, dir): void {
        const ns = root.nodesAt(root.stack[level].path);
        if (ns.length === 0)
            return;
        let i = (level < root.sels.length) ? root.sels[level] : -1;
        if (i < 0)
            i = (dir > 0) ? -1 : ns.length;
        for (let k = 0; k < ns.length; k++) {
            i = (i + dir + ns.length) % ns.length;
            const n = ns[i];
            if (n && !n.separator && n.enabled) {
                root.setSel(level, i);
                root.closeTo(level);
                return;
            }
        }
    }

    function enterSub(level): void {
        const i = (level < root.sels.length) ? root.sels[level] : -1;
        if (i < 0)
            return;
        root.openSub(level, i);
        if (root.stack.length > level + 1)
            root.step(level + 1, 1);
    }

    function activateCurrent(level): void {
        const n = root.currentNode(level);
        if (!n || n.separator || !n.enabled)
            return;
        if (n.children && n.children.length > 0) {
            root.enterSub(level);
            return;
        }
        root.trigger(n);
    }

    function handleKey(event): void {
        const L = root.stack.length - 1;
        if (L < 0)
            return;
        switch (event.key) {
        case Qt.Key_Escape:
            if (L > 0)
                root.closeTo(L - 1);
            else
                root.closeAll();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            root.step(L, 1);
            event.accepted = true;
            break;
        case Qt.Key_Up:
            root.step(L, -1);
            event.accepted = true;
            break;
        case Qt.Key_Home:
            root.setSel(L, -1);
            root.step(L, 1);
            event.accepted = true;
            break;
        case Qt.Key_End:
            root.setSel(L, -1);
            root.step(L, -1);
            event.accepted = true;
            break;
        case Qt.Key_Right: {
            const n = root.currentNode(L);
            if (n && n.enabled && n.children && n.children.length > 0)
                root.enterSub(L);
            else
                root.moveTop(1);
            event.accepted = true;
            break;
        }
        case Qt.Key_Left:
            if (L > 0)
                root.closeTo(L - 1);
            else
                root.moveTop(-1);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            root.activateCurrent(L);
            event.accepted = true;
            break;
        }
    }

    // ---- the bar entries --------------------------------------------------

    Row {
        id: chips
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Repeater {
            id: chipRepeater
            model: root.menus

            Rectangle {
                id: chip
                required property var modelData
                required property int index

                readonly property bool isOpen: root.openIndex === chip.index

                height: 24
                width: chipLabel.implicitWidth + 16
                radius: 8
                color: chip.isOpen ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
                     : chipMouse.containsMouse ? Theme.card
                     : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Theme.animMs }
                }

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: chip.modelData.label || ""
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Normal
                    color: Theme.fg
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleTop(chip.index)
                    // Once one menu is open, sliding across the bar switches
                    // which one is open, the way a real menu bar behaves.
                    onEntered: {
                        if (root.open && !chip.isOpen)
                            root.openTop(chip.index);
                    }
                }
            }
        }
    }

    // ---- the dropdown ladder ----------------------------------------------

    MenuPopup { id: p0; bar: root; level: 0; barScreen: root.barScreen }
    MenuPopup { id: p1; bar: root; level: 1; barScreen: root.barScreen }
    MenuPopup { id: p2; bar: root; level: 2; barScreen: root.barScreen }
    MenuPopup { id: p3; bar: root; level: 3; barScreen: root.barScreen }
    MenuPopup { id: p4; bar: root; level: 4; barScreen: root.barScreen }

    // Level 0 holds an exclusive keyboard grab, so a menu left open would eat
    // every key in the session. Any click outside the bar or the dropdowns
    // releases it - the same safety net the command palette uses.
    HyprlandFocusGrab {
        windows: root.barWindow ? [root.barWindow, p0, p1, p2, p3, p4]
                                : [p0, p1, p2, p3, p4]
        active: root.open && root.active
        onCleared: root.closeAll()
    }

    // A menu belongs to one window. When focus moves, the old menu is gone.
    Connections {
        target: AppMenuSource
        function onAddressChanged() {
            root.closeAll();
        }
    }

    onActiveChanged: {
        if (!root.active)
            root.closeAll();
    }
}
