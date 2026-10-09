import QtQuick
import QtQuick.Controls
Button {
 id:root
 property bool primary:false
 property string variant:primary?"primary":"secondary"
 property bool busy:false
 property string hint:""
 property int textAlignment:Text.AlignHCenter
 Accessible.name:text
 hoverEnabled:true
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 implicitHeight:Math.max(NoesisStyle.control,contentItem.implicitHeight+topPadding+bottomPadding)
 leftPadding:NoesisStyle.md;rightPadding:NoesisStyle.md;topPadding:NoesisStyle.sm;bottomPadding:NoesisStyle.sm
 contentItem:Text {textFormat:Text.PlainText;text:root.text;color:!root.enabled?NoesisStyle.quiet:root.variant==="primary"?NoesisStyle.selectionInk:root.variant==="danger"?NoesisStyle.error:root.highlighted?NoesisStyle.accent:NoesisStyle.ink;font:root.font;horizontalAlignment:root.textAlignment;verticalAlignment:Text.AlignVCenter;wrapMode:Text.Wrap}
 background:Rectangle {color:!root.enabled?NoesisStyle.hover:root.variant==="primary"?NoesisStyle.accent:root.down||root.hovered||root.highlighted||root.variant==="secondary"?NoesisStyle.hover:"transparent";radius:NoesisStyle.radius;border.width:root.activeFocus||root.variant==="secondary"?2:0;border.color:root.activeFocus?NoesisStyle.ink:NoesisStyle.rule;Behavior on color {ColorAnimation {duration:NoesisStyle.transition}}}
 ToolTip.visible:hint!==""&&hovered
 ToolTip.text:hint
 ToolTip.delay:600
}
