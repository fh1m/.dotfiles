pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root;property int page:0;property var clocks:[];property var events:[];property var tasks:[];property var upcoming:[];property var focusState:({phase:"focus",running:false,remaining:1500,focus:25,short:5,long:15,cycles:4,completed:0,task:0,auto:true});property var queue:[];property string operation:"";signal saved()
 property var laps:[];property bool stopwatchRunning:false;property real stopwatchStarted:0;property real stopwatchAccumulated:0
 function stopwatchElapsed(now){return stopwatchAccumulated+(stopwatchRunning?(now-stopwatchStarted)/1000:0);}
 function stopwatchToggle(){if(stopwatchRunning)stopwatchAccumulated=stopwatchElapsed(Date.now());else stopwatchStarted=Date.now();stopwatchRunning=!stopwatchRunning;saveStopwatch();}
 function stopwatchReset(){stopwatchRunning=false;stopwatchAccumulated=0;laps=[];saveStopwatch();}
 function stopwatchLap(){laps=laps.concat([stopwatchElapsed(Date.now())]);saveStopwatch();}
 function saveStopwatch(){stopwatchFile.setText(JSON.stringify({running:stopwatchRunning,started:stopwatchStarted,accumulated:stopwatchAccumulated,laps:laps}));}
 FileView {id:stopwatchFile;path:"@HOME@/.local/share/sensei-calendar/stopwatch.json";printErrors:false;onLoaded:{try{let d=JSON.parse(text());root.stopwatchRunning=!!d.running;root.stopwatchStarted=Number(d.started)||0;root.stopwatchAccumulated=Number(d.accumulated)||0;root.laps=d.laps||[];}catch(e){}}}property string selectedDay:Qt.formatDateTime(new Date(),'yyyy-MM-dd');property string month:Qt.formatDateTime(new Date(),'yyyy-MM-01');property string error:"";property bool importing:false
 function refresh(){if(!list.running)list.running=true;}
 function dispatch(command){if(act.running){queue=queue.concat([command]);return;}error="";operation=command[1];act.command=command;act.running=true;}
 function save(value){dispatch(["@HOME@/.local/bin/sensei-calendar","save",JSON.stringify(value)]);}
 function action(name,id){dispatch(["@HOME@/.local/bin/sensei-calendar",name,String(id)]);}
 function taskSave(value){dispatch(["@HOME@/.local/bin/sensei-calendar","task-save",JSON.stringify(value)]);}
 function focusAction(name,values){dispatch(["@HOME@/.local/bin/sensei-calendar","focus",name,JSON.stringify(values||{})]);}
 function formatSeconds(value){const s=Math.max(0,Math.ceil(value));return String(Math.floor(s/60)).padStart(2,'0')+":"+String(s%60).padStart(2,'0');}
 function focusRemaining(now){return focusState.running?Math.max(0,focusState.ends-now/1000):focusState.remaining;}
 SystemClock {id:dayClock;precision:root.focusState.running?SystemClock.Seconds:SystemClock.Minutes}
 readonly property string barSummary:{const d=Qt.formatDateTime(dayClock.date,'yyyy-MM-dd');const todo=tasks.filter(t=>!t.archived&&!t.done&&t.date<=d).length;let items=['DHAKA · UTC+06',todo+' tasks'];if(upcoming.length)items.push('Next '+upcoming[0].time+' '+upcoming[0].title);else items.push('Agenda clear');return items.join('  /  ');}
 readonly property string focusReadout:focusState.running?(focusState.phase==='focus'?'FOCUS ':'BREAK ')+formatSeconds(focusRemaining(dayClock.date.getTime())):''
 function timer(seconds,title){dispatch(["@HOME@/.local/bin/sensei-calendar","timer",String(seconds),title]);}
 onMonthChanged:refresh()
 Process {id:list;command:["@HOME@/.local/bin/sensei-calendar","list",root.month];stdout:StdioCollector {onStreamFinished:{try{let d=JSON.parse(text);root.events=d.events;root.clocks=d.clocks;root.tasks=d.tasks||[];root.upcoming=d.upcoming||[];root.focusState=d.focus||root.focusState;}catch(e){}}}}
 Process {id:act;stderr:StdioCollector {onStreamFinished:root.error=text.trim()}onExited:(code,status)=>{if(code===0&&(root.operation==="save"||root.operation==="task-save"))root.saved();root.refresh();if(root.queue.length){let next=root.queue[0];root.queue=root.queue.slice(1);Qt.callLater(()=>root.dispatch(next));}}}
 Process {id:ics;property string chosen:"";command:["env","GDK_DEBUG=no-portals","zenity","--file-selection","--title=Sensei, import calendar","--file-filter=Calendar | *.ics"];stdout:StdioCollector {onStreamFinished:ics.chosen=text.trim()}onExited:(code,status)=>{if(code===0&&ics.chosen)root.action("import",ics.chosen);ShellState.externalDialogOpen=false;}}
 function importCalendar(){ShellState.externalDialogOpen=true;ics.chosen="";ics.running=true;}
 FileView {path:"@HOME@/.local/share/sensei-calendar/revision";watchChanges:true;printErrors:false;onFileChanged:{reload();root.refresh();}}
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="calendar")root.refresh();}}
 property string today:Qt.formatDateTime(dayClock.date,"yyyy-MM-dd")
 onTodayChanged:refresh()
 Component.onCompleted:refresh()
}
