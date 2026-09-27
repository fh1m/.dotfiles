import QtQuick
import QtQuick.Effects
Item {
 id:root
 property alias source:image.source
 property alias sourceSize:image.sourceSize
 property alias fillMode:image.fillMode
 property alias asynchronous:image.asynchronous
 readonly property int status:image.status
 property real cornerRadius:6
 Image {id:image;anchors.fill:parent;visible:false;asynchronous:true;retainWhileLoading:true;fillMode:Image.PreserveAspectCrop}
 MultiEffect {anchors.fill:parent;source:image;maskEnabled:true;maskSource:mask;maskThresholdMin:.5;maskSpreadAtMin:1}
 Item {id:mask;anchors.fill:parent;opacity:0;layer.enabled:true
 Rectangle {anchors.fill:parent;radius:root.cornerRadius;color:'white';antialiasing:true}
 }
}
