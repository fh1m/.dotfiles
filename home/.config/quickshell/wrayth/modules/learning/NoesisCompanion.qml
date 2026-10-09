import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../noesis-ui" as Shared
import qs.services
import "../../services" as LearningBridge
PanelWindow {
 id:companion
 IpcHandler {target:"noesis-companion";function state():string{return JSON.stringify({visible:companion.visible,screen:companion.screen?.name,width:companion.width,height:companion.height,context:LearningBridge.NoesisBridge.currentContext.id||""});}}
 readonly property var companionScreen:Quickshell.screens.find(s=>s.name==="DP-2")||null
 screen:companionScreen
 visible:!LearningBridge.NoesisBridge.windowOpen&&companionScreen!==null&&!!LearningBridge.NoesisBridge.currentContext.id&&LearningBridge.NoesisBridge.currentContext.vault===LearningBridge.NoesisBridge.activeVault
 anchors {top:true;right:true}
 margins {top:52;right:16}
 implicitWidth:Math.min(480,(companionScreen?.width||480)-32)
 implicitHeight:112
 exclusiveZone:0
 color:Shared.NoesisStyle.surface
 ColumnLayout {anchors.fill:parent;anchors.margins:Shared.NoesisStyle.md;spacing:Shared.NoesisStyle.sm
  Text {text:LearningBridge.NoesisBridge.currentContext.title||LearningBridge.NoesisBridge.currentContext.path||"Current context";color:Shared.NoesisStyle.accent;font.family:Shared.NoesisStyle.uiFont;font.pixelSize:Shared.NoesisStyle.label;Layout.fillWidth:true;elide:Text.ElideRight}
  RowLayout {
   Shared.NoesisButton {text:"Resume";onClicked:LearningBridge.NoesisBridge.resume()}
   Shared.NoesisButton {text:"Capture";onClicked:LearningBridge.NoesisBridge.capture()}
  }
 }
}
