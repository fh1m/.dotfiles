import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property alias currentIndex:list.currentIndex
 readonly property bool listFocused:list.activeFocus
 property var rows:[]
 property string headingLabel:"Course outline"
 property string parentId:""
 property string cursor:""
 property string expandedModule:""
 property var moduleRows:[]
 property string moduleCursor:""
 signal expandModule(var row,bool more)
 property bool busy:false
 property bool editing:false
 property string selectedMember:""
 property string activeLesson:""
 signal openMember(var row)
 signal moveMember(string identity,string direction)
 signal loadMore()
 signal importOutline()
 spacing:NoesisStyle.sm
 Shortcut {sequence:"Ctrl+Shift+R";enabled:root.visible&&!root.busy;onActivated:{root.editing=!root.editing;if(root.editing){list.currentIndex=Math.max(0,list.currentIndex);list.forceActiveFocus();}}}
 Shortcut {sequence:"Ctrl+Shift+PgDown";enabled:root.visible&&!root.busy&&root.cursor!=="";onActivated:root.loadMore()}
 onParentIdChanged:{editing=false;selectedMember="";expandedModule="";moduleRows=[];moduleCursor="";}
 onRowsChanged:if(editing&&selectedMember&&rows.length){let index=rows.findIndex(r=>r.id===selectedMember);if(index>=0){Qt.callLater(()=>{list.currentIndex=index;list.positionViewAtIndex(index,ListView.Contain);list.forceActiveFocus();});}}
 function move(direction){let index=list.currentIndex;if(index<0||busy)return;selectedMember=rows[index].id;moveMember(selectedMember,direction);}
 function label(row){let kind=row.unit_kind||({task:"Assignment",project:"Project",capability:"Capability",concept:"Concept"})[row.type]||row.type;kind=kind.charAt(0).toUpperCase()+kind.slice(1);let status=({active:"In progress",queued:"Not started",read:"Read",complete:"Complete",parked:"Paused",passed:"Completed",replaced:"Replaced"})[row.status]||"";return kind+(status?" · "+status:"")+(row.position?" · "+row.position:"");}
 Flow {
  Layout.fillWidth:true;spacing:NoesisStyle.sm
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:root.editing?"Arrange outline":root.headingLabel;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;color:NoesisStyle.ink;Layout.fillWidth:true}
  NoesisButton {text:root.editing?"Done":"Arrange";highlighted:root.editing;visible:root.rows.length>0;enabled:!root.busy;onClicked:{root.editing=!root.editing;if(root.editing){list.currentIndex=Math.max(0,list.currentIndex);list.forceActiveFocus();}} hint:"Ctrl+Shift+R";Accessible.name:"Arrange course outline"}
  NoesisButton {text:"↑";visible:root.editing;enabled:!root.busy&&list.currentIndex>0;onClicked:root.move("up");hint:"Alt+Up";Accessible.name:"Move selected outline item earlier"}
  NoesisButton {text:"↓";visible:root.editing;enabled:!root.busy&&list.currentIndex>=0&&list.currentIndex+1<root.rows.length;onClicked:root.move("down");hint:"Alt+Down";Accessible.name:"Move selected outline item later"}
 }
 NoesisButton {text:"Add a course outline";visible:root.rows.length===0&&!root.busy;enabled:!root.busy;onClicked:root.importOutline();hint:"Ctrl+Shift+O · review before adding lessons"}
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:root.editing;text:"Select a lesson, then move it earlier or later. Its history stays intact.";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true}
 ListView {
  id:list
  Layout.fillWidth:true
  Layout.preferredHeight:list.contentHeight;Layout.minimumHeight:0
  model:root.rows;clip:true;keyNavigationEnabled:true
  Keys.onRightPressed:{let row=root.rows[currentIndex];if(row?.unit_kind==="module"&&!root.busy){root.expandedModule=row.id;root.moduleRows=[];root.moduleCursor="";root.expandModule(row,false);}}
  Keys.onLeftPressed:if(root.expandedModule){root.expandedModule="";root.moduleRows=[];}
  Keys.onReturnPressed:if(currentIndex>=0&&!root.busy)root.openMember(root.rows[currentIndex])
  Shortcut {sequence:"Alt+Up";enabled:root.editing&&list.activeFocus&&list.currentIndex>0;onActivated:root.move("up")}
  Shortcut {sequence:"Alt+Down";enabled:root.editing&&list.activeFocus&&list.currentIndex+1<root.rows.length;onActivated:root.move("down")}
  delegate:ColumnLayout {
   required property var modelData
   required property int index
   width:ListView.view.width
   spacing:NoesisStyle.sm
   RowLayout {Layout.fillWidth:true;spacing:NoesisStyle.sm
    NoesisRow {Layout.fillWidth:true;title:(modelData.unit_kind==="module"?(root.expandedModule===modelData.id?"▾ ":"▸ "):"")+modelData.title;subtitle:modelData.unit_kind==="module"?"Lessons and assessments":root.label(modelData);highlighted:root.editing&&list.currentIndex===index
     onClicked:{if(root.busy)return;if(root.editing){list.currentIndex=index;root.selectedMember=modelData.id;list.forceActiveFocus();}else if(modelData.unit_kind==="module"){if(root.expandedModule===modelData.id){root.expandedModule="";root.moduleRows=[];}else {root.expandedModule=modelData.id;root.moduleRows=[];root.expandModule(modelData,false);}}else root.openMember(modelData);}}
   }
   ColumnLayout {visible:root.expandedModule===modelData.id;Layout.fillWidth:true;Layout.leftMargin:NoesisStyle.lg;spacing:NoesisStyle.sm
    Repeater {model:parent.visible?root.moduleRows:[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title;highlighted:root.activeLesson===modelData.id;subtitle:root.label(modelData);onClicked:root.openMember(modelData)}}
    NoesisButton {visible:root.moduleCursor!=="";text:"More lessons";enabled:!root.busy;onClicked:root.expandModule(modelData,true)}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!root.busy&&root.moduleRows.length===0;text:"No lessons in this module yet.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
   }
  }
  ScrollBar.vertical:ScrollBar {policy:ScrollBar.AsNeeded}
 }
 NoesisButton {text:"Load more lessons";hint:"Ctrl+Shift+PageDown";visible:root.cursor!=="";enabled:!root.busy;onClicked:root.loadMore()}
}
