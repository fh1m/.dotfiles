import QtQuick
import qs.components
import qs.config
import qs.services
BarSurface {
 id:root
 property bool condensed:false
 clip:true
 property int page: -1
 property string target:"monitor"
 property string label:"Monitor"
 property string glyph:"\uf080"
 property string detail:target==="monitor"?"Telemetry":""
 implicitWidth:condensed?48:target==="monitor"?112:124;implicitHeight:34
 Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
 grouped:condensed
 selected:ShellState.dropdown===target;hovered:pointer.containsMouse;pressed:pointer.pressed
 Row {anchors.left:parent.left;anchors.leftMargin:8;anchors.verticalCenter:parent.verticalCenter;spacing:8
     NrLabel {text:root.glyph;centred:true;anchors.verticalCenter:parent.verticalCenter;pixelSize:23;color:root.target==="phone"?PhoneBridge.ready?Theme.semanticCyan:Theme.dim:Theme.signalRed}
     Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
         Text {text:root.label;font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
         Text {text:root.detail;visible:root.detail!=="";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
     }
 }
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:{if(root.page>=0)ShellState.monitorPage=root.page;ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown(root.target);}}
}
