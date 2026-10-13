pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
    id: root
    property var data: ({peer:{state:"unavailable",authenticated:false},input:"inactive",storage:"not configured"})
    property string error: ""
    readonly property bool working: action.running
    readonly property bool online: data.peer?.authenticated === true
    readonly property bool inputRunning: data.input === "active"
    function refresh():void {if(!scan.running)scan.running=true;}
    function inputToggle():void {execute(["input",inputRunning?"stop":"start"]);}
    function openStorage():void {execute(["storage","open"]);}
    function execute(args):void {if(action.running)return;error="";action.command=[Quickshell.env("HOME")+"/.local/bin/den"].concat(args);action.running=true;}
    Component.onCompleted:refresh()
    IpcHandler {target:"den-view";function state():string{return JSON.stringify({data:root.data,error:root.error});}function refresh():void{root.refresh();}}
    Process {id:scan;command:[Quickshell.env("HOME")+"/.local/bin/den","status","--json"]
        stdout:StdioCollector {onStreamFinished:{try{root.data=JSON.parse(text);}catch(e){root.data={peer:{state:"unavailable",authenticated:false},input:"inactive",storage:"not configured"};root.error="Den status unavailable";}}}
    }
    Process {id:action
        stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim().split("\n").filter(s=>s.startsWith("Den:")).join("\n")||"Den action unavailable";}
        onExited:root.refresh()
    }
    Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="system")root.refresh();}function onSystemPageChanged(){if(ShellState.dropdown==="system")root.refresh();}}
    Timer {interval:15000;repeat:true;running:ShellState.dropdown==="system"&&ShellState.systemPage===0;onTriggered:root.refresh()}
}
