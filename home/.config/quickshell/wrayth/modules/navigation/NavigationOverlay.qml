import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.modules.dropdowns
Variants {
 model:ShellState.barScreens
 PanelWindow {
 id:overlay;property bool presented:false;property bool previewPaused:false;property real reveal:0;required property ShellScreen modelData;screen:modelData;color:"transparent";visible:presented;anchors {top:true;bottom:true;left:true;right:true}mask:Region {width:WindowDesk.opened?overlay.width:0;height:overlay.height}exclusionMode:ExclusionMode.Ignore;WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.namespace:"sensei-navigation";WlrLayershell.keyboardFocus:WindowDesk.opened?WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None
 IpcHandler {target:"navigationview";function showcaseHide(addresses:string):void{WindowDesk.showcaseHidden=addresses==="clear"?[]:addresses.split(",").filter(Boolean);}
 function freeze(paused:bool):void{overlay.previewPaused=paused;}function state():string{return JSON.stringify({presented:overlay.presented,reveal:overlay.reveal,width:panel.width,height:panel.height,enter:enter.running,leave:leave.running});}}
 Timer {id:selectionHandoff;interval:45;onTriggered:WindowDesk.finishSelection()}
 NumberAnimation {id:enter;target:overlay;property:"reveal";to:1;duration:230;easing.type:Easing.OutCubic}
 SequentialAnimation {id:leave;NumberAnimation {target:overlay;property:"reveal";to:0;duration:150;easing.type:Easing.InCubic}ScriptAction {script:{overlay.presented=false;selectionHandoff.restart();}}}
 Rectangle {anchors.fill:parent;opacity:overlay.reveal;color:Theme.alpha(Theme.deep,.18);MouseArea {anchors.fill:parent;onClicked:WindowDesk.cancel()}}
 ChamferPanel {id:panel;anchors.centerIn:parent;anchors.verticalCenterOffset:12*(1-overlay.reveal);opacity:overlay.reveal;enabled:WindowDesk.opened;width:Math.min(Math.max(320,(overlay.screen?.width??1920)-64),1660);height:WindowDesk.mode==='overview'||WindowDesk.mode==='workspaces'?820:730;fillColor:Theme.widgetGlass;borderColor:Theme.widgetBorder;borderWidth:1;chamfer:Appearance.chamfer.panel
 Column {anchors.fill:parent;anchors.margins:18;spacing:12
 Row {spacing:10;Text {width:620;text:WindowDesk.mode==='overview'||WindowDesk.mode==='workspaces'?"Sensei, your workspace constellation.":WindowDesk.mode==='same'?"Sensei, instances of your current app.":"Sensei, choose your next focus.";font.family:Appearance.font.data;font.pixelSize:18;color:Theme.signal}ControlTile {implicitWidth:155;implicitHeight:29;label:"Applications";selected:WindowDesk.mode==='apps';onActivated:{WindowDesk.mode='apps';WindowDesk.pinned=true;WindowDesk.selected=0}}ControlTile {implicitWidth:155;implicitHeight:29;label:"Workspaces";selected:WindowDesk.mode==='overview';onActivated:{WindowDesk.mode='overview';WindowDesk.pinned=true}}ControlTile {implicitWidth:135;implicitHeight:29;label:overlay.previewPaused?"Frozen":"Live";glyph:"\uf03d";selected:!overlay.previewPaused;onActivated:overlay.previewPaused=!overlay.previewPaused}ControlTile {implicitWidth:120;implicitHeight:29;label:"Close · Esc";onActivated:WindowDesk.cancel()}}
 DeskTextField {id:search;width:parent.width;height:37;placeholderText:"Fuzzy search every installed app and running window · arrows / Tab select · Enter launches or focuses";text:WindowDesk.query;onTextEdited:{WindowDesk.query=text;WindowDesk.selected=0;WindowDesk.pinned=true;}font.family:Appearance.font.data;font.pixelSize:14;color:Theme.text;Keys.onPressed:e=>{if(e.key===Qt.Key_Tab){WindowDesk.cycle(e.modifiers&Qt.ShiftModifier?-1:1);e.accepted=true;}else if((e.key===Qt.Key_Return||e.key===Qt.Key_Enter)){WindowDesk.commit();e.accepted=true;}else if(e.key===Qt.Key_Escape){WindowDesk.cancel();e.accepted=true;}else if(e.key===Qt.Key_Left||e.key===Qt.Key_Up){WindowDesk.cycle(-1);e.accepted=true;}else if(e.key===Qt.Key_Right||e.key===Qt.Key_Down){WindowDesk.cycle(1);e.accepted=true;}}Keys.onReleased:e=>{if(e.key===Qt.Key_Alt||e.key===Qt.Key_Meta)e.accepted=true;}}
 Item {width:parent.width;height:WindowDesk.mode==='overview'||WindowDesk.mode==='workspaces'?665:475
 Grid {anchors.fill:parent;visible:!WindowDesk.query.trim()&&(WindowDesk.mode==='overview'||WindowDesk.mode==='workspaces');columns:3;spacing:12
 Repeater {model:6;WorkspacePreview {required property int index;workspace:index+1;width:(parent.width-24)/3;height:315;selected:WindowDesk.selected===index;retainFrame:overlay.visible&&overlay.previewPaused;livePreview:overlay.visible&&!overlay.previewPaused}}
 }
 ListView {id:searchResults;anchors.fill:parent;visible:!!WindowDesk.query.trim();clip:true;spacing:7;model:WindowDesk.searchResults;currentIndex:WindowDesk.selected;onCurrentIndexChanged:positionViewAtIndex(currentIndex,ListView.Contain);ScrollBar.vertical:ScrollBar {}
 delegate:ChamferPanel {id:resultCard;required property var modelData;required property int index;width:searchResults.width;height:70;chamfer:8;fillColor:WindowDesk.selected===index?Theme.widgetRaised:Theme.widgetSurface;borderColor:WindowDesk.selected===index?Theme.widgetAccent:Theme.widgetBorder
 Row {anchors.fill:parent;anchors.margins:10;spacing:12
 AppIcon {width:36;height:36;size:36;anchors.verticalCenter:parent.verticalCenter;entry:resultCard.modelData}
 Column {width:parent.width-170;spacing:6;Text {width:parent.width;text:WindowDesk.resultName(resultCard.modelData);font.family:Appearance.font.data;font.pixelSize:15;color:Theme.text;elide:Text.ElideRight}Text {width:parent.width;text:WindowDesk.isWindow(resultCard.modelData)?"Running · "+(resultCard.modelData.lastIpcObject?.class||'')+" · workspace "+(resultCard.modelData.workspace?.name||''):(resultCard.modelData.genericName||Launcher.tagFor(resultCard.modelData))+" · "+(resultCard.modelData.id||'');font.family:Appearance.font.data;font.pixelSize:11;color:Theme.dim;elide:Text.ElideRight}}
 Text {width:110;anchors.verticalCenter:parent.verticalCenter;text:WindowDesk.isWindow(resultCard.modelData)?"Focus window":"Launch app";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.signal}
 }
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:WindowDesk.selectResult(resultCard.modelData)}
 }
 Text {anchors.centerIn:parent;visible:searchResults.count===0;text:"Sensei, no matching apps or windows.";font.family:Appearance.font.data;font.pixelSize:16;color:Theme.dim}
 }
 Flickable {id:windows;anchors.fill:parent;visible:!WindowDesk.query.trim()&&(WindowDesk.mode==='apps'||WindowDesk.mode==='same');property int currentIndex:WindowDesk.selected;contentWidth:appRow.width;contentHeight:height;clip:true;boundsBehavior:Flickable.StopAtBounds;onCurrentIndexChanged:contentX=Math.max(0,Math.min(contentWidth-width,currentIndex*402));ScrollBar.horizontal:ScrollBar {}
 Row {id:appRow;spacing:12
 Repeater {model:WindowDesk.matches
 ChamferPanel {id:card;required property var modelData;required property int index;width:390;height:440;fillColor:Theme.widgetSurface;borderColor:WindowDesk.selected===index?Theme.widgetAccent:Theme.widgetBorder;borderWidth:WindowDesk.selected===index?2:1;chamfer:10;scale:WindowDesk.selected===index?1:.985;Behavior on scale {NumberAnimation {duration:130}}
 MouseArea {anchors.fill:parent;onClicked:WindowDesk.choose(card.modelData)}
 Column {anchors.fill:parent;anchors.margins:12;spacing:10
 Row {width:parent.width;spacing:10;AppIcon {size:32;entry:card.modelData}Text {width:parent.width-42;anchors.verticalCenter:parent.verticalCenter;text:WindowDesk.desktopEntryFor(card.modelData)?.name||card.modelData.wayland?.appId||card.modelData.lastIpcObject?.class||"Application";font.family:Appearance.font.data;font.pixelSize:15;color:Theme.signal;elide:Text.ElideRight}}
 WindowPreview {width:parent.width;height:220;window:card.modelData;frameInterval:WindowDesk.selected===card.index?33:100;retainFrame:overlay.visible&&overlay.previewPaused;livePreview:overlay.visible&&!overlay.previewPaused&&card.index>=windows.currentIndex-1&&card.index<=windows.currentIndex+2;MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:WindowDesk.choose(card.modelData)}}
 Text {width:parent.width;maximumLineCount:2;wrapMode:Text.Wrap;text:card.modelData.title;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.text;elide:Text.ElideRight}
 Text {text:"Workspace "+(card.modelData.workspace?.name??"—")+" · "+(card.modelData.monitor?.name??"");font.family:Appearance.font.data;font.pixelSize:10;color:Theme.dim}
 Row {spacing:5;ControlTile {implicitWidth:105;implicitHeight:28;label:"Focus";onActivated:WindowDesk.choose(card.modelData)}ControlTile {implicitWidth:105;implicitHeight:28;label:"Float / tile";onActivated:WindowDesk.floatWindow(card.modelData)}ControlTile {implicitWidth:105;implicitHeight:28;label:"Close app";onActivated:{WindowDesk.pinned=true;card.modelData.wayland?.close();}}}
 DeskComboBox {width:parent.width;height:29;model:Spaces.workspaceNames;currentIndex:Math.max(0,(card.modelData.workspace?.id??1)-1);onActivated:WindowDesk.move(card.modelData,currentIndex+1);font.family:Appearance.font.data;font.pixelSize:11}
 }

 }
 }
 }
 }
 }
 Row {visible:!WindowDesk.query.trim()&&(WindowDesk.mode==='apps'||WindowDesk.mode==='same');spacing:7
 Repeater {model:WindowDesk.apps;ChamferPanel {id:quickCard;required property var modelData;width:Math.min(190,(panel.width-36-49)/8);height:36;chamfer:6;fillColor:quickHover.containsMouse?Theme.widgetRaised:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Row {anchors.fill:parent;anchors.margins:6;spacing:7;AppIcon {size:24;entry:quickCard.modelData}Text {width:parent.width-31;anchors.verticalCenter:parent.verticalCenter;text:quickCard.modelData.name;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:11;color:Theme.text}}
 MouseArea {id:quickHover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:WindowDesk.launch(quickCard.modelData)}
 }}
 }
 Text {width:parent.width;text:"Sensei, hover never changes application focus. Enter / click chooses · Esc cancels · releasing Alt / Super keeps this view open · drag windows between workspace previews · previews run only while open.";font.family:Appearance.font.data;font.pixelSize:11;color:Theme.dim;wrapMode:Text.Wrap}
 }
 }
 ChamferPanel {id:dragGhost;z:999;visible:WindowDesk.dragWindow!==null;x:WindowDesk.dragX-130;y:WindowDesk.dragY-70;width:260;height:166;fillColor:Theme.widgetGlass;borderColor:Theme.widgetAccent;borderWidth:2;chamfer:10;opacity:.95
 WindowPreview {x:5;y:5;width:250;height:125;window:WindowDesk.dragWindow;livePreview:dragGhost.visible;frameInterval:80}
 Text {x:9;y:137;width:242;text:WindowDesk.dragTarget?'Move to '+Spaces.workspaceNames[WindowDesk.dragTarget-1]:'Drop on a workspace';elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.signal}
 }
 Connections {target:WindowDesk;function onOpenedChanged(){enter.stop();leave.stop();if(WindowDesk.opened){overlay.presented=true;enter.start();Qt.callLater(()=>search.forceActiveFocus());}else leave.start();}}
 }
}
