import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

NoesisDialog {
 id:root
 property var target:({})
 property var rows:[]
 property var chosen:({})
 property string vaultScope:""
 property bool submitting:false
 signal search(string query)
 title:"Connect a prerequisite"
 function begin(record){target=Object.assign({},record);vaultScope=NoesisController.activeVault;rows=[];chosen=({});lookup.text="";reason.text="";role.currentIndex=0;submitting=false;open();lookup.forceActiveFocus();}
 function results(records){if(opened&&vaultScope===NoesisController.activeVault){rows=records.filter(row=>row.id!==target.id);matches.currentIndex=rows.length?0:-1;}}
 contentItem:ColumnLayout {
  spacing:NoesisStyle.md
  Text {text:"What do you need for this lesson or problem? Reuse material in this vault.";Layout.fillWidth:true;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
  NoesisField {id:lookup;Layout.fillWidth:true;placeholderText:"Find a concept, prerequisite or exercise";onTextEdited:delay.restart();Keys.onDownPressed:{if(root.rows.length){matches.currentIndex=0;matches.forceActiveFocus();}}}
  ListView {id:matches;Layout.fillWidth:true;Layout.preferredHeight:Math.min(200,root.rows.length*NoesisStyle.row);model:root.rows;clip:true;keyNavigationEnabled:true
   Keys.onReturnPressed:{if(currentIndex>=0){root.chosen=root.rows[currentIndex];reason.forceActiveFocus();}}
   delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.title;subtitle:modelData.type;highlighted:root.chosen.id===modelData.id;onClicked:{root.chosen=modelData;reason.forceActiveFocus();}}
   ScrollBar.vertical:ScrollBar {}
  }
  Text {visible:!!root.chosen.id;text:"Prerequisite · "+(root.chosen.title||"");Layout.fillWidth:true;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
  NoesisField {id:reason;Layout.fillWidth:true;placeholderText:"Why is this needed here?";Accessible.name:"Prerequisite reason"}
  NoesisSelect {id:role;Layout.fillWidth:true;model:["Required before continuing","Study alongside","Optional deeper study"];Accessible.name:"Prerequisite role"}
  Text {text:"This connects the material. It does not claim that you understand it or award capability.";Layout.fillWidth:true;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
  NoesisButton {id:save;text:"Connect prerequisite";primary:true;hint:"Ctrl+Enter";enabled:!!root.chosen.id&&reason.text.trim()!==""&&!NoesisController.working&&root.vaultScope===NoesisController.activeVault;onClicked:{root.submitting=true;NoesisController.run(["link",root.target.id,root.chosen.id,"prerequisite","--role",["gate","parallel","deep-descent"][role.currentIndex],"--reason",reason.text]);}}
 }
 Timer {id:delay;interval:150;onTriggered:root.search(lookup.text)}
 Shortcut {sequence:"Ctrl+Return";enabled:root.opened;onActivated:if(save.enabled)save.clicked()}
 Connections {target:NoesisController;function onFinished(ok){if(root.submitting){root.submitting=false;if(ok)root.close();}}}
}
