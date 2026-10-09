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
   Text {textFormat:Text.PlainText;text:root.title;color:root.highlighted?NoesisStyle.accent:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;Layout.fillWidth:true;wrapMode:Text.Wrap}
   Text {textFormat:Text.PlainText;text:root.subtitle;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true;wrapMode:Text.Wrap;visible:text!==""}
  }
  Text {textFormat:Text.PlainText;text:root.trailing;color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;visible:text!==""}
 }
 background:Rectangle {color:root.highlighted||root.hovered?NoesisStyle.hover:"transparent";radius:NoesisStyle.radius;border.width:root.activeFocus?1:0;border.color:NoesisStyle.accent;Behavior on color {ColorAnimation {duration:NoesisStyle.transition}}}
}
