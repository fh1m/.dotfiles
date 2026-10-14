import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ItemDelegate {
 id:root
 property string title:""
 property string subtitle:""
 property string trailing:""
 Accessible.name:title+". "+subtitle
 implicitHeight:Math.max(NoesisStyle.row,contentItem.implicitHeight+2*padding)
 padding:NoesisStyle.md
 contentItem:RowLayout {
  spacing:NoesisStyle.md
  ColumnLayout {Layout.fillWidth:true;spacing:NoesisStyle.xs
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.title;font.bold:root.highlighted;font.underline:root.activeFocus;color:root.highlighted?NoesisStyle.accent:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.uiText;Layout.fillWidth:true;wrapMode:Text.Wrap}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.subtitle;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true;wrapMode:Text.Wrap;visible:text!==""}
  }
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.trailing;color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;visible:text!==""}
 }
 background:Rectangle {color:root.highlighted||root.hovered?NoesisStyle.hover:"transparent";radius:NoesisStyle.radius;Behavior on color {ColorAnimation {duration:NoesisStyle.transition}}
  Rectangle {anchors.left:parent.left;anchors.top:parent.top;anchors.bottom:parent.bottom;width:2;color:NoesisStyle.accent;visible:root.highlighted}
 }
}
