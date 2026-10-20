import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
Column {
 id:root;width:parent.width;spacing:12
 property bool compact:false
 signal expandRequested()
 property var route:({outputs:[],active:false});property string error:''
 property string chosenOutput:""
 property var outputLabels:[]
 property bool busy:task.running
 property var selected:(route.outputs||[])[output.currentIndex]||{}
 function accept(d){
  const labels=(d.outputs||[]).map(o=>o.description+(o.port?' · '+o.port:''));
  root.route=d;
  if(!root.chosenOutput||(d.outputs||[]).every(o=>o.name!==root.chosenOutput))root.chosenOutput=d.output||(d.outputs||[])[0]?.name||'';
  if(JSON.stringify(labels)!==JSON.stringify(root.outputLabels))root.outputLabels=labels;
  Qt.callLater(()=>output.currentIndex=Math.max(0,(root.route.outputs||[]).findIndex(o=>o.name===root.chosenOutput)));
 }
 function run(args){if(task.running)return;error='';task.command=[Quickshell.env('HOME')+'/.local/bin/sensei-den-audio'].concat(args);task.running=true;}
 onVisibleChanged:if(visible)run(['status'])
 Component.onCompleted:if(visible)run(['status'])
 Process {id:task;stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);if(d.error&&!d.outputs)root.error=d.error;else root.accept(d);}catch(e){root.error='Den audio control is unavailable.';}}}}
 Timer {interval:5000;repeat:true;running:root.visible&&!root.busy;onTriggered:root.run(['status'])}
 Rectangle {
  width:parent.width;height:root.compact?58:88;radius:6;color:Theme.alpha(Theme.widgetSurface,.7);border.color:Theme.widgetBorder
  Column {anchors.left:parent.left;anchors.right:routeButton.left;anchors.margins:12;anchors.verticalCenter:parent.verticalCenter;spacing:6
   Text {width:parent.width;text:(root.route.active?'PC AUDIO / HOMIE → ARETE':'PC AUDIO / off');font.family:Appearance.font.heading;font.pixelSize:13;color:root.route.error?Theme.widgetAccent:Theme.paper}
   Text {width:parent.width;text:root.error||root.route.error||(root.route.active?(root.route.destination?.description||'Laptop output')+' · '+(root.route.destination?.port||''):'PC audio on laptop headphones or speakers');elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
   Text {visible:!root.compact;width:parent.width;text:root.route.note||'Choose an output. Meeting microphones stay unchanged.';elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}
  }
  MusicButton {id:routeButton;anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;implicitWidth:94;implicitHeight:30;label:root.compact?'Routing':'Refresh';glyph:'\uf1de';enabled:!root.busy;onActivated:root.compact?root.expandRequested():root.run(['status'])}
 }
 Column {visible:!root.compact;width:parent.width;spacing:12
  Text {width:parent.width;text:'PC playback → encrypted LAN → selected laptop output';font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paper}
  DeskComboBox {id:output;width:parent.width;height:38;model:root.outputLabels;onActivated:root.chosenOutput=root.route.outputs[currentIndex]?.name||'';Accessible.name:'Laptop output for Homie audio'}
  DeskComboBox {visible:(root.selected.ports||[]).length>1;width:parent.width;height:34;model:(root.selected.ports||[]).map(p=>p.description+(p.available==='not available'?' · unplugged':''));currentIndex:Math.max(0,(root.selected.ports||[]).findIndex(p=>p.name===root.selected.activePort));onActivated:root.run(['port',root.selected.name,root.selected.ports[currentIndex].name]);Accessible.name:'Headphones or speakers port'}
  Row {width:parent.width;spacing:10
   MusicButton {implicitWidth:190;implicitHeight:36;label:'Stereo LAN';glyph:'\uf0ac';selected:!!root.route.active&&root.route.mode==='lan';enabled:!root.busy&&root.route.outputs?.length>0;onActivated:root.run(['start','lan',root.selected.name])}
   MusicButton {implicitWidth:180;implicitHeight:36;label:'AUX input';glyph:'\uf025';selected:!!root.route.active&&root.route.mode==='aux';enabled:!root.busy&&!!root.route.hubAvailable&&root.route.outputs?.length>0;onActivated:root.run(['start','aux',root.selected.name])}
   MusicButton {implicitWidth:140;implicitHeight:36;label:'Stop';glyph:'\uf04d';enabled:!root.busy&&!!root.route.active;onActivated:root.run(['stop'])}
  }
  Text {width:parent.width;text:'SOURCE / '+(root.route.source?.description||'Homie default playback')+' · '+(root.route.source?.port||'')+'\n'+(root.route.source?.muted?'Muted':(root.route.source?.volume??0)+'%')+' · '+((root.route.source?.applications||[]).map(a=>a.name+(a.muted?' (muted)':'')).join(', ')||'No application reported');wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
  Text {width:parent.width;text:'DESTINATION / '+(root.route.destination?.muted?'Muted':(root.route.destination?.volume??0)+'%')+' · '+(root.route.destination?.state||'not selected')+' · '+(root.route.linked?'Playback stream connected':'No connected LAN playback stream')+'\n'+(root.route.destination?.format||'');wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
  Row {spacing:10
   MusicButton {implicitWidth:180;implicitHeight:34;label:'Check signal';glyph:'\uf201';enabled:!root.busy&&!!root.route.active;onActivated:root.run(['check'])}
   MusicButton {implicitWidth:160;implicitHeight:34;label:'Test PC sound';glyph:'\uf028';enabled:!root.busy&&!!root.route.active;onActivated:root.run(['test'])}
  }
  Text {width:parent.width;text:(root.route.signal?.message||'Check samples only playback monitors, briefly in RAM. A connected stream is not proof of audible sound.')+(root.route.signal?.destination?'\nPC peak '+root.route.signal.source.peakDb+' dBFS → laptop peak '+root.route.signal.destination.peakDb+' dBFS · '+Qt.formatDateTime(new Date(root.route.signal.at*1000),"hh:mm:ss"):'');wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
  Text {width:parent.width;text:'LAN preserves stereo and follows your selected laptop output. AUX needs the hub’s microphone input contact; output-to-output wiring carries no input. Reconnect with Listen after a host or device disconnects.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}
 }
}
