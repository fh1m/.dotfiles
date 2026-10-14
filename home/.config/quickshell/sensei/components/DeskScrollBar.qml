import QtQuick
import QtQuick.Controls
import qs.config
ScrollBar {
 id:root
 implicitWidth:6;implicitHeight:6;padding:0
 hoverEnabled:true
 minimumSize:0.06
 policy:ScrollBar.AsNeeded
 contentItem:Rectangle {
  implicitWidth:6;implicitHeight:6;radius:3
  color:root.pressed?Theme.widgetAccent:root.hovered?Theme.widgetMuted:Theme.widgetBorder
  opacity:root.size<1?(root.active||root.hovered?1:.5):0
  Behavior on color {ColorAnimation {duration:120}}
  Behavior on opacity {NumberAnimation {duration:160}}
 }
}
