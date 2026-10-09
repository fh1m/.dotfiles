import QtQuick
import QtQuick.Controls
Dialog {
 id:root
 modal:true
 Overlay.modal:Rectangle {color:"#b3090807"}
 padding:NoesisStyle.xl
 closePolicy:Popup.CloseOnEscape
 font.family:NoesisStyle.uiFont
 font.pixelSize:NoesisStyle.body
 header:Label {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:root.title;visible:text!=="";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;leftPadding:NoesisStyle.xl;rightPadding:NoesisStyle.xl;topPadding:NoesisStyle.xl;bottomPadding:NoesisStyle.sm;wrapMode:Text.Wrap}
 background:Rectangle {color:NoesisStyle.canvas;radius:NoesisStyle.radius;}
 enter:Transition {NumberAnimation {property:"opacity";from:0;to:1;duration:NoesisStyle.transition}}
 exit:Transition {NumberAnimation {property:"opacity";from:1;to:0;duration:NoesisStyle.transition}}
}
