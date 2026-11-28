import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.modules.dropdowns
// The navigationview IPC lives outside the per-screen Variants. Inside it, one
// handler per screen made Qt drop all but the first ("another handler is
// registered for target navigationview"), so only one screen could be driven.
Scope {
 IpcHandler {target:"navigationview";function showcaseHide(addresses:string):void{WindowDesk.showcaseHidden=addresses==="clear"?[]:addresses.split(",").filter(Boolean);}
 function freeze(paused:bool):void{WindowDesk.previewPaused=paused;}function state():string{return JSON.stringify({opened:WindowDesk.opened,previewPaused:WindowDesk.previewPaused,showcaseHidden:WindowDesk.showcaseHidden});}}
 Variants {
 model:ShellState.overlayScreens
 PanelWindow {
 id:overlay;property bool presented:false;property real reveal:0;required property ShellScreen modelData;screen:modelData;color:"transparent";visible:presented;anchors {top:true;bottom:true;left:true;right:true}mask:Region {width:WindowDesk.opened?overlay.width:0;height:overlay.height}exclusionMode:ExclusionMode.Ignore;WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.namespace:"sensei-navigation";WlrLayershell.keyboardFocus:WindowDesk.opened?WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None

 readonly property bool workspaceMode:WindowDesk.mode==="overview"||WindowDesk.mode==="workspaces"
 function present(){overlay.presented=true;enter.start();Qt.callLater(()=>{if(WindowDesk.opened)search.forceActiveFocus();});}
 Component.onCompleted:if(WindowDesk.opened)present()
 NumberAnimation {id:enter;target:overlay;property:"reveal";to:1;duration:Theme.reducedMotion?0:100;easing.type:Easing.OutCubic}
 NumberAnimation {id:leave;target:overlay;property:"reveal";to:0;duration:Theme.reducedMotion?0:90;easing.type:Easing.InCubic;onFinished:overlay.presented=false}
 Rectangle {anchors.fill:parent;opacity:overlay.reveal;color:Theme.alpha(Theme.deep,.18);MouseArea {anchors.fill:parent;onClicked:WindowDesk.cancel()}}
 ChamferPanel {id:panel;anchors.centerIn:parent;anchors.verticalCenterOffset:12*(1-overlay.reveal);opacity:overlay.reveal;enabled:WindowDesk.opened;width:Math.min(Math.max(0,overlay.width-32),1660);height:Math.min(Math.max(0,overlay.height-32),overlay.workspaceMode?820:730);fillColor:Theme.widgetGlass;borderColor:Theme.widgetBorder;borderWidth:1;chamfer:Appearance.chamfer.panel
 Column {anchors.fill:parent;anchors.margins:18;spacing:12
 Flow {id:toolbar;width:parent.width;spacing:8
 Text { textFormat:Text.PlainText;width:toolbar.width>=930?toolbar.width-508:toolbar.width;height:29;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight;text:overlay.workspaceMode?"Choose a workspace":WindowDesk.mode==="same"?"Switch within this app":"Choose a window";font.family:Appearance.font.data;font.pixelSize:18;color:Theme.signal}
 ControlTile {implicitWidth:128;implicitHeight:29;label:"Applications";selected:WindowDesk.mode==="apps";onActivated:WindowDesk.open("apps",0)}
 ControlTile {implicitWidth:128;implicitHeight:29;label:"Workspaces";selected:overlay.workspaceMode;onActivated:WindowDesk.open("overview",0)}
 ControlTile {implicitWidth:112;implicitHeight:29;label:WindowDesk.previewPaused?"Still":"Live";glyph:"\uf03d";selected:!WindowDesk.previewPaused;onActivated:WindowDesk.previewPaused=!WindowDesk.previewPaused}
 ControlTile {implicitWidth:108;implicitHeight:29;label:"Close";glyph:"\uf00d";onActivated:WindowDesk.cancel()}
 }
 DeskTextField {id:search;width:parent.width;height:37;placeholderText:"Fuzzy search every installed app and running window · arrows / Tab select · Enter launches or focuses";text:WindowDesk.query;onTextEdited:{WindowDesk.query=text;WindowDesk.selected=0;WindowDesk.pinned=true;}font.family:Appearance.font.data;font.pixelSize:14;color:Theme.text;Keys.onPressed:e=>{if(e.key===Qt.Key_Tab){WindowDesk.cycle(e.modifiers&Qt.ShiftModifier?-1:1);e.accepted=true;}else if((e.key===Qt.Key_Return||e.key===Qt.Key_Enter)){WindowDesk.commit();e.accepted=true;}else if(e.key===Qt.Key_Escape){WindowDesk.cancel();e.accepted=true;}else if(e.key===Qt.Key_Left||e.key===Qt.Key_Up){WindowDesk.cycle(-1);e.accepted=true;}else if(e.key===Qt.Key_Right||e.key===Qt.Key_Down){WindowDesk.cycle(1);e.accepted=true;}}Keys.onReleased:e=>{if(e.key===Qt.Key_Alt||e.key===Qt.Key_Meta)e.accepted=true;}}
 Item {width:parent.width;height:Math.max(0,parent.height-toolbar.height-search.height-footer.height-(quickApps.visible?quickApps.height:0)-parent.spacing*(quickApps.visible?4:3))
 Flickable {id:workspaceScroll;anchors.fill:parent;visible:!WindowDesk.query.trim()&&overlay.workspaceMode;clip:true;contentHeight:workspaceGrid.implicitHeight;contentWidth:width;ScrollBar.vertical:ScrollBar {}
     function revealSelected(){
         if(!visible)return;
         const row=Math.floor(WindowDesk.selected/workspaceGrid.columns);
         const y=row*(workspaceGrid.cardHeight+workspaceGrid.spacing);
         contentY=Math.min(Math.max(0,contentHeight-height),Math.max(y+workspaceGrid.cardHeight-height,Math.min(contentY,y)));
     }
     Connections {target:WindowDesk;function onSelectedChanged(){workspaceScroll.revealSelected();}}
     onVisibleChanged:if(visible)Qt.callLater(revealSelected)
 Grid {id:workspaceGrid;width:workspaceScroll.width;columns:Math.max(1,Math.min(4,Math.floor((width+spacing)/250)));spacing:12
     readonly property real cardHeight:Math.min(315,Math.max(132,Math.floor((workspaceScroll.height-spacing)/2)))
 Repeater {model:WindowDesk.workspaceIds;WorkspacePreview {required property int index;required property int modelData;workspace:modelData;output:overlay.screen?.name??"";width:(workspaceGrid.width-workspaceGrid.spacing*(workspaceGrid.columns-1))/workspaceGrid.columns;height:workspaceGrid.cardHeight;selected:WindowDesk.selected===index;retainFrame:WindowDesk.opened&&workspaceScroll.visible&&y+height>workspaceScroll.contentY&&y<workspaceScroll.contentY+workspaceScroll.height;livePreview:retainFrame&&selected&&!WindowDesk.previewPaused}}
 }
 }
 ListView {id:searchResults;anchors.fill:parent;visible:!!WindowDesk.query.trim();clip:true;spacing:7;model:WindowDesk.searchResults;currentIndex:WindowDesk.selected;onCurrentIndexChanged:positionViewAtIndex(currentIndex,ListView.Contain);ScrollBar.vertical:ScrollBar {}
 delegate:ChamferPanel {id:resultCard;required property var modelData;required property int index;width:searchResults.width;height:70;chamfer:8;fillColor:WindowDesk.selected===index?Theme.widgetRaised:Theme.widgetSurface;borderColor:WindowDesk.selected===index?Theme.widgetAccent:Theme.widgetBorder
 Row {anchors.fill:parent;anchors.margins:10;spacing:12
 AppIcon {width:36;height:36;size:36;anchors.verticalCenter:parent.verticalCenter;entry:resultCard.modelData}
 Column {width:parent.width-170;spacing:6;Text { textFormat: Text.PlainText;width:parent.width;text:WindowDesk.resultName(resultCard.modelData);font.family:Appearance.font.data;font.pixelSize:15;color:Theme.text;elide:Text.ElideRight}Text { textFormat: Text.PlainText;width:parent.width;text:WindowDesk.isWindow(resultCard.modelData)?"Running · "+(resultCard.modelData.lastIpcObject?.class||'')+" · workspace "+(resultCard.modelData.workspace?.name||''):(resultCard.modelData.genericName||Launcher.tagFor(resultCard.modelData))+" · "+(resultCard.modelData.id||'');font.family:Appearance.font.data;font.pixelSize:11;color:Theme.dim;elide:Text.ElideRight}}
 Text { textFormat: Text.PlainText;width:110;anchors.verticalCenter:parent.verticalCenter;text:WindowDesk.isWindow(resultCard.modelData)?"Focus window":"Launch app";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.signal}
 }
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:WindowDesk.selectResult(resultCard.modelData)}
 }
 Text { textFormat: Text.PlainText;anchors.centerIn:parent;visible:searchResults.count===0;text:"Sensei, no matching apps or windows.";font.family:Appearance.font.data;font.pixelSize:16;color:Theme.dim}
 }
 Flickable {id:windows;anchors.fill:parent;visible:!WindowDesk.query.trim()&&(WindowDesk.mode==='apps'||WindowDesk.mode==='same');property int currentIndex:WindowDesk.selected;readonly property real cardWidth:Math.min(390,width);contentWidth:appRow.width;contentHeight:Math.max(height,appRow.height);clip:true;boundsBehavior:Flickable.StopAtBounds;onCurrentIndexChanged:contentX=Math.max(0,Math.min(contentWidth-width,currentIndex*(cardWidth+appRow.spacing)));ScrollBar.horizontal:ScrollBar {} ScrollBar.vertical:ScrollBar {}
 Text {anchors.centerIn:parent;visible:WindowDesk.matches.length===0;text:"No open windows. Search to launch an app.";font.family:Appearance.font.data;font.pixelSize:16;color:Theme.dim}
 Row {id:appRow;spacing:12
 Repeater {model:WindowDesk.matches
 ChamferPanel {id:card;required property var modelData;required property int index;width:windows.cardWidth;height:Math.max(300,Math.min(440,windows.height));fillColor:Theme.widgetSurface;borderColor:WindowDesk.selected===index?Theme.widgetAccent:Theme.widgetBorder;borderWidth:WindowDesk.selected===index?2:1;chamfer:10;scale:WindowDesk.selected===index?1:.985;Behavior on scale {NumberAnimation {duration:Theme.reducedMotion?0:130}}
 MouseArea {anchors.fill:parent;onClicked:WindowDesk.choose(card.modelData)}
 Column {anchors.fill:parent;anchors.margins:12;spacing:10
 Row {width:parent.width;spacing:10;AppIcon {size:32;entry:card.modelData}Text { textFormat: Text.PlainText;width:parent.width-42;anchors.verticalCenter:parent.verticalCenter;text:WindowDesk.desktopEntryFor(card.modelData)?.name||card.modelData.wayland?.appId||card.modelData.lastIpcObject?.class||"Application";font.family:Appearance.font.data;font.pixelSize:15;color:Theme.signal;elide:Text.ElideRight}}
 WindowPreview {width:parent.width;height:Math.min(220,Math.max(76,card.height-188));window:card.modelData;frameInterval:140;retainFrame:WindowDesk.opened&&windows.visible&&card.x+card.width>windows.contentX&&card.x<windows.contentX+windows.width;livePreview:retainFrame&&!WindowDesk.previewPaused&&WindowDesk.selected===card.index;MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:WindowDesk.choose(card.modelData)}}
 Text { textFormat: Text.PlainText;width:parent.width;maximumLineCount:2;wrapMode:Text.Wrap;text:card.modelData.title;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.text;elide:Text.ElideRight}
 Text { textFormat: Text.PlainText;text:"Workspace "+(card.modelData.workspace?.name??"—")+" · "+(card.modelData.monitor?.name??"");font.family:Appearance.font.data;font.pixelSize:10;color:Theme.dim}
 Row {spacing:5;ControlTile {implicitWidth:105;implicitHeight:28;label:"Focus";onActivated:WindowDesk.choose(card.modelData)}ControlTile {implicitWidth:105;implicitHeight:28;label:"Float / tile";onActivated:WindowDesk.floatWindow(card.modelData)}ControlTile {implicitWidth:105;implicitHeight:28;label:"Close app";onActivated:{WindowDesk.pinned=true;card.modelData.wayland?.close();}}}
 DeskComboBox {width:parent.width;height:29;model:Spaces.workspaceIds.map(id=>Spaces.workspaceNames[id-1]);currentIndex:Math.max(0,Spaces.workspaceIds.indexOf(Spaces.logicalId(card.modelData.workspace?.id??1)));onActivated:WindowDesk.move(card.modelData,Spaces.workspaceIds[currentIndex]);font.family:Appearance.font.data;font.pixelSize:11}
 }

 }
 }
 }
 }
 }
 Row {id:quickApps;visible:width>=680&&WindowDesk.apps.length>0&&!WindowDesk.query.trim()&&(WindowDesk.mode==='apps'||WindowDesk.mode==='same');width:parent.width;spacing:7
 Repeater {model:WindowDesk.apps;ChamferPanel {id:quickCard;required property var modelData;width:Math.min(190,(panel.width-36-49)/8);height:36;chamfer:6;fillColor:quickHover.containsMouse?Theme.widgetRaised:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Row {anchors.fill:parent;anchors.margins:6;spacing:7;AppIcon {size:24;entry:quickCard.modelData}Text { textFormat: Text.PlainText;width:parent.width-31;anchors.verticalCenter:parent.verticalCenter;text:quickCard.modelData.name;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:11;color:Theme.text}}
 MouseArea {id:quickHover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:WindowDesk.launch(quickCard.modelData)}
 }}
 }
 Text { id:footer;textFormat:Text.PlainText;width:parent.width;text:overlay.workspaceMode?"Arrows to select · Enter to switch · Drag windows between workspaces · Esc to close":"Arrows to select · Enter to focus or launch · Esc to close";font.family:Appearance.font.data;font.pixelSize:11;color:Theme.dim;wrapMode:Text.Wrap}
 }
 }
 ChamferPanel {id:dragGhost;z:999;visible:WindowDesk.dragWindow!==null;x:WindowDesk.dragX-130;y:WindowDesk.dragY-70;width:260;height:166;fillColor:Theme.widgetGlass;borderColor:Theme.widgetAccent;borderWidth:2;chamfer:10;opacity:.95
 WindowPreview {x:5;y:5;width:250;height:125;window:WindowDesk.dragWindow;livePreview:dragGhost.visible;frameInterval:80}
 Text { textFormat: Text.PlainText;x:9;y:137;width:242;text:WindowDesk.dragTarget?'Move to '+Spaces.workspaceNames[WindowDesk.dragTarget-1]:'Drop on a workspace';elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.signal}
 }
 Connections {target:WindowDesk;function onOpenedChanged(){enter.stop();leave.stop();if(WindowDesk.opened)overlay.present();else if(WindowDesk.pendingSelection){overlay.presented=false;overlay.reveal=0;Qt.callLater(WindowDesk.finishSelection);}else leave.start();}}
 }
}
}
