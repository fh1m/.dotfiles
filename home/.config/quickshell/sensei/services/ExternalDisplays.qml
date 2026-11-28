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
    property bool pendingLayout:false
    property int recoveryInterval:60000
    property var pending:({})
    property var inflight:({})
    function optimistic(output,level){data=Object.assign({},data,{displays:displays.map(d=>d.output===output?Object.assign({},d,{level:level}):d)});}
    function display(output:string):var {return displays.find(d=>d.output===output)??null;}
    function refresh(layout=true):void {
        if(scan.running){refreshPending=true;pendingLayout=pendingLayout||layout;return;}
        scan.command=[Quickshell.env("HOME")+"/.local/bin/sensei-displays","sync"].concat(layout?[]:["--no-layout","--no-notify"]);
        scan.running=true;
    }
    function setLevel(output:string,level:real):void {
        if(!display(output)?.ready)return;
        const next=Object.assign({},pending);next[output]=Math.max(0,Math.min(100,Math.round(level)));pending=next;optimistic(output,next[output]);debounce.restart();
    }
    function next():void {
        if(control.running)return;
        const names=Object.keys(pending);if(!names.length)return;
        const output=names[0],value=pending[output],remaining=Object.assign({},pending);delete remaining[output];pending=remaining;
        inflight={output:output,level:value};control.command=[Quickshell.env("HOME")+"/.local/bin/sensei-displays","brightness",output,String(value)];control.running=true;
    }
    function accept(line:string):void {try{const value=JSON.parse(line);if(value.error)error=value.error;else{data=Object.assign({},value,{displays:(value.displays||[]).map(d=>pending[d.output]!==undefined?Object.assign({},d,{level:pending[d.output]}):d)});error="";}}catch(e){error="Display controls unavailable";}}
    Component.onCompleted:refresh()
    Timer {id:recovery;interval:root.recoveryInterval;repeat:true;running:["system","external-display","displays"].includes(ShellState.dropdown);onTriggered:root.refresh(false)}
    Timer {id:debounce;interval:180;onTriggered:root.next()}
    Process {id:scan;command:[Quickshell.env("HOME")+"/.local/bin/sensei-displays","sync"]
        stdout:SplitParser {onRead:line=>root.accept(line)}
        onExited:{if(root.refreshPending){const layout=root.pendingLayout;root.refreshPending=false;root.pendingLayout=false;Qt.callLater(()=>root.refresh(layout));}}
    }
    Process {id:control;stdout:SplitParser {onRead:line=>root.accept(line)} onExited:{inflight=({});Qt.callLater(()=>root.next());}}
    Connections {target:Hyprland;function onRawEvent(event){if(["monitoradded","monitoraddedv2","monitorremoved","monitorremovedv2","configreloaded"].includes(event.name))settle.restart();}}
    Connections {target:ShellState;function onDropdownChanged(){if(["system","external-display","displays"].includes(ShellState.dropdown))root.refresh(false);}}
    Timer {id:settle;interval:700;onTriggered:root.refresh()}
    IpcHandler {target:"displays";function refresh():void {root.refresh();}function state():string {return JSON.stringify({data:root.data,error:root.error,externalScreens:ShellState.externalScreens.map(s=>s.name),bottomBars:ShellState.bottomBarScreens.map(s=>s.name)});}function workspace(number:int,output:string):void {Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-displays","workspace",String(number),output]);}function panel(output:string):void {ShellState.dropdownOriginScreen=output;ShellState.dropdownAnchorX=12;ShellState.dropdown="external-display";}}
}
