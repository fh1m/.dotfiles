import QtQuick
import QtQuick.Controls
import qs.config
Button {
 id:root
 Accessible.name:text
 font.family:Appearance.font.data;font.pixelSize:13
 padding:10
 contentItem:Text {text:root.text;color:root.enabled?(root.highlighted?Theme.widgetAccent:Theme.widgetText):Theme.widgetMuted;font:root.font;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
 background:Rectangle {color:root.down||root.hovered||root.highlighted?Theme.widgetRaised:Theme.widgetSurface;radius:3;border.width:1;border.color:root.activeFocus?Theme.widgetAccent:Theme.widgetBorder}
}
