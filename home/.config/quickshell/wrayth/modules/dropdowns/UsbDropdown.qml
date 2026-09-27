import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root
 title:"\uf287 USB LAB";katakana:"ДИАГНОСТИКА"
 greeting:"Sensei, trace a device from its port to the processes using it."
 implicitWidth:1040
 property string selectedPort:""
 property int page:0
 onPageChanged:if(page===3)UsbLab.loadHistory()
 IpcHandler {target:"usblab";function page(index:int):void{root.page=Math.max(0,Math.min(4,index));}function select(port:string):void{root.selectedPort=port;}function state():string{return JSON.stringify({devices:root.devices.length,port:root.device.port,page:root.page,height:root.height,error:UsbLab.error});}}
 readonly property var devices:UsbLab.data.devices||[]
 readonly property var device:devices.find(d=>d.port===selectedPort)||devices[0]||({nodes:[],interfaces:[],mounts:[],processes:[],warnings:[]})
 function size(v){return v===null||v===undefined?"unknown":v>=1073741824?(v/1073741824).toFixed(2)+" GiB":v>=1048576?(v/1048576).toFixed(1)+" MiB":Math.round(v)+" B";}
 function line(k,v){return k+"   "+(v===undefined||v===""?"not reported":v);}
 function details(){let d=device;return [line("Port / topology",d.port),line("Manufacturer",d.manufacturer),line("VID : PID",(d.vendor||"—")+" : "+(d.product||"—")),line("Serial",d.serial),line("Negotiated speed",(d.speed||"unknown")+" Mbit/s"),line("USB transfer requests",(d.urbRate||0)+" URBs/s · "+(d.urbTotal||0)+" total"),line("USB revision",d.version),line("Power descriptor",d.power),line("Kernel authorized",d.authorized),line("Runtime power",d.runtime),line("Power control",d.control),line("Bus / address",(d.bus||"—")+" / "+(d.device||"—")),"","Bound interfaces",...(d.interfaces||[]).map(i=>i.interface+" · class "+i.class+" · "+i.driver),"",...(d.warnings||[]).map(s=>"⚠ "+s)].join("\n");}
 Column {width:parent.width;spacing:9
  Row {spacing:7;Repeater {model:["Devices / ports","Storage","Access / processes","History","Kernel / faults"];ControlTile {required property string modelData;required property int index;label:modelData;navigation:true;selected:root.page===index;implicitWidth:172;implicitHeight:30;onActivated:root.page=index}}ControlTile {label:UsbLab.busy?"Reading…":"Refresh";glyph:"\uf021";implicitWidth:112;implicitHeight:30;enabled:!UsbLab.busy;onActivated:UsbLab.refresh()}}
  Row {visible:root.page===3;spacing:8;DeskTextField {width:360;placeholderText:"Search all history · port, device, serial node";text:UsbLab.query;onTextEdited:{UsbLab.query=text;UsbLab.offset=0;historyDelay.restart();}}ControlTile {label:"Newer";implicitWidth:108;implicitHeight:32;enabled:UsbLab.offset>0;onActivated:{UsbLab.offset=Math.max(0,UsbLab.offset-100);UsbLab.loadHistory();}}ControlTile {label:"Older";implicitWidth:108;implicitHeight:32;enabled:UsbLab.offset+100<UsbLab.history.total;onActivated:{UsbLab.offset+=100;UsbLab.loadHistory();}}ControlTile {label:"Export full report";glyph:"\uf093";implicitWidth:190;implicitHeight:32;onActivated:UsbLab.exportReport()}Text {anchors.verticalCenter:parent.verticalCenter;text:UsbLab.history.total+" matching events";font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}}
  Timer {id:historyDelay;interval:350;onTriggered:UsbLab.loadHistory()}
  Row {width:parent.width;height:root.page===3?260:305;spacing:12
   ListView {id:deviceList;width:250;height:parent.height;clip:true;spacing:6;model:root.devices;visible:root.page<3
    delegate:ControlTile {required property var modelData;width:deviceList.width;implicitHeight:48;label:modelData.name;detail:modelData.port+" · "+modelData.speed+" Mbit/s";glyph:modelData.nodes.some(n=>n.subsystem==="tty")?"\uf2db":"\uf287";selected:root.device.port===modelData.port;onActivated:root.selectedPort=modelData.port}
    ScrollBar.vertical:DeskScrollBar {}
   }
   Flickable {width:root.page<3?parent.width-262:parent.width;height:parent.height;contentHeight:body.height;clip:true;boundsBehavior:Flickable.StopAtBounds;ScrollBar.vertical:DeskScrollBar {}
    Column {id:body;width:parent.width;spacing:9
     NrLabel {visible:root.page<3;width:parent.width;text:root.device.name||"No USB devices";font.weight:Font.Bold;pixelSize:15;color:Theme.widgetAccent;font.capitalization:Font.MixedCase;tracked:false;elide:Text.ElideRight}
     Text {visible:root.page===0;width:parent.width;text:root.details();font.family:Appearance.font.data;font.pixelSize:12;lineHeight:1.4;color:Theme.widgetText;wrapMode:Text.Wrap;textFormat:Text.PlainText}
     Repeater {model:root.page===1?(root.device.mounts||[]):[]
      ChamferPanel {required property var modelData;width:body.width;height:94;scanlines:false;chamfer:7;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
       Column {x:12;y:10;width:parent.width-24;spacing:8
        Text {width:parent.width;text:modelData.path+" · "+(modelData.filesystem||"unknown")+" · "+(modelData.readOnly?"read-only":"read/write");font.family:Appearance.font.data;font.pixelSize:13;font.bold:true;color:Theme.widgetText;elide:Text.ElideRight}
        Text {text:root.size(modelData.free)+" free / "+root.size(modelData.total)+" total";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted}
        Rectangle {width:parent.width;height:4;color:Theme.widgetBorder;Rectangle {height:4;width:parent.width*(modelData.total?(modelData.total-modelData.free)/modelData.total:0);color:Theme.widgetAccent}}
        Text {text:modelData.device+" · "+(modelData.label||"no volume label");font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}
       }
      }
     }
     Text {visible:root.page===1&&!(root.device.mounts||[]).length;width:parent.width;text:"No mounted filesystem on this device. Serial boards, cameras and HID devices do not expose disk space. Unmounted block devices are listed under Access.";wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetMuted}
     Repeater {model:root.page===2?(root.device.nodes||[]):[]
      Text {required property var modelData;width:body.width;wrapMode:Text.Wrap;text:modelData.path+" · "+modelData.subsystem+"\n"+modelData.permissions+" · "+modelData.owner+":"+modelData.group+" · Sensei: "+(modelData.canRead?"read ":"")+(modelData.canWrite?"write":"no write access");font.family:Appearance.font.data;font.pixelSize:12;lineHeight:1.3;color:Theme.widgetText}
     }
     Text {visible:root.page===2;text:"Open device / filesystem handles";font.family:Appearance.font.data;font.pixelSize:13;font.bold:true;color:Theme.widgetAccent}
     Repeater {model:root.page===2?(root.device.processes||[]):[]
      ChamferPanel {required property var modelData;width:body.width;height:processText.implicitHeight+20;scanlines:false;chamfer:6;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
       Text {id:processText;x:10;y:10;width:parent.width-20;text:modelData.name+" · PID "+modelData.pid+" · "+modelData.user+"\nProcess-wide I/O: read "+root.size(modelData.readBps)+"/s · write "+root.size(modelData.writeBps)+"/s\n"+modelData.handles.map(h=>h.access+" · "+h.path).join("\n");font.family:Appearance.font.data;font.pixelSize:12;lineHeight:1.3;color:Theme.widgetText;wrapMode:Text.Wrap}
      }
     }
     Text {visible:root.page===2&&!(root.device.processes||[]).length;width:parent.width;text:"No visible userspace handles. This does not mean the kernel or a restricted process is idle.";wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted}
     Repeater {model:root.page===3?(UsbLab.history.events||[]):[]
      Text {required property var modelData;width:body.width;text:new Date(modelData.time*1000).toLocaleString()+" · "+modelData.action+" · "+modelData.port+"\n"+modelData.name+" · "+modelData.subsystem+" "+modelData.node;font.family:Appearance.font.data;font.pixelSize:12;color:/remove/.test(modelData.action)?Theme.widgetAccent:Theme.widgetText;wrapMode:Text.Wrap;lineHeight:1.25}
     }
     Text {visible:root.page===4;width:parent.width;text:(UsbLab.data.logs||[]).join("\n\n")||"No readable USB kernel messages. Kernel log visibility depends on journal permissions.";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;wrapMode:Text.Wrap;textFormat:Text.PlainText}
    }
   }
  }
  Text {width:parent.width;text:UsbLab.error||((root.page===2?(UsbLab.data.audit||"")+" Restricted: "+(UsbLab.data.processesRestricted||0)+". ":"")+(UsbLab.data.notes||"Sensei, reading the USB topology…"));font.family:Appearance.font.data;font.pixelSize:10;color:Theme.widgetMuted;wrapMode:Text.Wrap;maximumLineCount:3;elide:Text.ElideRight}
 }
}
