pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {id:root;property bool remoteActive:false;property string error:"";function refresh(){if(!query.running)query.running=true;}function toggleRemote(){if(change.running)return;change.command=["sudo","-n","/usr/local/libexec/fh1m-remote",remoteActive?"stop":"start"];change.running=true;}
Process {id:query;command:["systemctl","is-active","nxserver.service"];stdout:StdioCollector{onStreamFinished:root.remoteActive=text.trim()==="active"}}
Process {id:change;onExited:root.refresh();stderr:StdioCollector{onStreamFinished:root.error=text.trim()}}
Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="system")root.refresh();}}
}
