pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root
 property var comic:({})
 property var packages:({installed:[],updates:[]})
 property var packageJob:({status:"idle",log:""})
 property string packageJobError:""
 property bool packageBusy:packageJob.status==="running" || packageStart.running
 property var network:({})
 property int networkPage:0
 property bool comicLoading:comicProcess.running
 property bool packagesLoading:packageProcess.running
 property string comicError:""
 property string packagesError:""
 function loadComic(number='latest'){if(comicProcess.running)return;comicError='';comicProcess.command=['/home/fh1m/.local/bin/sensei-desktop-data','comic',String(number)];comicProcess.running=true;}
 function loadPackages(check=false){if(packageProcess.running)return;packagesError='';packageProcess.command=['/home/fh1m/.local/bin/sensei-desktop-data','packages',check?'check':'cached'];packageProcess.running=true;}
 function loadNetwork(){if(!networkProcess.running)networkProcess.running=true;}
 function packageAction(action,name=''){
  if(packageBusy)return;
  packageJobError='';packageStart.command=[Quickshell.env('HOME')+'/.local/bin/sensei-package-job','start',action,name];packageStart.running=true;
 }
 function loadPackageJob(){if(!jobState.running)jobState.running=true;}
 function packageAnswer(value){if(!packageResponse.running){packageResponse.command=[Quickshell.env('HOME')+'/.local/bin/sensei-package-job','respond',packageJob.id||'',value];packageResponse.running=true;}}
 function packageCancel(){if(!packageResponse.running){packageResponse.command=[Quickshell.env('HOME')+'/.local/bin/sensei-package-job','cancel',packageJob.id||''];packageResponse.running=true;}}
 Process {id:packageStart;stdout:StdioCollector {onStreamFinished:{try {const r=JSON.parse(text);root.packageJobError=r.error||'';if(r.started)jobPoll.restart();}catch(e){root.packageJobError='Could not start update';}}}onExited:root.loadPackageJob()}
 Process {id:jobState;command:[Quickshell.env('HOME')+'/.local/bin/sensei-package-job','state'];stdout:StdioCollector {onStreamFinished:{try {const r=JSON.parse(text);const previous=root.packageJob.status;root.packageJob=r;if(previous==='running' && r.status==='done')root.loadPackages(true);}catch(e){root.packageJobError='Could not read update state';}}}}
 Process {id:packageResponse;stdout:StdioCollector {onStreamFinished:{if(text.trim()){try {root.packageJobError=JSON.parse(text).error||'';}catch(e){}}}}}
 Timer {id:jobPoll;interval:800;repeat:true;running:ShellState.dropdown==='system' && ShellState.systemPage===4;onTriggered:root.loadPackageJob()}

 Process {id:comicProcess;stdout:StdioCollector {onStreamFinished:{try{const data=JSON.parse(text);if(data.error)root.comicError=data.error;else root.comic=data;}catch(e){root.comicError=String(e);}}}}
 Process {id:packageProcess;stdout:StdioCollector {onStreamFinished:{try{const data=JSON.parse(text);if(data.error)root.packagesError=data.error;else {root.packages=data;root.packagesError=data.error||'';}}catch(e){root.packagesError=String(e);}}}}
 Process {id:networkProcess;command:['/home/fh1m/.local/bin/sensei-desktop-data','network'];stdout:StdioCollector {onStreamFinished:{try{root.network=JSON.parse(text);}catch(e){root.network={error:String(e)};}}}}
}
