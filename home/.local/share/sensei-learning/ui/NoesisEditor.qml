import QtQuick
import QtQuick.Controls
TextArea {
 id:root
 readOnly:NoesisController.exitRequested
 Accessible.name:placeholderText
 Keys.onPressed:event=>{if((event.key===Qt.Key_Tab||event.key===Qt.Key_Backtab)&&(event.modifiers&Qt.ControlModifier)){event.accepted=true;let next=root.nextItemInFocusChain(!(event.modifiers&Qt.ShiftModifier)&&event.key!==Qt.Key_Backtab);if(next)next.forceActiveFocus(Qt.TabFocusReason);}}
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body
 color:NoesisStyle.ink;placeholderTextColor:NoesisStyle.quiet
 selectionColor:NoesisStyle.accent;selectedTextColor:NoesisStyle.selectionInk
 padding:NoesisStyle.md;wrapMode:TextEdit.Wrap
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.hover
  Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;height:2;visible:root.activeFocus;color:NoesisStyle.accent}
 }
}
