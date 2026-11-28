import QtQuick
import Quickshell.Wayland
import qs.services
import qs.config
Rectangle {
 id:root
 property var window:null
 property bool livePreview:true
 property bool retainFrame:false
 property int frameInterval:50
 property bool sharedClock:false
 readonly property bool scheduled:sharedClock&&livePreview&&visible
 function requestFrame():void {attach();if(captureHandle)capture.captureFrame();}
 property var captureHandle:null
 color:Theme.deep;clip:true
 function attach(){if(!captureHandle&&window)captureHandle=WindowDesk.captureFor(window);}
 onWindowChanged:{captureHandle=null;Qt.callLater(attach);}
 ScreencopyView {id:capture;anchors.centerIn:parent;width:implicitWidth;height:implicitHeight;captureSource:(root.livePreview||root.retainFrame)&&root.visible?root.captureHandle:null;live:false;paintCursor:false;constraintSize:Qt.size(root.width,root.height)}
 Timer {id:frameTimer;interval:root.frameInterval;repeat:true;running:root.livePreview&&root.visible&&!root.sharedClock;onTriggered:root.requestFrame()}
 readonly property bool hasContent:capture.hasContent
 readonly property string sourceApp:capture.captureSource?.appId??"NONE"
 readonly property bool timerRunning:frameTimer.running
 Component.onCompleted:{Qt.callLater(attach);WindowDesk.previews=WindowDesk.previews.concat([root]);}
 Component.onDestruction:WindowDesk.previews=WindowDesk.previews.filter(p=>p!==root)
 Text {textFormat:Text.PlainText;anchors.centerIn:parent;width:parent.width-8;horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight;visible:!capture.hasContent;text:root.livePreview||root.retainFrame?"Preview unavailable":root.window?.lastIpcObject?.class||"Preview paused";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.dim}
}
