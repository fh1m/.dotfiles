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
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.surface;border.width:1;border.color:root.activeFocus?NoesisStyle.accent:NoesisStyle.rule}
}
