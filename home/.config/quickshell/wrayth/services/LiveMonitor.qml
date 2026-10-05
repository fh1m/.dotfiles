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
 function refresh() { if (!poll.running) poll.running=true; }
 Process { id: poll; command: ["env","SENSEI_MONITOR_DETAIL="+(ShellState.dropdown === "monitor" && ShellState.monitorPage === 1 ? "1":"0"),"SENSEI_MONITOR_INVENTORY="+(ShellState.dropdown === "monitor" && ShellState.monitorPage >= 2 ? "1":"0"),"/home/fh1m/.local/bin/system-monitor-data"]; stdout: StdioCollector { onStreamFinished: { try { root.data=JSON.parse(text);root.rxHistory=root.rxHistory.concat([root.data.network.reduce((n,v)=>n+v.rx,0)]).slice(-180);root.txHistory=root.txHistory.concat([root.data.network.reduce((n,v)=>n+v.tx,0)]).slice(-180);root.cpuHistory=root.cpuHistory.concat([root.data.cpu]).slice(-180);root.ramHistory=root.ramHistory.concat([100*root.data.memory.used/root.data.memory.total]).slice(-180);root.gpuHistory=root.gpuHistory.concat([RobotBench.data.gpu.usage ?? 0]).slice(-180); } catch(e) {} } } }
 Timer { interval:500; repeat:true; running:ShellState.dropdown === "monitor" || ShellState.dropdown === "ident"; triggeredOnStart:true; onTriggered:root.refresh() }
}
