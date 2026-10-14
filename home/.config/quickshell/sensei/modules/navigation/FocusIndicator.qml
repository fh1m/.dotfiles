import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
Variants {
 model:ShellState.screens
 PanelWindow {
  id:root
  required property ShellScreen modelData
  property var monitor:Hyprland.monitors.values.find(m=>m.name===modelData.name)
  property real flash:0
  screen:modelData
  visible:flash>0&&ActiveWindow.present&&WindowDesk.focusScreen===modelData.name&&!WindowDesk.opened&&!ShellState.locked
  color:"transparent"
  implicitWidth:Math.max(1,ActiveWindow.width)
  implicitHeight:Math.max(1,ActiveWindow.height)
  anchors {top:true;left:true}
  margins.left:Math.max(0,ActiveWindow.x-(monitor?.lastIpcObject?.x??0))
  margins.top:Math.max(0,ActiveWindow.y-(monitor?.lastIpcObject?.y??0))
  exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Overlay
  WlrLayershell.namespace:"sensei-focus"
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
  mask:Region {}
  Rectangle {anchors.fill:parent;color:"transparent";radius:5;border.width:2;border.color:Theme.focusBlue;opacity:root.flash}
  Repeater {
   model:4
   Item {
    required property int index
    width:28;height:28
    x:index%2===0?0:root.width-width
    y:index<2?0:root.height-height
    rotation:index===0?0:index===1?90:index===2?270:180
    opacity:root.flash
    Rectangle {width:28;height:3;color:Theme.signal}
    Rectangle {width:3;height:28;color:Theme.signal}
   }
  }
  SequentialAnimation {
   id:pulse
   NumberAnimation {target:root;property:"flash";to:1;duration:65}
   NumberAnimation {target:root;property:"flash";to:0;duration:700;easing.type:Easing.OutCubic}
  }
  Connections {target:WindowDesk;function onFocusStampChanged(){if(WindowDesk.focusScreen===root.modelData.name){root.flash=0;pulse.restart();}}}
 }
}
