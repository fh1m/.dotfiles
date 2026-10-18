import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// The workspace page marker: which page of workspaces the indicator beside it
// is showing, and how many there are. It sits where the hazard stripes were,
// with the bar's accent line running underneath it unbroken.
//
// **Changing page never moves anything along the bar** -- the bar's standing
// no-shifting rule. That falls out of `Spaces.pipCount` resting at three pips
// rather than out of a fixed width here: paging leaves the count alone, it only
// moves which pip is lit. The marker is therefore only as wide as the pips it
// is actually showing, so it can sit right against the workspace slots instead
// of holding open room for pages nobody has. It does widen by one pip's pitch
// when a workspace on a third page is created, which is a rare, deliberate act
// rather than a value ticking over.
Item {
    id: root

    property string output: ""
    readonly property bool external: ShellState.isExternalOutput(output || Spaces.focusedMonitor?.name || "")
    readonly property string modeText: external ? (ShellState.externalBarEdge(output||Spaces.focusedMonitor?.name||"")==="top"?"Upper":"Lower") : MachineProfile.role(output)==="screenpad" ? "Utility" : Spaces.modeGlyph + " " + Spaces.pageLabel

    // Five normal pages covers workspaces 1 to 25, and one more for the
    // special page. Beyond that the pips stop being countable at a glance
    // anyway, so the marker does not grow.
    readonly property int maxPips: 6
    readonly property int pipSize: 5
    readonly property int pipGap: 3
    readonly property int labelGap: 8

    readonly property int shown: Math.max(1, Math.min(Spaces.pipCount, maxPips))

    implicitWidth: external ? 78 : labelSlot.implicitWidth + labelGap + shown * (pipSize + pipGap) - pipGap
    implicitHeight: 11


    // A fixed slot measured from the widest label, so `P1` and `SPC` occupy
    // the same room.
    TextMetrics {
        id: widest

        font: label.font
        text: root.modeText
    }

    Item {
        id: labelSlot
        visible:!root.external

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: widest.advanceWidth + (root.external ? 28 : 0)
        implicitHeight: label.implicitHeight

        InstrumentIcon { visible:root.external;anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;kind:"monitor";ink:Theme.dim }

        NrLabel {
            id: label

            anchors.left: parent.left
            anchors.leftMargin: root.external ? 28 : 0
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.external ? 12 : Appearance.size.label
            tracked: !root.external
            color: !root.external && Spaces.special ? Theme.signalRed : Theme.dim
            text: root.modeText
        }
    }

    Rectangle {
        visible:root.external;anchors.centerIn:parent;width:78;height:24;radius:4;color:roleHover.containsMouse?Theme.surfaceTwo:"transparent"
        Text {x:30;anchors.verticalCenter:parent.verticalCenter;text:root.modeText;font.family:Appearance.font.barUi;font.pixelSize:11;color:Theme.widgetMuted}
        Accessible.role:Accessible.Button
        Accessible.name:root.modeText+" display settings"
        activeFocusOnTab:true
        function openDisplay(){ShellState.barContext(root.output);ShellState.openDropdownOn("displays",root.QsWindow.window?.screen?.name??"");}
        Accessible.onPressAction:openDisplay()
        Keys.onReturnPressed:openDisplay()
        Keys.onSpacePressed:openDisplay()
        Rectangle {x:6;y:4;width:16;height:12;radius:2;color:"transparent";border.width:1;border.color:Theme.paperMuted
            Rectangle {x:3;width:8;height:2;y:ShellState.externalBarEdge(root.output)==="top"?2:8;color:Theme.signalRed}
        }
        Rectangle {x:12;y:17;width:4;height:1;color:Theme.paperMuted}
        MouseArea {id:roleHover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:parent.openDisplay()}
    }
    Row {
        id: pips
        visible: !root.external

        anchors.left: labelSlot.right
        anchors.leftMargin: root.labelGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.pipGap

        Repeater {
            model: root.shown

            Rectangle {
                required property int index

                readonly property bool lit: index === Math.min(Spaces.litPip, root.shown - 1)

                width: root.pipSize
                height: root.pipSize
                color: lit ? Theme.accent : Theme.hair

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.duration.state
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    MouseArea {anchors.fill:parent;enabled:!root.external&&Spaces.special;onClicked:{const name=Spaces.activeSpecial.slice(8);if(!/^[A-Za-z0-9._-]+$/.test(name))return;Quickshell.execDetached(["hyprctl","dispatch",'hl.dsp.workspace.toggle_special("'+name+'")']);}}

}
