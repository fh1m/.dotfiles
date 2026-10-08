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
 color:NoesisStyle.canvas
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
    Text {text:"Noesis";color:Theme.widgetAccent;font.family:NoesisStyle.uiFont;font.pixelSize:18;font.bold:true}
    Text {text:"Learning, research and engineering";color:Theme.widgetMuted;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true}
    NoesisButton {text:Oasis.legacyInterface?"Connected":"Previous UI";onClicked:{Oasis.legacyInterface=!Oasis.legacyInterface;Oasis.refresh();}}
    NoesisButton {text:"Minimize";onClicked:win.minimized=true}
    NoesisButton {text:win.maximized?"Restore":"Expand";onClicked:win.maximized=!win.maximized}
    NoesisButton {text:"Close";onClicked:Oasis.close()}
   }
   MouseArea {anchors.fill:parent;anchors.rightMargin:340;acceptedButtons:Qt.LeftButton;onPressed:win.startSystemMove()}
  }
  Loader {id:content;Layout.fillWidth:true;Layout.fillHeight:true;sourceComponent:Oasis.legacyInterface?previous:connected}
  Component {id:previous;Content.OasisDropdown {chamfer:0}}
  Component {id:connected;NoesisWorkspace {}}
 }
 IpcHandler {target:"noesis-window";function state():string{return JSON.stringify({visible:win.visible,width:win.width,height:win.height,screen:win.screen?.name,section:content.item.section,selected:content.item.selected.path||"",rows:content.item.rows.length,reference_hidden:content.item.referenceHidden,worker:content.item.coreRunning||false,watch:content.item.watchRunning||false,preview_length:content.item.previewLength||0,context_tab:content.item.contextTab||"",read_viewport_height:content.item.readViewportHeight||0,read_content_height:content.item.readContentHeight||0,overview_counts:content.item.workflow?.counts||null,cursor:content.item.cursor||"",attempt:content.item.activeAttempt||"",capture_length:content.item.captureLength||0,error:Oasis.error,message:Oasis.message,working:Oasis.working,capture_open:content.item.captureOpen||false,capture_focused:content.item.captureFocused||false,search_focused:content.item.searchFocused||false,inspector:content.item.inspectorVisible||false});}function more():void{if(!Oasis.legacyInterface&&content.item.cursor)content.item.load(true);}function section(name:string):void{content.item.section=name;}function select(path:string):void{let n=(content.item.rows||Oasis.state.notes||[]).find(x=>x.path===path);if(n){if(Oasis.legacyInterface){content.item.selected=n;Oasis.preview(path);}else content.item.select(n);}}}
}
