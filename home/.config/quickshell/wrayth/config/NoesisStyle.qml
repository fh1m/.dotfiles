pragma Singleton
import QtQuick
import Quickshell
import qs.config
Singleton {
 readonly property string uiFont:"Adwaita Sans"
 readonly property string codeFont:Appearance.font.data
 readonly property int caption:12
 readonly property int label:13
 readonly property int body:15
 readonly property int heading:22
 readonly property int title:30
 readonly property int xs:4
 readonly property int sm:8
 readonly property int md:12
 readonly property int lg:16
 readonly property int xl:24
 readonly property int page:32
 readonly property int control:34
 readonly property int row:62
 readonly property int radius:5
 readonly property int readingWidth:760
 readonly property color canvas:"#000000"
 readonly property color surface:Theme.widgetSurface
 readonly property color hover:Theme.widgetRaised
 readonly property color ink:Theme.widgetText
 readonly property color secondary:Theme.widgetMuted
 readonly property color quiet:Theme.widgetFaint
 readonly property color accent:Theme.widgetAccent
 readonly property color rule:Theme.widgetBorder
 readonly property int transition:Appearance.duration.state
}
