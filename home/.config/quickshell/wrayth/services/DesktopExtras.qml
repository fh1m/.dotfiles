pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root
 property var comic:({})
 property var packages:({installed:[],updates:[]})
 property var network:({})
 property int networkPage:0
 property bool comicLoading:comicProcess.running
 property bool packagesLoading:packageProcess.running
 property string comicError:""
 property string packagesError:""
 function loadComic(number='latest'){if(comicProcess.running)return;comicError='';comicProcess.command=['@HOME@/.local/bin/sensei-desktop-data','comic',String(number)];comicProcess.running=true;}
 function loadPackages(check=false){if(packageProcess.running)return;packagesError='';packageProcess.command=['@HOME@/.local/bin/sensei-desktop-data','packages',check?'check':'cached'];packageProcess.running=true;}
 function loadNetwork(){if(!networkProcess.running)networkProcess.running=true;}
 function packageAction(action,name=''){Quickshell.execDetached(['kitty','--title','Sensei · Packages','@HOME@/.local/bin/sensei-package-action',action,name]);}
 Process {id:comicProcess;stdout:StdioCollector {onStreamFinished:{try{const data=JSON.parse(text);if(data.error)root.comicError=data.error;else root.comic=data;}catch(e){root.comicError=String(e);}}}}
 Process {id:packageProcess;stdout:StdioCollector {onStreamFinished:{try{const data=JSON.parse(text);if(data.error)root.packagesError=data.error;else {root.packages=data;root.packagesError=data.error||'';}}catch(e){root.packagesError=String(e);}}}}
 Process {id:networkProcess;command:['@HOME@/.local/bin/sensei-desktop-data','network'];stdout:StdioCollector {onStreamFinished:{try{root.network=JSON.parse(text);}catch(e){root.network={error:String(e)};}}}}
}
