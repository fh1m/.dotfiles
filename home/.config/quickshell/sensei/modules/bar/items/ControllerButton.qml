import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
BarSurface {
 id:root;visible:Controllers.data.controllers.length>0;implicitWidth:visible?44:0;implicitHeight:34;grouped:true;selected:ShellState.dropdown==='controllers'
 Text {anchors.centerIn:parent;text:'\uf11b';font.family:Appearance.font.icons;font.pixelSize:19;color:Controllers.data.controllers.length?Theme.signalRed:Theme.paperMuted}
 Text {visible:Controllers.data.controllers.length>1;anchors.right:parent.right;anchors.rightMargin:3;anchors.top:parent.top;anchors.topMargin:2;text:Controllers.data.controllers.length;font.family:Appearance.font.data;font.pixelSize:9;color:Theme.paperMuted}
 Accessible.name:"Controllers, "+Controllers.data.controllers.length+" connected"
 HoverHandler {cursorShape:Qt.PointingHandCursor}
 TapHandler {onTapped:ShellState.toggleDropdownAt('controllers',root,root.QsWindow.window)}
}
