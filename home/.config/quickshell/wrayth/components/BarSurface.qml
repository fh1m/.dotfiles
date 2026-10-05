import QtQuick
import qs.config

// One filled control surface for both bars. Colour changes are cheap; the
// geometry remains fixed so interaction never reconfigures a layer surface.
ChamferPanel {
    id: root
    property bool hovered: false
    property bool selected: false
    property bool pressed: false
    property bool grouped: false
    chamfer: grouped ? 2 : 4
    scanlines: false
    fillColor: pressed ? Theme.widgetRaised
                       : hovered ? Theme.blend(Theme.barBg, Theme.widgetRaised, .80)
                       : Theme.blend(Theme.barBg, Theme.widgetRaised, .32)
    borderColor: grouped ? "transparent" : selected ? Theme.alpha(Theme.widgetAccent, .52)
                          : hovered ? Theme.alpha(Theme.widgetAccent, .25) : Theme.alpha(Theme.widgetText, .10)
    borderWidth: grouped ? 0 : 1
    scale: pressed ? .975 : 1
    Behavior on fillColor { ColorAnimation { duration: root.pressed ? 60 : 130 } }
    Behavior on borderColor { ColorAnimation { duration: 130 } }
    Behavior on scale { NumberAnimation { duration: root.pressed ? 60 : 150; easing.type: Easing.OutCubic } }
}
