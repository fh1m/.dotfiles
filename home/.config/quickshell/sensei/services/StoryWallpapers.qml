pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id:root;property var outputs:[];property bool reduced:false;property var views:({});property bool nativePlayback:false;property bool panorama:false;property bool away:false
 FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/story-ready.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{const d=JSON.parse(text());root.outputs=d.outputs||[];root.views=d.views||{};root.panorama=d.panorama===true;root.nativePlayback=d.nativePlayback===true;}catch(e){root.outputs=[];}}}
 FileView {path:Quickshell.env("HOME")+"/.config/sensei-den/companion.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.reduced=JSON.parse(text()).reducedMotion===true;}catch(e){}}}
 FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/presence.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.away=JSON.parse(text()).mode?.effective!=="together";}catch(e){}}}
 Timer {interval:10000;repeat:true;running:root.outputs.length>0;onTriggered:health.running=true}
 Process {id:health;command:["systemctl","--user","is-active","--quiet","sensei-story.service","sensei-awww.service"];onExited:(code,status)=>{if(code!==0)root.outputs=[];}}
}
