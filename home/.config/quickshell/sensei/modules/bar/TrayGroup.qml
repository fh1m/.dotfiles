import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.components
import qs.config
import qs.services
BarSurface {
 id:root
 readonly property var items:SystemTray.items.values
 function openMenu(index){const icon=trayItems.itemAt(index);if(!icon||!icon.modelData.hasMenu)return false;const window=icon.QsWindow.window;if(!window)return false;const p=window.contentItem.mapFromItem(icon,0,icon.height);icon.modelData.display(window,Math.round(p.x),Math.round(p.y));return true;}
 IpcHandler {target:'tray-'+(root.QsWindow.window?.screen?.name||'pending');function state():string{return JSON.stringify({output:root.QsWindow.window?.screen?.name||'',items:root.items.map(i=>({title:i.title,hasMenu:i.hasMenu}))});}function menu(index:int):bool{return root.openMenu(index);}}

 visible:items.length>0
 implicitWidth:visible?trayRow.implicitWidth+12:0
 implicitHeight:34
 grouped:true
 Row {id:trayRow;anchors.centerIn:parent;spacing:10
  Repeater {id:trayItems;model:root.items
   Item {id:trayIcon;required property var modelData;required property int index;width:26;height:26
    Image {id:trayArt;visible:status===Image.Ready;anchors.centerIn:parent;width:18;height:18;source:trayIcon.modelData.icon;sourceSize:Qt.size(36,36);fillMode:Image.PreserveAspectFit;asynchronous:true}
    Text { textFormat: Text.PlainText;anchors.centerIn:parent;visible:trayArt.status!==Image.Ready;text:"\uf009";font.family:Appearance.font.icons;font.pixelSize:16;color:Theme.text}
    MouseArea {anchors.fill:parent;acceptedButtons:Qt.LeftButton|Qt.RightButton|Qt.MiddleButton;cursorShape:Qt.PointingHandCursor
     onClicked:mouse=>{if(mouse.button===Qt.RightButton||trayIcon.modelData.onlyMenu){root.openMenu(trayIcon.index);}else if(mouse.button===Qt.MiddleButton)trayIcon.modelData.secondaryActivate();else trayIcon.modelData.activate();}
     onWheel:event=>{trayIcon.modelData.scroll(event.angleDelta.y,false);event.accepted=true;}
    }
   }
  }
 }
}
