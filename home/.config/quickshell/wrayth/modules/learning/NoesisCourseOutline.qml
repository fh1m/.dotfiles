import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

ColumnLayout {
 id:root
 property alias currentIndex:list.currentIndex
 readonly property bool listFocused:list.activeFocus
 property var rows:[]
 property string parentId:""
 property string cursor:""
 property bool busy:false
 property bool editing:false
 property string selectedMember:""
 signal openMember(var row)
 signal moveMember(string identity,string direction)
 signal loadMore()
 signal importOutline()
 spacing:NoesisStyle.sm
 Shortcut {sequence:"Ctrl+Shift+R";enabled:root.visible&&!root.busy;onActivated:{root.editing=!root.editing;if(root.editing){list.currentIndex=Math.max(0,list.currentIndex);list.forceActiveFocus();}}}
 Shortcut {sequence:"Ctrl+Shift+PgDown";enabled:root.visible&&!root.busy&&root.cursor!=="";onActivated:root.loadMore()}
 onParentIdChanged:{editing=false;selectedMember="";}
 onRowsChanged:if(editing&&selectedMember&&rows.length){let index=rows.findIndex(r=>r.id===selectedMember);if(index>=0){Qt.callLater(()=>{list.currentIndex=index;list.positionViewAtIndex(index,ListView.Contain);list.forceActiveFocus();});}}
 function move(direction){let index=list.currentIndex;if(index<0||busy)return;selectedMember=rows[index].id;moveMember(selectedMember,direction);}
 function label(row){let kind=row.unit_kind||({task:"Assignment",project:"Project",capability:"Capability",concept:"Concept"})[row.type]||row.type;kind=kind.charAt(0).toUpperCase()+kind.slice(1);let status=({active:"In progress",queued:"Not started",read:"Read",complete:"Complete",parked:"Paused",passed:"Completed",replaced:"Replaced"})[row.status]||"";return kind+(status?" · "+status:"")+(row.position?" · "+row.position:"");}
 RowLayout {
  Layout.fillWidth:true
  Text {text:root.editing?"Arrange outline":"Course outline";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;color:NoesisStyle.ink;Layout.fillWidth:true}
  NoesisButton {text:root.editing?"Done":"Arrange";highlighted:root.editing;visible:root.rows.length>0;enabled:!root.busy;onClicked:{root.editing=!root.editing;if(root.editing){list.currentIndex=Math.max(0,list.currentIndex);list.forceActiveFocus();}} hint:"Ctrl+Shift+R";Accessible.name:"Arrange course outline"}
  NoesisButton {text:"↑";visible:root.editing;enabled:!root.busy&&list.currentIndex>0;onClicked:root.move("up");hint:"Alt+Up";Accessible.name:"Move selected outline item earlier"}
  NoesisButton {text:"↓";visible:root.editing;enabled:!root.busy&&list.currentIndex>=0&&list.currentIndex+1<root.rows.length;onClicked:root.move("down");hint:"Alt+Down";Accessible.name:"Move selected outline item later"}
 }
 NoesisButton {text:"Add a course outline";visible:root.rows.length===0&&!root.busy;enabled:!root.busy;onClicked:root.importOutline();hint:"Ctrl+Shift+O · review before adding lessons"}
 Text {visible:root.editing;text:"Select a lesson, then move it earlier or later. Its history stays intact.";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true}
 ListView {
  id:list
  Layout.fillWidth:true
  Layout.preferredHeight:Math.min(360,root.rows.length*NoesisStyle.row)
  model:root.rows;clip:true;keyNavigationEnabled:true
  Keys.onReturnPressed:if(currentIndex>=0&&!root.busy)root.openMember(root.rows[currentIndex])
  Shortcut {sequence:"Alt+Up";enabled:root.editing&&list.activeFocus&&list.currentIndex>0;onActivated:root.move("up")}
  Shortcut {sequence:"Alt+Down";enabled:root.editing&&list.activeFocus&&list.currentIndex+1<root.rows.length;onActivated:root.move("down")}
  delegate:NoesisRow {
   required property var modelData
   required property int index
   width:ListView.view.width
   title:modelData.title
   subtitle:root.label(modelData)
   highlighted:root.editing&&ListView.isCurrentItem
   onClicked:{if(root.busy)return;if(root.editing){list.currentIndex=index;root.selectedMember=modelData.id;list.forceActiveFocus();}else root.openMember(modelData);}
  }
  ScrollBar.vertical:ScrollBar {policy:ScrollBar.AlwaysOn}
 }
 NoesisButton {text:"Load more lessons";hint:"Ctrl+Shift+PageDown";visible:root.cursor!=="";enabled:!root.busy;onClicked:root.loadMore()}
}
