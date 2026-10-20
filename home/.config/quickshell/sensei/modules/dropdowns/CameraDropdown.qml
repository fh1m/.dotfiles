import QtQuick
import QtQuick.Controls
import QtMultimedia
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;property string outputName:"";property bool instrument:false;title:"Meeting check / camera & sound";implicitWidth:740
 readonly property var origin:ShellState.screens.find(s=>s.name===root.outputName)||ShellState.screens[0]
 readonly property real viewportHeight:Math.max(180,Math.min(680,(origin?.height??1080)-170))
 headerRight:ControlTile {implicitWidth:140;implicitHeight:30;label:root.instrument?"Return":"Pin preview";onActivated:root.instrument?ShellState.releaseInstrument():ShellState.pinInstrument("camera")}
 property int frames:0
 IpcHandler {target:"camera-check-"+root.outputName+(root.instrument?"-instrument":"");function state():string{return JSON.stringify({opened:root.opened,preview:root.preview,active:cam.active,listening:root.listen,frames:root.frames,error:cam.errorString,cameras:devices.videoInputs.length,microphones:devices.audioInputs.length,speakers:devices.audioOutputs.length});}function openOn(output:string):void{if(ShellState.screens.some(s=>s.name===output)){ShellState.openDropdownOn("camera",output);}}function preview(enabled:bool):void{root.preview=enabled;}function listen(enabled:bool):void{root.listen=enabled;}}
 Connections {target:video.videoSink;function onVideoFrameChanged(){root.frames++;}}
 Connections {target:devices;function onVideoInputsChanged(){root.preview=false;root.cameraIndex=-1;}function onAudioInputsChanged(){root.listen=false;}function onAudioOutputsChanged(){root.listen=false;}}
 property bool preview:false
 property bool listen:false
 property bool mirrored:true
 property int cameraIndex:-1
 property int micIndex:-1
 property int speakerIndex:-1
 readonly property bool opened:root.instrument?(ShellState.instrumentPinned&&ShellState.instrumentKind==="camera"):ShellState.dropdown==="camera"&&ShellState.dropdownOriginScreen===root.outputName
 onOpenedChanged:if(!opened){preview=false;listen=false;video.clearOutput();}
 Component.onDestruction:{preview=false;listen=false;}
 MediaDevices {id:devices}
 Camera {id:cam;cameraDevice:devices.videoInputs[root.cameraIndex]??devices.defaultVideoInput;active:root.opened&&root.preview}
 AudioInput {id:mic;device:devices.audioInputs[root.micIndex]??devices.defaultAudioInput;muted:!root.listen}
 AudioOutput {id:speaker;device:devices.audioOutputs[root.speakerIndex]??devices.defaultAudioOutput;volume:.12;muted:!root.listen}
 CaptureSession {camera:cam;videoOutput:video;audioInput:root.opened&&root.listen?mic:null;audioOutput:root.opened&&root.listen?speaker:null}
 Timer {interval:15000;running:root.listen;onTriggered:root.listen=false}
 ScrollView {id:cameraScroll;width:parent.width;height:root.viewportHeight;contentWidth:availableWidth;contentHeight:cameraBody.implicitHeight;clip:true
 Column {id:cameraBody;width:cameraScroll.availableWidth;spacing:12
  Text {text:"CAMERA SOURCE";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;font.letterSpacing:1;color:Theme.widgetMuted}
  DeskComboBox {width:parent.width;currentIndex:root.cameraIndex<0?Math.max(0,devices.videoInputs.findIndex(d=>String(d.id)===String(devices.defaultVideoInput.id))):root.cameraIndex;model:devices.videoInputs;textRole:"description";onActivated:index=>root.cameraIndex=index}
  Rectangle {width:parent.width;height:Math.min(240,root.viewportHeight*.42,width*9/16);radius:8;color:Theme.surfaceOne;clip:true
   VideoOutput {id:video;anchors.fill:parent;fillMode:VideoOutput.PreserveAspectFit;mirrored:root.mirrored;endOfStreamPolicy:VideoOutput.ClearOutput}
   Text {anchors.centerIn:parent;visible:!root.preview;text:"Camera stays off until you start preview";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.section;color:Theme.paperMuted}
  }
  Row {width:parent.width;spacing:10
   ControlTile {implicitWidth:(parent.width-10)/2;label:root.preview?"Stop preview":"Start preview";selected:root.preview;glyph:"\uf030";onActivated:root.preview=!root.preview}
   ControlTile {implicitWidth:(parent.width-10)/2;label:"Mirror preview";selected:root.mirrored;onActivated:root.mirrored=!root.mirrored}
  }
  Text {width:parent.width;text:cam.errorString||"Local preview only · no recording · closes with this panel";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:cam.errorString?Theme.signalRed:Theme.paperMuted}
  MeetingCheck {width:parent.width}
  Text {text:"MONITOR MICROPHONE";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;font.letterSpacing:1;color:Theme.widgetMuted}
  DeskComboBox {width:parent.width;currentIndex:root.micIndex<0?Math.max(0,devices.audioInputs.findIndex(d=>String(d.id)===String(devices.defaultAudioInput.id))):root.micIndex;model:devices.audioInputs;textRole:"description";onActivated:index=>root.micIndex=index}
  Text {text:"HEADPHONE / PLAYBACK OUTPUT";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;font.letterSpacing:1;color:Theme.widgetMuted}
  DeskComboBox {width:parent.width;currentIndex:root.speakerIndex<0?Math.max(0,devices.audioOutputs.findIndex(d=>String(d.id)===String(devices.defaultAudioOutput.id))):root.speakerIndex;model:devices.audioOutputs;textRole:"description";onActivated:index=>root.speakerIndex=index}
  Row {spacing:8
   ControlTile {implicitWidth:(parent.width-8)/2;label:root.listen?"Stop mic return":"Hear mic · 15s";selected:root.listen;glyph:"\uf130";onActivated:root.listen=!root.listen}
   ControlTile {implicitWidth:(parent.width-8)/2;label:"Sound controls";glyph:"\uf028";onActivated:ShellState.openDropdownOn("sound",root.outputName)}
  }
  Text {width:parent.width;text:"Use headphones for mic return. Starts at 12% monitor volume; actual meeting-app settings remain separate.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
 }
 }
}
