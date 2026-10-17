pragma Singleton
import QtQuick
import Quickshell
import QtMultimedia
Singleton {
 id:root
 MediaDevices {id:devices}
 readonly property var inputs:devices.videoInputs
 readonly property bool available:inputs.length>0
 readonly property var microphones:devices.audioInputs
 readonly property var speakers:devices.audioOutputs
}
