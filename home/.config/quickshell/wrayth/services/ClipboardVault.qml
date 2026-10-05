pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id: root
 property var items: []
 property var detail: ({})
 property int count: 0
 property int events: 0
 property int limit: 150
 property real bytes: 0
 property string query: ""
 property string filter: "all"
 property int selected: 0
 property string error: ""
 property bool refreshPending:false
 function refresh() { if (list.running) {refreshPending=true;return;} list.command=["/home/fh1m/.local/bin/clipboard-vault","list",query,filter,String(limit)];list.running=true; }
 function select(id) { selected=id;if(!preview.running)preview.running=true; }
 function action(name) { if (selected && !act.running) {act.command=["/home/fh1m/.local/bin/clipboard-vault",name,String(selected)];act.running=true;} }
 onQueryChanged: debounce.restart()
 onFilterChanged: refresh()
 Timer { id:debounce; interval:220; onTriggered:root.refresh() }
 FileView {path:"/home/fh1m/.clipboard/revision";watchChanges:true;printErrors:false;onFileChanged:{reload();if(ShellState.dropdown==="clipboard")debounce.restart();}}
 // FileView watches every vault revision; reopening an unchanged vault should
 // reuse its model instead of rebuilding the list and preview on every click.
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="clipboard" && root.items.length===0)root.refresh();}}
 Process { id:list; property string requestedQuery:"";property string requestedFilter:"all";onStarted:{requestedQuery=root.query;requestedFilter=root.filter;} stdout:StdioCollector { onStreamFinished: {try {if(list.requestedQuery!==root.query||list.requestedFilter!==root.filter){root.refreshPending=true;return;}let d=JSON.parse(text);root.items=d.items;root.count=d.count;root.events=d.events;root.bytes=d.bytes;if(!d.items.some(item=>item.id===root.selected)){root.selected=0;root.detail=({});if(d.items.length)root.select(d.items[0].id);}}catch(e){root.error=String(e);} } }onExited:if(root.refreshPending){root.refreshPending=false;Qt.callLater(root.refresh)} }
 Process { id:preview; property int requested:0; command:["/home/fh1m/.local/bin/clipboard-vault","detail",String(root.selected)];onStarted:requested=root.selected;stdout:StdioCollector { onStreamFinished: {try {if(preview.requested===root.selected)root.detail=JSON.parse(text);}catch(e){root.error=String(e);} } }onExited:if(requested!==root.selected)Qt.callLater(()=>preview.running=true) }
 Process { id:act;stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited: {root.refresh();if(root.selected && !preview.running)preview.running=true;} }
}
