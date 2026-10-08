import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
import "../dropdowns" as Content

FloatingWindow {
 id:win
 title:"Noesis — Learning workspace"
 visible:Oasis.windowOpen
 color:NoesisStyle.canvas
 readonly property var mainScreen:Quickshell.screens.find(s=>s.name===Oasis.mainMonitor)||Quickshell.screens[0]||null
 minimumSize:Qt.size(Math.min(1000,(mainScreen?.width||1920)-40),Math.min(650,(mainScreen?.height||1080)-80))
 implicitWidth:Math.min(Oasis.windowWidth,(mainScreen?.width||1920)-40)
 implicitHeight:Math.min(Oasis.windowHeight,(mainScreen?.height||1080)-80)
 screen:mainScreen
 Connections {target:Oasis;function onOpenSerialChanged(){win.minimized=false;focusDelay.restart();}}
 onClosed:Oasis.close()
 onVisibleChanged:if(visible){presentationReady=false;focusDelay.restart();}
 onWidthChanged:if(visible&&presentationReady&&modeSteps.length===0&&Oasis.presentationMode==="normal"){Oasis.windowWidth=width;saveGeometry.restart();}
 onHeightChanged:if(visible&&presentationReady&&modeSteps.length===0&&Oasis.presentationMode==="normal"){Oasis.windowHeight=height;saveGeometry.restart();}
 property string windowAddress:""
 property real compositorScale:1
 property bool presentationReady:false
 property var modeSteps:[]
 property int modeStep:0
 property bool presentationPending:false
 property int presentationRetries:0
 function nextModeStep(){if(modeStep>=modeSteps.length){modeSteps=[];presentationCheck.running=true;if(presentationPending){presentationPending=false;applyPresentation();}return;}modeDispatch.command=modeSteps[modeStep];modeDispatch.running=true;}
 function applyPresentation(){
  if(!windowAddress){clientLookup.running=true;return;}
  if(modeDispatch.running||modeSteps.length){presentationPending=true;return;}
  let target='window="address:'+windowAddress+'"';
  modeSteps=[["hyprctl","dispatch",'hl.dsp.window.fullscreen({mode="maximized",action="unset",'+target+'})'],["hyprctl","dispatch",'hl.dsp.window.float({action="'+(Oasis.presentationMode==="tiled"?"unset":"set")+'",'+target+'})']];
  if(Oasis.presentationMode==="workspace")modeSteps.push(["hyprctl","dispatch",'hl.dsp.window.fullscreen({mode="maximized",action="set",'+target+'})']);
  if(Oasis.presentationMode==="normal")modeSteps.push(["hyprctl","dispatch",'hl.dsp.window.resize({x='+Math.round(win.implicitWidth*compositorScale)+',y='+Math.round(win.implicitHeight*compositorScale)+',relative=false,'+target+'})']);
  modeStep=0;nextModeStep();
 }
 Timer {id:focusDelay;interval:300;onTriggered:clientLookup.running=true}
 Process {id:clientLookup;command:["hyprctl","clients","-j"]
  stdout:StdioCollector {onStreamFinished:{try{let client=JSON.parse(text).find(c=>c.pid===Quickshell.processId&&c.title===win.title);if(!client){Oasis.error="Noesis window is not yet available to the compositor.";return;}win.windowAddress=client.address;win.compositorScale=client.size[0]/Math.max(1,win.width);win.applyPresentation();Quickshell.execDetached(["hyprctl","dispatch",'hl.dsp.focus({window="address:'+client.address+'"})']);}catch(error){Oasis.error="Window discovery failed: "+String(error);}}}
 }
 Process {id:modeDispatch;onExited:code=>{if(code===0){win.modeStep++;Qt.callLater(()=>win.nextModeStep());}else{win.modeSteps=[];Oasis.error="Window presentation could not be applied by the compositor.";}}}
 Process {id:presentationCheck;command:["hyprctl","clients","-j"]
  stdout:StdioCollector {onStreamFinished:{try{let c=JSON.parse(text).find(c=>c.address===win.windowAddress);let ready=c&&c.floating===(Oasis.presentationMode!=="tiled")&&((c.fullscreen===1)===(Oasis.presentationMode==="workspace"));if(ready){win.presentationReady=true;win.presentationRetries=0;}else if(win.presentationRetries++<3){presentationRetry.restart();}else{Oasis.error="The compositor did not apply the requested window mode.";}}catch(error){Oasis.error="Window mode verification failed: "+String(error);}}}
 }
 Timer {id:presentationRetry;interval:250;onTriggered:win.applyPresentation()}
 Timer {id:saveGeometry;interval:600;onTriggered:if(win.presentationReady&&Oasis.presentationMode==="normal")geometryWrite.running=true}
 Process {id:geometryWrite;command:["@HOME@/.local/bin/noesis","window-state","--width",String(Oasis.windowWidth),"--height",String(Oasis.windowHeight)]}
 Shortcut {sequence:"Ctrl+Alt+M";onActivated:{let modes=["normal","workspace","tiled"];Oasis.presentationMode=modes[(modes.indexOf(Oasis.presentationMode)+1)%3];Oasis.savePreferences();win.applyPresentation();}}
 ColumnLayout {
  anchors.fill:parent;spacing:0
  Rectangle {Layout.fillWidth:true;Layout.preferredHeight:42;color:Theme.widgetSurface
   RowLayout {anchors.fill:parent;anchors.leftMargin:16;anchors.rightMargin:12;spacing:12
    Text {text:"Noesis";color:Theme.widgetAccent;font.family:NoesisStyle.uiFont;font.pixelSize:18;font.bold:true}
    Text {text:"Learning, research and engineering";color:Theme.widgetMuted;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true}
    NoesisButton {visible:Quickshell.env("NOESIS_DEVELOPMENT")==="1";text:Oasis.legacyInterface?"Connected":"Previous UI";onClicked:{Oasis.legacyInterface=!Oasis.legacyInterface;Oasis.refresh();}}
    NoesisButton {text:"Minimize";onClicked:win.minimized=true}
    NoesisSelect {model:["Workspace","Tiled","Window"];currentIndex:["workspace","tiled","normal"].indexOf(Oasis.presentationMode);Accessible.name:"Window presentation";onActivated:{Oasis.presentationMode=["workspace","tiled","normal"][currentIndex];Oasis.savePreferences();win.applyPresentation();}}

    NoesisButton {text:"Close";onClicked:Oasis.close()}
   }
   MouseArea {anchors.fill:parent;anchors.rightMargin:340;acceptedButtons:Qt.LeftButton;onPressed:win.startSystemMove()}
  }
  Loader {id:content;Layout.fillWidth:true;Layout.fillHeight:true;sourceComponent:Oasis.legacyInterface?previous:connected}
  Component {id:previous;Content.OasisDropdown {chamfer:0}}
  Component {id:connected;NoesisWorkspace {}}
 }
 IpcHandler {target:"noesis-window";function state():string{return JSON.stringify({visible:win.visible,width:win.width,height:win.height,screen:win.screen?.name,section:content.item.section,vault:Oasis.activeVault,collection:content.item.collectionScope||false,draft_length:content.item.selected.id?(Oasis.drafts[Oasis.activeVault+":"+content.item.selected.id]||"").length:0,presentation:Oasis.presentationMode,window_address:windowAddress,mode_pending:modeDispatch.running,selected:content.item.selected.path||"",rows:content.item.rows.length,reference_hidden:content.item.referenceHidden,worker:content.item.coreRunning||false,watch:content.item.watchRunning||false,preview_length:content.item.previewLength||0,context_tab:content.item.contextTab||"",read_viewport_height:content.item.readViewportHeight||0,read_content_height:content.item.readContentHeight||0,overview_counts:content.item.workflow?.counts||null,cursor:content.item.cursor||"",attempt:content.item.activeAttempt||"",capture_length:content.item.captureLength||0,reported_outcome:content.item.reportedOutcome||"unknown",declared_assistance:content.item.declaredAssistance||"unknown",error:Oasis.error,message:Oasis.message,working:Oasis.working,capture_open:content.item.captureOpen||false,capture_focused:content.item.captureFocused||false,search_focused:content.item.searchFocused||false,inspector:content.item.inspectorVisible||false});}function more():void{if(!Oasis.legacyInterface&&content.item.cursor)content.item.load(true);}function section(name:string):void{content.item.section=name;}function select(path:string):void{let n=(content.item.rows||Oasis.state.notes||[]).find(x=>x.path===path);if(n){if(Oasis.legacyInterface){content.item.selected=n;Oasis.preview(path);}else content.item.select(n);}}}
}
