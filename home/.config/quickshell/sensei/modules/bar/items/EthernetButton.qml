import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.modules.bar
Item {
 id:root
 property bool condensed:true
 visible:Ethernet.connected
 implicitWidth:visible?(condensed?44:120):0;implicitHeight:34
 BarSurface {anchors.fill:parent;grouped:true;selected:ShellState.dropdown==="ethernet";hovered:hover.hovered;pressed:tap.pressed}
 Item {x:10;anchors.verticalCenter:parent.verticalCenter;width:24;height:24
  // Native vector jack, with bounded motion only during real traffic.
  Rectangle {x:4;y:3;width:16;height:13;radius:2;color:"transparent";border.color:Theme.signalRed;border.width:1.6}
  Repeater {model:4;Rectangle {required property int index;x:7+index*3;y:5;width:1;height:4;color:Theme.signalRed}}
  Rectangle {x:9;y:16;width:6;height:5;radius:1;color:Theme.signalRed}
  Rectangle {id:packet;x:6;y:12;width:3;height:2;radius:1;color:Theme.paper
   SequentialAnimation on x {running:root.visible&&ShellState.ambientMotion&&(SysInfo.netRxRate+SysInfo.netTxRate)>2048;loops:Animation.Infinite;NumberAnimation {from:6;to:16;duration:600}PauseAnimation {duration:400}}
  }
 }
 Column {x:40;anchors.verticalCenter:parent.verticalCenter;visible:!root.condensed;spacing:2
  Text {text:"Ethernet";font.family:Appearance.font.barUi;font.pixelSize:12;color:Theme.paper}
  Text {text:Ethernet.details.speedMbps?Ethernet.details.speedMbps+" Mb/s":"Connected";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.paperMuted}
 }
 HoverHandler {id:hover;cursorShape:Qt.PointingHandCursor}
 TapHandler {id:tap;onTapped:{ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdownAt("ethernet",root,root.QsWindow.window);}}
 Component.onCompleted:Qt.callLater(()=>ShellState.publishAnchor("ethernet",root.mapToItem(null,0,0).x,root.QsWindow.window?.screen?.name??""))
}
