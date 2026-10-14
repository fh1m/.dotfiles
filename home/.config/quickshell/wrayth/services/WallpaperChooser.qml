pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root;property string output:"eDP-1";property string chosen:""
 function open(target){if(chooser.running)return;output=target;chosen="";ShellState.externalDialogOpen=true;chooser.running=true;}
 Process {id:chooser;command:["env","GDK_DEBUG=no-portals","zenity","--file-selection","--title=Sensei, choose a wallpaper for "+root.output,"--width=1100","--height=720","--filename="+(Wallpapers.folder||"@HOME@/Pictures")+"/","--file-filter=Images | *.png *.jpg *.jpeg *.webp *.bmp"]
 stdout:StdioCollector {onStreamFinished:root.chosen=text.trim()}
 onExited:(code,status)=>{if(code===0&&root.chosen)Wallpapers.setDisplay(root.output,root.chosen,Wallpapers.displayMode(root.output));ShellState.externalDialogOpen=false;}
 }
}
