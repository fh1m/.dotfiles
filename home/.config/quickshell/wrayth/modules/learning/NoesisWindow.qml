import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
import "../dropdowns" as Content

FloatingWindow {
 id:win
 title:"Noesis — Learning workspace"
 visible:Oasis.windowOpen
 color:"#000000"
 readonly property var mainScreen:Quickshell.screens.find(s=>s.name===Oasis.mainMonitor)||Quickshell.screens[0]||null
 minimumSize:Qt.size(Math.min(1000,(mainScreen?.width||1920)-40),Math.min(650,(mainScreen?.height||1080)-80))
 implicitWidth:Math.min(Oasis.windowWidth,(mainScreen?.width||1920)-40)
 implicitHeight:Math.min(Oasis.windowHeight,(mainScreen?.height||1080)-80)
 screen:mainScreen
 Connections {target:Oasis;function onOpenSerialChanged(){win.minimized=false;focusDelay.restart();}}
 onClosed:Oasis.close()
 onVisibleChanged:if(visible)focusDelay.restart()
 onWidthChanged:if(visible)saveGeometry.restart()
 onHeightChanged:if(visible)saveGeometry.restart()
 Timer {id:focusDelay;interval:80;onTriggered:Quickshell.execDetached(["hyprctl","dispatch",'hl.dsp.focus({window="title:^Noesis — Learning workspace$"})'])}
 Timer {id:saveGeometry;interval:600;onTriggered:geometryWrite.running=true}
 Process {id:geometryWrite;command:["@HOME@/.local/bin/noesis","window-state","--width",String(win.width),"--height",String(win.height)]}
 ColumnLayout {
  anchors.fill:parent;spacing:0
  Rectangle {Layout.fillWidth:true;Layout.preferredHeight:42;color:Theme.widgetSurface
   RowLayout {anchors.fill:parent;anchors.leftMargin:16;anchors.rightMargin:12;spacing:12
    Text {text:"Noesis";color:Theme.widgetAccent;font.family:Appearance.font.data;font.pixelSize:18;font.bold:true}
    Text {text:"Study · attempt · understand · build";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;Layout.fillWidth:true}
    ActionButton {text:Oasis.legacyInterface?"Connected":"Previous UI";onClicked:{Oasis.legacyInterface=!Oasis.legacyInterface;Oasis.refresh();}}
    ActionButton {text:"Minimize";glyph:"\uf068";onClicked:win.minimized=true}
    ActionButton {text:win.maximized?"Restore":"Expand";glyph:"\uf065";onClicked:win.maximized=!win.maximized}
    ActionButton {text:"Close";glyph:"\uf00d";onClicked:Oasis.close()}
   }
   MouseArea {anchors.fill:parent;anchors.rightMargin:340;acceptedButtons:Qt.LeftButton;onPressed:win.startSystemMove()}
  }
  Loader {id:content;Layout.fillWidth:true;Layout.fillHeight:true;sourceComponent:Oasis.legacyInterface?previous:connected}
  Component {id:previous;Content.OasisDropdown {chamfer:0}}
  Component {id:connected;NoesisWorkspace {}}
 }
 IpcHandler {target:"noesis-window";function state():string{return JSON.stringify({visible:win.visible,width:win.width,height:win.height,screen:win.screen?.name,section:content.item.section,selected:content.item.selected.path||"",rows:content.item.rows.length,reference_hidden:content.item.referenceHidden,worker:content.item.coreRunning||false,watch:content.item.watchRunning||false,preview_length:content.item.previewLength||0});}function section(name:string):void{content.item.section=name;}function select(path:string):void{let n=(Oasis.state.notes||[]).find(x=>x.path===path);if(n){if(Oasis.legacyInterface){content.item.selected=n;Oasis.preview(path);}else content.item.select(n);}}}
}
