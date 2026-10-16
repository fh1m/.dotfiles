import QtQuick
import Quickshell
import Quickshell.Io

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
    property real now:Date.now()/1000
    width:32;height:32
    x:freeLeft+(freeRight-freeLeft-width)/2
    readonly property bool available:preferred && freeRight-freeLeft>=56
    visible:available && lease.output===output && lease.expires>now && renderState.output===output && renderState.eligible===true && renderState.allowed===false
    IpcHandler {target:"companion-perch-"+root.output+"-"+root.edge;function state():string{return JSON.stringify({visible:root.visible,x:root.x,width:root.width,available:root.available});}}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-render.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.renderState=JSON.parse(text());}catch(e){}}}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-travel.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.lease=JSON.parse(text());root.now=Date.now()/1000;}catch(e){}}}
    Timer {interval:1000;repeat:true;running:root.visible;onTriggered:root.now=Date.now()/1000}
    Image {
        anchors.fill:parent
        source:Quickshell.env("HOME")+"/.local/share/sensei-companion/fh1m-motion-v2.png"
        readonly property real cell:1254/4
        sourceClipRect:Qt.rect(cell,cell*3,cell,cell)
        fillMode:Image.PreserveAspectFit;smooth:true;asynchronous:true
    }
}
