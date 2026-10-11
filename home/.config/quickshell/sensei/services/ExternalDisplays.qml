pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
Singleton {
    id: root
    property var data: ({displays:[],outputs:[]})
    readonly property var displays: data.displays ?? []
    property string error: ""
    property bool refreshPending:false
    property var pending:({})
    function display(output:string):var {return displays.find(d=>d.output===output)??null;}
    function refresh():void {if(scan.running){refreshPending=true;return;}scan.running=true;}
    function setLevel(output:string,level:real):void {
        if(!display(output)?.ready)return;
        const next=Object.assign({},pending);next[output]=Math.max(0,Math.min(100,Math.round(level)));pending=next;debounce.restart();
    }
    function next():void {
        if(control.running)return;
        const names=Object.keys(pending);if(!names.length)return;
        const output=names[0],value=pending[output],remaining=Object.assign({},pending);delete remaining[output];pending=remaining;
        control.command=[Quickshell.env("HOME")+"/.local/bin/sensei-displays","brightness",output,String(value)];control.running=true;
    }
    function accept(line:string):void {try{const value=JSON.parse(line);if(value.error)error=value.error;else{data=value;error="";}}catch(e){error="Display controls unavailable";}}
    Component.onCompleted:refresh()
    Timer {id:debounce;interval:180;onTriggered:root.next()}
    Process {id:scan;command:[Quickshell.env("HOME")+"/.local/bin/sensei-displays","sync"]
        stdout:SplitParser {onRead:line=>root.accept(line)}
        onExited:if(root.refreshPending){root.refreshPending=false;Qt.callLater(()=>root.refresh());}
    }
    Process {id:control;stdout:SplitParser {onRead:line=>root.accept(line)} onExited:Qt.callLater(()=>root.next())}
    Connections {target:Hyprland;function onRawEvent(event){if(["monitoradded","monitoraddedv2","monitorremoved"].includes(event.name))settle.restart();}}
    Connections {target:ShellState;function onDropdownChanged(){if(["system","external-display"].includes(ShellState.dropdown))root.refresh();}}
    Timer {id:settle;interval:700;onTriggered:root.refresh()}
    IpcHandler {target:"displays";function refresh():void {root.refresh();}function state():string {return JSON.stringify({data:root.data,error:root.error,externalScreens:ShellState.externalScreens.map(s=>s.name),bottomBars:ShellState.bottomBarScreens.map(s=>s.name)});}function workspace(number:int,output:string):void {Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-displays","workspace",String(number),output]);}function panel(output:string):void {ShellState.dropdownOriginScreen=output;ShellState.dropdownAnchorX=12;ShellState.dropdown="external-display";}}
}
