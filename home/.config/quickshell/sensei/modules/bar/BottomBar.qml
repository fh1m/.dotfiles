import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import "../../services" as LearningBridge
import qs.modules.bar.items
import qs.modules.dropdowns

// ScreenPad's bottom strip: machine meters, centered workspaces, robot bench.
Variants {
    model: ShellState.bottomBarScreens
    PanelWindow {
        id: bar
        property string outputName: ""
        readonly property bool topEdge: external && ShellState.externalBarEdge(outputName)==="top"
        property string registration: ""
        function registerEdge():void {if(registration)ShellState.registerBar(registration,null);registration=outputName+(topEdge?":top":":bottom");ShellState.registerBar(registration,bar);}
        onTopEdgeChanged: if(outputName)registerEdge()
        Component.onCompleted: {outputName=modelData.name;if(outputName==="DP-2")ShellState.bottomBarWindow = bar;registerEdge();}
        Component.onDestruction: {if (ShellState.bottomBarWindow === bar) ShellState.bottomBarWindow = null;ShellState.registerBar(registration,null);}
        required property ShellScreen modelData
        IpcHandler {target:"bar-controls-bottom-"+bar.outputName;function expand(side:string,value:string):void {if(side==="left")bar.archiveOpen=value==="on";else if(side==="right")bar.machineOpen=value==="on";}function state():string {return JSON.stringify({left:bar.archiveOpen,right:bar.machineOpen});}}
        readonly property bool external: ShellState.externalScreens.some(s=>s.name===outputName)
        HoverHandler {onHoveredChanged:{ShellState.barHovered=hovered;if(hovered)ShellState.barContext(bar.outputName);}}
        property bool archiveOpen: false
        property bool machineOpen: false
        screen: modelData
        color: "transparent"
        implicitHeight: Appearance.metrics.barHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "sensei-bar"
        anchors { top: bar.topEdge; bottom: !bar.topEdge; left: true; right: true }
        Rectangle { anchors.fill: parent; color: Theme.barBg }
        Item {
            id:outputLabel
            visible:bar.external
            anchors.left:parent.left;anchors.leftMargin:20;anchors.verticalCenter:parent.verticalCenter
            width:34;height:30
            InstrumentIcon {anchors.centerIn:parent;kind:MachineProfile.desktop?"system":"monitor";ink:Theme.widgetMuted}
            Accessible.role:Accessible.Button
            Accessible.name:MachineProfile.host+" display arrangement"
            activeFocusOnTab:true
            function openDisplay(){ShellState.barContext(bar.outputName);ShellState.openDropdown("displays");}
            Accessible.onPressAction:openDisplay()
            Keys.onReturnPressed:openDisplay()
            Keys.onSpacePressed:openDisplay()
            MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:outputLabel.openDisplay()}
        }
        Row {
            id: meters
            visible: !bar.external
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            TrayGroup { visible:!bar.external;anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { condensed: !bar.archiveOpen; anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { condensed: !bar.archiveOpen; target: "clipboard"; label: "Clipboard"; detail:"History"; glyph: "\uf0ea"; anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { condensed: !bar.archiveOpen; target: "phone"; label: "Phone"; detail:PhoneBridge.phoneNearby?"Nearby":PhoneBridge.ready?"Online":"Offline"; glyph: "\uf10b"; anchors.verticalCenter: parent.verticalCenter }
            RailFold { expanded: bar.archiveOpen; onToggled: bar.archiveOpen = !bar.archiveOpen; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            id: navigation
            anchors.centerIn: parent
            spacing: 10
            PageMarker { output:bar.outputName;anchors.verticalCenter: parent.verticalCenter }
            Workspaces { id: workspaces;railOutput:bar.outputName;output:bar.external?bar.outputName:Spaces.mainMonitor?.name??bar.outputName;compact:bar.external&&bar.width<1500;anchors.verticalCenter: parent.verticalCenter }
        }
        CompanionPerch {
            output:bar.outputName;edge:bar.topEdge?"top":"bottom"
            preferred:!ShellState.barScreens.some(s=>s.name===bar.outputName)
            freeLeft:(bar.external?outputLabel.x+outputLabel.width:meters.x+meters.width)+12
            freeRight:navigation.x-12
            anchors.verticalCenter:parent.verticalCenter
        }
        Row {
            id:machineControls
            spacing: 3
            RailFold { visible:!bar.external; expanded: bar.machineOpen; opensRight: false; onToggled: bar.machineOpen = !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            ArchiveButton { visible:!bar.external; condensed: !bar.machineOpen; target: "oasis"; label: "Noesis"; detail:LearningBridge.NoesisBridge.activeVault?"Build · understand":"Choose a vault"; glyph: "\uf02d"; anchors.verticalCenter: parent.verticalCenter }
            CameraButton {visible:!bar.external&&Cameras.available;anchors.verticalCenter:parent.verticalCenter}
            UsbBadge { visible:!bar.external; condensed: !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            SimLaunchpad { visible:!bar.external; condensed: !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            DisplayBadge { output: MachineProfile.desktop ? bar.outputName : bar.external?bar.outputName:bar.outputName==="DP-2"?"screenpad":"main"; condensed: !bar.external && !bar.machineOpen; anchors.verticalCenter: parent.verticalCenter }
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
