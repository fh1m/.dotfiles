import QtQuick
import qs.components
import qs.config
import qs.services
ChamferPanel {
 id:root;property int workspace:1;property bool selected:false;property bool livePreview:true;property bool retainFrame:false;property var windows:WindowDesk.all.filter(t=>t.workspace?.id===root.workspace);fillColor:Theme.widgetSurface;borderColor:WindowDesk.dragTarget===workspace?Theme.signal:selected?Theme.signal:Theme.hair;borderWidth:WindowDesk.dragTarget===workspace||selected?2:1;chamfer:10;clip:true
 Component.onCompleted:WindowDesk.workspaceCards=WindowDesk.workspaceCards.concat([root])
 Component.onDestruction:WindowDesk.workspaceCards=WindowDesk.workspaceCards.filter(c=>c!==root)
 MouseArea {anchors.fill:parent;onClicked:WindowDesk.workspace(root.workspace)}
 Image {anchors.fill:parent;anchors.margins:10;source:Wallpapers.displaySource(root.workspace===6?"DP-2":"eDP-1");fillMode:Image.PreserveAspectCrop;opacity:.35;asynchronous:true}
 Text {x:10;y:9;text:Spaces.workspaceNames[root.workspace-1]+" · "+root.windows.length+" windows";font.family:Appearance.font.data;font.pixelSize:13;color:root.selected?Theme.signal:Theme.text}
 Item {id:area;x:8;y:34;width:parent.width-16;height:parent.height-44;clip:true
 Repeater {model:root.windows
 WindowPreview {id:tile;required property var modelData;opacity:WindowDesk.dragWindow===modelData ? .35 : 1;window:modelData;livePreview:root.livePreview;retainFrame:root.retainFrame;x:Math.max(0,Math.min(area.width-40,((modelData.lastIpcObject?.at?.[0]??0)-(modelData.monitor?.lastIpcObject?.x??0))/1920*area.width));y:Math.max(0,Math.min(area.height-30,((modelData.lastIpcObject?.at?.[1]??44)-(modelData.monitor?.lastIpcObject?.y??0)-44)/(root.workspace===6?506:1036)*area.height));width:Math.max(40,Math.min(area.width,(modelData.lastIpcObject?.size?.[0]??1920)/1920*area.width));height:Math.max(30,Math.min(area.height,(modelData.lastIpcObject?.size?.[1]??1080)/(root.workspace===6?506:1036)*area.height));border.width:1;border.color:Theme.hair
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
