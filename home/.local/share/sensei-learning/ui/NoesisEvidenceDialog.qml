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
 readonly property var dimensionIds:["explain","derive","implement","predict-debug","transfer","use","encountered","retained"]
 readonly property var evidenceKindIds:["explanation","derivation","unit-test","software-run","simulation","bench-test","sensor-measurement","in-water-test","external-verdict"]
 readonly property string chosenDimension:dimensionIds[dimension.currentIndex]
 readonly property string chosenCriterion:criterionOptions.length>1?criteriaPicker.currentText:criterion.text
 readonly property var matchingClaim:currentClaims.find(row=>row.criterion===chosenCriterion&&row.dimension===root.chosenDimension&&row.scope===claimScope.text)
 property string claimCursor:""
 property string retainedBasisId:""
 readonly property var dimensionNames:({encountered:"Encountered",use:"Can use",explain:"Can explain",derive:"Can derive",implement:"Can implement","predict-debug":"Can predict or debug",transfer:"Can transfer"})
 readonly property var retentionCandidates:currentClaims.filter(row=>row.criterion===chosenCriterion&&row.decision==="accept"&&row.dimension&&row.dimension!=="retained"&&!row.availability)
 readonly property var retainedBasis:retentionCandidates.find(row=>row.decision_id===retainedBasisId)||({})
 readonly property bool isRetention:chosenDimension==="retained"
 readonly property int retentionDays:Number(interval.text)
 readonly property bool retentionReady:!isRetention||(!!retainedBasis.decision_id&&Number.isInteger(retentionDays)&&retentionDays>=1&&retentionDays<=3650&&evidence.outcome==="succeeded"&&Date.parse(evidence.timestamp)>=Date.parse(retainedBasis.checked)+retentionDays*86400000)
 onRetainedBasisChanged:if(retainedBasis.decision_id)claimScope.text=retainedBasis.scope
 signal moreClaims(string cursor)
 function appendClaims(page){currentClaims=currentClaims.concat(page.evidence||[]);claimCursor=page.claim_cursor||"";loading=false;}
 property bool provenanceOpen:false
 property bool loading:false
 property bool submitting:false
 property string submittedOperation:""
 signal lookup(string query)
 signal inspect(string identity)
 title:"Assess what this attempt demonstrates"
 height:Math.min(780*NoesisStyle.interfaceScale,(parent?.height||900)-32)
 function begin(activity){retainedBasisId="";claimCursor="";currentClaims=[];interval.text="7";provenanceOpen=false;evidence=activity;selected=({});criterionOptions=[];decision.currentIndex=0;dimension.currentIndex=0;confidence.currentIndex=0;attribution.currentIndex=0;resolution.currentIndex=0;evidenceKind.currentIndex=0;claimScope.text=activity.scope||"";capabilities=[];vaultScope=NoesisController.activeVault;filter.text="";criterion.text="";reasoning.text="";loading=true;open();lookup("");filter.forceActiveFocus();}
 function detail(record){retainedBasisId="";claimCursor=record.overview?.claim_cursor||"";currentClaims=record.overview?.evidence||[];selected=Object.assign({},record.props,{path:record.path});criterionOptions=Array.isArray(selected.criteria)?selected.criteria.filter(value=>typeof value==="string"):[];criterion.text=criterionOptions.length===1?criterionOptions[0]:"";if(criterionOptions.length===1)reasoning.forceActiveFocus();else if(criterionOptions.length>1)criteriaPicker.forceActiveFocus();else criterion.forceActiveFocus();}
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
  NoesisSelect {id:dimension;objectName:"claim-dimension";visible:!!root.selected.id;Layout.fillWidth:true;model:["Explain the mechanism","Derive the mechanism","Build an implementation","Predict or debug behavior","Transfer to a changed problem","Use the idea","Encounter the idea","Demonstrate retention after a delay"];Accessible.name:"Understanding dimension"}
  ColumnLayout {visible:!!root.selected.id&&root.isRetention;Layout.fillWidth:true;spacing:NoesisStyle.sm
   Text {Layout.fillWidth:true;text:"Which earlier ability are you checking again?";textFormat:Text.PlainText;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisSelect {objectName:"retention-basis";Layout.fillWidth:true;model:["Choose an earlier established ability"].concat(root.retentionCandidates.map(row=>(root.dimensionNames[row.dimension]||"Earlier ability")+" · "+row.scope+" · "+String(row.checked).slice(0,10)));currentIndex:Math.max(0,root.retentionCandidates.findIndex(row=>row.decision_id===root.retainedBasisId)+1);Accessible.name:"Earlier established ability";onActivated:root.retainedBasisId=currentIndex?root.retentionCandidates[currentIndex-1].decision_id:""}
   NoesisButton {visible:root.claimCursor!=="";text:"Find more earlier judgments";enabled:!root.loading;onClicked:{root.loading=true;root.moreClaims(root.claimCursor);}}
   Text {Layout.fillWidth:true;text:"Minimum delay in days · chosen by you";textFormat:Text.PlainText;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisField {id:interval;objectName:"retention-days";Layout.fillWidth:true;text:"7";Accessible.name:"Minimum retention interval in days"}
   Text {Layout.fillWidth:true;text:root.retentionReady?"The saved successful assessment meets this interval. Your decision remains scoped to the earlier ability.":"Choose an earlier accepted ability and an interval of 1–3650 days. This evidence must be a successful assessment performed after that delay. A scheduled reminder is not retention.";textFormat:Text.PlainText;wrapMode:Text.Wrap;color:root.retentionReady?NoesisStyle.secondary:NoesisStyle.warning;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  }
  Text {textFormat:Text.PlainText;visible:!!root.selected.id;Layout.fillWidth:true;text:"Scope · what this evidence actually establishes";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisField {id:claimScope;enabled:!root.isRetention;objectName:"claim-scope";visible:!!root.selected.id;Layout.fillWidth:true;placeholderText:"Specific mechanism, conditions or changed case";Accessible.name:"Understanding claim scope"}
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
   NoesisButton {id:save;text:"Save decision";hint:"Ctrl+Enter";primary:true;enabled:!!root.selected.id&&root.chosenCriterion.trim()!==""&&claimScope.text.trim()!==""&&reasoning.text.trim()!==""&&(!root.isRetention||decision.currentIndex!==0||root.retentionReady)&&!NoesisController.working&&!NoesisController.uncertainReceipt&&!NoesisController.exitRequested&&NoesisController.hostReady&&root.vaultScope===NoesisController.activeVault;onClicked:{NoesisController.run(["event",root.selected.path,"capability-decision","--target-id",root.selected.id,"--evidence",reasoning.text,"--data",JSON.stringify(Object.assign({actor:"learner",criterion:root.chosenCriterion,decision:["accept","reject","withdraw"][decision.currentIndex],evidence_id:root.evidence.id,dimension:root.chosenDimension,scope:claimScope.text,confidence:confidence.currentText,evidence_kind:root.evidenceKindIds[evidenceKind.currentIndex],independent:attribution.currentIndex===1},root.isRetention?{retained_from:root.retainedBasisId,interval_days:root.retentionDays}:{},(()=>{let previous=root.currentClaims.find(row=>row.criterion===root.chosenCriterion&&row.dimension===root.chosenDimension&&row.scope===claimScope.text&&row.decision!=="conflict");return previous?{supersedes:previous.decision_id}:root.matchingClaim?.decision==="conflict"&&resolution.currentIndex===1?{resolves:root.matchingClaim.head_ids}:{};})()))]);root.submittedOperation=NoesisController.operationId;root.submitting=root.submittedOperation!=="";}}
 }
 Timer {id:searchDelay;interval:180;onTriggered:{root.loading=true;root.lookup(filter.text);}}
 Shortcut {sequence:"Ctrl+Return";enabled:root.visible;onActivated:if(save.enabled)save.clicked()}
 Connections {target:NoesisController;function onFinished(ok){if(root.submitting&&root.submittedOperation===NoesisController.operationId&&root.vaultScope===NoesisController.operationVault){root.submitting=false;if(ok)root.close();}}}
}
