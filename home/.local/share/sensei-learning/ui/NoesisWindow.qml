import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

FloatingWindow {
 id:win
 readonly property var studyDesk:secondaryDesk
 readonly property var workspacePage:content.item
 readonly property var applicationSurface:applicationContent
 function openSettings(){content.item.openSettings();}
 function beginRecord(kind,medium){content.item.beginRecord(kind,medium);}
 function focusTodayQuiet(){content.item.focusTodayQuiet();}
 function focusSourceRevision(){content.item.focusSourceRevision();}
 function pageAnnotations(cursor){content.item.loadAnnotations(cursor||null);}
 title:"Noesis — Learning workspace"
 visible:NoesisController.windowOpen
 fullscreen:NoesisController.presentationMode==="fullscreen"
 maximized:NoesisController.presentationMode==="workspace"
 color:NoesisStyle.canvas
 readonly property var mainScreen:Quickshell.screens.find(s=>s.name===NoesisController.mainMonitor)||Quickshell.screens[0]||null
 minimumSize:Qt.size(Math.min(500,(mainScreen?.width||1920)-40),Math.min(500,(mainScreen?.height||1080)-80))
 implicitWidth:Math.min(NoesisController.windowWidth,(mainScreen?.width||1920)-40)
 implicitHeight:Math.min(NoesisController.windowHeight,(mainScreen?.height||1080)-80)
 screen:mainScreen
 Connections {target:NoesisController;function onPresentationModeChanged(){win.presentationRetries=0;win.nativeStateRetries=0;win.presentationReady=false;win.applyPresentation();}function onOpenSerialChanged(){win.minimized=false;focusDelay.restart();}function onFinished(ok){if(ok&&NoesisController.operationVault===NoesisController.activeVault&&NoesisController.specialistHandoff&&NoesisController.presentationMode!=="tiled"&&NoesisController.returnBehavior==="hide"){if(!NoesisController.legacyInterface)content.item.stashDraft();NoesisController.close();}}}
 NoesisStudyDesk {id:secondaryDesk;workspace:content.item}
 onClosed:NoesisController.requestExit()
 onVisibleChanged:if(visible){presentationRetries=0;presentationReady=false;focusDelay.restart();}
 onWidthChanged:if(visible&&presentationReady&&modeSteps.length===0&&NoesisController.presentationMode==="normal"){saveGeometry.restart();}
 onHeightChanged:if(visible&&presentationReady&&modeSteps.length===0&&NoesisController.presentationMode==="normal"){saveGeometry.restart();}
 property string windowAddress:""
 property real compositorScale:1
 property bool presentationReady:false
 property var modeSteps:[]
 property int modeStep:0
 property bool presentationPending:false
 property int presentationRetries:0
 property int nativeStateRetries:0
 function nextModeStep(){if(modeStep>=modeSteps.length){modeSteps=[];presentationCheck.running=true;if(presentationPending){presentationPending=false;applyPresentation();}return;}modeDispatch.command=modeSteps[modeStep];modeDispatch.running=true;}
 function applyPresentation(){
  presentationReady=false;
  if(!windowAddress){clientLookup.running=true;return;}
  if(modeDispatch.running||modeSteps.length||nativeStateCheck.running){presentationPending=true;return;}
  nativeStateCheck.running=true;
 }
 function dispatchPresentation(){
  let target='window="address:'+windowAddress+'"';
  modeSteps=[["hyprctl","dispatch",'hl.dsp.window.float({action="'+(NoesisController.presentationMode==="tiled"?"disable":"enable")+'",'+target+'})']];
  if(NoesisController.presentationMode==="normal")modeSteps.push(["hyprctl","dispatch",'hl.dsp.window.resize({x='+Math.round(win.implicitWidth)+',y='+Math.round(win.implicitHeight)+',relative=false,'+target+'})']);
  if(NoesisController.presentationMode==="normal")modeSteps.push(["hyprctl","dispatch",'hl.dsp.window.center({'+target+'})']);
  modeStep=0;nextModeStep();
 }
 Timer {id:focusDelay;interval:300;onTriggered:clientLookup.running=true}
 Process {id:clientLookup;command:["hyprctl","clients","-j"]
  stdout:StdioCollector {onStreamFinished:{try{let client=JSON.parse(text).find(c=>c.pid===Quickshell.processId&&c.title===win.title);if(!client){NoesisController.error="Noesis window is not yet available to the compositor.";return;}win.windowAddress=client.address;win.applyPresentation();Quickshell.execDetached(["hyprctl","dispatch",'hl.dsp.focus({window="address:'+win.windowAddress+'"})']);}catch(error){NoesisController.error="Window discovery failed: "+String(error);}}}
 }
 Process {id:nativeStateCheck;command:["hyprctl","clients","-j"]
  stdout:StdioCollector {onStreamFinished:{try{let c=JSON.parse(text).find(c=>c.address===win.windowAddress);let expected=NoesisController.presentationMode==="fullscreen"?2:NoesisController.presentationMode==="workspace"?1:0;if(c&&c.fullscreen===expected){win.nativeStateRetries=0;win.dispatchPresentation();}else if(win.nativeStateRetries++<10){nativeStateRetry.restart();}else NoesisController.error="Qt's requested window state was not acknowledged by the compositor.";}catch(error){NoesisController.error="Native window state could not be verified.";}}}
 }
 Timer {id:nativeStateRetry;interval:100;onTriggered:nativeStateCheck.running=true}
 Process {id:modeDispatch;onExited:code=>{if(code===0){win.modeStep++;Qt.callLater(()=>win.nextModeStep());}else{win.modeSteps=[];NoesisController.error="Window presentation could not be applied by the compositor.";}}}
 Process {id:presentationCheck;command:["hyprctl","clients","-j"]
  stdout:StdioCollector {onStreamFinished:{try{let c=JSON.parse(text).find(c=>c.address===win.windowAddress);let ready=c&&c.floating===(NoesisController.presentationMode!=="tiled")&&c.fullscreen===(NoesisController.presentationMode==="fullscreen"?2:NoesisController.presentationMode==="workspace"?1:0);if(ready&&NoesisController.presentationMode==="normal")ready=Math.abs(c.size[0]-win.implicitWidth)<5&&Math.abs(c.size[1]-win.implicitHeight)<5;if(ready){win.presentationReady=true;win.presentationRetries=0;}else if(win.presentationRetries++<3){presentationRetry.restart();}else{NoesisController.error="The compositor did not apply the requested window mode.";}}catch(error){NoesisController.error="Window mode verification failed: "+String(error);}}}
 }
 Timer {id:presentationRetry;interval:250;onTriggered:win.applyPresentation()}
 Timer {id:saveGeometry;interval:600;onTriggered:if(win.presentationReady&&NoesisController.presentationMode==="normal"){NoesisController.windowWidth=win.width;NoesisController.windowHeight=win.height;NoesisController.savePreferences();}}

 Shortcut {sequence:"Ctrl+Alt+M";onActivated:{let modes=["normal","fullscreen","workspace","tiled"];NoesisController.presentationMode=modes[(modes.indexOf(NoesisController.presentationMode)+1)%modes.length];NoesisController.savePreferences();win.applyPresentation();}}
 ColumnLayout {id:applicationContent;objectName:"noesisApplicationContent";readonly property real qtDpr:Screen.devicePixelRatio
  anchors.fill:parent;spacing:0
  Rectangle {visible:!content.item?.focusMode;Layout.fillWidth:true;Layout.preferredHeight:Math.max(48,NoesisStyle.control+8);color:NoesisStyle.surface
   RowLayout {anchors.fill:parent;anchors.leftMargin:16;anchors.rightMargin:12;spacing:12
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Noesis";MouseArea {anchors.fill:parent;acceptedButtons:Qt.LeftButton;onPressed:win.startSystemMove()}color:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;font.bold:true}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:win.width>=1400*NoesisStyle.interfaceScale;text:"Learning, research and engineering";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true}
    NoesisButton {visible:false;text:NoesisController.legacyInterface?"Connected":"Previous UI";onClicked:{NoesisController.legacyInterface=!NoesisController.legacyInterface;NoesisController.refresh();}}
    Item {Layout.fillWidth:true;visible:win.width<1400*NoesisStyle.interfaceScale}
    NoesisButton {variant:"tertiary";text:"Window";visible:win.width<700*NoesisStyle.interfaceScale;onClicked:windowActions.begin([{action:"settings",label:"Settings"},{action:"hide",label:"Hide and preserve context"},{action:"close",label:"Close application"},{action:"desk",label:secondaryDesk.enabledByUser?"Free ScreenPad for tools":"Show Study desk"}])}
    NoesisButton {variant:"tertiary";visible:secondaryDesk.deskScreen!==null&&NoesisController.standalone&&NoesisController.presentationMode==="fullscreen"&&win.width>=900*NoesisStyle.interfaceScale;text:secondaryDesk.enabledByUser?"Free ScreenPad":"Show Study desk";onClicked:{secondaryDesk.enabledByUser=!secondaryDesk.enabledByUser;secondaryDesk.saveLayout();}}
    NoesisButton {variant:"tertiary";visible:win.width>=700*NoesisStyle.interfaceScale;text:"Settings";onClicked:content.item.openSettings()}
    NoesisButton {variant:"tertiary";visible:win.width>=700*NoesisStyle.interfaceScale;text:"Hide";onClicked:{if(!NoesisController.legacyInterface)content.item.stashDraft();NoesisController.close();}}
    NoesisSelect {visible:win.width>=1200*NoesisStyle.interfaceScale;model:["Full screen","Maximized","Tiled","Window"];currentIndex:["fullscreen","workspace","tiled","normal"].indexOf(NoesisController.presentationMode);Accessible.name:"Window presentation";onActivated:{NoesisController.presentationMode=["fullscreen","workspace","tiled","normal"][currentIndex];NoesisController.savePreferences();win.applyPresentation();}}

    NoesisButton {variant:"tertiary";visible:win.width>=700*NoesisStyle.interfaceScale;text:NoesisController.exitRequested?"Finishing…":"Close";onClicked:NoesisController.requestExit()}
   }
  }
  Loader {id:content;Layout.fillWidth:true;Layout.fillHeight:true;sourceComponent:connected}
  Component {id:connected;NoesisWorkspace {sourceOnSecondDisplay:secondaryDesk.visible&&secondaryDesk.hasSource}}
 }
 NoesisActionDialog {id:windowActions;onVisibleChanged:if(content.item)content.item.windowLayerOpen=visible;parent:content.item;anchors.centerIn:parent;width:Math.min(560,win.width-32);height:Math.min(480,win.height-32);title:"Window";onChosen:action=>{if(action==="desk"){secondaryDesk.enabledByUser=!secondaryDesk.enabledByUser;secondaryDesk.saveLayout();}else if(action==="settings")content.item.openSettings();else if(action==="hide")NoesisController.hide();else if(action==="close")NoesisController.requestExit();}}
 IpcHandler {target:"noesis-window";function state():string{return JSON.stringify({qt_device_pixel_ratio:applicationContent.qtDpr,compositor_scale:win.compositorScale,interface_scale:NoesisStyle.interfaceScale,reading_scale:NoesisStyle.readingScale,course_id:content.item.courseRecord.id||"",practice_thinking:content.item.practiceThinking,statement_height:content.item.statementHeight,reasoning_viewport_height:content.item.reasoningViewportHeight,practice_viewport_height:content.item.practiceViewportHeight,practice_scroll_fraction:content.item.practiceScrollFraction,visible:win.visible,minimized:win.minimized,width:win.width,height:win.height,screen:win.screen?.name,section:content.item.section,vault:NoesisController.activeVault,collection:content.item.collectionScope||false,draft_length:content.item.selected.id?(NoesisController.drafts[NoesisController.activeVault+":"+content.item.selected.id]||"").length:0,presentation:NoesisController.presentationMode,window_address:windowAddress,mode_pending:nativeStateCheck.running||nativeStateRetry.running||modeDispatch.running||modeSteps.length>0||presentationPending||!presentationReady,selected:content.item.selected.path||"",rows:content.item.rows.length,reference_hidden:content.item.referenceHidden,worker:content.item.coreRunning||false,watch:content.item.watchRunning||false,preview_length:content.item.previewLength||0,context_tab:content.item.contextTab||"",read_scroll_fraction:content.item.readScrollFraction||0,read_viewport_height:content.item.readViewportHeight||0,read_content_height:content.item.readContentHeight||0,outline_rows:content.item.outlineRows?.length||0,expanded_module_rows:content.item.expandedModuleRows,outline_import_open:content.item.outlineImportOpen||false,check_open:content.item.checkOpen||false,check_stage:content.item.checkStageName||"",check_purpose_length:content.item.checkPurposeLength||0,check_focused:content.item.checkFocused||false,outline_editing:content.item.outlineEditing||false,outline_index:content.item.outlineIndex,outline_focused:content.item.outlineFocused||false,loaded_figures:content.item.loadedFigures||0,experiment:content.item.workflow?.kind==="experiment"?content.item.workflow:null,context_actions:content.item.contextActions?content.item.contextActions().map(action=>action.action):[],learning_context:content.item.learningContext||{},overview_counts:content.item.workflow?.counts||null,priority_open:content.item.priorityOpen||false,pinned:content.item.selectedState?.pin||false,manual_priority:content.item.selectedState?.manual_priority||"normal",today:content.item.home||{},source_revision:content.item.workflow?.source_version??null,historical_snapshot:content.item.workflow?.historical_snapshot||false,source_revisions:content.item.sourceRevisions||[],annotation_count:content.item.workflow?.annotation_count||0,annotation_ids:(content.item.workflow?.annotations||[]).map(row=>row.native_id),annotation_cursor:content.item.workflow?.cursor||"",annotation_newer_cursor:content.item.workflow?.newer_cursor||"",cursor:content.item.cursor||"",attempt:content.item.activeAttempt||"",capture_length:content.item.captureLength||0,reported_outcome:content.item.reportedOutcome||"unknown",declared_assistance:content.item.declaredAssistance||"unknown",error:NoesisController.error,message:NoesisController.message,working:NoesisController.working,capture_open:content.item.captureOpen||false,capture_focused:content.item.captureFocused||false,search_focused:content.item.searchFocused||false,inspector:content.item.inspectorVisible||false});}function more():void{if(!NoesisController.legacyInterface&&content.item.cursor)content.item.load(true);}function section(name:string):void{content.item.section=name;}function select(path:string):void{let n=(content.item.rows||NoesisController.state.notes||[]).find(x=>x.path===path);if(n){if(NoesisController.legacyInterface){content.item.selected=n;NoesisController.preview(path);}else content.item.select(n);}}}
}
