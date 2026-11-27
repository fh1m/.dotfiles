pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id: root
 property var data: ({cpu:0,cores:[],memory:{},processes:[],mounts:[],network:[],storage:[],ips:[],load:[],uptime:0})
 property var cpuHistory: []
 property var ramHistory: []
 property var gpuHistory: []
 property var rxHistory: []
 property var txHistory: []
 readonly property bool active: ShellState.dropdown === "monitor" || ShellState.dropdown === "ident" || (ShellState.dropdown === "code" && CodeDesk.tab === 0)
 readonly property bool detailed: ShellState.dropdown === "monitor" && ShellState.monitorPage === 1
 readonly property bool inventory: ShellState.dropdown === "monitor" && ShellState.monitorPage >= 2
 function configure() { if (poll.running) poll.write(JSON.stringify({detail:detailed,inventory:inventory,private:Demo.active})+"\n"); }
 function refresh() { configure(); }
 onDetailedChanged: configure()
 onInventoryChanged: configure()
 Connections { target: Demo; function onActiveChanged() { root.data={cpu:0,cores:[],memory:{},processes:[],mounts:[],network:[],storage:[],ips:[],load:[],uptime:0}; root.configure(); } }
 Process {
  id: poll
  running: root.active
  stdinEnabled: true
  command: ["env","SENSEI_MONITOR_DETAIL="+(root.detailed?"1":"0"),"SENSEI_MONITOR_INVENTORY="+(root.inventory?"1":"0"),"SENSEI_MONITOR_PRIVATE="+(Demo.active?"1":"0"),"@HOME@/.local/bin/system-monitor-data","--stream"]
  onStarted: root.configure()
  stdout: SplitParser { onRead: line=> {
   try {
    const d=JSON.parse(line);if(d.private!==Demo.active)return;root.data=d;
    root.rxHistory=root.rxHistory.concat([d.network.reduce((n,v)=>n+v.rx,0)]).slice(-180);
    root.txHistory=root.txHistory.concat([d.network.reduce((n,v)=>n+v.tx,0)]).slice(-180);
    root.cpuHistory=root.cpuHistory.concat([d.cpu]).slice(-180);
    root.ramHistory=root.ramHistory.concat([100*d.memory.used/d.memory.total]).slice(-180);
    root.gpuHistory=root.gpuHistory.concat([RobotBench.data.gpu.usage??0]).slice(-180);
   } catch(e) { console.warn("Monitor sample unavailable"); }
  }}
  onExited: if(root.active) recovery.restart()
 }
 Timer { id: recovery; interval:5000; onTriggered: if(root.active) poll.running=true }
}
