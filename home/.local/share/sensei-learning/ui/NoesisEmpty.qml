import QtQuick
import QtQuick.Layouts
ColumnLayout {
 property string title:""
 property string description:""
 property string action:""
 signal activated()
 spacing:NoesisStyle.md
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:parent.title;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;wrapMode:Text.Wrap;Layout.fillWidth:true}
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:parent.description;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;Layout.fillWidth:true}
 NoesisButton {text:parent.action;visible:text!=="";primary:true;onClicked:parent.activated()}
}
