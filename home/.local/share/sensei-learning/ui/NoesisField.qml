import QtQuick
import QtQuick.Controls
TextField {
 id:root
 readOnly:NoesisController.exitRequested
 Accessible.name:placeholderText
 hoverEnabled:true;selectByMouse:true
 implicitHeight:NoesisStyle.control
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 color:NoesisStyle.ink;placeholderTextColor:NoesisStyle.quiet
 selectionColor:NoesisStyle.accent;selectedTextColor:NoesisStyle.selectionInk
 leftPadding:NoesisStyle.md;rightPadding:NoesisStyle.md
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.surface;border.width:1;border.color:root.activeFocus?NoesisStyle.accent:NoesisStyle.rule;Behavior on border.color {ColorAnimation {duration:NoesisStyle.transition}}}
}
