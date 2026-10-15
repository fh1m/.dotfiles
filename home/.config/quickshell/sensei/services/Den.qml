pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
    id: root
    property var data: ({peer:{host:"Homie",authenticated:false},input:"unknown",storage:"unavailable",clipboard:"unavailable"})
    property string error: ""
    readonly property bool working: action.running || companionAction.running
    readonly property bool online: data.peer?.authenticated === true
    readonly property bool inputRunning: data.input === "active"
    function refresh():void {if(!scan.running)scan.running=true;}
    function inputToggle():void {execute(["toggle"]);}
    function locate():void {execute(["locate"]);}
    function home():void {execute(["home"]);}
    function openStorage():void {execute(["storage"]);}
    function companion(name:string,value:string):void {
        if(companionAction.running)return;
        error="";
        companionAction.command=[Quickshell.env("HOME")+"/.local/bin/sensei-den","companion",name].concat(value?[value]:[]);
        companionAction.running=true;
    }
    function execute(args):void {if(action.running)return;error="";action.command=[Quickshell.env("HOME")+"/.local/bin/den-control"].concat(args);action.running=true;}
    Component.onCompleted:refresh()
    IpcHandler {target:"den-view";function state():string{return JSON.stringify({data:root.data,error:root.error});}function refresh():void{root.refresh();}function act(name:string):void{if(["toggle","locate","home","storage"].indexOf(name)>=0)root.execute([name]);}}
    Process {id:scan;command:[Quickshell.env("HOME")+"/.local/bin/den-control","status","--json"]
        stdout:StdioCollector {onStreamFinished:{try{root.data=JSON.parse(text);}catch(e){root.data={peer:{state:"unavailable",authenticated:false},input:"inactive",storage:"not configured"};root.error="Den status unavailable";}}}
    }
    Process {id:action
        stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim().split("\n").filter(s=>s.startsWith("Den:")).join("\n")||"Den action unavailable";}
        onExited:root.refresh()
    }
    Process {id:companionAction;stdout:StdioCollector {}
        onExited:(code,status)=>{if(code!==0)root.error="Companion action unavailable";root.refresh();}}
    Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="system")root.refresh();}function onSystemPageChanged(){if(ShellState.dropdown==="system")root.refresh();}}
    Timer {interval:15000;repeat:true;running:ShellState.dropdown==="system"&&ShellState.systemPage===0;onTriggered:root.refresh()}
}
