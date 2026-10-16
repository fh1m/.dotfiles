import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Passive artwork in measured negative space, never a new bar button.
Item {
    id:root
    property string output:""
    property string edge:"top"
    property bool preferred:true
    property real freeLeft:0
    property real freeRight:0
    property var renderState:({})
    property var lease:({})
    property int frame:0
    property real now:Date.now()/1000
    width:renderState.speaking?Math.min(330,Math.max(32,freeRight-freeLeft-20)):32;height:32
    x:freeLeft+(freeRight-freeLeft-width)/2
    readonly property bool available:preferred && freeRight-freeLeft>=56
    visible:available && lease.output===output && lease.expires>now && renderState.output===output && renderState.eligible===true && renderState.allowed===false
    IpcHandler {target:"companion-perch-"+root.output+"-"+root.edge;function state():string{return JSON.stringify({visible:root.visible,x:root.x,width:root.width,available:root.available});}}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-render.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.renderState=JSON.parse(text());}catch(e){}}}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-travel.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.lease=JSON.parse(text());root.now=Date.now()/1000;}catch(e){}}}
    Timer {interval:1000;repeat:true;running:root.visible;onTriggered:root.now=Date.now()/1000}
    Timer {interval:250;repeat:true;running:root.visible&&root.renderState.reducedMotion!==true&&root.renderState.activity==="dance";onTriggered:root.frame=(root.frame+1)%4}
    Text {x:40;anchors.verticalCenter:parent.verticalCenter;width:Math.max(0,parent.width-44);visible:root.renderState.speaking===true&&parent.width>90;text:root.renderState.message||"";textFormat:Text.PlainText;maximumLineCount:2;wrapMode:Text.Wrap;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}
    Image {
        width:32;height:32;anchors.left:parent.left
        source:Quickshell.env("HOME")+"/.local/share/sensei-companion/"+(root.renderState.extraPose>=0?"zondo-life-v2.png":"fh1m-motion-v2.png")
        readonly property int tile:root.renderState.activity==="dance"?root.frame:(root.renderState.extraPose>=0?root.renderState.extraPose:(root.renderState.pose??13))
        readonly property real cell:1254/4
        sourceClipRect:{if(!(root.renderState.extraPose>=0))return Qt.rect((tile%4)*cell,Math.floor(tile/4)*cell,cell,cell);const xs=[0,313,627,945,1254],ys=[0,323,627,931,1254],c=tile%4,r=Math.floor(tile/4);return Qt.rect(xs[c],ys[r],xs[c+1]-xs[c],ys[r+1]-ys[r]);}
        fillMode:Image.PreserveAspectFit;smooth:true;asynchronous:true
    }
}
