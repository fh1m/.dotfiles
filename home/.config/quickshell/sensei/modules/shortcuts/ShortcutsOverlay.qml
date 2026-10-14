import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import "shortcuts.js" as Catalog

Variants {
    model: ShellState.overlayScreens

    PanelWindow {
        id: overlay
        required property ShellScreen modelData
        property string query: ""
        property int selected: 0
        readonly property bool shown: ShellState.shortcutsOpen
        readonly property var results: {
            const terms = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
            const ranked = Catalog.shortcuts.map((entry, index) => {
                const hay = (entry.key + " " + entry.title + " " + entry.group + " " + entry.detail).toLowerCase();
                let score = 0;
                for (const term of terms) {
                    const exact = hay.indexOf(term);
                    if (exact >= 0) { score += 100 - Math.min(exact, 80); continue; }
                    let at = 0, gaps = 0;
                    for (const letter of term) {
                        const found = hay.indexOf(letter, at);
                        if (found < 0) return {entry, index, score: -1};
                        gaps += found - at;
                        at = found + 1;
                    }
                    score += 30 - Math.min(gaps, 29);
                }
                return {entry, index, score};
            }).filter(row => row.score >= 0);
            if (terms.length) ranked.sort((a, b) => b.score - a.score || a.index - b.index);
            return ranked.map(row => row.entry);
        }
        IpcHandler {
            target: "shortcutview"
            function state(): string { return JSON.stringify({shown: overlay.shown, screen: overlay.modelData.name, width: overlay.width, height: overlay.height, panelWidth: panel.width, panelHeight: panel.height, panelX: panel.x, panelY: panel.y, results: overlay.results.length, listCount: list.count}); }
        }

        function move(delta) {
            if (!results.length) return;
            selected = Math.max(0, Math.min(results.length - 1, selected + delta));
            list.positionViewAtIndex(selected, ListView.Contain);
        }
        function copySelected() {
            if (!results.length) return;
            Quickshell.execDetached(["wl-copy", results[selected].key]);
        }

        screen: modelData
        color: "transparent"
        visible: shown
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sensei-shortcuts"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        onShownChanged: if (shown) { query = ""; selected = 0; searchInput.text = ""; searchInput.forceActiveFocus(); }

        Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.38 }
        MouseArea { anchors.fill: parent; onClicked: ShellState.shortcutsOpen = false }

        ChamferPanel {
            id: panel
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(14, (overlay.height - height) / 2)
            width: Math.min(820, overlay.width - 28)
            height: Math.min(640, overlay.height - 28)
            fillColor: Theme.widgetGlass
            borderColor: Theme.widgetAccent
            chamfer: 18
            MouseArea { anchors.fill: parent }

            Rectangle { x: 18; y: 22; width: 4; height: 30; color: Theme.widgetAccent }
            Text {
                x: 34; y: 17; text: "KEYMAP  //  FIELD GUIDE"
                color: Theme.widgetText; font.family: Appearance.font.data
                font.pixelSize: 19; font.weight: Font.Bold; renderType: Text.NativeRendering
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 22; y: 24
                text: overlay.results.length + " / " + Catalog.shortcuts.length + " BINDINGS"
                color: Theme.widgetAccent; font.family: Appearance.font.data
                font.pixelSize: 11; font.weight: Font.DemiBold; renderType: Text.NativeRendering
            }

            ChamferPanel {
                id: searchBox
                x: 20; y: 67; width: parent.width - 40; height: 44
                chamfer: 8; fillColor: Theme.widgetRaised; borderColor: Theme.widgetBorder
                Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: ""; color: Theme.widgetAccent; font.family: Appearance.font.data; font.pixelSize: 16 }
                TextInput {
                    id: searchInput
                    x: 42; y: 8; width: parent.width - 56; height: 30
                    color: Theme.widgetText; selectionColor: Theme.widgetAccent
                    selectedTextColor: "#000000"; font.family: Appearance.font.data
                    font.pixelSize: 14; renderType: Text.NativeRendering
                    onTextChanged: { overlay.query = text; overlay.selected = 0; list.positionViewAtBeginning(); }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) { ShellState.shortcutsOpen = false; event.accepted = true; }
                        else if (event.key === Qt.Key_Down) { overlay.move(1); event.accepted = true; }
                        else if (event.key === Qt.Key_Up) { overlay.move(-1); event.accepted = true; }
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { overlay.copySelected(); event.accepted = true; }
                    }
                }
                Text {
                    x: 42; anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text.length === 0; text: "Search key, action, category, or purpose…"
                    color: Theme.widgetFaint; font.family: Appearance.font.data; font.pixelSize: 13
                    renderType: Text.NativeRendering
                }
            }

            ListView {
                id: list
                x: 20; y: 122; width: parent.width - 40; height: parent.height - 161
                clip: true; spacing: 5; model: overlay.results
                delegate: ChamferPanel {
                    required property var modelData
                    required property int index
                    width: list.width - 8; height: 61; x: 4; chamfer: 7
                    fillColor: index === overlay.selected ? "#301620" : pointer.containsMouse ? "#1c2633" : Theme.widgetSurface
                    borderColor: index === overlay.selected ? Theme.widgetAccent : Theme.widgetBorder
                    Rectangle { x: 10; y: 13; width: 3; height: 35; color: index === overlay.selected ? Theme.widgetAccent : "#344050" }
                    Text {
                        x: 22; y: 8; width: parent.width - 255; elide: Text.ElideRight
                        text: modelData.title; color: index === overlay.selected ? "#ffb2c3" : Theme.widgetText
                        font.family: Appearance.font.data; font.pixelSize: 13; font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                    Text {
                        x: 22; y: 33; width: parent.width - 255; elide: Text.ElideRight
                        text: modelData.group.toUpperCase() + "  /  " + modelData.detail
                        color: Theme.widgetMuted; font.family: Appearance.font.data; font.pixelSize: 11
                        renderType: Text.NativeRendering
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 15; anchors.verticalCenter: parent.verticalCenter
                        width: 220; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft
                        text: modelData.key; color: index === overlay.selected ? "#ffb2c3" : "#8bb9f6"
                        font.family: Appearance.font.data; font.pixelSize: 12; font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: pointer; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { overlay.selected = index; searchInput.forceActiveFocus(); }
                        onDoubleClicked: overlay.copySelected()
                    }
                }
                Text {
                    anchors.centerIn: parent; visible: list.count === 0
                    text: "NO MATCH  //  TRY THE ACTION OR CATEGORY"
                    color: Theme.widgetMuted; font.family: Appearance.font.data; font.pixelSize: 12
                }
            }

            Text {
                x: 22; y: parent.height - 30
                text: "↑↓ BROWSE    ·    ENTER COPY KEY    ·    ESC CLOSE    //    SENSEI, EVERY CONTROL HAS A HOME"
                color: Theme.widgetMuted; font.family: Appearance.font.data; font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }
    }
}
