import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
ItemDelegate {
 id:root
 property string title:""
 property string subtitle:""
 property string trailing:""
 Accessible.name:title+". "+subtitle
 implicitHeight:NoesisStyle.row
 padding:NoesisStyle.md
 contentItem:RowLayout {
  spacing:NoesisStyle.md
  ColumnLayout {Layout.fillWidth:true;spacing:NoesisStyle.xs
   Text {text:root.title;color:root.highlighted?NoesisStyle.accent:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;Layout.fillWidth:true;elide:Text.ElideRight}
   Text {text:root.subtitle;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;Layout.fillWidth:true;elide:Text.ElideRight;visible:text!==""}
  }
  Text {text:root.trailing;color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;visible:text!==""}
 }
 background:Rectangle {color:root.highlighted||root.hovered?NoesisStyle.hover:"transparent";radius:NoesisStyle.radius;border.width:root.activeFocus?1:0;border.color:NoesisStyle.accent;Behavior on color {ColorAnimation {duration:NoesisStyle.transition}}}
}
