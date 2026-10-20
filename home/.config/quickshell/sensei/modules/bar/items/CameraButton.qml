import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.modules.bar
Item {
 id:root
 property bool condensed:true
 visible:Cameras.available;implicitWidth:visible?44:0;implicitHeight:34
 BarSurface {anchors.fill:parent;grouped:true;selected:ShellState.dropdown==="camera";hovered:hover.hovered;pressed:tap.pressed}
 Text {anchors.centerIn:parent;text:"\uf030";font.family:Appearance.font.icons;font.pixelSize:18;color:Theme.signalRed}
 HoverHandler {id:hover;cursorShape:Qt.PointingHandCursor}
 TapHandler {id:tap;onTapped:{ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdownAt("camera",root,root.QsWindow.window);}}
 Component.onCompleted:Qt.callLater(()=>ShellState.publishAnchor("camera",root.mapToItem(null,0,0).x,root.QsWindow.window?.screen?.name??""))
}
