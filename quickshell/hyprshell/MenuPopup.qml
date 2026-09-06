import QtQuick
import Quickshell
import Quickshell.Wayland

// One level of the global menu dropdown. MenuBar declares a fixed ladder of
// these (level 0..N) and drives them through its `stack`; nothing here creates
// windows, so there is no recursive component and no dynamic instantiation.
//
// Geometry is expressed relative to the *bottom of the bar*: the surface asks
// for exclusiveZone 0, so the compositor already subtracts the bar's own
// exclusive zone from the top anchor and `margins.top: 0` sits flush under it.
PanelWindow {
    id: pop

    property var bar: null
    property int level: 0
    property var barScreen: null

    // { path: [indices into the *filtered* node lists], x, y }
    readonly property var entry: (pop.bar && pop.bar.stack.length > pop.level) ? pop.bar.stack[pop.level] : null
    readonly property var nodes: (pop.bar && pop.entry) ? pop.bar.nodesAt(pop.entry.path) : []
    readonly property int sel: (pop.bar && pop.bar.sels.length > pop.level) ? pop.bar.sels[pop.level] : -1

    visible: pop.entry !== null && pop.bar !== null && pop.bar.active
    screen: pop.barScreen
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.namespace: "hyprshell-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    // Exactly one surface in the ladder takes the keyboard, and it is always
    // level 0 - it is the one that stays alive for the whole interaction, so
    // focus never has to be handed over as submenus come and go. Every key is
    // routed straight back into MenuBar, which knows the whole stack.
    WlrLayershell.keyboardFocus: (pop.level === 0 && pop.visible) ? WlrKeyboardFocus.OnDemand
                                                                  : WlrKeyboardFocus.None

    // ---- metrics ----------------------------------------------------------
    readonly property int padH: 10
    readonly property int padV: 6
    readonly property int rowHeight: 28
    readonly property int sepHeight: 9

    FontMetrics {
        id: fm
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    // A checkmark gutter only when this menu actually has checkable entries,
    // so a plain menu is not indented for nothing.
    readonly property int gutter: {
        const ns = pop.nodes;
        for (let i = 0; i < ns.length; i++)
            if (ns[i] && ns[i].checked !== null && ns[i].checked !== undefined)
                return 20;
        return 0;
    }

    function rowH(n) {
        return (n && n.separator) ? pop.sepHeight : pop.rowHeight;
    }

    // Accelerators arrive as the app spelled them ("Control+Shift+N").
    function shortcutText(s) {
        if (!s)
            return "";
        return ("" + s).replace(/Control/g, "Ctrl").replace(/Meta/g, "Super");
    }

    function hasKids(n) {
        return !!(n && n.children && n.children.length > 0);
    }

    readonly property int contentW: {
        let w = 0;
        const ns = pop.nodes;
        for (let i = 0; i < ns.length; i++) {
            const n = ns[i];
            if (!n || n.separator)
                continue;
            let x = fm.advanceWidth(n.label || "");
            if (pop.hasKids(n))
                x += 22;
            else if (n.shortcut)
                x += 28 + fm.advanceWidth(pop.shortcutText(n.shortcut));
            w = Math.max(w, x);
        }
        if (ns.length === 0)
            w = fm.advanceWidth("(empty)");
        return Math.ceil(w);
    }

    readonly property int contentH: {
        let h = 0;
        const ns = pop.nodes;
        for (let i = 0; i < ns.length; i++)
            h += pop.rowH(ns[i]);
        return ns.length === 0 ? pop.rowHeight : h;
    }

    implicitWidth: Math.max(170, Math.min(560, pop.contentW + pop.padH * 2 + pop.gutter + 2))
    implicitHeight: pop.contentH + pop.padV * 2 + 2

    // ---- placement --------------------------------------------------------
    readonly property int screenW: pop.barScreen ? pop.barScreen.width : 1920
    readonly property int screenH: pop.barScreen ? pop.barScreen.height : 1080
    readonly property int wantX: pop.entry ? pop.entry.x : 0
    readonly property int wantY: pop.entry ? pop.entry.y : 0

    readonly property int posX: Math.max(4, Math.min(pop.wantX, pop.screenW - pop.implicitWidth - 4))
    readonly property int posY: Math.max(0, Math.min(pop.wantY,
                                                     pop.screenH - Theme.barHeight - pop.implicitHeight - 4))

    anchors {
        top: true
        left: true
    }
    margins {
        top: pop.posY
        left: pop.posX
    }

    // y of row i's top edge, measured from this surface's own top edge.
    function rowTop(i) {
        let y = 1 + pop.padV;
        const ns = pop.nodes;
        for (let k = 0; k < i && k < ns.length; k++)
            y += pop.rowH(ns[k]);
        return y;
    }

    // Where a submenu spawned from row i wants to sit, in the same
    // below-the-bar coordinate space this surface uses.
    function subGeom(i) {
        return {
            "x": pop.posX + pop.implicitWidth - 4,
            "y": pop.posY + pop.rowTop(i) - 1 - pop.padV
        };
    }

    // ---- surface ----------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        FocusScope {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (pop.bar)
                    pop.bar.handleKey(event);
            }
        }

        Text {
            anchors.centerIn: parent
            visible: pop.nodes.length === 0
            text: "(empty)"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: Theme.fgDim
        }

        Column {
            id: rows
            x: 1
            y: 1 + pop.padV
            width: parent.width - 2

            Repeater {
                model: pop.nodes

                Item {
                    id: rowItem
                    required property var modelData
                    required property int index

                    width: rows.width
                    height: pop.rowH(rowItem.modelData)

                    readonly property bool isSep: !!rowItem.modelData.separator
                    readonly property bool kids: pop.hasKids(rowItem.modelData)

                    Rectangle {
                        visible: rowItem.isSep
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: pop.padH
                        anchors.rightMargin: pop.padH
                        height: 1
                        color: Theme.border
                    }

                    Rectangle {
                        id: rowBg
                        visible: !rowItem.isSep
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        radius: Theme.radiusSmall
                        color: pop.sel === rowItem.index ? Theme.cardHover : "transparent"
                        opacity: rowItem.modelData.enabled ? 1.0 : 0.4

                        Text {
                            visible: pop.gutter > 0
                            anchors.left: parent.left
                            anchors.leftMargin: pop.padH - 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: rowItem.modelData.checked === true ? "✓" : ""
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            color: Theme.fg
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: pop.padH - 4 + pop.gutter
                            anchors.right: trailing.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: rowItem.modelData.label || ""
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            color: Theme.fg
                        }

                        Text {
                            id: trailing
                            anchors.right: parent.right
                            anchors.rightMargin: pop.padH - 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: rowItem.kids ? "›" : pop.shortcutText(rowItem.modelData.shortcut)
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            color: Theme.fgDim
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                if (pop.bar)
                                    pop.bar.hoverRow(pop.level, rowItem.index);
                            }
                            onClicked: {
                                if (pop.bar)
                                    pop.bar.clickRow(pop.level, rowItem.index);
                            }
                        }
                    }
                }
            }
        }
    }

    // The layer surface only exists once it is shown, so grab the keyboard the
    // moment it appears rather than at component completion.
    onVisibleChanged: {
        if (pop.visible && pop.level === 0)
            keys.forceActiveFocus();
    }
    onEntryChanged: {
        if (pop.visible && pop.level === 0)
            keys.forceActiveFocus();
    }
}
