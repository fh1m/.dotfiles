pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
Singleton {
 id:root;property var previews:[];property bool opened:false;property string mode:"apps";property string query:"";property int selected:0;property bool pinned:false;property var mru:[];property var snapshot:[];property string sameClass:"";property string focusTitle:"";property int focusWorkspace:1;property string focusScreen:"eDP-1";property int focusStamp:0;property string lastFocusAddress:""
 property var showcaseHidden:[]
 readonly property var all:Hyprland.toplevels.values.filter(t=>(!Demo.active||!showcaseHidden.includes(root.addressFor(t)))&&t.wayland?.appId!=="wrayth-deck"&&t.workspace?.name!=="special:deck"&&t.workspace?.name!=="deck")
 property var pendingSelection:null
 function finishSelection(){const p=pendingSelection;pendingSelection=null;if(!p)return;if(p.kind==='window')Hyprland.dispatch('hl.dsp.focus({window='+JSON.stringify('address:'+p.address)+'})');else if(p.kind==='workspace')Hyprland.dispatch('hl.dsp.focus({workspace='+JSON.stringify(String(p.id))+'})');else if(p.kind==='app')executeApp(p.entry);}
 property var workspaceCards:[]
 property var dragWindow:null
 property real dragX:0
 property real dragY:0
 property int dragTarget:0
 function beginDrag(t,x,y){dragWindow=t;pinned=true;updateDrag(x,y);}
 function updateDrag(x,y){dragX=x;dragY=y;dragTarget=0;for(const card of workspaceCards){if(!card.visible)continue;const p=card.mapFromItem(null,x,y);if(p.x>=0&&p.y>=0&&p.x<card.width&&p.y<card.height){dragTarget=card.workspace;break;}}}
 function finishDrag(){const t=dragWindow,id=dragTarget;dragWindow=null;dragTarget=0;if(t&&id&&t.workspace?.id!==id)move(t,id);}
 function cancelDrag(){dragWindow=null;dragTarget=0;}
 function addressFor(t){return t?.address?(t.address.startsWith("0x")?t.address:"0x"+t.address):"";}
 function captureFor(t){if(t?.wayland)return t.wayland;return ToplevelManager.toplevels.values.find(w=>w.title===(t?.title||t?.lastIpcObject?.title)&&w.appId===t?.lastIpcObject?.class)??null;}

 onAllChanged:{if(opened)snapshot=snapshot.filter(t=>all.includes(t)).concat(all.filter(t=>!snapshot.includes(t)));}
 readonly property var matches:{let source=snapshot.filter(t=>all.includes(t));if(mode==='same')source=source.filter(t=>(t.wayland?.appId||t.lastIpcObject?.class||'')===sameClass);if(!query)return source;return source.filter(t=>Math.max(fuzzy(t.title),fuzzy(t.wayland?.appId||t.lastIpcObject?.class))>=0);}
 function fuzzy(text){const value=String(text||'').toLowerCase(),q=query.trim().toLowerCase();const normal=value.replace(/[^a-z0-9\u0400-\u04ff]/g,''),needle=q.replace(/[^a-z0-9\u0400-\u04ff]/g,'');let score=Math.max(Launcher.score(value,q),Launcher.score(normal,needle));if(score>=0&&value.includes(q))score+=80;if(score>=0&&value.startsWith(q))score+=40;return score;}
 function appScore(e){return Math.max(fuzzy(e.name),fuzzy(e.id),fuzzy(e.genericName)-10,fuzzy((e.keywords||[]).join(' '))-30);}

 readonly property var installed:(DesktopEntries.applications?.values??[]).filter(e=>!e.noDisplay&&appScore(e)>=0).sort((a,b)=>appScore(b)-appScore(a)||(Launcher.launches[b.id]??0)-(Launcher.launches[a.id]??0)||a.name.localeCompare(b.name))
 readonly property var apps:installed.slice(0,8)
 readonly property var searchResults:{if(!query.trim())return [];let results=matches.concat(installed);return results.sort((a,b)=>resultScore(b)-resultScore(a)||Number(isWindow(b))-Number(isWindow(a))||resultName(a).localeCompare(resultName(b)));}
 function isWindow(r){return !!r?.address;}
 function desktopEntryFor(r){
  if(!isWindow(r))return r;
  const normalize=v=>String(v||'').toLowerCase().replace(/\.desktop$/,'');
  const ids=[r.wayland?.appId,r.lastIpcObject?.class,r.lastIpcObject?.initialClass].map(normalize).filter(Boolean);
  const entries=DesktopEntries.applications?.values??[];
  return entries.find(e=>ids.includes(normalize(e.id))||ids.includes(normalize(e.startupClass)))
    ??entries.find(e=>ids.includes(normalize(e.command?.[0]?.split('/').pop())))??null;
 }
 function iconFor(r){
  const entry=desktopEntryFor(r),icon=entry?.icon||'';
  if(icon)return icon.startsWith('/')?'file://'+icon:Quickshell.iconPath(icon,true);
  if(isWindow(r))return Quickshell.iconPath(r.wayland?.appId||r.lastIpcObject?.class||'',true);
  return '';
 }
 function resultName(r){return isWindow(r)?(r.title||r.lastIpcObject?.class||'Window'):(r?.name||'Application');}
 function resultScore(r){return isWindow(r)?Math.max(fuzzy(r.title),fuzzy(r.lastIpcObject?.class)):appScore(r);}
 function selectResult(r){if(!r)return;if(isWindow(r))choose(r);else launch(r);}

 function open(kind,delta){if(opened){cycle(delta);return;}ShellState.closeAll();mode=kind;query="";pinned=true;sameClass=ActiveWindow.ipc?.class||"";snapshot=all.slice().sort((a,b)=>{let ai=mru.indexOf(a.address),bi=mru.indexOf(b.address);return (ai<0?999:ai)-(bi<0?999:bi);});selected=kind==='workspaces'?Spaces.activeId-1:0;opened=true;Hyprland.refreshToplevels();if(kind==='apps'||kind==='same')cycle(delta);}
 function cycle(delta){let count=query.trim()?searchResults.length:((mode==='workspaces'||mode==='overview')?6:matches.length);if(count)selected=(selected+delta+count)%count;}
 function cancel(){pendingSelection=null;cancelDrag();opened=false;query="";}
 function choose(t){if(!t?.address)return;pendingSelection={kind:'window',address:addressFor(t)};opened=false;}
 function workspace(id){pendingSelection={kind:'workspace',id:id};opened=false;}
 function commit(){if(!opened)return;if(query.trim()){selectResult(searchResults[selected]);return;}if(mode==='overview'){workspace(selected+1);return;}if(mode==='workspaces')workspace(selected+1);else if(mode==='apps'||mode==='same')choose(matches[selected]);}
 function move(t,id){pinned=true;Hyprland.dispatch('hl.dsp.window.move({window="address:'+addressFor(t)+'",workspace="'+id+'",follow=false})');Qt.callLater(()=>Hyprland.refreshToplevels());}
 function floatWindow(t){pinned=true;Hyprland.dispatch('hl.dsp.window.float({action="toggle",window="address:'+addressFor(t)+'"})');}
 function launch(e){pendingSelection={kind:'app',entry:e};opened=false;}
 function executeApp(e){Launcher.record(e.id);Deck.leave();if(e.runInTerminal)Quickshell.execDetached({command:["kitty","-e"].concat(Array.from(e.command)),workingDirectory:e.workingDirectory||Quickshell.env('HOME')});else e.execute();}
 function syncFocus(){let t=root.all.find(w=>w.lastIpcObject?.focusHistoryID===0);if(!t)return;const address=t.address;if(!address||address===root.lastFocusAddress)return;root.lastFocusAddress=address;mru=[address].concat(mru.filter(a=>a!==address)).slice(0,100);focusTitle=t.title||t.wayland?.appId||"Window";focusWorkspace=t.workspace?.id??1;focusScreen=t.monitor?.name??"eDP-1";focusStamp++;}
 Connections {target:Hyprland;function onActiveToplevelChanged(){root.syncFocus();}function onRawEvent(event){if(['openwindow','closewindow','movewindow','workspace','focusedmon'].includes(event.name))Hyprland.refreshToplevels();}}
 Connections {target:ActiveWindow;function onIpcChanged(){root.syncFocus();}}
 Component.onCompleted:Qt.callLater(syncFocus)
 Timer {interval:900;repeat:true;running:root.opened;onTriggered:Hyprland.refreshToplevels()}
}
