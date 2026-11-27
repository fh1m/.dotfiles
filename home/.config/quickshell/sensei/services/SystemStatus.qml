pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
Singleton {
 id:root
 property int failedUnits:-1
 property int failedSystemUnits:-1
 property int failedUserUnits:-1
 readonly property bool healthKnown:failedUnits>=0
 readonly property bool breach:failedUnits>0
 property int pendingUpdates:-1
 property bool updatesKnown:false
 property double updatesChecked:0
 property string shieldState:"unknown"
 property string shieldFirewall:""
 readonly property bool shieldArmed:false
 property real pingMs:-1
 property bool routeKnown:false
 property bool defaultRoutePresent:false
 readonly property bool uplinkDown:routeKnown&&!defaultRoutePresent
 readonly property string ssid:{for(const d of Networking.devices?.values??[])for(const n of d.networks?.values??[])if(n.connected)return n.name;return "";}
 Process {id:failedProc;command:[Quickshell.env("HOME")+"/.local/bin/sensei-status","failed"];stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);root.failedSystemUnits=d.system??-1;root.failedUserUnits=d.user??-1;root.failedUnits=d.total??-1;}catch(e){root.failedUnits=-1;}}}}
 Process {id:updatesProc;command:[Quickshell.env("HOME")+"/.local/bin/sensei-status","updates"];stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);root.updatesKnown=d.known===true;if(d.known){root.pendingUpdates=d.count;root.updatesChecked=Date.now();}}catch(e){root.updatesKnown=false;}}}}
 Process {id:shieldProc;command:[Quickshell.env("HOME")+"/.local/bin/sensei-status","firewall"];stdout:StdioCollector {onStreamFinished:{try{root.shieldFirewall=JSON.parse(text).managers.join(", ");}catch(e){root.shieldFirewall="";}root.shieldState="unknown";}}}
 Process {id:pingProc;command:[Quickshell.env("HOME")+"/.local/bin/sensei-status","route"];stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);root.routeKnown=d.known;root.defaultRoutePresent=d.defaultRoutePresent;root.pingMs=d.gatewayPingMs??-1;}catch(e){root.routeKnown=false;root.pingMs=-1;}}}}
 Timer {interval:60000;running:true;repeat:true;triggeredOnStart:true;onTriggered:if(!failedProc.running)failedProc.running=true}
 Timer {interval:30*60000;running:true;repeat:true;triggeredOnStart:true;onTriggered:if(!updatesProc.running)updatesProc.running=true}
 Timer {interval:60000;running:true;repeat:true;triggeredOnStart:true;onTriggered:if(!shieldProc.running)shieldProc.running=true}
 Timer {interval:10000;running:true;repeat:true;triggeredOnStart:true;onTriggered:if(!pingProc.running)pingProc.running=true}
}
