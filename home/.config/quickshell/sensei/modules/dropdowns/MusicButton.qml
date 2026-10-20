import QtQuick
import qs.config
ControlTile {
 id:root
 textSize:Appearance.textSize.control
 textFamily:Appearance.font.ui
 implicitHeight:38
 radius:9
 color:root.down?Theme.alpha(Theme.paper,.16):root.selected?Theme.alpha(Theme.signalRed,.18):hover.hovered?Theme.alpha(Theme.paper,.1):Theme.alpha(Theme.paper,.045)
 border.color:root.activeFocus?Theme.signalRed:root.selected?Theme.alpha(Theme.signalRed,.4):Theme.alpha(Theme.paper,.13)
 HoverHandler {id:hover}
}
