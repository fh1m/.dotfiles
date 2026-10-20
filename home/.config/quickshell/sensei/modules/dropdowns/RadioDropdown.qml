import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root
 title:'\uf519 Radio / '+(MachineProfile.desktop?'Homie':'Arete');katakana:'THE INVISIBLE NEIGHBOURHOOD';implicitWidth:740
 property var hostWindow:null
 property int section:0
 property bool live:false
 property bool peakHold:false
 property var heldBins:[]
 property bool resetWaterfall:true
 readonly property real scopeMHz:selectedBand==='fm'?frequency:((Radio.data.bands||[]).find(b=>b.id===selectedBand)?.lowMHz+(Radio.data.bands||[]).find(b=>b.id===selectedBand)?.highMHz)/2
 onScopeMHzChanged:{live=false;heldBins=[];resetWaterfall=true;}
 onGainChanged:{live=false;heldBins=[];resetWaterfall=true;}
 property var liveBins:[]
 property var liveFrame:({})
 property var scopeCanvas:null
 property var waterfall:[]
 property real frequency:98.4
 property real gain:20
 property string selectedBand:"fm"
 readonly property var samples:liveBins.length?liveBins:Radio.receipt.bins||[]
 IpcHandler {enabled:!!root.hostWindow?.visible;target:'radio-panel';function state():string{return JSON.stringify({available:Radio.available,busy:Radio.busy,live:root.live,bins:root.samples.length,rows:root.waterfall.length,section:root.section,history:Radio.history.length,error:Radio.error});}function scope(enabled:bool):void{root.live=enabled;}function section(index:int):void{root.section=Math.max(0,Math.min(2,index));}function action(name:string):void{Radio.run(name);}}
 Connections {target:Radio;function onReceiptChanged(){if(!root.live){root.liveBins=[];root.liveFrame=({});root.waterfall=[];}}}
 Connections {target:root.hostWindow;function onVisibleChanged(){if(!root.hostWindow.visible)root.live=false;}}
 Process {id:scope;running:root.live&&!!root.hostWindow?.visible;command:[Quickshell.env('HOME')+'/.local/bin/sensei-radio','scope',String(root.scopeMHz),String(root.gain)];stdout:SplitParser {onRead:line=>{try{const d=JSON.parse(line);if(d.error){Radio.error=d.error;root.live=false;return;}root.liveFrame=d;root.liveBins=d.bins||[];if(root.peakHold)root.heldBins=root.liveBins.map((b,i)=>({hz:b.hz,db:root.heldBins[i]?.hz===b.hz?Math.max(b.db,root.heldBins[i].db):b.db}));if(root.liveBins.length){const points=root.liveBins.filter((_,i)=>i%Math.max(1,Math.ceil(root.liveBins.length/256))===0).map(b=>b.db);root.waterfall=[points].concat(root.waterfall).slice(0,64);if(root.scopeCanvas)root.scopeCanvas.requestPaint();}}catch(e){}}}onExited:root.live=false}
 Text {visible:!Radio.available;width:parent.width;text:'Connect an RTL-SDR receiver to this machine. The radio controls appear when USB is detected.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.paperMuted}
 Loader {width:parent.width;active:Radio.available;sourceComponent:Component {
 Column {width:parent.width;spacing:16
  Row {width:parent.width;spacing:12
   Text {width:parent.width-130;text:Radio.available?(Radio.data.devices[0].name+' · receive only'):'Connect the RTL-SDR to Homie';font.family:Appearance.font.ui;font.pixelSize:17;color:Theme.paper;wrapMode:Text.Wrap}
   MusicButton {implicitWidth:118;implicitHeight:34;label:'Refresh';glyph:'\uf021';enabled:!Radio.busy;onActivated:Radio.run('status')}
  }
  Text {width:parent.width;text:Radio.error||Radio.note||(Radio.busy?'Sampling the actual receiver…':'FM, spectrum and your own sensor experiments. No background scans.');font.family:Appearance.font.ui;font.pixelSize:12;wrapMode:Text.Wrap;color:Radio.error?Theme.widgetAccent:Theme.paperMuted}
  Row {width:parent.width;spacing:8
   Repeater {model:['Receiver','Experiments','Receipts'];MusicButton {required property string modelData;required property int index;implicitWidth:(parent.width-16)/3;implicitHeight:34;label:modelData;selected:root.section===index;onActivated:{root.section=index;if(index===2)Radio.run('history');}}}
  }
  Row {visible:root.section===0;spacing:10
   MusicButton {implicitWidth:180;implicitHeight:36;label:'Open Gqrx';glyph:'\uf1de';enabled:!root.live&&Radio.available&&!Radio.busy;onActivated:Radio.run('open')}
   MusicButton {implicitWidth:178;implicitHeight:36;label:'7s USB test';glyph:'\uf0e7';enabled:!root.live&&Radio.available&&!Radio.busy;onActivated:Radio.run('test')}
   MusicButton {implicitWidth:130;implicitHeight:36;label:'Stop FM';glyph:'\uf04d';onActivated:Radio.run('stop')}
  }
  ChamferPanel {visible:root.section===0;width:parent.width;height:134;fillColor:Theme.surfaceOne;borderColor:Theme.rule;scanlines:false
   Column {anchors.fill:parent;anchors.margins:14;spacing:12
    Text {text:'BROADCAST FM / '+root.frequency.toFixed(1)+' MHz';font.family:Appearance.font.heading;font.pixelSize:15;color:Theme.paper}
    Row {width:parent.width;spacing:12
     DeskTextField {id:tuning;width:150;height:36;placeholderText:'87.5–108 MHz';text:root.frequency.toFixed(1);onEditingFinished:{const value=Number(text);if(Number.isFinite(value)&&value>=87.5&&value<=108)root.frequency=value;else text=root.frequency.toFixed(1);}}
     MusicButton {implicitWidth:132;implicitHeight:36;label:'Listen';glyph:'\uf025';enabled:!root.live&&!Radio.busy&&Radio.available;onActivated:Radio.run('fm',[String(root.frequency),String(root.gain)])}
     ControlSlider {width:parent.width-306;title:'RF gain';valueText:root.gain.toFixed(1)+' dB';level:root.gain*100/49.6;onEdited:v=>root.gain=Math.round(v*49.6)/100}
    }
    Text {text:'PipeWire audio · '+root.gain.toFixed(1)+' dB RF gain · stop before opening another SDR app';font.family:Appearance.font.data;font.pixelSize:10;color:Theme.paperMuted}
   }
  }
  Row {visible:root.section===0;width:parent.width;spacing:10
   DeskComboBox {id:band;onCurrentIndexChanged:root.selectedBand=Radio.data.bands[currentIndex]?.id||'fm';width:parent.width-190;height:36;model:(Radio.data.bands||[]).map(b=>b.label+' · '+b.lowMHz+'–'+b.highMHz+' MHz');Accessible.name:'Receive spectrum band'}
   MusicButton {implicitWidth:180;implicitHeight:36;label:'5s spectrum';glyph:'\uf201';enabled:!root.live&&!Radio.busy&&Radio.available&&band.currentIndex>=0;onActivated:Radio.run('scan',[Radio.data.bands[band.currentIndex].id])}
  }
  Row {visible:root.section===0;width:parent.width;spacing:10
   MusicButton {implicitWidth:180;implicitHeight:34;label:root.live?'Stop live scope':'Live RF / 20 fps';glyph:root.live?'\uf04d':'\uf201';enabled:Radio.available&&!Radio.busy;selected:root.live;onActivated:{root.live=!root.live;if(root.live){root.waterfall=[];root.liveBins=[];root.heldBins=[];root.resetWaterfall=true;}}}
   Text {anchors.verticalCenter:parent.verticalCenter;text:'2.048 MHz window · '+root.scopeMHz.toFixed(3)+' MHz · stops on close';font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.paperMuted}
  }
  Row {visible:root.section===0;width:parent.width;spacing:10
   MusicButton {implicitWidth:150;implicitHeight:30;label:'Peak hold';glyph:'\uf201';selected:root.peakHold;onActivated:{root.peakHold=!root.peakHold;root.heldBins=[];}}
   MusicButton {implicitWidth:170;implicitHeight:30;label:'Tune strongest bin';glyph:'\uf140';enabled:root.samples.length>0&&root.selectedBand==='fm';onActivated:{const peak=root.samples.reduce((a,b)=>a.db>b.db?a:b);if(peak.hz>=87500000&&peak.hz<=108000000){root.live=false;root.frequency=Math.round(peak.hz/100000)/10;}}}
   Text {anchors.verticalCenter:parent.verticalCenter;text:'DC spikes can be receiver artefacts.';font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.paperMuted}
  }
  ChamferPanel {visible:root.section===0;width:parent.width;height:222;fillColor:Theme.ink;borderColor:Theme.rule;scanlines:false
   Canvas {id:spectrum;Component.onCompleted:root.scopeCanvas=spectrum;Component.onDestruction:root.scopeCanvas=null;anchors.fill:parent;anchors.margins:14;onPaint:{
    const c=getContext('2d'),w=width,h=root.waterfall.length?90:height-26;
    if(root.resetWaterfall){c.clearRect(0,0,width,height);root.resetWaterfall=false;}
    c.clearRect(0,0,w,h+4);c.clearRect(0,height-22,w,22);c.strokeStyle=Theme.alpha(Theme.paper,.12);c.lineWidth=1;
    for(let j=1;j<5;j++){c.beginPath();c.moveTo(0,j*h/5);c.lineTo(w,j*h/5);c.stroke();}
    const bins=root.samples;if(!bins.length)return;let low=Math.min(...bins.map(b=>b.db)),high=Math.max(...bins.map(b=>b.db));if(high-low<12)high=low+12;
    function trace(points,color,weight){c.beginPath();for(let i=0;i<points.length;i++){const x=i*w/(points.length-1),y=Math.max(0,Math.min(h,h-(points[i].db-low)/(high-low)*(h-8)));if(i===0)c.moveTo(x,y);else c.lineTo(x,y);}c.strokeStyle=color;c.lineWidth=weight;c.stroke();}
    if(root.peakHold&&root.heldBins.length===bins.length)trace(root.heldBins,Theme.alpha(Theme.paper,.32),1);
    trace(bins,Theme.widgetAccent,1.3);
    if(root.waterfall.length){const y=Math.ceil(h+6),bottom=Math.floor(height-25),depth=bottom-y;
     if(depth>1){const previous=c.getImageData(0,y,Math.floor(w),depth-1);c.putImageData(previous,0,y+1);}
     const row=root.waterfall[0];for(let x=0;x<row.length;x++){const v=Math.max(0,Math.min(1,(row[x]-low)/Math.max(12,high-low)));c.fillStyle=Qt.rgba(.08+v*.85,.015+v*.08,.08+v*.4,.25+v*.75);c.fillRect(x*w/row.length,y,Math.ceil(w/row.length),1);}
    }
    c.fillStyle=Theme.paperMuted;c.font='11px monospace';c.fillText((bins[0].hz/1e6).toFixed(2)+' MHz',0,height-3);c.fillText((bins[bins.length-1].hz/1e6).toFixed(2)+' MHz',Math.max(0,w-94),height-3);
   }}
   Text {anchors.centerIn:parent;visible:!root.samples.length;width:parent.width-40;text:'A real spectrum appears after a bounded capture.\nStart Live waterfall for real sweeps; Gqrx adds full demodulation.';horizontalAlignment:Text.AlignHCenter;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paperMuted}
  }
  Text {visible:root.section===0;width:parent.width;text:Radio.receipt.kind==='usb-test'?'2.048 MS/s · '+Radio.receipt.seconds+' s · reported sample loss: '+Radio.receipt.lostSamplesReported+' · '+Radio.receipt.tuner:root.samples.length?((root.liveFrame.label||Radio.receipt.label||'Spectrum')+' · '+root.samples.length+' bins · '+(root.liveFrame.units||Radio.receipt.units||'relative dB · uncalibrated')+(root.live?' · LIVE':Radio.receipt.peakMHz?' · peak '+Radio.receipt.peakMHz+' MHz':'')):'No capture yet';font.family:Appearance.font.data;font.pixelSize:11;wrapMode:Text.Wrap;color:Theme.paperMuted}
  Text {visible:root.section===1;width:parent.width;text:'TRY / Find FM stations. Compare antenna positions. Observe ISM-band energy. Use rtl_433 for your own weather sensors. Explore public beacon spectrum; cellular here is power only. Aircraft/satellite decoding needs suitable antennas and separate tools.';font.family:Appearance.font.ui;font.pixelSize:12;wrapMode:Text.Wrap;color:Theme.paperMuted}
  Column {visible:root.section===1;width:parent.width;spacing:16
   Text {width:parent.width;text:'RADIO LAB / reproducible curiosity';font.family:Appearance.font.heading;font.pixelSize:19;color:Theme.paper}
   Text {width:parent.width;text:'Capture → change one thing → capture again → compare. Keep frequency, gain and antenna details with the result; a stronger peak is not automatically a better antenna.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paperMuted}
   Row {spacing:10
    MusicButton {implicitWidth:220;implicitHeight:38;label:'15s sensor observation';glyph:'\uf2db';enabled:!root.live&&!Radio.busy&&Radio.available;onActivated:Radio.run('sensors')}
    MusicButton {implicitWidth:220;implicitHeight:38;label:'Compare last two scans';glyph:'\uf080';enabled:!root.live&&!Radio.busy;onActivated:Radio.run('compare')}
   }
   Text {width:parent.width;text:'433.92 MHz · rtl_433 · local packets only. Recognize your own sensor before assigning a device identity. Zero packets is a valid result.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
   Row {spacing:10
    MusicButton {implicitWidth:220;implicitHeight:38;label:'5s FM IQ · '+root.frequency.toFixed(1)+' MHz';glyph:'\uf111';enabled:!root.live&&!Radio.busy&&Radio.available;onActivated:Radio.run('record',[String(root.frequency)])}
    MusicButton {implicitWidth:220;implicitHeight:38;label:'Open receipt folder';glyph:'\uf07c';onActivated:Radio.run('folder')}
   }
   Text {width:parent.width;text:'1.024 MS/s · complex unsigned 8-bit · about 10 MB. SigMF metadata includes frequency, sample rate, timestamp, hardware and SHA-512. Use the capture in GNU Radio or another SigMF-aware tool.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
   Text {width:parent.width;text:Radio.receipt.kind==='comparison'?Radio.receipt.note:Radio.receipt.kind==='iq'?'IQ saved · '+Radio.receipt.bytes+' bytes · '+Radio.receipt.datatype:Radio.receipt.kind==='sensors'?Radio.receipt.packetCount+' packets · '+(Radio.receipt.models||[]).join(', '):'';wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetAccent}
   Text {width:parent.width;text:'FURTHER / Gqrx: AM, FM, SSB, waterfall and bookmarks. GNU Radio: build and test demodulators. SatDump and readsb are separate antenna-dependent projects. Legacy NOAA APT satellites are retired; use current transmission/pass information.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
  }
  Column {visible:root.section===2;width:parent.width;spacing:12
   Row {spacing:10
    MusicButton {implicitWidth:170;implicitHeight:34;label:'Refresh receipts';glyph:'\uf021';enabled:!Radio.busy;onActivated:Radio.run('history')}
    MusicButton {implicitWidth:200;implicitHeight:34;label:'Open local artifacts';glyph:'\uf07c';onActivated:Radio.run('folder')}
   }
   ListView {width:parent.width;height:430;clip:true;spacing:8;model:Radio.history
    delegate:Rectangle {required property var modelData;width:ListView.view.width;height:78;radius:6;color:Theme.surfaceOne
     Text {x:14;y:12;width:parent.width-28;text:modelData.kind.toUpperCase()+' · '+new Date(modelData.at*1000).toLocaleString();font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paper;elide:Text.ElideRight}
     Text {x:14;y:37;width:parent.width-28;text:modelData.note||modelData.label||modelData.frequencyMHz&&modelData.frequencyMHz+' MHz · '+(modelData.seconds||'')+' s'||modelData.tuner||modelData.id;font.family:Appearance.font.data;font.pixelSize:11;color:Theme.paperMuted;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight}
    }
   }
   Text {visible:!Radio.history.length;text:'A test or experiment leaves an inspectable local receipt here.';font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
  }

 }
 }}
 onSamplesChanged:if(root.scopeCanvas)root.scopeCanvas.requestPaint()
}
