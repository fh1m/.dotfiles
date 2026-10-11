import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Configurable views of one adapter; no second learning worker or draft store.
PanelWindow {
 id:desk
 readonly property var applicationSurface:deskSurface
 property var workspace:null
 property alias view:leftPane.view
 property int frameSerial:0
 function requestFrame(){repaint.restart();}
 Timer {id:repaint;interval:16;onTriggered:deskSurface.Window.window?.update()}
 Connections {target:deskSurface.Window.window;function onFrameSwapped(){desk.frameSerial++;}}
 Connections {target:desk.workspace;function onSelectedChanged(){desk.requestFrame();}function onDocumentPreviewChanged(){desk.requestFrame();}function onWorkflowChanged(){desk.requestFrame();}function onReferenceHiddenChanged(){desk.requestFrame();}}
 Connections {target:desk.workspace?.evidence;function onTextChanged(){desk.requestFrame();}}
 property bool split:true
 property bool enabledByUser:true
 readonly property bool hasSource:!leftPane.isKept&&leftPane.view==="source"||(split&&!rightPane.isKept&&rightPane.view==="source")
 readonly property var deskScreen:Quickshell.screens.find(s=>s.name!==NoesisController.mainMonitor&&s.name==="DP-2")||null
 readonly property var studyMonitor:Hyprland.monitors.values.find(m=>m.name===NoesisController.mainMonitor)||null
 readonly property string activeWorkspace:studyMonitor?.lastIpcObject?.activeWorkspace?.name||studyMonitor?.activeWorkspace?.name||""
 Connections {target:Hyprland;function onRawEvent(event:HyprlandEvent):void{if(["workspace","focusedmon","moveworkspace","renameworkspace","monitoradded","monitorremoved"].includes(event.name)){Hyprland.refreshWorkspaces();Hyprland.refreshMonitors();}}}
 readonly property bool fixture:Quickshell.env("NOESIS_STUDY_DESK_FIXTURE")==="1"
 function restoreLayout(){let p=NoesisController.layouts.StudyDesk||{};for(let pair of [[leftPane,p.left_kept],[rightPane,p.right_kept]]){let value=pair[1];if(value?.version===1&&typeof value.id==="string"&&typeof value.vault==="string"&&typeof value.vault_id==="string"){pair[0].kept=value;pair[0].keptAnchors=(pair[0]===leftPane?p.left_kept_anchors:p.right_kept_anchors)||({source:0,context:0,figures:0});}}if(leftPane.surfaces.includes(p.left_view))leftPane.view=p.left_view;if(rightPane.surfaces.includes(p.right_view))rightPane.view=p.right_view;if(typeof p.split==="boolean")split=p.split;if(typeof p.enabled==="boolean")enabledByUser=p.enabled;}
 function saveLayout(){NoesisController.layouts=Object.assign({},NoesisController.layouts,{StudyDesk:{left_view:leftPane.view,right_view:rightPane.view,left_kept:leftPane.kept,right_kept:rightPane.kept,left_kept_anchors:leftPane.keptAnchors,right_kept_anchors:rightPane.keptAnchors,split:split,enabled:enabledByUser,ratio:desk.visible&&panes.width>0?Math.min(.75,Math.max(.25,leftPane.width/panes.width)):(NoesisController.layouts.StudyDesk?.ratio||.5)}});NoesisController.savePreferences();}
 Component.onCompleted:if(NoesisController.preferencesReady)restoreLayout()
 Connections {target:NoesisController;function onPreferencesReadyChanged(){if(NoesisController.preferencesReady)desk.restoreLayout();}function onFlushRequested(){leftPane.flushLayout();rightPane.flushLayout();desk.saveLayout();}}
 screen:deskScreen
 visible:enabledByUser&&NoesisController.standalone&&(NoesisController.windowOpen||NoesisController.toolHandoffOpen)&&NoesisController.presentationMode==="fullscreen"&&deskScreen!==null&&(fixture||activeWorkspace===NoesisController.studyWorkspace)
 anchors {top:true;bottom:true;left:true;right:true}
 exclusionMode:ExclusionMode.Ignore
 WlrLayershell.layer:WlrLayer.Overlay
 WlrLayershell.namespace:"noesis-study-desk"
 WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
 color:NoesisStyle.canvas
 Rectangle {id:deskSurface;anchors.fill:parent;color:NoesisStyle.canvas
  ColumnLayout {
   anchors.fill:parent;anchors.margins:NoesisStyle.lg;spacing:NoesisStyle.sm
   RowLayout {
    Layout.fillWidth:true;spacing:NoesisStyle.md
    Text {font.hintingPreference:Font.PreferFullHinting;text:"Study / "+(desk.workspace?.ownerLabel||"Desk");color:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.uiText;font.bold:true;renderType:Text.NativeRendering}
    Text {font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:desk.workspace?.selected.title||"Choose an activity on the main display";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.uiText;font.bold:true;elide:Text.ElideRight;renderType:Text.NativeRendering}
    NoesisButton {text:desk.split?"One pane":"Two panes";onClicked:{desk.split=!desk.split;desk.saveLayout();}}
    NoesisButton {text:NoesisController.toolHandoffOpen&&!NoesisController.windowOpen?"Focus tool display":"Focus main page";onClicked:Quickshell.execDetached(["hyprctl","dispatch",'hl.dsp.focus({monitor='+JSON.stringify(NoesisController.mainMonitor)+'})'])}
    NoesisButton {text:"Use ScreenPad for tools";variant:"tertiary";onClicked:{desk.enabledByUser=false;desk.saveLayout();}}
   }
   Flow {visible:NoesisController.toolHandoffOpen&&!NoesisController.windowOpen;Layout.fillWidth:true;spacing:NoesisStyle.sm
    Text {text:"Supporting context held during tool work · updates resume with Noesis";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
    NoesisButton {text:"Resume Noesis";onClicked:NoesisController.open()}
   }
   SplitView {
    id:panes;Layout.fillWidth:true;Layout.fillHeight:true;orientation:Qt.Horizontal
    property bool userResizing:false
    onResizingChanged:{if(resizing)userResizing=true;else if(userResizing){userResizing=false;desk.saveLayout();}}
    handle:Rectangle {implicitWidth:12;color:NoesisStyle.canvas;Rectangle {anchors.centerIn:parent;width:2;height:parent.height;color:parent.SplitHandle.hovered?NoesisStyle.rule:"transparent"}}
    NoesisStudyPane {id:leftPane;workspace:desk.workspace;paneKey:"left";view:"source";SplitView.fillWidth:!desk.split;SplitView.preferredWidth:panes.width*Math.min(.75,Math.max(.25,NoesisController.layouts.StudyDesk?.ratio||.5));SplitView.minimumWidth:Math.min(380*NoesisStyle.interfaceScale,panes.width*.4);onLayoutEdited:{desk.saveLayout();desk.requestFrame();}}
    NoesisStudyPane {id:rightPane;workspace:desk.workspace;paneKey:"right";view:"notes";visible:desk.split;SplitView.fillWidth:true;SplitView.minimumWidth:Math.min(380*NoesisStyle.interfaceScale,panes.width*.4);onLayoutEdited:{desk.saveLayout();desk.requestFrame();}}
   }

  }
 }
 IpcHandler {target:"noesis-study-desk";function state():string{return JSON.stringify({frame_serial:desk.frameSerial,visible:desk.visible,screen:desk.screen?.name,width:desk.width,height:desk.height,view:desk.view,right_view:rightPane.view,left_label:leftPane.surfaceLabel,right_label:rightPane.surfaceLabel,left_problem:leftPane.problem,right_problem:rightPane.problem,left_source_scroll:leftPane.sourceAnchor,split:desk.split,record:desk.workspace?.selected.id||"",left_kept:leftPane.kept.id||"",left_kept_ready:leftPane.keptReady,left_kept_scroll:leftPane.keptAnchors.source||0,left_kept_error:leftPane.keptError,left_kept_protected:leftPane.keptProtected,right_kept:rightPane.kept.id||"",source_blocks:leftPane.blocks.length,active_workspace:desk.activeWorkspace});}function repaintNow():int{desk.requestFrame();return desk.frameSerial;}function showView(value:string):void{if(leftPane.surfaces.includes(value)){leftPane.view=value;desk.saveLayout();}}}
}
