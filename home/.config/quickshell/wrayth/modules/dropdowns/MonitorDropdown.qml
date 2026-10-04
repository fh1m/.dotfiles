import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root
 title:"\uf080 SYSTEM MONITOR";katakana:"ТЕЛЕМЕТРИЯ"
 implicitWidth:1040
 property int page:ShellState.monitorPage
 property string sort:"cpu"
 property var d:LiveMonitor.data
 property var gpu:RobotBench.data.gpu
 function size(v){return v===null||v===undefined?"—":v>=1073741824?(v/1073741824).toFixed(1)+" GiB":v>=1048576?(v/1048576).toFixed(1)+" MiB":v>=1024?(v/1024).toFixed(1)+" KiB":Math.round(v)+" B";}
 function sorted(){return d.processes.slice().sort((a,b)=>(b[root.sort]??-1)-(a[root.sort]??-1));}
 ListModel {id:processModel;dynamicRoles:true}
 function syncProcesses(){if(page!==1)return;const rows=sorted();for(let i=0;i<rows.length;i++){const row=rows[i];let at=-1;for(let j=i;j<processModel.count;j++)if(processModel.get(j).entry.pid===row.pid){at=j;break;}if(at<0)processModel.insert(i,{entry:row});else{if(at!==i)processModel.move(at,i,1);processModel.setProperty(i,"entry",row);}}while(processModel.count>rows.length)processModel.remove(processModel.count-1);}
 onDChanged:syncProcesses()
 onSortChanged:syncProcesses()
 onPageChanged:syncProcesses()
 Component.onCompleted:syncProcesses()

 Column {
 width:parent.width;spacing:10
 Row {spacing:8;Repeater {model:["Overview","Processes","GPU / CUDA","Storage / I/O","Network","Hardware","Power / Session"];ControlTile {required property string modelData;required property int index;implicitWidth:130;implicitHeight:30;label:modelData;navigation:true;selected:root.page===index;onActivated:{root.page=index;ShellState.monitorPage=index;}}}}
 Item {
 width:parent.width;height:322
 Flickable {id:sectionEnter1Container;
 anchors.fill:parent;visible:root.page===0; clip:true;contentHeight:overview.height;boundsBehavior:Flickable.StopAtBounds
 Column {id:overview;width:parent.width;spacing:10
 Row {spacing:12
 Repeater {model:3

 ChamferPanel {required property int index;readonly property var modelData: index===0?{name:"CPU",value:root.d.cpu.toFixed(1)+" %",history:LiveMonitor.cpuHistory,ink:Theme.widgetAccent}:index===1?{name:"RAM",value:root.size(root.d.memory.used)+" / "+root.size(root.d.memory.total),history:LiveMonitor.ramHistory,ink:Theme.widgetText}:{name:"Nvidia RTX 2060",value:root.gpu.state==="sleep"?"0% · sleeping":(root.gpu.usage??"—")+" %",history:LiveMonitor.gpuHistory,ink:Theme.widgetAccent};width:(overview.width-24)/3;height:124;fillColor:Theme.alpha(Theme.widgetSurface,.6);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;x:12;y:10;text:modelData.name;pixelSize:12;color:Theme.widgetMuted}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;x:12;y:31;text:modelData.value;pixelSize:15;color:modelData.ink}
 MonitorGraph {x:12;y:60;width:parent.width-24;height:52;values:modelData.history;ink:modelData.ink}
 }}
 }
 Row {spacing:12
 Rectangle {width:(overview.width-12)/2;height:94;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Column {x:12;y:10;spacing:7;NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Memory breakdown";color:Theme.widgetAccent;pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Available "+root.size(root.d.memory.available)+"   Cache "+root.size(root.d.memory.cache);pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Swap "+root.size(root.d.memory.swapUsed)+" / "+root.size(root.d.memory.swapTotal);pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Cache is reclaimable; used = total − available";pixelSize:10;color:Theme.widgetMuted}}
 }
 Rectangle {width:(overview.width-12)/2;height:94;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Column {x:12;y:10;spacing:7;NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Thermals / session";color:Theme.widgetAccent;pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"CPU "+(RobotBench.data.cpuTemperature??"—")+" °C   Load "+root.d.load.map(v=>v.toFixed(2)).join(" / ");pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Uptime "+Math.floor(root.d.uptime/3600)+"h "+Math.floor(root.d.uptime/60%60)+"m   "+(root.d.processCount??root.d.processes.length)+" processes";pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:Machine.cpuModel+" · "+root.d.cores.length+" threads";pixelSize:10;color:Theme.widgetMuted}}
 }
 }
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"CPU threads · each core 0–100%";pixelSize:11;color:Theme.widgetMuted}
 Flow {width:parent.width;spacing:6;Repeater {model:root.d.cores.length;Rectangle {required property int index;readonly property real modelData:root.d.cores[index]??0;width:76;height:32;color:Theme.alpha(Theme.widgetAccent,.05+modelData/450);border.color:Theme.widgetBorder;NrLabel { font.capitalization: Font.MixedCase; tracked: false;anchors.centerIn:parent;text:"#"+index+" "+Math.round(modelData)+"%";pixelSize:11}}}}
 Row {spacing:14;Repeater {model:root.d.network;NrLabel { font.capitalization: Font.MixedCase; tracked: false;required property var modelData;text:modelData.name+"  ↓ "+root.size(modelData.rx)+"/s  ↑ "+root.size(modelData.tx)+"/s";pixelSize:12;color:Theme.widgetAccent}}}
 }
 ScrollBar.vertical:DeskScrollBar {}
 }
 Column {id:sectionEnter2Container;
 anchors.fill:parent;visible:root.page===1; spacing:7
 Row {spacing:7;Repeater {model:[{key:"cpu",label:"CPU %"},{key:"ram",label:"RAM"},{key:"read",label:"Disk read"},{key:"write",label:"Disk write"}];ControlTile {required property var modelData;implicitWidth:125;implicitHeight:28;label:modelData.label;navigation:true;selected:root.sort===modelData.key;onActivated:root.sort=modelData.key}}NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"CPU 100% = one thread · — = no permission";pixelSize:10;color:Theme.widgetMuted;anchors.verticalCenter:parent.verticalCenter}}
 Row {spacing:12;NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:62;text:"PID";pixelSize:11;color:Theme.widgetMuted}NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:260;text:"Process / click for command";pixelSize:11;color:Theme.widgetMuted}Repeater {model:["CPU %","RAM","Read /s","Write /s","Threads"];NrLabel { font.capitalization: Font.MixedCase; tracked: false;required property string modelData;width:112;text:modelData;pixelSize:11;color:Theme.widgetMuted}}}
 ListView {width:parent.width;height:273;clip:true;model:processModel;spacing:3;ScrollBar.vertical:DeskScrollBar {}
 delegate:Rectangle {required property var entry;readonly property var modelData:entry;width:ListView.view.width;height:32;color:pointer.containsMouse?Theme.alpha(Theme.widgetAccent,.12):Theme.alpha(Theme.widgetSurface,.45);border.color:Theme.alpha(Theme.widgetBorder,.5)
 Row {x:8;anchors.verticalCenter:parent.verticalCenter;spacing:12;NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:54;text:modelData.pid;pixelSize:12;color:Theme.widgetMuted}NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:260;text:modelData.name;pixelSize:12;elide:Text.ElideRight}NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:112;text:modelData.cpu.toFixed(1);pixelSize:12;color:modelData.cpu>50?Theme.widgetAccent:Theme.widgetAccent}NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:112;text:root.size(modelData.ram);pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:112;text:root.size(modelData.read);pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:112;text:root.size(modelData.write);pixelSize:12}NrLabel { font.capitalization: Font.MixedCase; tracked: false;width:70;text:modelData.threads;pixelSize:12}}
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;onClicked:root.processCommand=modelData.command}
 }
 }
 }
 Flickable {id:sectionEnter3Container;anchors.fill:parent;visible:root.page===2; clip:true;contentHeight:gpuContent.height;Column {id:gpuContent;width:parent.width;spacing:12
 NrLabel {text:"Chrome graphics · "+ChromeControl.data.actual;pixelSize:15;font.capitalization:Font.MixedCase;tracked:false}
 Row {spacing:8
 Repeater {model:["auto","intel","nvidia"];ControlTile {required property string modelData;implicitWidth:140;implicitHeight:32;label:modelData==="auto"?"Auto · Intel":modelData==="intel"?"Intel":"Nvidia";selected:ChromeControl.data.mode===modelData;enabled:!ChromeControl.busy&&(modelData!=="nvidia"||ChromeControl.data.nvidiaAvailable);onActivated:ChromeControl.run(["mode",modelData])}}
 ControlTile {implicitWidth:180;implicitHeight:32;label:ChromeControl.busy?"Please wait…":"Restart Chrome";enabled:!ChromeControl.busy;onActivated:ChromeControl.run(["restart"])}
 }
 NrLabel {text:ChromeControl.error||((ChromeControl.data.note??"")+" Choice applies on next launch; restart restores saved tabs.");width:parent.width;wrapMode:Text.Wrap;pixelSize:11;font.capitalization:Font.MixedCase;tracked:false;color:Theme.widgetMuted}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Nvidia RTX 2060 · "+String(root.gpu.state);pixelSize:16;color:Theme.widgetAccent}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"CUDA contexts "+(root.gpu.computeCount??0)+"    Graphics "+(root.gpu.graphicsCount??0)+"    Utilization "+(root.gpu.usage??0)+"%    Temperature "+(root.gpu.temperature??"—")+" °C";pixelSize:13}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"VRAM used "+(root.gpu.memoryUsed??root.gpu.memoryUsedMiB??"—")+" MiB / "+(root.gpu.memoryTotal??root.gpu.memoryTotalMiB??"—")+" MiB";pixelSize:13}
 MonitorGraph {width:parent.width;height:70;values:LiveMonitor.gpuHistory;ink:Theme.widgetAccent}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:root.gpu.state==="sleep"?"Dedicated GPU is asleep. Monitoring does not wake it.":"Active GPU processes · compute / graphics contexts";pixelSize:12;color:Theme.widgetMuted}
 Repeater {model:root.gpu.processes??[];NrLabel { font.capitalization: Font.MixedCase; tracked: false;required property var modelData;text:(modelData.pid??"")+"   "+(modelData.name??"process")+"   "+(modelData.type??"")+"   "+(modelData.memoryMiB??modelData.usedMemoryMiB??"—")+" MiB";pixelSize:13}}
 Text { text:root.d.extra?.gpuDetails??"Loading hardware telemetry…";width:parent.width;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;wrapMode:Text.Wrap}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Intel drives both displays. Desktop rendering activity: "+(RobotBench.data.intelUsage??"—")+"%\nThis Intel counter covers Hyprland, not every Intel GPU process.";pixelSize:12;color:Theme.widgetMuted}
 Row {spacing:8;ControlTile {label:"NVIDIA terminal";glyph:"\uf120";onActivated:Quickshell.execDetached(["/home/fh1m/.local/bin/sim-console"])}ControlTile {label:"nvtop";onActivated:Quickshell.execDetached(["sensei-terminal","nvtop"])}ControlTile {label:"Robotics controls";onActivated:{ShellState.systemPage=2;ShellState.dropdown="system";}}}
 }ScrollBar.vertical:DeskScrollBar {}}
 Flickable {id:sectionEnter4Container;anchors.fill:parent;visible:root.page===3; clip:true;contentHeight:storageContent.height;Column {id:storageContent;width:parent.width;spacing:10
 Repeater {model:root.d.mounts;Rectangle {required property var modelData;width:storageContent.width;height:76;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;x:12;y:8;text:modelData.mount+"  ·  "+modelData.device+"  ·  "+modelData.fs;pixelSize:13;color:Theme.widgetAccent}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;x:12;y:30;text:root.size(modelData.used)+" used    "+root.size(modelData.free)+" available    "+root.size(modelData.total)+" total";pixelSize:12}
 Rectangle {x:12;y:57;width:parent.width-24;height:5;color:Theme.widgetBorder;Rectangle {width:parent.width*modelData.percent/100;height:parent.height;color:modelData.percent>90?Theme.widgetAccent:Theme.widgetAccent}}
 }}
 Repeater {model:root.d.storage;NrLabel { font.capitalization: Font.MixedCase; tracked: false;required property var modelData;text:modelData.name+"    read "+root.size(modelData.read)+"/s    write "+root.size(modelData.write)+"/s    busy "+modelData.busy.toFixed(1)+"%";pixelSize:13}}
 NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:"Process disk counters need permission. Network traffic is shown per interface;\nper-process network attribution requires additional tracing.";pixelSize:11;color:Theme.widgetMuted}
 }ScrollBar.vertical:DeskScrollBar {}}

 Flickable {anchors.fill:parent;visible:root.page>=4;clip:true;contentHeight:extraContent.height;ScrollBar.vertical:DeskScrollBar {}
 Column {id:extraContent;width:parent.width;spacing:12
 Row {visible:root.page===4;spacing:12
 Repeater {model:2
 Rectangle {required property int index;readonly property var modelData:index===0?{label:"Download",values:LiveMonitor.rxHistory,ink:Theme.widgetAccent}:{label:"Upload",values:LiveMonitor.txHistory,ink:Theme.widgetMuted};property real peak:Math.pow(2,Math.ceil(Math.log2(Math.max(1024,...modelData.values))));width:(extraContent.width-12)/2;height:94;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Text {x:10;y:8;text:modelData.label+" · graph ceiling "+root.size(peak)+"/s";font.family:Appearance.font.data;font.pixelSize:12;color:modelData.ink}
 MonitorGraph {x:10;y:32;width:parent.width-20;height:52;ink:modelData.ink;values:modelData.values.map(v=>v/peak*100)}
 }}
 }
 Text {width:parent.width;text:root.page===4?"Interfaces / addresses\n"+(root.d.extra?.addresses??"")+"\n\nRouting table\n"+(root.d.extra?.routes??"")+"\n\nDNS configuration\n"+(root.d.extra?.dns??"")+"\n\nTCP / UDP sockets — user-owned process names where permitted\n"+(root.d.extra?.connections??""):root.page===5?"CPU specification\n"+(root.d.extra?.cpuInfo??"")+"\n\nTemperature sensors\n"+(root.d.extra?.sensors??[]).map(v=>v.name+": "+v.value.toFixed(1)+" °C").join("\n")+"\n\nUSB devices\n"+(root.d.extra?.usb??"")+"\n\nPCI devices / controllers\n"+(root.d.extra?.pci??""):"Battery / charge\n"+(root.d.extra?.batteries??[]).map(b=>b.manufacturer+" "+b.model_name+" · "+b.status+" · "+b.capacity+"%\nEnergy "+(Number(b.energy_now)/1000000).toFixed(2)+" Wh / "+(Number(b.energy_full)/1000000).toFixed(2)+" Wh · Design "+(Number(b.energy_full_design)/1000000).toFixed(2)+" Wh\nHealth "+(100*Number(b.energy_full)/Number(b.energy_full_design)).toFixed(1)+"% · Charge cap "+b.charge_control_end_threshold+"% · Cycles "+b.cycle_count+"\nDraw "+(Number(b.power_now)/1000000).toFixed(2)+" W · Voltage "+(Number(b.voltage_now)/1000000).toFixed(2)+" V").join("\n\n")+"\n\nOperating system\n"+(root.d.extra?.os??"")+"\n\nKernel: "+root.d.kernel+"\nUser services with failures\n"+(root.d.extra?.services??"")+"\n\nCPU power profile: "+(root.d.extra?.profile??"—")+"\n\nAudio devices / applications\n"+(root.d.extra?.audio??"")+"\n\nDisplay details\n"+(root.d.extra?.displays??"")+"\n\nGraph sampling: 0.5 seconds. Inventory refresh: 5 seconds. Sleeping GPU is not queried.";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;wrapMode:Text.Wrap; textFormat:Text.PlainText}
 }
 }

 }
 Row {spacing:8;NrLabel { font.capitalization: Font.MixedCase; tracked: false;text:Demo.active ? ("Private host / addresses hidden · "+root.d.kernel) : (root.processCommand || (root.d.host+" · "+root.d.kernel+" · "+root.d.ips.join(" / ")));width:660;elide:Text.ElideRight;pixelSize:10;color:Theme.widgetMuted}ControlTile {implicitWidth:190;implicitHeight:25;label:"Capture 15s stall";onActivated:Quickshell.execDetached(["sensei-terminal","--hold","--title","Sensei · stall capture","-e","/home/fh1m/.local/bin/sensei-health"])}ControlTile {implicitWidth:150;implicitHeight:25;label:"Open btop";onActivated:Quickshell.execDetached(["sensei-terminal","btop"])}}
 }
 property string processCommand:""
}
