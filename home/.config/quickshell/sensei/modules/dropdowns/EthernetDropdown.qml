import QtQuick
import qs.components
import qs.services
DropdownFrame {
 title:"Wired / Ethernet";implicitWidth:596
 readonly property real surfaceHeight: 520
 NetworkWorkbench {width:parent.width;preferredInterface:Ethernet.device}
}
