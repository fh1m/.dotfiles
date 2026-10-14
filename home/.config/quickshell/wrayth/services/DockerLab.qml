pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id:root
 property var data:({containers:[],images:[],networks:[],volumes:[],disk:[],tasks:[],sessions:[],arm:[],serial:[],engine:{}})
 property var containers:[]
 property var images:[]
 property var networks:[]
 property var volumes:[]
 property var tasks:[]
 property var sessions:[]
 property var serial:[]
 property var arm:[]
 property var disk:[]
 property var compose:[]
 property var detail:({})
 property string selectedId:""
 property string selectedKind:"container"
 property string selectedKey:selectedKind+":"+selectedId
 property string detailKey:""
 property string message:""
 property bool success:true
 property int page:0
 property var queue:[]
 readonly property bool active:ShellState.dropdown==="docker"
 readonly property bool busy:inventory.running
 function refresh(){if(active&&!inventory.running)inventory.running=true;}
 function select(kind,id){selectedKind=kind;selectedId=id;detail={};loadDetails();}
 function loadDetails(){if(!selectedId||details.running||!active)return;detailKey=selectedKey;details.command=['@HOME@/.local/bin/sensei-docker','action','inspect',JSON.stringify([selectedKind,selectedId])];details.running=true;}
 function action(name,args){if(operation.running){if(queue.length<16)queue=queue.concat([{name:name,args:args||[]}]);else message="Sensei, finish queued tasks before adding more.";return;}operation.command=['timeout','30s','@HOME@/.local/bin/sensei-docker','action',name,JSON.stringify(args||[])];operation.running=true;message='Working · '+name;}
 function same(a,b){return JSON.stringify(a)===JSON.stringify(b);}
 onActiveChanged:if(active){refresh();if(selectedId)loadDetails();}
 onPageChanged:if(active)refresh()
 Process {id:inventory;command:['timeout','15s','@HOME@/.local/bin/sensei-docker'];stdout:StdioCollector {onStreamFinished:{try{let j=JSON.parse(text);for(let k of ['containers','images','networks','volumes','tasks','sessions','serial','arm','disk','compose'])if(j[k]&&!root.same(root[k],j[k]))root[k]=j[k];if(!root.same(root.data,j))root.data=j;if(j.error){root.message=j.error;root.success=false;}}catch(e){root.message=String(e);root.success=false;}}}}
 Process {id:details;stdout:StdioCollector {onStreamFinished:{if(root.detailKey!==root.selectedKey)return;try{let j=JSON.parse(text);root.detail=j;if(j.error){root.message=j.error;root.success=false;}}catch(e){root.message=String(e);}}}onExited:if(root.active&&root.detailKey!==root.selectedKey)Qt.callLater(root.loadDetails)}
 Process {id:operation;stdout:StdioCollector {onStreamFinished:{try{let j=JSON.parse(text);root.message=j.output||j.error||'Done.';root.success=j.ok!==false&&!j.error;}catch(e){root.message='The operation timed out or returned an invalid response.';root.success=false;}}}onExited:{root.refresh();if(root.selectedId)root.loadDetails();if(root.queue.length){let j=root.queue[0];root.queue=root.queue.slice(1);Qt.callLater(()=>root.action(j.name,j.args));}}}
 Process {command:['docker','events','--format','{{json .}}'];running:root.active;stdout:SplitParser {onRead:line=>eventDelay.restart()}}
 Timer {id:eventDelay;interval:350;onTriggered:{root.refresh();root.loadDetails();}}
 Timer {interval:3000;repeat:true;running:root.active&&(root.data.tasks||[]).some(t=>t.state==='running'||t.state==='queued');onTriggered:root.refresh()}
 Timer {interval:3000;repeat:true;running:root.active&&root.page===0&&root.detail.inspect?.State?.Running===true;onTriggered:root.loadDetails()}
 Component.onCompleted:if(active)refresh()
 IpcHandler {target:'dockerlab';function open():void{ShellState.dropdown='docker';}function page(index:int):void{root.page=Math.max(0,Math.min(7,index));}function state():string{return JSON.stringify({page:root.page,busy:root.busy,containers:root.data.containers.length,images:root.data.images.length,gpu:root.data.gpu,arm:root.data.arm,selected:root.selectedId,error:root.data.error||'',message:root.message});}}
}
