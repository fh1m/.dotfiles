pragma Singleton
import QtQuick
import Quickshell
Singleton {
 property real interfaceScale:1
 property real readingScale:1
 readonly property string uiFont:"Zed Sans"
 readonly property string codeFont:"ZedMono Nerd Font Mono"
 readonly property int caption:Math.round(13*interfaceScale)
 readonly property int label:Math.round(14*interfaceScale)
 readonly property int body:Math.round(17*readingScale)
 readonly property int subheading:Math.round(18*interfaceScale)
 readonly property int sectionHeading:Math.round(18*interfaceScale)
 readonly property int heading:Math.round(22*interfaceScale)
 readonly property int title:Math.round(28*interfaceScale)
 readonly property int xs:4
 readonly property int sm:8
 readonly property int md:12
 readonly property int lg:16
 readonly property int xl:24
 readonly property int page:32
 readonly property int control:Math.round(40*interfaceScale)
 readonly property int row:Math.round(64*interfaceScale)
 readonly property int radius:5
 readonly property int readingWidth:Math.round(760*readingScale)
 readonly property color canvas:"#141210"
 readonly property color surface:"#090807"
 readonly property color hover:"#1e1b18"
 readonly property color ink:"#e8e2da"
 readonly property color secondary:"#a9a29a"
 readonly property color quiet:"#9b938a"
 readonly property color accent:"#f23d70"
 readonly property color error:"#ff8585"
 readonly property color warning:"#ffca80"
 readonly property color success:"#8edca5"
 readonly property color selectionInk:"#141210"
 readonly property color rule:"#807870"
 readonly property int transition:100
}
