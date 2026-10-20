import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
Column {
 id:root;spacing:12;property var snapshot:({interfaces:[],neighbors:[],routes:[]});property var prepared:({});property string phase:"inventory";property string report:"Routes, observed neighbors and owned sockets. Explicit scans stay within your selected private LAN.";property var deferred:[]
 property string diagnosticText:""
 property bool showTechnical:false
 function diagnose(action){if(tool.running||worker.running)return;tool.command=[Quickshell.env("HOME")+"/.local/bin/sensei-network",action];if(['health','link'].includes(action))tool.command=tool.command.concat(['--interface',interfaces.model[interfaces.currentIndex]?.ifname||'']);if(['resolve','trace'].includes(action))tool.command=tool.command.concat(['--target',diagnosticHost.text.trim()||'example.com']);tool.running=true;}
 function present(d){if(d.error)return d.error;let lines=[d.kind];if(d.data)lines=lines.concat(Object.entries(d.data).filter(x=>x[1]).map(x=>x[0]+': '+x[1]));if(d.addresses)lines.push(d.host+' → '+d.addresses.join(' · ')+' · '+d.elapsedMs+' ms');if(d.checks)lines=lines.concat(d.checks.map(c=>c.name+' / '+c.state+'\n'+(typeof c.detail==='object'?JSON.stringify(c.detail):c.detail)));if(d.links)lines=lines.concat(d.links.map(l=>l.ifname+' · '+l.operstate+' · MTU '+l.mtu+'\nRX '+JSON.stringify(l.stats64?.rx||{})+'\nTX '+JSON.stringify(l.stats64?.tx||{})));if(d.physical)lines.push(d.physical);if(d.result)lines.push(d.result);if(d.note)lines.push(d.note);return lines.join('\n\n');}
 function request(args,op){if(worker.running)return;phase=op;worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-actions"].concat(args);worker.running=true;}
 function action(name,params){prepared={};request(["prepare",name,"--params",JSON.stringify(params)],"prepare");}
 Component.onCompleted:request(["run","network.inspect"],"inventory")
 Text {text:"NETWORK WORKBENCH";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;font.letterSpacing:1;color:Theme.widgetAccent}
 DeskComboBox {id:interfaces;width:parent.width;model:root.snapshot.interfaces.filter(r=>r.operstate==="UP"&&r.ifname!=="lo");textRole:"ifname";enabled:!worker.running;onActivated:root.prepared={}}
 Text {width:parent.width;text:"LINK → GATEWAY → DNS → INTERNET";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
 DeskTextField {id:diagnosticHost;width:parent.width;placeholderText:"DNS / path target · example.com";maximumLength:253}
 Flow {width:parent.width;spacing:8
  Repeater {model:[{id:'health',name:'Connection test'},{id:'link',name:'Link / errors'},{id:'resolve',name:'Resolve DNS'},{id:'trace',name:'Trace route'},{id:'public',name:'Public IP / ISP'}]
   ControlTile {required property var modelData;label:modelData.name;enabled:!tool.running&&!worker.running&&(interfaces.currentIndex>=0||!['health','link'].includes(modelData.id));onActivated:root.diagnose(modelData.id)}
  }
 }
 Text {width:parent.width;text:tool.running?'Checking… bounded diagnostics; no connection settings are changed':'ISP lookup contacts ipinfo.io only when clicked. VPN egress can differ from the physical ISP.';wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
 ScrollView {visible:root.diagnosticText!=='';width:parent.width;height:Math.min(300,diagnosticView.implicitHeight+20);contentWidth:availableWidth;clip:true
  TextArea {id:diagnosticView;readOnly:true;text:root.diagnosticText;textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper;background:Rectangle {color:Theme.surfaceOne;radius:5;border.color:Theme.rule}}
 }
 Process {id:tool;stdout:StdioCollector {onStreamFinished:{try{root.diagnosticText=root.present(JSON.parse(text));}catch(e){root.diagnosticText='The diagnostic returned an unreadable response; no action was repeated.';}}}}
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
 ControlTile {label:root.showTechnical?"Hide technical snapshot":"Routes, DNS and socket snapshot";onActivated:root.showTechnical=!root.showTechnical}
 Text {visible:root.showTechnical||root.phase!=="inventory";width:parent.width;text:root.report;wrapMode:Text.Wrap;textFormat:Text.PlainText;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.widgetMuted}
 Process {id:worker;onExited:if(root.deferred.length){let next=root.deferred;root.deferred=[];root.request(next,"result");}stdout:StdioCollector {onStreamFinished:{try{const row=JSON.parse(text);if(row.error){root.report=row.error;return;}if(root.phase==="inventory"){root.snapshot=row;root.report=row.note+"\n"+row.interfaces.map(i=>i.ifname+" · MTU "+i.mtu+" · "+i.operstate+"\n"+(i.addr_info||[]).map(a=>a.local+"/"+a.prefixlen).join(" · ")).join("\n")+"\n\n"+row.routes.map(r=>(r.dst||"default")+" via "+(r.gateway||"direct")+" · "+r.dev).join("\n")+"\n\nDNS\n"+(row.dns||"Use system resolver controls")+"\n\nSOCKETS\n"+(row.sockets||"").slice(-6000);}else if(root.phase==="prepare"){root.prepared=row;root.report=JSON.stringify(row.plan,null,2);}else{root.prepared={};root.report=JSON.stringify(row,null,2);}}catch(e){root.report="Network tools unavailable; no scan was repeated.";}}}}
}
