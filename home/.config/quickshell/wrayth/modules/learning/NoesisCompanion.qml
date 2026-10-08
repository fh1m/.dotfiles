import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
PanelWindow {
 id:companion
 IpcHandler {target:"noesis-companion";function state():string{return JSON.stringify({visible:companion.visible,screen:companion.screen?.name,width:companion.width,height:companion.height,context:Oasis.currentContext.id||""});}}
 readonly property var companionScreen:Quickshell.screens.find(s=>s.name==="DP-2")||null
 screen:companionScreen
 visible:companionScreen!==null&&!!Oasis.currentContext.id&&Oasis.currentContext.vault===Oasis.activeVault
 anchors {top:true;right:true}
 margins {top:52;right:16}
 implicitWidth:Math.min(480,(companionScreen?.width||480)-32)
 implicitHeight:112
 exclusiveZone:0
 color:NoesisStyle.surface
 ColumnLayout {anchors.fill:parent;anchors.margins:NoesisStyle.md;spacing:NoesisStyle.sm
  Text {text:Oasis.currentContext.title||Oasis.currentContext.path||"Current context";color:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;Layout.fillWidth:true;elide:Text.ElideRight}
  RowLayout {
   NoesisButton {text:"Resume";onClicked:Oasis.open()}
   NoesisButton {text:"Capture";onClicked:{Oasis.open();Oasis.captureRequested();}}
   NoesisButton {text:Oasis.currentContext.session_state==="paused"?"Resume session":"Pause session";visible:["session","practice-session"].includes(Oasis.currentContext.type);onClicked:Oasis.run(["event",Oasis.currentContext.path,"session-state","--target-id",Oasis.currentContext.id,"--data",JSON.stringify({state:Oasis.currentContext.session_state==="paused"?"active":"paused"})])}
  }
 }
}
