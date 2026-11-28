import QtQuick
import qs.components
import qs.config
import qs.services

ChamferPanel {
    id: root
    property int workspace: 1
    property bool selected: false
    readonly property var windows: WindowDesk.scopedWindows.filter(w => Spaces.logicalId(Spaces.windowWorkspace(w)) === workspace)
    readonly property var activeDisplays: WindowDesk.displays.filter(m => (!WindowDesk.displayFilter || m.name === WindowDesk.displayFilter) && Spaces.logicalId(m.activeWorkspace?.id) === workspace)
    fillColor: selected ? Theme.widgetRaised : Theme.widgetSurface
    borderColor: selected || WindowDesk.dragTarget === workspace ? Theme.signal : Theme.widgetBorder
    borderWidth: 1
    chamfer: 10
    clip: true
    Component.onCompleted: WindowDesk.workspaceCards = WindowDesk.workspaceCards.concat([root])
    Component.onDestruction: WindowDesk.workspaceCards = WindowDesk.workspaceCards.filter(card => card !== root)

    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: WindowDesk.workspace(root.workspace) }
    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7
        Text {
            width: parent.width; textFormat: Text.PlainText; elide: Text.ElideRight
            text: WindowDesk.workspaceTitle(root.workspace) + "  ·  " + root.windows.length
            font.family: Appearance.font.reading; font.pixelSize: 16; color: root.selected ? Theme.signal : Theme.text
        }
        Text {
            width: parent.width; textFormat: Text.PlainText; elide: Text.ElideRight
            text: root.activeDisplays.length ? "Showing on " + root.activeDisplays.map(m => WindowDesk.displayLabel(m.name)).join(", ") : root.windows.length ? "Open in background" : "No open windows"
            font.family: Appearance.font.reading; font.pixelSize: 12; color: Theme.dim
        }
        Rectangle { width: parent.width; height: 1; color: Theme.widgetBorder }
        Repeater {
            model: root.windows.slice(0, Math.max(1, Math.floor((root.height - 96) / 31)))
            Rectangle {
                id: slot
                required property var modelData
                width: parent.width; height: 26; radius: 4
                color: pointer.containsMouse ? Theme.widgetRaised : Theme.alpha(Theme.deep,.48)
                Row {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 7
                    AppIcon { size: 16; entry: slot.modelData; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        width: Math.max(12,parent.width - 108); anchors.verticalCenter: parent.verticalCenter
                        text: WindowDesk.resultName(slot.modelData); textFormat: Text.PlainText; elide: Text.ElideRight
                        font.family: Appearance.font.reading; font.pixelSize: 12; color: Theme.text
                    }
                    Text {
                        width: 77; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight
                        text: WindowDesk.displayLabel(WindowDesk.displayOf(slot.modelData)); textFormat: Text.PlainText; elide: Text.ElideRight
                        font.family: Appearance.font.data; font.pixelSize: 10; color: Theme.dim
                    }
                }
                MouseArea {
                    id: pointer
                    anchors.fill: parent; hoverEnabled: true; preventStealing: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point start: Qt.point(0, 0)
                    property bool moved: false
                    onPressed: e => { start = Qt.point(e.x,e.y); moved=false; }
                    onPositionChanged: e => {
                        if (!pressed) return;
                        const point = mapToItem(null,e.x,e.y);
                        if (!moved && Math.hypot(e.x-start.x,e.y-start.y)>8) { moved=true; WindowDesk.beginDrag(slot.modelData,point.x,point.y); }
                        if (moved) WindowDesk.updateDrag(point.x,point.y);
                    }
                    onReleased: if(moved) WindowDesk.finishDrag()
                    onCanceled: WindowDesk.cancelDrag()
                    onClicked: if(!moved) WindowDesk.choose(slot.modelData)
                }
            }
        }
        Text {
            readonly property int hidden: Math.max(0, root.windows.length - Math.max(1, Math.floor((root.height - 96) / 31)))
            visible: hidden > 0
            text: "+" + hidden + " more in Applications"; textFormat: Text.PlainText
            font.family: Appearance.font.reading; font.pixelSize: 11; color: Theme.dim
        }
    }
}
