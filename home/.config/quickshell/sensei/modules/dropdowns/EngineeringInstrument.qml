import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
Variants {
 model:ShellState.instrumentPinned?ShellState.screens.filter(s=>MachineProfile.role(s.name)==="screenpad"):[]
 PanelWindow {
  id:window;required property ShellScreen modelData;screen:modelData
  anchors {left:true;right:true;bottom:true}
  margins {left:12;right:12;bottom:Appearance.metrics.barHeight+8}
  implicitWidth:modelData.width-24
  implicitHeight:Math.min(modelData.height-Appearance.metrics.barHeight-24,(content.item?.implicitHeight??460)+12)
  color:"transparent";exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Top
  WlrLayershell.namespace:"sensei-engineering-instrument"
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
  Loader {id:content;anchors.fill:parent;sourceComponent:ShellState.instrumentKind==="camera"?camera:ShellState.instrumentKind==="context"?context:engineering}
  Component {id:context;ContextInstrument {width:window.width;maximumBodyHeight:Math.max(160,window.modelData.height-Appearance.metrics.barHeight-134)}}
 Component {id:camera;CameraDropdown {width:window.width;outputName:window.modelData.name;instrument:true}}
  Component {id:engineering;EngineeringDropdown {width:window.width;outputName:window.modelData.name;instrument:true}}
 }
}
