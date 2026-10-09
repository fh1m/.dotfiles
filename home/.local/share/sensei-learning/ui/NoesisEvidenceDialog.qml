import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

NoesisDialog {
 id:root
 property var evidence:({})
 property var capabilities:[]
 property var selected:({})
 property string vaultScope:""
 property var criterionOptions:[]
 readonly property string chosenCriterion:criterionOptions.length>1?criteriaPicker.currentText:criterion.text
 property bool loading:false
 property bool submitting:false
 signal lookup(string query)
 signal inspect(string identity)
 title:"Review capability evidence"
 function begin(activity){evidence=activity;selected=({});criterionOptions=[];decision.currentIndex=0;capabilities=[];vaultScope=NoesisController.activeVault;filter.text="";criterion.text="";reasoning.text="";loading=true;open();lookup("");filter.forceActiveFocus();}
 function detail(record){selected=Object.assign({},record.props,{path:record.path});criterionOptions=Array.isArray(selected.criteria)?selected.criteria.filter(value=>typeof value==="string"):[];criterion.text=criterionOptions.length===1?criterionOptions[0]:"";if(criterionOptions.length===1)reasoning.forceActiveFocus();else if(criterionOptions.length>1)criteriaPicker.forceActiveFocus();else criterion.forceActiveFocus();}
 contentItem:ColumnLayout {spacing:NoesisStyle.md
  Text {text:"Reported "+(root.evidence.outcome||"unknown")+" · assistance: "+(root.evidence.assistance||["unknown"]).join(", ")+"\nScope: "+(root.evidence.scope||"not recorded");color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
  NoesisField {id:filter;visible:!root.selected.id;Layout.fillWidth:true;placeholderText:"Find a capability";onTextChanged:searchDelay.restart();Keys.onDownPressed:{list.currentIndex=0;list.forceActiveFocus();}}
  ListView {id:list;visible:!root.selected.id;Layout.fillWidth:true;Layout.preferredHeight:140;clip:true;model:root.capabilities
   Keys.onReturnPressed:if(currentIndex>=0)root.inspect(root.capabilities[currentIndex].id)
   Keys.onEnterPressed:if(currentIndex>=0)root.inspect(root.capabilities[currentIndex].id)
   delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.title;highlighted:root.selected.id===modelData.id;onClicked:root.inspect(modelData.id)}
   ScrollBar.vertical:ScrollBar {}
   NoesisEmpty {anchors.fill:parent;visible:root.capabilities.length===0&&!root.loading;title:"Define the ability first";description:"Add a capability from a learning path, then judge this evidence against a scoped criterion."}
  }
  RowLayout {visible:!!root.selected.id;Layout.fillWidth:true
   Text {text:root.selected.title||"Capability";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;elide:Text.ElideRight;Layout.fillWidth:true}
   NoesisButton {text:"Change";onClicked:{root.selected=({});filter.forceActiveFocus();}}
  }
  NoesisSelect {id:criteriaPicker;visible:!!root.selected.id&&root.criterionOptions.length>1;model:root.criterionOptions;Layout.fillWidth:true;Accessible.name:"Assessment criterion"}
  NoesisField {id:criterion;visible:!!root.selected.id&&root.criterionOptions.length<=1;Layout.fillWidth:true;placeholderText:"Specific assessment criterion"}
  NoesisSelect {id:decision;visible:!!root.selected.id;Layout.fillWidth:true;model:["accept","reject","withdraw"];Accessible.name:"Learner evidence decision"}
  NoesisEditor {id:reasoning;visible:!!root.selected.id;Layout.fillWidth:true;Layout.preferredHeight:90;placeholderText:"Why does this evidence support, fail to support, or no longer support this criterion?"}
  Text {visible:!!root.selected.id;text:"Your explicit decision applies to this criterion and evidence. Consumption and assisted success do not automatically establish capability.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
  RowLayout {Layout.fillWidth:true
   NoesisButton {text:"Cancel";onClicked:root.close()}
   Item {Layout.fillWidth:true}
   NoesisButton {id:save;text:"Save decision";hint:"Ctrl+Enter";primary:true;enabled:!!root.selected.id&&root.chosenCriterion.trim()!==""&&reasoning.text.trim()!==""&&!NoesisController.working&&root.vaultScope===NoesisController.activeVault;onClicked:{root.submitting=true;NoesisController.run(["event",root.selected.path,"capability-decision","--target-id",root.selected.id,"--evidence",reasoning.text,"--data",JSON.stringify({actor:"learner",criterion:root.chosenCriterion,decision:decision.currentText,evidence_id:root.evidence.id})]);}}
  }
 }
 Timer {id:searchDelay;interval:180;onTriggered:{root.loading=true;root.lookup(filter.text);}}
 Shortcut {sequence:"Ctrl+Return";enabled:root.visible;onActivated:if(save.enabled)save.clicked()}
 Connections {target:NoesisController;function onFinished(ok){if(root.submitting){root.submitting=false;if(ok)root.close();}}}
}
