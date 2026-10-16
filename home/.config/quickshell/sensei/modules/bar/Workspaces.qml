import QtQuick
import Quickshell.Io
import qs.components
import qs.config
import qs.services

// Five slots, never more, never fewer, never a different width. What is in them
// is `Spaces`' business: the page of numbered workspaces holding the active one,
// or the special workspaces while one of those is up.
Item {
    id: root
    property string output:""
    property bool compact:false
    readonly property bool external: ShellState.isExternalOutput(output)
    readonly property var monitorSlots:Spaces.slotsFor(output)

    // The bar draws the line under these, so it needs their pitch and which one
    // is lit. -1 leaves the line short rather than guessing.
    readonly property int itemWidth: compact?38:Appearance.metrics.workspaceWidth
    readonly property int itemSpacing: 7
    readonly property int activeIndex: monitorSlots.findIndex(s=>s.active)
    readonly property bool ownsFocus: !Spaces.remoteCapture && (!output || Spaces.focusedMonitor?.name===output)
    property int carriageIndex: 0
    onActiveIndexChanged: if (activeIndex >= 0) carriageIndex = activeIndex
    Component.onCompleted: if (activeIndex >= 0) carriageIndex = activeIndex
    IpcHandler {target:"workspace-rail-"+root.output;function state():string {return JSON.stringify({output:root.output,active:root.activeIndex,carriage:root.carriageIndex,x:carriage.x,slots:root.monitorSlots});}}

    implicitWidth: slots.implicitWidth + 6
    implicitHeight: Appearance.metrics.workspaceHeight + 6

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceOne
        radius: Theme.radiusSmall
        border.width: 1
        border.color: Theme.rule
    }
    Rectangle {
        id: carriage
        opacity: root.activeIndex >= 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        x: 3 + root.carriageIndex * (root.itemWidth + root.itemSpacing)
        y: 3
        width: root.itemWidth
        height: Appearance.metrics.workspaceHeight
        color: Theme.surfaceTwo
        radius: Theme.radiusSmall
        border.width: 1
        border.color: Theme.rule
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }
    Row {
    id: slots
    x: 3
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.itemSpacing

    Repeater {
        model: root.monitorSlots

        Item {
            id: button

            required property var modelData
            readonly property bool active: modelData.active
            readonly property bool occupied: modelData.occupied??false

            width: root.itemWidth
            height: Appearance.metrics.workspaceHeight
            scale: 1
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            HoverHandler { id: workspaceHover }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.itemWidth - 12
                height: button.active ? 2 : 1
                color: button.active ? Theme.signalRed : button.occupied ? Theme.paperMuted : Theme.rule
                Behavior on width { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
            }

            Rectangle {anchors.top:parent.top;anchors.left:parent.left;anchors.topMargin:4;anchors.leftMargin:5;width:6;height:3;visible:button.modelData.elsewhere??false;color:Theme.widgetMuted;opacity:.7}
            Text {anchors.top:parent.top;anchors.right:parent.right;anchors.topMargin:2;anchors.rightMargin:4;text:button.modelData.count>9?"9+":String(button.modelData.count??0);visible:!root.compact&&(button.modelData.count??0)>0;font.family:Appearance.font.data;font.pixelSize:8;color:button.active?Theme.paper:Theme.widgetMuted}
            Rectangle {anchors.top:parent.top;anchors.right:parent.right;anchors.topMargin:3;anchors.rightMargin:17;width:4;height:4;radius:2;visible:button.modelData.attention??false;color:Theme.signalRed}

            // **`NrLabel`, so the number is centred on its ink.** It was a
            // bare `Text` centred as an item, which is off in both directions
            // at once: the tracking is added after the last digit as well, and
            // the item is as tall as the font's whole line while a digit draws
            // in the top two thirds of it. The spec calls this slot out by
            // name -- "the active workspace number worst of all".
            Row {
                anchors.centerIn: parent
                spacing: 5
                Text {
                    textFormat: Text.PlainText
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: button.modelData.glyph ?? ""
                    font.family: "ZedMono Nerd Font"
                    font.pixelSize: root.external ? 16 : 14
                    color: button.active ? Theme.signalRed : button.occupied ? Theme.paper : Theme.widgetMuted
                    renderType: Text.NativeRendering
                }
                NrLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    visible:!root.compact
                    centred: true
                    text: button.modelData.label
                    font.capitalization: Font.MixedCase
                    // Empty workspaces are quieter than occupied ones but must stay legible:
                    // Theme.mute is 3.6:1 on the bar, below WCAG AA for text.
                    color: button.active ? Theme.paper : button.occupied ? Theme.paper : Theme.widgetMuted
                    pixelSize: root.external ? 13 : 11
                    font.family: Appearance.font.barUi
                    tracked: false
                    font.letterSpacing: root.external ? 0 : 0.5; font.features: Appearance.tabularFigures
                }
            }

            Row {anchors.bottom:parent.bottom;anchors.bottomMargin:4;anchors.horizontalCenter:parent.horizontalCenter;spacing:2;visible:root.compact
                Repeater {model:Math.min(4,button.modelData.count??0);Rectangle {width:3;height:2;radius:1;color:button.active?Theme.signalRed:Theme.paperMuted}}
            }
            Accessible.role:Accessible.Button
            Accessible.name:modelData.label+", "+(modelData.count??0)+" windows"+(modelData.attention?", needs attention":"")
            activeFocusOnTab:true
            function overview(){WindowDesk.open('overview',0);if(root.output)ShellState.overlayScreenName=root.output;WindowDesk.selected=Math.max(0,WindowDesk.workspaceIds.indexOf(Number(modelData.target)));}
            Keys.onMenuPressed:overview()
            Keys.onReturnPressed:Spaces.activate(button.modelData,root.output)
            Keys.onSpacePressed:Spaces.activate(button.modelData,root.output)
            Rectangle {anchors.fill:parent;radius:Theme.radiusSmall;color:"transparent";border.width:button.activeFocus?1:0;border.color:Theme.paperMuted}
            MouseArea {
                anchors.fill: parent
                acceptedButtons:Qt.LeftButton|Qt.RightButton
                enabled: !button.modelData.empty
                cursorShape: Qt.PointingHandCursor

                // **No press flash here.** The shared flash exists to say a
                // click landed before the work starts, but a workspace switch
                // lands in a frame or two and lights this very slot -- so the
                // flash fired and faded on top of the highlight arriving, and
                // read as a blink rather than as an acknowledgement. The slot
                // taking the accent and the bar's line sliding to it are the
                // confirmation, and they are already animated.
                onClicked:mouse=>{if(mouse.button===Qt.RightButton)button.overview();else Spaces.activate(button.modelData,root.output);}
            }
        }
    }
    }
}
