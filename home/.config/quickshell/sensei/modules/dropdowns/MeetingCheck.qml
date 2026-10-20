import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
Column {
 id:root;spacing:10;property var snapshot:({sources:[],streams:[]});property string report:"Check the microphone before joining. Tests are local and save no recording.";property string operation:"doctor";property string transcript:"";property real peak:-90;property real rms:-90;property real clipping:0
 function run(action){if(worker.running)return;operation=action;worker.command=action.startsWith("effects-")?[Quickshell.env("HOME")+"/.local/bin/sensei-voice-effects",action.slice(8)]:[Quickshell.env("HOME")+"/.local/bin/sensei-voice",action];worker.running=true;}
 Component.onCompleted:run("doctor")
 Timer {interval:2500;repeat:true;running:root.visible&&!worker.running&&!meter.running;onTriggered:{refresh.running=true;}}
 Process {id:refresh;command:[Quickshell.env("HOME")+"/.local/bin/sensei-voice","doctor"];stdout:StdioCollector {onStreamFinished:{try{root.snapshot=JSON.parse(text);}catch(e){}}}}
 Row {width:parent.width;spacing:8
  ControlTile {implicitWidth:(parent.width-16)/3;label:"Refresh inputs";enabled:!worker.running;onActivated:root.run("doctor")}
  ControlTile {implicitWidth:(parent.width-16)/3;label:worker.running?"Checking…":"Test signal · 3s";enabled:!worker.running;onActivated:root.run("probe")}
  ControlTile {implicitWidth:(parent.width-16)/3;label:"Use raw default mic";enabled:!worker.running;onActivated:root.run("route-default")}
 }
 Row {width:parent.width;spacing:8
  ControlTile {implicitWidth:(parent.width-8)/2;label:"Den Voice · enable";enabled:!worker.running;onActivated:root.run("effects-on")}
  ControlTile {implicitWidth:(parent.width-8)/2;label:"Restore raw call audio";enabled:!worker.running;onActivated:root.run("effects-off")}
 }
 Text {width:parent.width;text:root.snapshot.sources.filter(s=>s.name===root.snapshot.default).map(s=>s.label+" · "+s.gainPercent+"%"+(s.muted?" · MUTED":" · ready")).join("")||"No default input";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.widgetText}
 Text {width:parent.width;text:root.report;wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.widgetMuted}
 Text {width:parent.width;text:"Whisper transcribes locally; it does not suppress noise. In Vesktop, select the USB mic explicitly if an app overrides routing.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.caption;color:Theme.widgetMuted}
 ControlTile {width:parent.width;label:worker.running&&root.operation==="transcribe"?"Recording / transcribing…":"Local voice note · 3 seconds";enabled:!worker.running;onActivated:root.run("transcribe")}
 Row {width:parent.width;spacing:8
  ControlTile {implicitWidth:(parent.width-8)/2;label:meter.running?"Stop input meter":"Live input meter · 15s";onActivated:meter.running=!meter.running}
  ControlTile {implicitWidth:(parent.width-8)/2;label:"Cancel voice capture";enabled:worker.running;onActivated:worker.running=false}
 }
 Rectangle {width:parent.width;height:5;color:Theme.surfaceTwo;radius:2;Rectangle {width:parent.width*Math.max(0,Math.min(1,(root.peak+60)/60));height:parent.height;color:root.clipping>0?Theme.signalRed:Theme.widgetAccent;radius:2}}
 Text {width:parent.width;text:meter.running?"Peak "+root.peak+" dBFS · AC RMS "+root.rms+" dBFS · clipping "+root.clipping+"%":"Meter off · microphone tests are always explicit";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.caption;color:Theme.widgetMuted}
 Process {id:meter;command:[Quickshell.env("HOME")+"/.local/bin/sensei-voice","meter","--seconds","15"];stdout:SplitParser {onRead:line=>{try{const d=JSON.parse(line);if(d.error)root.report=d.error;if(d.type==="meter"){root.peak=d.peakDbFS;root.rms=d.acRmsDbFS??d.rmsDbFS;root.clipping=d.clippedPercent;if(d.dcOffsetWarning)root.report="High microphone DC offset: total RMS is misleading. Use Den Voice high-pass processing and check speech levels.";}}catch(e){}}}}
 ControlTile {width:parent.width;label:"Copy reviewed transcript";enabled:root.transcript!==""&&!worker.running;onActivated:Quickshell.execDetached(["wl-copy","--",root.transcript])}
 Repeater {model:root.snapshot.streams
  Text {required property var modelData;width:parent.width;text:modelData.app+" → "+(root.snapshot.sources.find(s=>s.index===modelData.sourceIndex)?.label||"speaker capture / other source")+(modelData.muted?" · MUTED":"");wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.widgetText}
 }
 Component.onDestruction:{meter.running=false;worker.running=false;refresh.running=false;}
 Process {id:worker;stdout:StdioCollector {onStreamFinished:{try{const row=JSON.parse(text);if(row.error)root.report=row.error;else if(root.operation==="doctor")root.snapshot=row;else if(root.operation==="probe")root.report=row.source+" · "+row.seconds+" s\nPeak "+row.peakDbFS+" dBFS · RMS "+row.rmsDbFS+" dBFS · AC RMS "+row.acRmsDbFS+" dBFS · DC offset "+row.dcOffset+" · Clipping "+row.clippedPercent+"%\n"+row.note;else if(root.operation==="transcribe"){root.transcript=row.transcript;root.report=row.transcript+"\n"+row.note;}else if(root.operation.startsWith("effects-"))root.report=row.note;else root.report="Routed "+row.routed+" active capture streams to "+row.source+". Mute states preserved.";}catch(e){root.report="Audio check unavailable; open Sound controls.";}}}}
}
