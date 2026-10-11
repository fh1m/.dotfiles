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
 property var captureHandle:null
 color:Theme.deep;clip:true
 function attach(){if(!captureHandle&&window)captureHandle=WindowDesk.captureFor(window);}
 onWindowChanged:{captureHandle=null;Qt.callLater(attach);}
 ScreencopyView {id:capture;anchors.centerIn:parent;width:implicitWidth;height:implicitHeight;captureSource:(root.livePreview||root.retainFrame)&&root.visible?root.captureHandle:null;live:false;paintCursor:false;constraintSize:Qt.size(root.width,root.height)}
 Timer {id:frameTimer;interval:root.frameInterval;repeat:true;running:root.livePreview&&root.visible;onTriggered:{root.attach();if(root.captureHandle)capture.captureFrame();}}
 readonly property bool hasContent:capture.hasContent
 readonly property string sourceApp:capture.captureSource?.appId??"NONE"
 readonly property bool timerRunning:frameTimer.running
 Component.onCompleted:{Qt.callLater(attach);WindowDesk.previews=WindowDesk.previews.concat([root]);}
 Component.onDestruction:WindowDesk.previews=WindowDesk.previews.filter(p=>p!==root)
 Text {anchors.centerIn:parent;visible:!capture.hasContent;text:root.window?.lastIpcObject?.class||"Preparing preview…";font.family:Appearance.font.data;font.pixelSize:14;color:Theme.dim}
}
