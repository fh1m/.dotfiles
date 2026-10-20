import QtQuick
import qs.components
import qs.config
import qs.services
Rectangle {
 id:root
 implicitHeight:140
 color:Theme.surfaceOne;radius:3;border.width:1;border.color:Theme.rule
 readonly property var d:LiveMonitor.data
 readonly property var gpu:RobotBench.data.gpu
 function size(bytes):string {return bytes===undefined||bytes===null?'—':(bytes/1073741824).toFixed(1)+' GiB';}
 function rate(key):string {if(!d.network?.length)return '—';const n=d.network.reduce((sum,item)=>sum+(item[key]||0),0);return n>=1048576?(n/1048576).toFixed(1)+' MiB/s':(n/1024).toFixed(1)+' KiB/s';}
 Column {anchors.fill:parent;anchors.margins:12;spacing:10
  Text { textFormat: Text.PlainText;text:'Operator · system at a glance';color:Theme.paperMuted;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body}
  Row {width:parent.width;spacing:0
   Repeater {model:[
    {label:'CPU',value:d.memory?.total?Math.round(d.cpu)+'%':'—',detail:d.load?.length?'Load '+d.load[0].toFixed(2):'Waiting for telemetry'},
    {label:'Memory available',value:root.size(d.memory?.available),detail:root.size(d.memory?.used)+' / '+root.size(d.memory?.total)},
    {label:'NVIDIA',value:gpu.state==='sleep'?'Sleeping':gpu.usage===null||gpu.usage===undefined?'—':gpu.usage+'%',detail:(gpu.computeCount??0)+' CUDA · '+(gpu.graphicsCount??0)+' graphics'},
    {label:'CPU temperature',value:RobotBench.data.cpuTemperature===null||RobotBench.data.cpuTemperature===undefined?'—':RobotBench.data.cpuTemperature+' °C',detail:(RobotBench.data.fanMode===2?'Auto fans':RobotBench.data.fanMode===0?'Fan boost':RobotBench.data.fanMode===1?'Manual fans':'Fans unavailable')+(RobotBench.data.fans?.length?' · '+Math.max(...RobotBench.data.fans)+' rpm':'')},
    {label:Power.onBattery?'Battery':'AC power',value:Math.round(Power.charge)+'%',detail:Power.profileName},
    {label:'Uptime',value:d.uptime?Math.floor(d.uptime/3600)+'h '+Math.floor(d.uptime/60%60)+'m':'—',detail:d.processCount===undefined?'Waiting for telemetry':d.processCount+' processes'}
   ]
    Item {required property var modelData;required property int index;width:parent.width/6;height:64
     Rectangle {visible:index>0;x:0;y:2;width:1;height:60;color:Theme.rule}
     Column {x:index===0?0:14;width:parent.width-(index===0?10:24);spacing:5
      Text { textFormat: Text.PlainText;width:parent.width;text:modelData.label;color:Theme.paperMuted;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;elide:Text.ElideRight}
      Text { textFormat: Text.PlainText;width:parent.width;text:modelData.value;color:index===0||index===2?Theme.signalRed:Theme.paper;font.family:Appearance.font.telemetry;font.pixelSize:20;elide:Text.ElideRight}
      Text { textFormat: Text.PlainText;width:parent.width;text:modelData.detail;color:Theme.paperMuted;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;elide:Text.ElideRight}
     }
    }
   }
  }
  Text { textFormat: Text.PlainText;width:parent.width;text:'Network ↓ '+root.rate('rx')+'  ↑ '+root.rate('tx')+'    ·    '+(RobotBench.data.boardCount??0)+' USB boards    ·    '+(RobotBench.data.simCount??0)+' simulators    ·    '+ClipboardVault.count+' saved clips';color:Theme.paperMuted;font.family:Appearance.font.telemetry;font.pixelSize:11;elide:Text.ElideRight}
 }
}
