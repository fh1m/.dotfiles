import QtQuick
import QtQuick.Controls
TextField {
 id:root
 renderType:TextEdit.NativeRendering
 font.hintingPreference:Font.PreferFullHinting
 readOnly:NoesisController.exitRequested
 Accessible.name:placeholderText
 hoverEnabled:true;selectByMouse:true
 implicitHeight:NoesisStyle.control
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 color:NoesisStyle.ink;placeholderTextColor:NoesisStyle.quiet
 selectionColor:NoesisStyle.accent;selectedTextColor:NoesisStyle.selectionInk
 leftPadding:NoesisStyle.md;rightPadding:NoesisStyle.md
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.hover
  Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:2;visible:root.activeFocus;color:NoesisStyle.accent}
 }
}
