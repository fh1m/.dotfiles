import QtQuick
import QtQuick.Controls
import qs.config
Button {
 id:root
 property bool primary:false
 property string hint:""
 property int textAlignment:Text.AlignHCenter
 Accessible.name:text
 hoverEnabled:true
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 implicitHeight:NoesisStyle.control
 leftPadding:NoesisStyle.md;rightPadding:NoesisStyle.md;topPadding:NoesisStyle.sm;bottomPadding:NoesisStyle.sm
 contentItem:Text {text:root.text;color:!root.enabled?NoesisStyle.quiet:root.primary||root.highlighted?NoesisStyle.accent:NoesisStyle.ink;font:root.font;horizontalAlignment:root.textAlignment;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
 background:Rectangle {color:root.down||root.hovered||root.highlighted||root.primary?NoesisStyle.hover:"transparent";radius:NoesisStyle.radius;border.width:root.activeFocus||root.primary?1:0;border.color:root.activeFocus?NoesisStyle.accent:NoesisStyle.rule;Behavior on color {ColorAnimation {duration:NoesisStyle.transition}}}
 ToolTip.visible:hint!==""&&hovered
 ToolTip.text:hint
 ToolTip.delay:600
}
