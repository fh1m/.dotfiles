pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
 id:root;property var outputs:[];property bool reduced:false
 FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/story-ready.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.outputs=JSON.parse(text()).outputs||[];}catch(e){root.outputs=[];}}}
 FileView {path:Quickshell.env("HOME")+"/.config/sensei-den/companion.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.reduced=JSON.parse(text()).reducedMotion===true;}catch(e){}}}
 Timer {interval:10000;repeat:true;running:root.outputs.length>0;onTriggered:health.running=true}
 Process {id:health;command:["systemctl","--user","is-active","--quiet","sensei-story.service","sensei-awww.service"];onExited:(code,status)=>{if(code!==0)root.outputs=[];}}
}
