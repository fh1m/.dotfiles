import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:block
 property var value:({})
 property bool originalAvailable:true
 property string originalAction:"View in complete note ↗"
 signal openOriginal()
 spacing:NoesisStyle.sm
 readonly property bool code:value.kind==="code"
 readonly property bool table:value.kind==="table"
 readonly property bool handoff:value.kind==="caption"
 readonly property var cells:table?(value.columns_html||value.columns||[]).concat((value.rows_html||value.rows||[]).reduce((items,row)=>items.concat(row),[])):[]
 Text {visible:block.code||block.value.kind==="quote";Layout.fillWidth:true;textFormat:Text.PlainText;text:block.code?block.value.language||"Code excerpt":"Quoted passage";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;renderType:Text.NativeRendering}
 TextEdit {
  id:readingText;padding:block.code?NoesisStyle.md:block.value.kind==="quote"?NoesisStyle.sm:0
  visible:!block.table&&!block.handoff;Layout.fillWidth:true;readOnly:true;selectByMouse:true;wrapMode:TextEdit.Wrap
  text:block.code?block.value.text||"":(block.value.html||block.value.display_text||block.value.text||"").replace(/<code>/g,"<font face='"+NoesisStyle.codeFont+"'>").replace(/<\/code>/g,"</font>")
  textFormat:block.code||!block.value.html?TextEdit.PlainText:TextEdit.RichText
  color:NoesisStyle.ink;font.family:block.code?NoesisStyle.codeFont:NoesisStyle.uiFont
  font.pixelSize:block.value.kind==="heading"?(block.value.level===1?NoesisStyle.heading:block.value.level===2?NoesisStyle.sectionHeading:NoesisStyle.subheading):block.code?NoesisStyle.label:NoesisStyle.body
  font.bold:block.value.kind==="heading";renderType:TextEdit.NativeRendering;font.hintingPreference:Font.PreferFullHinting
  Accessible.name:block.code?"Code excerpt":"Formatted reading"
  Rectangle {z:-1;anchors.fill:parent;color:block.code?NoesisStyle.surface:block.value.kind==="quote"?NoesisStyle.hover:"transparent";radius:NoesisStyle.radius}
 }
 ColumnLayout {visible:block.handoff;Layout.fillWidth:true;spacing:NoesisStyle.xs
  Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:block.value.display_text||block.value.text||"Specialist content";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;renderType:Text.NativeRendering}
  NoesisButton {text:block.originalAvailable?block.originalAction:"Complete note protected for this attempt";enabled:block.originalAvailable;variant:"tertiary";onClicked:block.openOriginal()}
 }
 ScrollView {id:tableScroll;implicitWidth:0;implicitHeight:0;visible:block.table;Layout.fillWidth:true;Layout.preferredHeight:tableGrid.implicitHeight;clip:true;contentWidth:Math.max(block.width,Math.max(1,(block.value.columns||[]).length)*120*NoesisStyle.readingScale);contentHeight:tableGrid.implicitHeight
  GridLayout {id:tableGrid;width:tableScroll.contentWidth;columns:Math.max(1,(block.value.columns||[]).length);columnSpacing:NoesisStyle.md;rowSpacing:NoesisStyle.sm
   Repeater {model:block.cells;delegate:TextEdit {required property string modelData;required property int index;Layout.preferredWidth:(tableGrid.width-(tableGrid.columns-1)*tableGrid.columnSpacing)/tableGrid.columns;text:modelData.replace(/<code>/g,"<font face='"+NoesisStyle.codeFont+"'>").replace(/<\/code>/g,"</font>");textFormat:block.value.columns_html?TextEdit.RichText:TextEdit.PlainText;readOnly:true;selectByMouse:true;wrapMode:TextEdit.Wrap;color:index<tableGrid.columns?NoesisStyle.ink:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;font.bold:index<tableGrid.columns;renderType:TextEdit.NativeRendering}}
  }
 }
}
