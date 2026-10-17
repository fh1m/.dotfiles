import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 title:"Wired / Ethernet";implicitWidth:596
 Column {width:parent.width;spacing:14
  Text {text:Ethernet.device+" · "+(Ethernet.details.speedMbps||"?")+" Mb/s · "+(Ethernet.details.duplex||"unknown duplex");font.family:Appearance.font.ui;font.pixelSize:17;color:Theme.paper}
  Text {text:"↓ "+Ethernet.rate(SysInfo.netRxRate)+"   ↑ "+Ethernet.rate(SysInfo.netTxRate);font.family:Appearance.font.telemetry;font.pixelSize:14;color:Theme.signalRed}
  Rectangle {width:parent.width;height:96;radius:6;color:Theme.surfaceOne
   Sparkline {anchors.fill:parent;anchors.margins:10;downValues:SysInfo.netRxHistory;upValues:SysInfo.netTxHistory;points:60;floorValue:1024;downColor:Theme.signalRed;upColor:Theme.semanticCyan;strokeWidth:1.5}
  }
  Text {width:parent.width;text:"Link rate is negotiated capacity; graph is observed traffic across active interfaces.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}
  Text {width:parent.width;text:Ethernet.details.details||Ethernet.details.error||"Reading NetworkManager…";textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.telemetry;font.pixelSize:12;color:Theme.paper}
  Row {spacing:8
   ControlTile {label:"Refresh";glyph:"\uf021";onActivated:Ethernet.refresh()}
   ControlTile {label:"Connections";glyph:"\uf1e6";onActivated:Quickshell.execDetached(["nm-connection-editor"])}
   ControlTile {label:"Diagnostics";glyph:"\uf201";onActivated:{DesktopExtras.networkPage=2;ShellState.systemPage=3;ShellState.toggleDropdown("system");}}
  }
 }
}
