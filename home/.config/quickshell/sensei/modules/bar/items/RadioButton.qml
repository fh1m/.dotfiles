import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.modules.bar
Item {
 id:root
 visible:MachineProfile.desktop&&Radio.available
 implicitWidth:visible?44:0;implicitHeight:34
 BarSurface {anchors.fill:parent;grouped:true;selected:ShellState.dropdown==='radio';hovered:hover.hovered;pressed:tap.pressed}
 Text {anchors.centerIn:parent;text:'\uf519';font.family:Appearance.font.icons;font.pixelSize:18;color:Theme.signalRed}
 HoverHandler {id:hover;cursorShape:Qt.PointingHandCursor}
 TapHandler {id:tap;onTapped:{const output=root.QsWindow.window?.screen?.name||MachineProfile.primaryOutput;ShellState.publishAnchor('radio',root.mapToItem(null,0,0).x,output);ShellState.toggleDropdownOn('radio',output);}}
}
