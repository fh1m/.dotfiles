import QtQuick
import qs.services
import qs.config
Item {
 id:root
 property var entry:null
 property int size:32
 implicitWidth:size
 implicitHeight:size
 Image {
  id:art;anchors.fill:parent;source:WindowDesk.iconFor(root.entry)
  sourceSize.width:root.size*2;sourceSize.height:root.size*2
  fillMode:Image.PreserveAspectFit;asynchronous:true;smooth:true
  visible:status===Image.Ready
 }
 Text {
  anchors.centerIn:parent;visible:art.status!==Image.Ready
  text:"\uf2d0";font.family:Appearance.font.icons;font.pixelSize:root.size*.65;color:Theme.dim
 }
}
