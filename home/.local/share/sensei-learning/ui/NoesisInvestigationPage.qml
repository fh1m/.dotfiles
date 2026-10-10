import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property var record:({})
 property var frontier:({items:[]})
 property var preview:({blocks:[]})
 property var claims:[]
 property string claimCursor:""
 property string claimNewerCursor:""
 signal pageClaims(string cursor)
 property string notes:""
 property string status:"active"
 signal disposition(string value)
 property string depth:"normal"
 readonly property var depthIds:["quick","normal","deep","research-grade"]
 function claimLabel(row){let dimensions={encountered:"Encountered",use:"Can use",explain:"Can explain",derive:"Can derive",implement:"Can implement","predict-debug":"Can predict / debug",transfer:"Can transfer",retained:"Retained"};let decisions={accept:"evidence accepted",reject:"not established",withdraw:"judgment withdrawn",conflict:"competing judgments"};return (dimensions[row.dimension]||"Legacy criterion")+" · "+(decisions[row.decision]||"not assessed");}
 property string attemptId:""
 property bool referenceHidden:false
 property bool busy:false
 property bool reasoningOnly:false
 property bool mechanismExpanded:false
 property string previousKey:""
 onRecordChanged:{let key=(record.vault||"")+":"+(record.id||"");if(key!==previousKey){mechanismExpanded=false;reasoningOnly=false;previousKey=key;}}
 readonly property bool compact:width<1000*NoesisStyle.interfaceScale
 readonly property var questions:(frontier.items||[]).filter(row=>row.type==="question"&&row.id!==record.id&&!["answered","resolved","complete","retired","abandoned"].includes(row.status))
 readonly property var capabilities:(frontier.items||[]).filter(row=>row.type==="capability"&&row.id!==record.id)
 readonly property var origin:(frontier.items||[]).find(row=>row.id===frontier.parent_ref?.record_id)
 readonly property var supporting:(frontier.items||[]).filter(row=>!["question","capability"].includes(row.type)&&row.id!==record.id&&row.id!==origin?.id)
 readonly property real sourceAnchor:sourceScroll.ScrollBar.vertical.position
 readonly property real notesAnchor:notesScroll.ScrollBar.vertical.position
 signal notesEdited(string value)
 signal preserveNote()
 signal startAttempt()
 signal evaluateAttempt()
 signal revealReference()
 signal openNote()
 signal askQuestion()
 signal defineCapability()
 signal openMember(var row)
 signal chooseDepth(string value)
 signal showHistory()
 signal reviewEvidence()
 signal pageFrontier(string cursor)
 spacing:NoesisStyle.md
 function restoreAnchors(view){Qt.callLater(()=>{sourceScroll.ScrollBar.vertical.position=Math.max(0,Math.min(1-sourceScroll.ScrollBar.vertical.size,view.source_anchor||0));notesScroll.ScrollBar.vertical.position=Math.max(0,Math.min(1-notesScroll.ScrollBar.vertical.size,view.notes_anchor||0));});}

 Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:root.record.title||"Investigation";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.title;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
 Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
  NoesisButton {text:"← Return to motivation";visible:!!root.origin;onClicked:root.openMember(root.origin)}
  NoesisButton {text:root.attemptId?"Record reconstruction result":"Start independent reconstruction";primary:true;enabled:!root.busy;onClicked:root.attemptId?root.evaluateAttempt():root.startAttempt()}
  NoesisButton {text:"Open derivation in Obsidian ↗";enabled:!root.busy&&!root.referenceHidden;onClicked:root.openNote()}
  NoesisButton {text:"Investigate a missing mechanism";enabled:!root.busy;onClicked:root.askQuestion()}
  NoesisButton {text:root.reasoningOnly?"Show question & frontier":"Show reasoning";visible:root.compact;highlighted:root.reasoningOnly;onClicked:root.reasoningOnly=!root.reasoningOnly}
 }
 Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:root.attemptId?(root.referenceHidden?"Reconstruction in progress · reference protected":"Reconstruction in progress · reference exposure recorded"):"Start with a prediction. Rebuild the mechanism, test a changed case, and keep unanswered questions visible.";color:NoesisStyle.secondary;wrapMode:Text.Wrap;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;renderType:Text.NativeRendering}

 SplitView {
  id:panes;Layout.fillWidth:true;Layout.fillHeight:true;orientation:Qt.Horizontal
  handle:Item {implicitWidth:NoesisStyle.lg}
  ScrollView {
   id:sourceScroll;visible:!root.compact||!root.reasoningOnly;SplitView.preferredWidth:panes.width*.53;SplitView.minimumWidth:0;SplitView.fillWidth:root.compact;clip:true;contentWidth:availableWidth;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
   ColumnLayout {width:sourceScroll.availableWidth;spacing:NoesisStyle.lg
    Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"The question & mechanism";color:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
    Repeater {model:root.referenceHidden?[]:(root.mechanismExpanded?(root.preview.blocks||[]):(root.preview.blocks||[]).slice(0,2));delegate:TextEdit {required property var modelData;Layout.fillWidth:true;Layout.maximumWidth:NoesisStyle.readingWidth;text:modelData.text;readOnly:true;selectByMouse:true;textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap;color:NoesisStyle.ink;font.family:modelData.kind==="code"?NoesisStyle.codeFont:NoesisStyle.uiFont;font.pixelSize:modelData.kind==="heading"?NoesisStyle.sectionHeading:NoesisStyle.body;font.bold:modelData.kind==="heading";renderType:TextEdit.NativeRendering}}
    Text {textFormat:Text.PlainText;Layout.fillWidth:true;visible:root.referenceHidden||!(root.preview.blocks||[]).length;text:root.referenceHidden?"Reference hidden for this attempt. The question stays in the title; reconstruct before consulting your notes.":"What problem makes this mechanism necessary? Write a question, predict a simple case, then test your explanation.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
    NoesisButton {visible:!root.referenceHidden&&(root.preview.blocks||[]).length>2;text:root.mechanismExpanded?"Collapse mechanism notes":"Read mechanism & source notes";onClicked:root.mechanismExpanded=!root.mechanismExpanded}
    NoesisButton {visible:root.attemptId;text:"Reveal reference deliberately";enabled:root.referenceHidden&&!root.busy;onClicked:root.revealReference()}
    ColumnLayout {visible:!root.referenceHidden;Layout.fillWidth:true;spacing:NoesisStyle.sm
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Knowledge frontier";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Understanding is scoped. Confidence, assistance and evidence stay separate.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     Repeater {model:root.capabilities;delegate:ColumnLayout {required property var modelData;Layout.fillWidth:true;spacing:NoesisStyle.xs
      NoesisButton {text:modelData.title;onClicked:root.openMember(modelData)}
      Repeater {model:modelData.claims||[];delegate:Text {textFormat:Text.PlainText;required property var modelData;Layout.fillWidth:true;text:root.claimLabel(modelData)+(modelData.independent?" · learner-reported unaided":"")+"\n"+modelData.criterion+"\n"+(modelData.scope||"Scope not recorded")+(modelData.availability?"\nEvidence unavailable":"");color:modelData.decision==="conflict"?NoesisStyle.warning:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}}
      Text {textFormat:Text.PlainText;Layout.fillWidth:true;visible:!modelData.claim_count||modelData.claims_truncated;text:modelData.claim_count?"Open this ability to inspect all criteria.":"No understanding claim yet · attach actual work before deciding.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     }}
     Repeater {model:root.claims;delegate:Text {textFormat:Text.PlainText;required property var modelData;Layout.fillWidth:true;text:root.claimLabel(modelData)+"\n"+modelData.criterion+"\n"+(modelData.scope||"Scope not recorded")+"\nEvidence: "+modelData.evidence_kind+" · confidence: "+modelData.confidence+(modelData.availability?"\nEvidence unavailable":"");color:modelData.decision==="conflict"?NoesisStyle.warning:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}}
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
      NoesisButton {visible:root.claimNewerCursor!=="";text:"Previous criteria";onClicked:root.pageClaims(root.claimNewerCursor)}
      NoesisButton {visible:root.claimCursor!=="";text:"More understanding criteria";onClicked:root.pageClaims(root.claimCursor)}
     }
     NoesisButton {text:"Define an ability to demonstrate";visible:root.record.type!=="capability";enabled:!root.busy;onClicked:root.defineCapability()}
    }
    ColumnLayout {visible:!root.referenceHidden;Layout.fillWidth:true;spacing:NoesisStyle.sm
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Unanswered mechanisms";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     Repeater {model:root.questions;delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title;subtitle:modelData.status==="parked"?"Parked deliberately · return when useful":"Question · "+modelData.depth+" investigation";onClicked:root.openMember(modelData)}}
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;visible:!root.questions.length;text:"No linked questions yet. Record a missing mechanism when you encounter one; you can keep using the abstraction.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
      NoesisButton {visible:!!root.frontier.newer_cursor;text:"Previous frontier page";onClicked:root.pageFrontier(root.frontier.newer_cursor)}
      NoesisButton {visible:!!root.frontier.cursor;text:"More connected work";onClicked:root.pageFrontier(root.frontier.cursor)}
     }
    }
    ColumnLayout {visible:!root.referenceHidden&&root.supporting.length>0;Layout.fillWidth:true;spacing:NoesisStyle.sm
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Sources, applications & deeper mechanisms";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     Repeater {model:root.supporting;delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title;subtitle:({resource:"Source",paper:"Paper",concept:"Mechanism",project:"Implementation",experiment:"Experiment",artifact:"Artifact",path:"Learning path"})[modelData.type]||modelData.type;onClicked:root.openMember(modelData)}}
    }
   }
  }
  Rectangle {
   visible:!root.compact||root.reasoningOnly;color:NoesisStyle.canvas;radius:NoesisStyle.radius;SplitView.fillWidth:true;SplitView.minimumWidth:0
   ScrollView {id:notesScroll;anchors.fill:parent;anchors.margins:NoesisStyle.lg;clip:true;contentWidth:availableWidth;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
    ColumnLayout {width:notesScroll.availableWidth;spacing:NoesisStyle.md
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Your reconstruction";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Predict → reconstruct → test → explain the discrepancy. These are prompts, not a compulsory form.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Investigation depth";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;renderType:Text.NativeRendering}
     NoesisSelect {Layout.fillWidth:true;model:["Quick exploration","Normal study","Deep reconstruction","Research-grade reproduction"];currentIndex:Math.max(0,root.depthIds.indexOf(root.depth));Accessible.name:"Investigation depth";enabled:!root.busy;onActivated:root.chooseDepth(root.depthIds[currentIndex])}
     NoesisEditor {id:reasoning;objectName:"investigation-reasoning";Layout.fillWidth:true;Layout.preferredHeight:Math.max(280*NoesisStyle.interfaceScale,implicitHeight);text:root.notes;placeholderText:"My prediction…\n\nThe mechanism, reconstructed…\n\nWhat changed, and what remains unknown…";Accessible.name:"Investigation reasoning draft";onTextChanged:if(text!==root.notes)root.notesEdited(text)}
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
      NoesisButton {text:"Preserve reasoning";enabled:root.notes.trim()!==""&&!root.busy;onClicked:root.preserveNote()}
      NoesisButton {text:"Review evidence & history";enabled:!root.busy;onClicked:root.showHistory()}
      NoesisButton {text:"Make an understanding claim";enabled:!root.attemptId&&!root.referenceHidden&&!root.busy;onClicked:root.reviewEvidence()}
     }
     Flow {visible:root.record.type==="question";Layout.fillWidth:true;spacing:NoesisStyle.sm
      NoesisButton {text:root.status==="parked"?"Resume this question":"Park this question";enabled:!root.busy;onClicked:root.disposition(root.status==="parked"?"active":"parked")}
      NoesisButton {text:root.status==="answered"?"Reopen the question":"Mark question answered";enabled:!root.busy&&!root.attemptId;onClicked:root.disposition(root.status==="answered"?"active":"answered")}
     }
     Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:"Saving notes does not award understanding. A claim needs actual evidence and your explicit decision.";color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
    }
   }
  }
 }
}
