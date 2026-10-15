import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

// A stable, opaque tab surface over Hyprland's native window group.
// Native grouping owns membership; direct click targets own focus and close.
Variants {
    // **One bar per group, not one per member.** Every member of a group lists
    // the whole group in `grouped`, so filtering on the count alone drew one
    // identical bar for each member, each highlighting a different tab. Only the
    // head -- the first address in the list, which every member agrees on -- gets
    // a bar.
    model: Hyprland.toplevels.values.filter(t => {
        const w = t.lastIpcObject;
        return w && w.visible && !w.hidden && (w.grouped?.length ?? 0) > 1 && w.grouped[0] === w.address;
    })
    PanelWindow {
        id: marker
        required property var modelData
        readonly property var group: modelData.lastIpcObject
        readonly property var groupScreen: ShellState.screens.find(s => s.name === modelData.monitor?.name) ?? null
        readonly property var monitor: Hyprland.monitors.values.find(m => m.name === groupScreen?.name) ?? null
        readonly property var members: group?.grouped ?? []
        // The highlighted tab is the focused member's, so focusing another
        // tab moves the highlight. Falls back to the head when focus is elsewhere.
        readonly property string activeAddress: Hyprland.activeToplevel?.lastIpcObject?.address ?? ""
        readonly property int position: Math.max(1, members.indexOf(activeAddress) >= 0 ? members.indexOf(activeAddress) + 1 : members.indexOf(group?.address) + 1)
        readonly property int groupWorkspace: group?.workspace?.id ?? -1
        readonly property int shownWorkspace: monitor?.activeWorkspace?.id ?? -2
        screen: groupScreen
        color: "transparent"
        visible: groupScreen !== null && members.length > 1 && groupWorkspace === shownWorkspace && !group.hidden && !group.fullscreen && !ShellState.locked
        implicitWidth: Math.max(1, (group?.size?.[0] ?? 1) - 24)
        implicitHeight: 26
        anchors { top: true; left: true }
        margins.left: Math.max(0, (group?.at?.[0] ?? 0) + 12 - (monitor?.lastIpcObject?.x ?? 0))
        margins.top: Math.max(0, (group?.at?.[1] ?? 0) - (monitor?.lastIpcObject?.y ?? 0) - 31)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sensei-tabs"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {item: hitSurface}
        // Keep the input region aligned with the opaque surface.
        Item {id:hitSurface;anchors.fill:parent}
        Rectangle {anchors.fill:parent;color:"#000000";radius:4;border.width:1;border.color:Theme.alpha(Theme.signalRed,.38)}
        Repeater {
            model: marker.members
            Item {
                id: tab
                required property string modelData
                required property int index
                readonly property var groupWindow: Hyprland.toplevels.values.find(t => WindowDesk.addressFor(t) === modelData) ?? null
                readonly property string tabTitle: Demo.active
                    ? (WindowDesk.desktopEntryFor(groupWindow)?.name ?? groupWindow?.lastIpcObject?.class ?? "Window")
                    : (groupWindow?.title ?? groupWindow?.lastIpcObject?.title ?? "Window")
                readonly property real tabWidth: marker.width / Math.max(1, marker.members.length)
                readonly property bool current: marker.position === index + 1
                x: index * tabWidth
                width: Math.max(1, tabWidth)
                height: marker.height - 2
                MouseArea {
                    anchors.fill:parent
                    acceptedButtons:Qt.LeftButton|Qt.MiddleButton
                    property real startX:0
                    property bool reordered:false
                    onPressed:event=>{startX=mapToItem(hitSurface,event.x,event.y).x;reordered=false;}
                    onReleased:event=>{
                        if(event.button!==Qt.LeftButton)return;
                        const delta=mapToItem(hitSurface,event.x,event.y).x-startX;
                        const steps=Math.max(-tab.index,Math.min(marker.members.length-1-tab.index,Math.round(delta/tab.tabWidth)));
                        reordered=steps!==0;
                        for(let i=0;i<Math.abs(steps);i++)Hyprland.dispatch('hl.dsp.group.move_window({window="address:'+tab.modelData+'",forward='+(steps>0?'true':'false')+'})');
                    }
                    onClicked:event=>{
                        if(reordered)return;
                        if(event.button===Qt.MiddleButton)Hyprland.dispatch('hl.dsp.window.close({window="address:'+tab.modelData+'"})');
                        else Hyprland.dispatch('hl.dsp.focus({window="address:'+tab.modelData+'"})');
                    }
                }
                Rectangle {
                    visible: index > 0
                    x: 0; y: 5; width: 1; height: 18
                    color: Theme.rule
                }
                Row {
                    id: titleGroup
                    anchors.verticalCenter: parent.verticalCenter
                    x: 16
                    spacing: 8
                    Item {
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            id: appArt
                            anchors.fill: parent
                            source: WindowDesk.iconFor(tab.groupWindow)
                            sourceSize: Qt.size(32, 32)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                        Text {
                            textFormat: Text.PlainText
                            anchors.centerIn: parent
                            visible: appArt.status !== Image.Ready
                            text: "·"
                            color: Theme.paperMuted
                            font.pixelSize: 15
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.tabTitle
                        textFormat: Text.PlainText
                        width: Math.min(implicitWidth, Math.max(1, tab.tabWidth - (tab.index === marker.members.length - 1 ? 136 : 44)))
                        elide: Text.ElideRight
                        color: tab.current ? Theme.signalRed : Theme.paperMuted
                        font.family: Appearance.font.barUi
                        font.pixelSize: 12
                        font.weight: tab.current ? Font.Bold : Font.DemiBold
                        renderType: Text.NativeRendering
                    }
                }
                Rectangle {anchors.fill:parent;anchors.margins:2;color:Theme.signalRed;opacity:tab.current?.055:0;radius:3;z:-1}
                Rectangle {
                    visible: tab.current
                    x: 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 12
                    radius: 1.5
                    color: Theme.signalRed
                }
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 92
            height: 19
            color: "#000000"
            radius: Theme.radiusSmall
            border.width: 1
            border.color: Theme.rule
            Rectangle { x: 1; y: 3; width: 2; height: parent.height - 6; color: Theme.signalRed }
            Text {
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: `Tabs  ${marker.position} / ${marker.members.length}`
                color: Theme.paper
                font.family: Appearance.font.telemetry
                font.pixelSize: 11
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }
        }
    }
}
