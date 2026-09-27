import QtQuick
import qs.components
import qs.config
import qs.services
Rectangle {
 id:root
 property int page: -1
 property string target:"monitor"
 property string label:"SYSTEM MONITOR"
 property string glyph:"\uf080"
 implicitWidth:target==="monitor"?164:124;implicitHeight:30
 radius:2;color:pointer.containsMouse || ShellState.dropdown===target?Theme.alpha(Theme.signal,.14):"transparent";border.width:1;border.color:"#26282d"
 Row {anchors.centerIn:parent;spacing:9;NrLabel {text:root.glyph;centred:true;anchors.verticalCenter:parent.verticalCenter;pixelSize:16;color:Theme.signal}NrLabel {text:root.label;centred:true;anchors.verticalCenter:parent.verticalCenter;pixelSize:12;color:Theme.text;font.letterSpacing:.5}}
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:{if(root.page>=0)ShellState.monitorPage=root.page;ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown(root.target);}}
}
