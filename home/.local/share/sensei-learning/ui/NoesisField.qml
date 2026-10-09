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
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.hover
  Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:root.activeFocus?2:1;color:root.activeFocus?NoesisStyle.accent:NoesisStyle.rule}
 }
}
