import QtQuick
import Sensei.Media 1.0
import qs.services
MpvSurface {
    id:root
    property string ownerOutput:""
    Component.onDestruction:if(ownerOutput)YouTubeDesk.forgetEngine(ownerOutput,root)
    z:0
    visible:YouTubeDesk.nativeVideo&&parent!==null
}
