import QtQuick
import qs.config
import qs.services

// Existing shared CAVA output: no second capture process and no synthetic bars.
Item {
    id: root
    property bool enabledSpectrum: SpotifyDesk.spectrumEnabled
    property color accent: Theme.widgetAccent
    readonly property bool activeView: visible && enabledSpectrum && SpotifyDesk.playing
    property var levels: []
    onActiveViewChanged: levels = activeView ? Cava.levels : []
    Connections {
        target: Cava
        function onLevelsChanged() { if (root.activeView) root.levels = Cava.levels; }
    }
    Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:Theme.alpha(root.accent,.2)}
    Row {
        anchors.fill:parent
        spacing:3
        Repeater {
            model:48
            Item {
                required property int index
                width:Math.max(1,(root.width-47*3)/48)
                height:root.height
                Rectangle {
                    anchors.bottom:parent.bottom
                    width:parent.width
                    height:Math.max(1,(root.levels[parent.index]||0)*(root.height-2))
                    radius:Math.min(2,width/2)
                    color:root.accent
                    opacity:.3+.6*(root.levels[parent.index]||0)
                    Behavior on height {NumberAnimation {duration:80;easing.type:Easing.OutQuad}}
                }
            }
        }
    }
}
