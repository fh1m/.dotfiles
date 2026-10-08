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
 minimumSize:Qt.size(1000,650)
 implicitWidth:Math.min(Oasis.windowWidth,(ShellState.barScreens[0]?.width||1920)-40)
 implicitHeight:Math.min(Oasis.windowHeight,(ShellState.barScreens[0]?.height||1080)-80)
 screen:ShellState.barScreens[0]||null
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
    ActionButton {text:"Minimize";glyph:"\uf068";onClicked:win.minimized=true}
    ActionButton {text:win.maximized?"Restore":"Expand";glyph:"\uf065";onClicked:win.maximized=!win.maximized}
    ActionButton {text:"Close";glyph:"\uf00d";onClicked:Oasis.close()}
   }
   MouseArea {anchors.fill:parent;anchors.rightMargin:340;acceptedButtons:Qt.LeftButton;onPressed:win.startSystemMove()}
  }
  Content.OasisDropdown {id:content;Layout.fillWidth:true;Layout.fillHeight:true;chamfer:0}
 }
 IpcHandler {target:"noesis-window";function state():string{return JSON.stringify({visible:win.visible,width:win.width,height:win.height,screen:win.screen?.name,section:content.section,selected:content.selected.path||"",rows:content.rows.length,reference_hidden:content.referenceHidden});}function section(name:string):void{content.section=name;}function select(path:string):void{let n=(Oasis.state.notes||[]).find(x=>x.path===path);if(n){content.selected=n;Oasis.preview(path);}}}
}
