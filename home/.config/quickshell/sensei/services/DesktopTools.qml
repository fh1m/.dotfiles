pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root
 property bool quiet:false
 property bool previousDnd:false
 function toggleQuiet():void {
  if(!quiet){previousDnd=Notifications.doNotDisturb;Notifications.doNotDisturb=true;quiet=true;}
  else {quiet=false;Notifications.doNotDisturb=previousDnd;}
  Quickshell.execDetached([Quickshell.env('HOME')+'/.local/bin/sensei-den','companion','quiet',quiet?'on':'off']);
 }
 function scratch():void {ShellState.closeAll();Quickshell.execDetached([Quickshell.env('HOME')+'/.local/bin/sensei-workbench','scratch']);}
 function capture():void {ShellState.closeAll();Quickshell.execDetached([Quickshell.env('HOME')+'/.local/bin/sensei-workbench','capture']);}
 IpcHandler {target:'workbench';function scratch():void {root.scratch();}function capture():void {root.capture();}function quiet():void {root.toggleQuiet();}function state():string{return JSON.stringify({quiet:root.quiet});}}
}
