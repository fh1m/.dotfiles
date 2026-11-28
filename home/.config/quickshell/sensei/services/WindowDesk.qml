pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import qs.config
Singleton {
 id:root;property var previews:[];property bool opened:false;property string mode:"apps";property string query:"";property int selected:0;property bool pinned:false;property var mru:[];property var snapshot:[];property string sameClass:"";property string focusTitle:"";property int focusWorkspace:1;property string focusScreen:"eDP-1";property int focusStamp:0;property string lastFocusAddress:""
 property var showcaseHidden:[]
 // Freezes the previews while the overlay is open. Global, not per screen: the
 // navigationview IPC answers for the whole shell.
 property bool previewPaused:false
 readonly property var all:Hyprland.toplevels.values.filter(t=>(!Demo.active||!showcaseHidden.includes(root.addressFor(t)))&&t.wayland?.appId!=="sensei-deck"&&t.workspace?.name!=="special:deck"&&t.workspace?.name!=="deck")
 readonly property var workspaceIds: Spaces.workspaceIds.concat(Array.from(new Set(all.map(t=>t.workspace?.id).filter(id=>Number.isInteger(id)&&id<0))).sort((a,b)=>b-a))
 property string displayFilter:""
 readonly property var displays: Spaces.outputState.filter(m=>ShellState.screens.some(s=>s.name===m.name))
 function displayOf(t){return t.monitor?.name||displays.find(m=>m.id===t.lastIpcObject?.monitor)?.name||"";}
 function displayLabel(name){
    if(!name)return "Unknown display";
    const role=MachineProfile.role(name);
    if(name===MachineProfile.primaryOutput)return MachineProfile.desktop?"Main":"OLED";
    return ({screenpad:"ScreenPad",upper:"Upper",lower:"Lower"})[role]||name;
 }
 readonly property var scopedWindows: displayFilter?all.filter(t=>displayOf(t)===displayFilter):all
 readonly property var displayedWorkspaceIds: displayFilter ? (MachineProfile.role(displayFilter)==="screenpad" ? [...new Set([Spaces.logicalId(displays.find(m=>m.name===displayFilter)?.activeWorkspace?.id??90),...scopedWindows.map(t=>Spaces.logicalId(Spaces.windowWorkspace(t)))])] : Spaces.workspaceIds.concat(workspaceIds.filter(id=>id<0&&scopedWindows.some(t=>Spaces.windowWorkspace(t)===id)))) : workspaceIds
 function selectDisplay(name){
    if(name&&!displays.some(m=>m.name===name))return;
    displayFilter=name;
    const here=displays.find(m=>m.name===(name||ShellState.overlayScreenName));
    selected=(mode==="overview"||mode==="workspaces")&&!query.trim()?Math.max(0,displayedWorkspaceIds.indexOf(Spaces.logicalId(here?.activeWorkspace?.id??Spaces.activeId))):0;
 }
 function cycleDisplay(){const names=["",...displays.map(m=>m.name)];selectDisplay(names[(names.indexOf(displayFilter)+1)%names.length]);}
 onDisplaysChanged:if(displayFilter&&!displays.some(m=>m.name===displayFilter))selectDisplay("");
 function workspaceTitle(id){if(id===90)return "Utility";if(id>0)return Spaces.workspaceNames[Spaces.logicalId(id)-1]||String(id);const name=scopedWindows.find(t=>t.workspace?.id===id)?.workspace?.name||"Special";return Spaces.labelFor(name.replace(/^special:/,""));}
 property var pendingSelection:null
 function finishSelection(){
    const p=pendingSelection;pendingSelection=null;if(!p)return;
    if(p.kind==='window'){Hyprland.dispatch('hl.dsp.focus({window='+JSON.stringify('address:'+p.address)+'})');return;}
    if(p.kind==='app'){executeApp(p.entry);return;}
    if(p.kind!=='workspace')return;
    if(p.id>0){
        const output=p.output||ShellState.overlayScreens[0]?.name||ShellState.focusedScreenName();
        if(p.output&&MachineProfile.role(output)==="screenpad"){Hyprland.dispatch('hl.dsp.focus({monitor='+JSON.stringify(output)+'})');return;}
        if(output)Quickshell.execDetached([Quickshell.env('HOME')+'/.local/bin/sensei-displays','workspace',String(p.id),output].concat(p.output?['--only']:[]));
    }else{
        const t=all.find(w=>(!p.output||displayOf(w)===p.output)&&w.workspace?.id===p.id);
        if(t)Hyprland.dispatch('hl.dsp.focus({window='+JSON.stringify('address:'+addressFor(t))+'})');
    }
 }
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
 readonly property var matches:{let source=snapshot.filter(t=>scopedWindows.includes(t));if(mode==='same')source=source.filter(t=>(t.wayland?.appId||t.lastIpcObject?.class||'')===sameClass);if(!query)return source;return source.filter(t=>Math.max(fuzzy(t.title),fuzzy(t.wayland?.appId||t.lastIpcObject?.class))>=0);}
 function fuzzy(text){const value=String(text||'').toLowerCase(),q=query.trim().toLowerCase();const normal=value.replace(/[^a-z0-9\u0400-\u04ff]/g,''),needle=q.replace(/[^a-z0-9\u0400-\u04ff]/g,'');let score=Math.max(Launcher.score(value,q),Launcher.score(normal,needle));if(score>=0&&value.includes(q))score+=80;if(score>=0&&value.startsWith(q))score+=40;return score;}
 function appScore(e){return Math.max(fuzzy(e.name),fuzzy(e.id),fuzzy(e.genericName)-10,fuzzy((e.keywords||[]).join(' '))-30);}

 readonly property var installed:!opened ? [] : (DesktopEntries.applications?.values??[]).filter(e=>!e.noDisplay).map(entry=>({entry,score:query.trim()?appScore(entry):0})).filter(row=>row.score>=0).sort((a,b)=>b.score-a.score||(Launcher.launches[b.entry.id]??0)-(Launcher.launches[a.entry.id]??0)||a.entry.name.localeCompare(b.entry.name)).map(row=>row.entry)
 readonly property var apps:installed.slice(0,8)
 readonly property var searchResults:{if(!query.trim())return [];return matches.concat(installed).map(result=>({result,score:resultScore(result)})).sort((a,b)=>b.score-a.score||Number(isWindow(b.result))-Number(isWindow(a.result))||resultName(a.result).localeCompare(resultName(b.result))).map(row=>row.result);}
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

 function open(kind,delta){
    if(opened&&kind===mode){if(delta)cycle(delta);return;}
    if(!opened){ShellState.closeAll();ShellState.overlayScreenName=ShellState.focusedScreenName();displayFilter="";}
    pendingSelection=null;mode=kind;query="";pinned=true;sameClass=ActiveWindow.ipc?.class||"";
    const ranks=new Map(mru.map((address,index)=>[address,index]));
    snapshot=all.slice().sort((a,b)=>(ranks.get(a.address)??999)-(ranks.get(b.address)??999));
    selectDisplay(displayFilter);
    opened=true;
    if(kind==='apps'||kind==='same')cycle(delta);
 }
 function cycle(delta){let count=query.trim()?searchResults.length:((mode==='workspaces'||mode==='overview')?root.displayedWorkspaceIds.length:matches.length);if(count)selected=(selected+delta+count)%count;}
 function cancel(){pendingSelection=null;cancelDrag();opened=false;query="";}
 function choose(t){if(!t?.address)return;pendingSelection={kind:'window',address:addressFor(t)};opened=false;}
 function workspace(id){if(!Number.isInteger(id))return;pendingSelection={kind:'workspace',id:id,output:displayFilter};opened=false;}
 function commit(){if(!opened)return;if(query.trim()){selectResult(searchResults[selected]);return;}if(mode==='overview'||mode==='workspaces')workspace(root.displayedWorkspaceIds[selected]);else if(mode==='apps'||mode==='same')choose(matches[selected]);}
 function move(t,id){pinned=true;Quickshell.execDetached([Quickshell.env('HOME')+'/.local/bin/sensei-displays','move',String(id),addressFor(t)]);Qt.callLater(()=>Hyprland.refreshToplevels());}
 function floatWindow(t){pinned=true;Hyprland.dispatch('hl.dsp.window.float({action="toggle",window="address:'+addressFor(t)+'"})');}
 function launch(e){pendingSelection={kind:'app',entry:e};opened=false;}
 function executeApp(e){Launcher.record(e.id);Deck.leave();Launcher.launchEntry(e);}
 function syncFocus(){let t=root.all.find(w=>w.lastIpcObject?.focusHistoryID===0);if(!t)return;const address=t.address;if(!address||address===root.lastFocusAddress)return;root.lastFocusAddress=address;mru=[address].concat(mru.filter(a=>a!==address)).slice(0,100);focusTitle=t.title||t.wayland?.appId||"Window";focusWorkspace=t.workspace?.id??1;focusScreen=t.monitor?.name??"eDP-1";focusStamp++;}
 property string newlyOpened:""
 Timer {id:groupDelay;interval:300;onTriggered:{if(autoGroup.running){restart();return;}if(!autoGroup.running){autoGroup.command=[Quickshell.env('HOME')+'/.local/bin/sensei-tabs','auto',root.newlyOpened];autoGroup.running=true;}}}
 Process {id:autoGroup;onExited:Hyprland.refreshToplevels()}
 Connections {target:Hyprland;function onActiveToplevelChanged(){root.syncFocus();}function onRawEvent(event){if(event.name==='moveoutofgroup'||(event.name==='togglegroup'&&String(event.data||'').startsWith('0,'))){const parts=String(event.data||'').split(',');Quickshell.execDetached([Quickshell.env('HOME')+'/.local/bin/sensei-tabs','pause',parts[parts.length-1]]);}if(event.name==='workspace'||event.name==='closewindow'){root.newlyOpened='';groupDelay.restart();}if(['openwindow','movewindow','movewindowv2'].includes(event.name)){root.newlyOpened=String(event.data||'').split(',')[0];groupDelay.restart();}if(['openwindow','closewindow','movewindow','workspace','focusedmon'].includes(event.name))Hyprland.refreshToplevels();}}
 Connections {target:ActiveWindow;function onIpcChanged(){root.syncFocus();}}
 Component.onCompleted:Qt.callLater(syncFocus)
 Timer {interval:900;running:true;onTriggered:{Hyprland.refreshToplevels();Hyprland.refreshMonitors();root.syncFocus();}}
}
