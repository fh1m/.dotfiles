import QtQuick
import QtQuick.Controls
import qs.config
TextArea {
 id:root
 Accessible.name:placeholderText
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body
 color:NoesisStyle.ink;placeholderTextColor:NoesisStyle.quiet
 selectionColor:NoesisStyle.accent;selectedTextColor:NoesisStyle.ink
 padding:NoesisStyle.md;wrapMode:TextEdit.Wrap
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.surface;border.width:1;border.color:root.activeFocus?NoesisStyle.accent:NoesisStyle.rule}
}
