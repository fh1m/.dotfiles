import QtQuick
import qs.components
import qs.config
import qs.services
ChamferPanel {
 id:root;property int workspace:1;property bool selected:false;property bool livePreview:true;property bool retainFrame:false;property var windows:WindowDesk.all.filter(t=>Spaces.logicalId(Spaces.windowWorkspace(t))===root.workspace);fillColor:Theme.widgetSurface;borderColor:WindowDesk.dragTarget===workspace?Theme.signal:selected?Theme.signal:Theme.hair;borderWidth:WindowDesk.dragTarget===workspace||selected?2:1;chamfer:10;clip:true
 readonly property var displays:Spaces.outputState.filter(m=>root.workspace===7?m.name==="DP-2":m.name==="eDP-1"||m.name.startsWith("HDMI-"))
 readonly property real originX:displays.length?Math.min(...displays.map(m=>m.x)):0
 readonly property real originY:displays.length?Math.min(...displays.map(m=>m.y)):0
 readonly property real spanWidth:displays.length?Math.max(...displays.map(m=>m.x+m.width/(m.scale||1)))-originX:1920
 readonly property real spanHeight:displays.length?Math.max(...displays.map(m=>m.y+m.height/(m.scale||1)))-originY:1080
 function monitorFor(t){const data=t.lastIpcObject||{};return Spaces.outputState.find(m=>m.name===t.monitor?.name||m.id===data.monitor)??{x:0,y:0,width:1920,height:1080,scale:1};}
 Component.onCompleted:WindowDesk.workspaceCards=WindowDesk.workspaceCards.concat([root])
 Component.onDestruction:WindowDesk.workspaceCards=WindowDesk.workspaceCards.filter(c=>c!==root)
 MouseArea {anchors.fill:parent;onClicked:WindowDesk.workspace(root.workspace)}
 Image {anchors.fill:parent;anchors.margins:10;source:Wallpapers.displaySource(root.workspace===7?"DP-2":"eDP-1");sourceSize:Qt.size(768,432);fillMode:Image.PreserveAspectCrop;opacity:.35;asynchronous:true}
 Text {x:10;y:9;text:WindowDesk.workspaceTitle(root.workspace)+" · "+root.windows.length+" windows";font.family:Appearance.font.data;font.pixelSize:13;color:root.selected?Theme.signal:Theme.text}
 Item {id:area;x:8;y:34;width:parent.width-16;height:parent.height-44;clip:true
 Repeater {model:root.windows
 WindowPreview {id:tile;required property var modelData;readonly property var display:root.monitorFor(modelData);readonly property real displayWidth:display.width/(display.scale||1);readonly property real displayHeight:display.height/(display.scale||1);opacity:WindowDesk.dragWindow===modelData ? .35 : 1;window:modelData;livePreview:root.livePreview;retainFrame:root.retainFrame;x:Math.max(0,Math.min(area.width-40,((modelData.lastIpcObject?.at?.[0]??0)-root.originX)/root.spanWidth*area.width));y:Math.max(0,Math.min(area.height-30,((modelData.lastIpcObject?.at?.[1]??44)-root.originY)/root.spanHeight*area.height));width:Math.max(40,Math.min(area.width,(modelData.lastIpcObject?.size?.[0]??tile.displayWidth)/root.spanWidth*area.width));height:Math.max(30,Math.min(area.height,(modelData.lastIpcObject?.size?.[1]??tile.displayHeight)/root.spanHeight*area.height));border.width:1;border.color:Theme.hair
 MouseArea {id:windowPointer;anchors.fill:parent;acceptedButtons:Qt.LeftButton|Qt.RightButton;cursorShape:pressed?Qt.ClosedHandCursor:Qt.OpenHandCursor;preventStealing:true
 property point pressPoint:Qt.point(0,0);property bool dragged:false
 onPressed:e=>{pressPoint=Qt.point(e.x,e.y);dragged=false;}
 onPositionChanged:e=>{if(!pressed||!(pressedButtons&Qt.LeftButton))return;const point=mapToItem(null,e.x,e.y);if(!dragged&&Math.hypot(e.x-pressPoint.x,e.y-pressPoint.y)>8){dragged=true;WindowDesk.beginDrag(tile.modelData,point.x,point.y);}if(dragged)WindowDesk.updateDrag(point.x,point.y);}
 onReleased:e=>{if(dragged)WindowDesk.finishDrag();}
 onCanceled:{WindowDesk.cancelDrag();dragged=false;}
 onClicked:e=>{if(dragged)return;if(e.button===Qt.RightButton){WindowDesk.mode='apps';WindowDesk.query=tile.modelData.title;WindowDesk.pinned=true;}else WindowDesk.choose(tile.modelData);}
 }

 }
 }
 }

 Text {anchors.centerIn:area;visible:root.windows.length===0;text:"Sensei, space for your next idea.";font.family:Appearance.font.data;font.pixelSize:11;color:Theme.dim}
}
