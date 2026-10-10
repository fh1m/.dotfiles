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
 property var currentClaims:[]
 readonly property var dimensionIds:["explain","derive","implement","predict-debug","transfer","use","encountered"]
 readonly property var evidenceKindIds:["explanation","derivation","unit-test","software-run","simulation","bench-test","sensor-measurement","in-water-test","external-verdict"]
 readonly property string chosenDimension:dimensionIds[dimension.currentIndex]
 readonly property string chosenCriterion:criterionOptions.length>1?criteriaPicker.currentText:criterion.text
 readonly property var matchingClaim:currentClaims.find(row=>row.criterion===chosenCriterion&&row.dimension===root.chosenDimension&&row.scope===claimScope.text)
 property bool provenanceOpen:false
 property bool loading:false
 property bool submitting:false
 property string submittedOperation:""
 signal lookup(string query)
 signal inspect(string identity)
 title:"Assess what this attempt demonstrates"
 height:Math.min(780*NoesisStyle.interfaceScale,(parent?.height||900)-32)
 function begin(activity){provenanceOpen=false;evidence=activity;selected=({});criterionOptions=[];decision.currentIndex=0;dimension.currentIndex=0;confidence.currentIndex=0;attribution.currentIndex=0;resolution.currentIndex=0;evidenceKind.currentIndex=0;claimScope.text=activity.scope||"";capabilities=[];vaultScope=NoesisController.activeVault;filter.text="";criterion.text="";reasoning.text="";loading=true;open();lookup("");filter.forceActiveFocus();}
 function detail(record){currentClaims=record.overview?.evidence||[];selected=Object.assign({},record.props,{path:record.path});criterionOptions=Array.isArray(selected.criteria)?selected.criteria.filter(value=>typeof value==="string"):[];criterion.text=criterionOptions.length===1?criterionOptions[0]:"";if(criterionOptions.length===1)reasoning.forceActiveFocus();else if(criterionOptions.length>1)criteriaPicker.forceActiveFocus();else criterion.forceActiveFocus();}
 contentItem:ScrollView {id:claimScroll;objectName:"claim-form";clip:true;contentWidth:availableWidth;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
 ColumnLayout {width:claimScroll.availableWidth;spacing:NoesisStyle.md
  Text {textFormat:Text.PlainText;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Reported "+(root.evidence.outcome||"unknown")+" · assistance: "+(root.evidence.assistance||["unknown"]).join(", ")+"\nScope: "+(root.evidence.scope||"not recorded");color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
  NoesisField {id:filter;visible:!root.selected.id;Layout.fillWidth:true;placeholderText:"Find a capability";onTextChanged:searchDelay.restart();Keys.onDownPressed:{list.currentIndex=0;list.forceActiveFocus();}}
  ListView {id:list;visible:!root.selected.id;Layout.fillWidth:true;Layout.preferredHeight:140;clip:true;model:root.capabilities
   Keys.onReturnPressed:if(currentIndex>=0)root.inspect(root.capabilities[currentIndex].id)
   Keys.onEnterPressed:if(currentIndex>=0)root.inspect(root.capabilities[currentIndex].id)
   delegate:NoesisRow {objectName:"claim-capability-row";required property var modelData;width:ListView.view.width;title:modelData.title;highlighted:root.selected.id===modelData.id;onClicked:root.inspect(modelData.id)}
   ScrollBar.vertical:ScrollBar {}
   NoesisEmpty {anchors.fill:parent;visible:root.capabilities.length===0&&!root.loading;title:"Choose an ability to assess";description:"Define one from the investigation page, for example ‘Explain a boundary condition’, then compare this attempt with its criterion."}
  }
  RowLayout {visible:!!root.selected.id;Layout.fillWidth:true
   Text {textFormat:Text.PlainText;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:root.selected.title||"Capability";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;elide:Text.ElideRight;Layout.fillWidth:true}
   NoesisButton {text:"Change";onClicked:{root.selected=({});filter.forceActiveFocus();}}
  }
  Text {textFormat:Text.PlainText;visible:!!root.selected.id;Layout.fillWidth:true;text:"Assessment criterion";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisSelect {id:criteriaPicker;visible:!!root.selected.id&&root.criterionOptions.length>1;model:root.criterionOptions;Layout.fillWidth:true;Accessible.name:"Assessment criterion"}
  NoesisField {id:criterion;visible:!!root.selected.id&&root.criterionOptions.length<=1;Layout.fillWidth:true;placeholderText:"Specific assessment criterion"}
  Text {textFormat:Text.PlainText;visible:!!root.selected.id;Layout.fillWidth:true;text:"Understanding dimension";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisSelect {id:dimension;visible:!!root.selected.id;Layout.fillWidth:true;model:["Explain the mechanism","Derive the mechanism","Build an implementation","Predict or debug behavior","Transfer to a changed problem","Use the idea","Encounter the idea"];Accessible.name:"Understanding dimension"}
  Text {textFormat:Text.PlainText;visible:!!root.selected.id;Layout.fillWidth:true;text:"Scope · what this evidence actually establishes";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisField {id:claimScope;objectName:"claim-scope";visible:!!root.selected.id;Layout.fillWidth:true;placeholderText:"Specific mechanism, conditions or changed case";Accessible.name:"Understanding claim scope"}
  NoesisButton {visible:!!root.selected.id;text:root.provenanceOpen?"Hide evidence provenance":"Evidence type, confidence & unaided claim";onClicked:root.provenanceOpen=!root.provenanceOpen}
  Text {textFormat:Text.PlainText;visible:!!root.selected.id&&!root.provenanceOpen;Layout.fillWidth:true;text:"Learner judgment · "+evidenceKind.currentText+" · confidence: "+confidence.currentText;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  Text {textFormat:Text.PlainText;visible:!!root.selected.id&&root.provenanceOpen;Layout.fillWidth:true;text:"Evidence kind";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisSelect {id:evidenceKind;visible:!!root.selected.id&&root.provenanceOpen;Layout.fillWidth:true;model:["Learner explanation","Mathematical derivation","Software unit test","Executed software","Simulation","Bench test","Sensor measurement","In-water vehicle test","External verdict"];Accessible.name:"Evidence kind"}
  Text {textFormat:Text.PlainText;visible:!!root.selected.id&&root.provenanceOpen;Layout.fillWidth:true;text:"Confidence · separate from evidence";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisSelect {id:confidence;visible:!!root.selected.id&&root.provenanceOpen;Layout.fillWidth:true;model:["unknown","low","medium","high"];Accessible.name:"Learner confidence"}
  NoesisSelect {id:attribution;visible:!!root.selected.id&&root.provenanceOpen;Layout.fillWidth:true;model:["Evidence-backed learner judgment","Learner-reported unaided assessment"];Accessible.name:"Evidence attribution"}
  Text {textFormat:Text.PlainText;visible:!!root.selected.id;Layout.fillWidth:true;text:"Your judgment";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisSelect {id:decision;objectName:"claim-decision";visible:!!root.selected.id;Layout.fillWidth:true;model:["Supports this criterion","Does not establish it","Withdraw earlier judgment"];Accessible.name:"Learner evidence decision"}
  NoesisSelect {id:resolution;visible:root.matchingClaim?.decision==="conflict";Layout.fillWidth:true;model:["Keep competing judgments visible","Resolve all current judgments with this decision"];Accessible.name:"Conflicting understanding judgments"}
  Text {textFormat:Text.PlainText;visible:!!root.selected.id;Layout.fillWidth:true;text:"Why this evidence?";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisEditor {id:reasoning;objectName:"claim-reason";visible:!!root.selected.id;Layout.fillWidth:true;Layout.preferredHeight:90;placeholderText:"Why does this evidence support, fail to support, or no longer support this criterion?"}
  Text {textFormat:Text.PlainText;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!!root.selected.id;text:"Your explicit decision applies to this criterion and evidence. Consumption and assisted success do not automatically establish capability.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
 }}
 footer:RowLayout {
   NoesisButton {text:"Cancel";onClicked:root.close()}
   Item {Layout.fillWidth:true}
   NoesisButton {id:save;text:"Save decision";hint:"Ctrl+Enter";primary:true;enabled:!!root.selected.id&&root.chosenCriterion.trim()!==""&&claimScope.text.trim()!==""&&reasoning.text.trim()!==""&&!NoesisController.working&&!NoesisController.uncertainReceipt&&!NoesisController.exitRequested&&NoesisController.hostReady&&root.vaultScope===NoesisController.activeVault;onClicked:{NoesisController.run(["event",root.selected.path,"capability-decision","--target-id",root.selected.id,"--evidence",reasoning.text,"--data",JSON.stringify(Object.assign({actor:"learner",criterion:root.chosenCriterion,decision:["accept","reject","withdraw"][decision.currentIndex],evidence_id:root.evidence.id,dimension:root.chosenDimension,scope:claimScope.text,confidence:confidence.currentText,evidence_kind:root.evidenceKindIds[evidenceKind.currentIndex],independent:attribution.currentIndex===1},(()=>{let previous=root.currentClaims.find(row=>row.criterion===root.chosenCriterion&&row.dimension===root.chosenDimension&&row.scope===claimScope.text&&row.decision!=="conflict");return previous?{supersedes:previous.decision_id}:root.matchingClaim?.decision==="conflict"&&resolution.currentIndex===1?{resolves:root.matchingClaim.head_ids}:{};})()))]);root.submittedOperation=NoesisController.operationId;root.submitting=root.submittedOperation!=="";}}
 }
 Timer {id:searchDelay;interval:180;onTriggered:{root.loading=true;root.lookup(filter.text);}}
 Shortcut {sequence:"Ctrl+Return";enabled:root.visible;onActivated:if(save.enabled)save.clicked()}
 Connections {target:NoesisController;function onFinished(ok){if(root.submitting&&root.submittedOperation===NoesisController.operationId&&root.vaultScope===NoesisController.operationVault){root.submitting=false;if(ok)root.close();}}}
}
