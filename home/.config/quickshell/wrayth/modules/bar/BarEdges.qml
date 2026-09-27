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
   anchors {bottom:true;left:true;right:true}
   margins.bottom:Appearance.metrics.barHeight
   exclusionMode:ExclusionMode.Ignore
   WlrLayershell.layer:WlrLayer.Top
   WlrLayershell.namespace:"sensei-bar-edge"
   mask:Region {}
   Rectangle {anchors.fill:parent;gradient:Gradient {GradientStop {position:0;color:"#00000000"}GradientStop {position:1;color:"#80000000"}}}
  }
 }
}
