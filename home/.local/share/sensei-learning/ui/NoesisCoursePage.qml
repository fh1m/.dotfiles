import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property var rows:[]
 property string parentId:""
 property string cursor:""
 property bool busy:false
 property string summary:""
 property var source:({})
 property alias currentIndex:outline.currentIndex
 property alias editing:outline.editing
 property alias moduleRows:outline.moduleRows
 property alias moduleCursor:outline.moduleCursor
 readonly property bool listFocused:outline.listFocused
 signal openMember(var row)
 signal moveMember(string identity,string direction)
 signal loadMore()
 signal importOutline()
 signal expandModule(var row,bool more)
 signal openSource()
 signal showActions()
 spacing:NoesisStyle.lg
 Text {textFormat:Text.PlainText;text:root.summary;visible:text!=="";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
 Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
  NoesisButton {text:root.source.local_file||root.source.zotero_attachment_key?"Open reading ↗":"Open source ↗";primary:true;visible:!!(root.source.source||root.source.local_file||root.source.zotero_attachment_key);enabled:!root.busy;onClicked:root.openSource()}
  NoesisButton {text:"Continue";visible:root.rows.length>0;enabled:!root.busy;onClicked:{let row=root.rows.find(row=>!["read","complete","passed","replaced"].includes(row.status))||root.rows[0];root.openMember(row);}}
  NoesisButton {text:"Course actions";enabled:!root.busy;onClicked:root.showActions()}
 }
 Text {textFormat:Text.PlainText;visible:!!(root.source.source||root.source.local_file);text:"Current material · "+(root.source.source_kind||"source")+"\n"+(root.source.source||root.source.local_file);color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
 NoesisCourseOutline {id:outline;Layout.fillWidth:true;rows:root.rows;parentId:root.parentId;cursor:root.cursor;busy:root.busy;headingLabel:root.source.unit_kind==="module"?"Module outline":"Course outline"
  onOpenMember:row=>root.openMember(row)
  onMoveMember:(identity,direction)=>root.moveMember(identity,direction)
  onLoadMore:root.loadMore()
  onImportOutline:root.importOutline()
  onExpandModule:(row,more)=>root.expandModule(row,more)
 }
}
