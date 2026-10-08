import QtQuick
import QtQuick.Controls
import qs.config
Dialog {
 id:root
 modal:true
 padding:NoesisStyle.xl
 closePolicy:Popup.CloseOnEscape
 font.family:NoesisStyle.uiFont
 font.pixelSize:NoesisStyle.body
 header:Label {text:root.title;visible:text!=="";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;leftPadding:NoesisStyle.xl;rightPadding:NoesisStyle.xl;topPadding:NoesisStyle.xl;bottomPadding:NoesisStyle.sm;wrapMode:Text.Wrap}
 background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
 enter:Transition {NumberAnimation {property:"opacity";from:0;to:1;duration:NoesisStyle.transition}}
 exit:Transition {NumberAnimation {property:"opacity";from:1;to:0;duration:NoesisStyle.transition}}
}
