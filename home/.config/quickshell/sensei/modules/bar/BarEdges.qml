import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
Scope {
 Variants {
  model:ShellState.barScreens
  PanelWindow {
   required property ShellScreen modelData
   screen:modelData;color:"transparent";implicitHeight:8
   anchors {top:true;left:true;right:true}
   margins.top:Appearance.metrics.barHeight
   exclusionMode:ExclusionMode.Ignore
   WlrLayershell.layer:WlrLayer.Top
   WlrLayershell.namespace:"sensei-bar-edge"
   mask:Region {}
   Rectangle {anchors.fill:parent;gradient:Gradient {GradientStop {position:0;color:"#80000000"}GradientStop {position:1;color:"#00000000"}}}
  }
 }
 Variants {
  model:ShellState.bottomBarScreens
  PanelWindow {
   required property ShellScreen modelData
   screen:modelData;color:"transparent";implicitHeight:8
   readonly property bool topEdge: !!modelData && ShellState.isExternalOutput(modelData.name) && ShellState.externalBarEdge(modelData.name)==="top"
   anchors {top:topEdge;bottom:!topEdge;left:true;right:true}
   margins.top:topEdge?Appearance.metrics.barHeight:0
   margins.bottom:topEdge?0:Appearance.metrics.barHeight
   exclusionMode:ExclusionMode.Ignore
   WlrLayershell.layer:WlrLayer.Top
   WlrLayershell.namespace:"sensei-bar-edge"
   mask:Region {}
   Rectangle {anchors.fill:parent;gradient:Gradient {GradientStop {position:0;color:topEdge?"#80000000":"#00000000"}GradientStop {position:1;color:topEdge?"#00000000":"#80000000"}}}
  }
 }
}
