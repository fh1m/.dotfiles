import QtQuick
import Quickshell.Services.SystemTray
import qs.components
import qs.config
import qs.services
BarSurface {
 id:root
 readonly property var items:SystemTray.items.values
 visible:items.length>0
 implicitWidth:visible?trayRow.implicitWidth+16:0
 implicitHeight:34
 grouped:false
 Row {id:trayRow;anchors.centerIn:parent;spacing:8
  Repeater {model:root.items
   Item {id:trayIcon;required property var modelData;width:24;height:24
    Image {id:trayArt;visible:status===Image.Ready;anchors.fill:parent;source:trayIcon.modelData.icon;sourceSize:Qt.size(48,48);fillMode:Image.PreserveAspectFit;asynchronous:true}
    Text {anchors.centerIn:parent;visible:trayArt.status!==Image.Ready;text:"\uf009";font.family:Appearance.font.icons;font.pixelSize:18;color:Theme.text}
    MouseArea {anchors.fill:parent;acceptedButtons:Qt.LeftButton|Qt.RightButton|Qt.MiddleButton;cursorShape:Qt.PointingHandCursor
     onClicked:mouse=>{if(mouse.button===Qt.RightButton||trayIcon.modelData.onlyMenu){const p=trayIcon.mapToItem(null,0,0);trayIcon.modelData.display(ShellState.bottomBarWindow,Math.round(p.x),Math.round(p.y));}else if(mouse.button===Qt.MiddleButton)trayIcon.modelData.secondaryActivate();else trayIcon.modelData.activate();}
     onWheel:event=>{trayIcon.modelData.scroll(event.angleDelta.y,false);event.accepted=true;}
    }
   }
  }
 }
}
