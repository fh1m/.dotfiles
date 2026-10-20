import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
Column {
 id:root;spacing:12;property var snapshot:({interfaces:[],neighbors:[],routes:[]});property var prepared:({});property string phase:"inventory";property string report:"Routes, observed neighbors and owned sockets. Explicit scans stay within your selected private LAN.";property var deferred:[]
 function request(args,op){if(worker.running)return;phase=op;worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-actions"].concat(args);worker.running=true;}
 function action(name,params){prepared={};request(["prepare",name,"--params",JSON.stringify(params)],"prepare");}
 Component.onCompleted:request(["run","network.inspect"],"inventory")
 Text {text:"NETWORK WORKBENCH";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;font.letterSpacing:1;color:Theme.widgetAccent}
 DeskComboBox {id:interfaces;width:parent.width;model:root.snapshot.interfaces.filter(r=>r.operstate==="UP"&&r.ifname!=="lo");textRole:"ifname";enabled:!worker.running;onActivated:root.prepared={}}
 Flow {width:parent.width;spacing:8
  ControlTile {label:"Routes / sockets";enabled:!worker.running;onActivated:root.request(["run","network.inspect"],"inventory")}
  ControlTile {label:"Discover LAN…";enabled:!worker.running&&interfaces.currentIndex>=0;onActivated:root.action("network.discover",{interface:interfaces.model[interfaces.currentIndex].ifname})}
 }
 Repeater {model:root.snapshot.neighbors
  Text {required property var modelData;width:parent.width;text:modelData.dst+" · "+(modelData.lladdr||"unresolved MAC")+" · "+modelData.dev+" · "+(modelData.state||[]).join(" / ");wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.widgetText}
 }
 DeskTextField {id:target;width:parent.width;placeholderText:"Owned LAN host IPv4, e.g. Homie’s address";maximumLength:15}
 ControlTile {label:"Inspect TCP ports…";enabled:!worker.running&&target.text.trim()!==""&&interfaces.currentIndex>=0;onActivated:root.action("network.ports",{interface:interfaces.model[interfaces.currentIndex].ifname,target:target.text.trim()})}
 Row {width:parent.width;spacing:8;visible:!!root.prepared.confirmation
  ControlTile {label:"Confirm probe";enabled:!worker.running;onActivated:root.request(["run",root.prepared.plan.action,"--params",JSON.stringify(root.prepared.plan.params),"--confirmation",root.prepared.confirmation],"result")}
  ControlTile {label:"Cancel";onActivated:root.prepared={}}
 }
 Text {width:parent.width;text:root.report;wrapMode:Text.Wrap;textFormat:Text.PlainText;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.widgetMuted}
 Process {id:worker;onExited:if(root.deferred.length){let next=root.deferred;root.deferred=[];root.request(next,"result");}stdout:StdioCollector {onStreamFinished:{try{const row=JSON.parse(text);if(row.error){root.report=row.error;return;}if(root.phase==="inventory"){root.snapshot=row;root.report=row.note+"\n"+row.interfaces.map(i=>i.ifname+" · MTU "+i.mtu+" · "+i.operstate+"\n"+(i.addr_info||[]).map(a=>a.local+"/"+a.prefixlen).join(" · ")).join("\n")+"\n\n"+row.routes.map(r=>(r.dst||"default")+" via "+(r.gateway||"direct")+" · "+r.dev).join("\n")+"\n\nDNS\n"+(row.dns||"Use system resolver controls")+"\n\nSOCKETS\n"+(row.sockets||"").slice(-6000);}else if(root.phase==="prepare"){root.prepared=row;root.report=JSON.stringify(row.plan,null,2);}else{root.prepared={};root.report=JSON.stringify(row,null,2);}}catch(e){root.report="Network tools unavailable; no scan was repeated.";}}}}
}
