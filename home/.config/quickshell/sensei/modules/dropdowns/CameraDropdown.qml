import QtQuick
import QtQuick.Controls
import QtMultimedia
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;title:"Meeting check / camera & sound";implicitWidth:740
 property int frames:0
 IpcHandler {target:"camera-check";function state():string{return JSON.stringify({opened:root.opened,preview:root.preview,active:cam.active,listening:root.listen,frames:root.frames,error:cam.errorString,cameras:devices.videoInputs.length,microphones:devices.audioInputs.length,speakers:devices.audioOutputs.length});}function preview(enabled:bool):void{root.preview=enabled;}function listen(enabled:bool):void{root.listen=enabled;}}
 Connections {target:video.videoSink;function onVideoFrameChanged(){root.frames++;}}
 Connections {target:devices;function onVideoInputsChanged(){root.preview=false;root.cameraIndex=0;}function onAudioInputsChanged(){root.listen=false;}function onAudioOutputsChanged(){root.listen=false;}}
 property bool preview:false
 property bool listen:false
 property bool mirrored:true
 property int cameraIndex:0
 property int micIndex:0
 property int speakerIndex:0
 readonly property bool opened:ShellState.dropdown==="camera"
 onOpenedChanged:if(!opened){preview=false;listen=false;video.clearOutput();}
 Component.onDestruction:{preview=false;listen=false;}
 MediaDevices {id:devices}
 Camera {id:cam;cameraDevice:devices.videoInputs[root.cameraIndex]??devices.defaultVideoInput;active:root.opened&&root.preview}
 AudioInput {id:mic;device:devices.audioInputs[root.micIndex]??devices.defaultAudioInput;muted:!root.listen}
 AudioOutput {id:speaker;device:devices.audioOutputs[root.speakerIndex]??devices.defaultAudioOutput;volume:.12;muted:!root.listen}
 CaptureSession {camera:cam;videoOutput:video;audioInput:root.opened&&root.listen?mic:null;audioOutput:root.opened&&root.listen?speaker:null}
 Timer {interval:15000;running:root.listen;onTriggered:root.listen=false}
 Column {width:parent.width;spacing:12
  DeskComboBox {width:parent.width;model:devices.videoInputs;textRole:"description";onActivated:index=>root.cameraIndex=index}
  Rectangle {width:parent.width;height:Math.min(360,width*9/16);radius:8;color:Theme.surfaceOne;clip:true
   VideoOutput {id:video;anchors.fill:parent;fillMode:VideoOutput.PreserveAspectFit;mirrored:root.mirrored;endOfStreamPolicy:VideoOutput.ClearOutput}
   Text {anchors.centerIn:parent;visible:!root.preview;text:"Camera stays off until you start preview";font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.paperMuted}
  }
  Row {spacing:10
   ControlTile {label:root.preview?"Stop preview":"Start preview";selected:root.preview;glyph:"\uf030";onActivated:root.preview=!root.preview}
   ControlTile {label:"Mirror preview";selected:root.mirrored;onActivated:root.mirrored=!root.mirrored}
  }
  Text {width:parent.width;text:cam.errorString||"Local preview only · no recording · closes with this panel";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:cam.errorString?Theme.signalRed:Theme.paperMuted}
  DeskComboBox {width:parent.width;model:devices.audioInputs;textRole:"description";onActivated:index=>root.micIndex=index}
  DeskComboBox {width:parent.width;model:devices.audioOutputs;textRole:"description";onActivated:index=>root.speakerIndex=index}
  Row {spacing:8
   ControlTile {label:root.listen?"Stop mic return":"Hear microphone · 15s";selected:root.listen;glyph:"\uf130";onActivated:root.listen=!root.listen}
   ControlTile {label:"Sound controls";glyph:"\uf028";onActivated:ShellState.toggleDropdown("sound")}
  }
  Text {width:parent.width;text:"Use headphones for mic return. Starts at 12% monitor volume; actual meeting-app settings remain separate.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}
 }
}
