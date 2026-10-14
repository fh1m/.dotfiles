import QtQuick
import QtQuick.Layouts

Rectangle {
 id:document
 property var blocks:[]
 property bool framed:true
 property string label:""
 property bool originalAvailable:true
 property string originalAction:"View in complete note ↗"
 signal openOriginal()
 color:framed?NoesisStyle.canvas:"transparent"
 radius:NoesisStyle.radius
 readonly property int inset:framed?NoesisStyle.xl:0
 implicitHeight:reading.implicitHeight+inset*2
 ColumnLayout {
  id:reading;x:document.inset;y:document.inset;width:Math.max(0,document.width-document.inset*2);spacing:NoesisStyle.lg
  Text {visible:document.label!=="";Layout.fillWidth:true;text:document.label;textFormat:Text.PlainText;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
  Repeater {model:document.blocks;delegate:NoesisDocumentBlock {required property var modelData;Layout.fillWidth:true;value:modelData;originalAvailable:document.originalAvailable;originalAction:document.originalAction;onOpenOriginal:document.openOriginal()}}
 }
}
