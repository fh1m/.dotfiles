import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
 id:pane
 color:NoesisStyle.surface
 radius:NoesisStyle.radius
 property var workspace:null
 property string paneKey:"left"
 property string view:"source"
 property bool keptOptions:false
 property var kept:({})
 property var keptResult:({})
 property int keptSerial:0
 property bool keptLoading:false
 property string keptError:""
 property bool restoringKept:false
 property var keptAnchors:({source:0,context:0,figures:0})
 function flushLayout(){anchorSave.stop();}
 function restoreKeptAnchors(){if(!keptReady)return;for(let pair of [[sourceScroll,"source"],[contextScroll,"context"],[figuresScroll,"figures"]])pair[0].contentItem.contentY=Math.min(keptAnchors[pair[1]]||0,Math.max(0,pair[0].contentItem.contentHeight-pair[0].availableHeight));}
 function keepAnchor(kind,value){if(restoringKept||!keptReady||workspace?.contextLoading||!NoesisController.windowOpen)return;keptAnchors=Object.assign({},keptAnchors,{[kind]:Math.max(0,value)});anchorSave.restart();}
 Timer {id:anchorRelease;interval:30;onTriggered:pane.restoringKept=false}
 Timer {id:anchorRestore;interval:30;onTriggered:{pane.restoreKeptAnchors();if(pane.keptReady)anchorRelease.restart();}}
 Timer {id:anchorSave;interval:500;onTriggered:pane.layoutEdited()}
 Connections {target:sourceScroll.contentItem;function onContentYChanged(){if(sourceScroll.visible)pane.keepAnchor("source",sourceScroll.contentItem.contentY);}}
 Connections {target:contextScroll.contentItem;function onContentYChanged(){if(contextScroll.visible)pane.keepAnchor("context",contextScroll.contentItem.contentY);}}
 Connections {target:figuresScroll.contentItem;function onContentYChanged(){if(figuresScroll.visible)pane.keepAnchor("figures",figuresScroll.contentItem.contentY);}}
 readonly property bool isKept:!!kept.id
 readonly property bool keptOwnerAvailable:!isKept||(kept.vault===NoesisController.activeVault)
 readonly property bool keptProtected:isKept&&(!!workspace?.contextLoading||!!workspace?.referenceHidden||!!workspace?.activeAttempt||!!keptResult.attempt||!!keptResult.attempt_conflict)
 readonly property bool keptReady:isKept&&keptOwnerAvailable&&!keptProtected&&!keptLoading&&!keptError&&!!keptResult.props?.id
 readonly property string keptMessage:!isKept||keptReady?"":keptProtected?(workspace?.contextLoading?"Checking the active activity before showing kept material…":"Kept material is concealed during a protected attempt."):keptError||"Refreshing kept activity…"
 readonly property var contentWorkspace:!isKept?workspace:({selected:keptReady?Object.assign({},keptResult.props,{title:keptResult.display_title,path:keptResult.path,vault:kept.vault,vault_id:kept.vault_id}):{},section:["task","problem"].includes(keptResult.props?.type)?"Practice":"Learn",documentPreview:keptReady?keptResult.preview||{}:{},workflow:keptReady?keptResult.overview||{}:{},learningContext:keptReady?keptResult.learning_context||{}:{},referenceHidden:keptProtected,contextLoading:keptLoading})
 function followActivity(){keptSerial=0;kept=({});keptAnchors=({source:0,context:0,figures:0});keptResult=({});keptError="";keptLoading=false;layoutEdited();}
 function refreshKept(reconcile){if(!isKept||!NoesisController.windowOpen)return;restoringKept=true;anchorRelease.stop();keptResult=({});keptSerial=0;keptLoading=false;if(kept.vault!==NoesisController.activeVault){keptError="Kept owner is not active. Return to its vault to view this context.";return;}keptError="";if(reconcile)workspace?.send("reconcile");keptSerial=workspace?.send("record",{record_id:kept.id})||0;keptLoading=keptSerial!==0;}
 function keepActivity(){if(!workspace?.selected.id||workspace.contextLoading||workspace.referenceHidden||workspace.activeAttempt||!["source","context","figures"].includes(view))return;kept={version:1,id:workspace.selected.id,vault:NoesisController.activeVault,vault_id:workspace.selected.vault_id,title:workspace.selected.title,owner:workspace.ownerLabel};layoutEdited();}
 onKeptChanged:Qt.callLater(()=>{if(pane.isKept)pane.refreshKept();})
 onViewChanged:if(isKept&&["notes","reference"].includes(view))followActivity()
 Connections {target:pane.workspace;function onSupportingResponse(response){if(!pane.keptSerial||response.request_id!==pane.keptSerial)return;pane.keptSerial=0;pane.keptLoading=false;if(response.error){pane.keptError="Kept activity is unavailable. Its identity remains preserved.";return;}let value=response.result;if(response.vault!==pane.kept.vault||value.owner?.vault_id!==pane.kept.vault_id||value.props?.id!==pane.kept.id){pane.keptError="Kept owner or identity changed. No replacement was selected.";return;}pane.keptResult=value;pane.keptError="";anchorRestore.restart();}function onContextLoadingChanged(){if(pane.workspace.contextLoading)pane.restoringKept=true;else if(pane.isKept)pane.refreshKept();}function onDocumentPreviewChanged(){if(pane.isKept&&!pane.workspace.contextLoading)pane.refreshKept();}}
 Connections {target:NoesisController;function onActiveVaultChanged(){pane.refreshKept();}function onWindowOpenChanged(){if(NoesisController.windowOpen)Qt.callLater(pane.refreshKept);}}
 readonly property var surfaces:["source","context","notes","figures","reference"]
 readonly property real sourceAnchor:sourceScroll.contentItem.contentY
 readonly property string surfaceLabel:surfaceChoice.currentText
 readonly property bool problem:contentWorkspace?.section==="Practice"
 readonly property var blocks:!contentWorkspace?.selected.id?[]:view==="reference"?(contentWorkspace?.referenceHidden?[]:contentWorkspace?.documentPreview.blocks||[]):problem?(contentWorkspace?.workflow.statement_preview?.blocks||[]):contentWorkspace?.referenceHidden?[]:(contentWorkspace?.documentPreview.blocks||[])
 readonly property string identity:isKept?kept.vault+":"+kept.id:(workspace?.selected.vault||"")+":"+(workspace?.selected.id||"")
 property var positions:({})
 property string previousIdentity:""
 onIdentityChanged:{if(isKept){previousIdentity=identity;return;}if(previousIdentity)positions[previousIdentity]=sourceScroll.contentItem.contentY;previousIdentity=identity;Qt.callLater(()=>sourceScroll.contentItem.contentY=Math.min(positions[identity]||0,Math.max(0,sourceScroll.contentItem.contentHeight-sourceScroll.availableHeight)));}
 signal layoutEdited()
 ColumnLayout {
 anchors.fill:parent;anchors.margins:NoesisStyle.md;spacing:NoesisStyle.sm
 RowLayout {
  Layout.fillWidth:true;spacing:NoesisStyle.md
  NoesisSelect {id:surfaceChoice;onModelChanged:Qt.callLater(()=>surfaceChoice.currentIndex=Qt.binding(()=>pane.surfaces.indexOf(pane.view)));objectName:"studySurface-"+pane.paneKey;Layout.preferredWidth:Math.min(240*NoesisStyle.interfaceScale,pane.width*.55);Layout.maximumWidth:pane.width*.55;model:[pane.problem?"Problem statement":"Source","Context","Notes & reasoning","Figures & artifacts",pane.contentWorkspace?.referenceHidden?"Reference (protected)":"Reference preview"];currentIndex:pane.surfaces.indexOf(pane.view);Accessible.name:pane.paneKey+" study pane";onActivated:{pane.view=pane.surfaces[currentIndex];pane.layoutEdited();}}
  Item {Layout.fillWidth:true}
  NoesisButton {Layout.maximumWidth:pane.width*.4;text:pane.view==="notes"?"Open complete note ↗":"Open original ↗";variant:"tertiary";visible:!pane.isKept&&!!pane.workspace?.selected.id&&(pane.view==="notes"||!["context","figures"].includes(pane.view)&&!!(pane.workspace?.selected.source||pane.workspace?.selected.local_file||pane.workspace?.selected.zotero_attachment_key));enabled:!pane.contentWorkspace?.referenceHidden&&!NoesisController.working;onClicked:if(pane.view==="notes")NoesisController.note(pane.workspace.selected.path);else pane.workspace.openSource()}

 }
 Flow {Layout.fillWidth:true;Layout.preferredHeight:implicitHeight;width:parent.width;spacing:NoesisStyle.sm
  NoesisButton {text:pane.isKept?"Follow active activity":"Keep here";visible:!pane.isKept&&["source","context","figures"].includes(pane.view);enabled:NoesisController.windowOpen&&(pane.isKept||!!pane.workspace?.selected.id&&!pane.workspace?.contextLoading&&!pane.workspace?.referenceHidden&&!pane.workspace?.activeAttempt);onClicked:if(pane.isKept)pane.followActivity();else pane.keepActivity()}
  NoesisButton {text:pane.keptOptions?"Hide kept context options":"Kept context options";visible:pane.isKept;onClicked:pane.keptOptions=!pane.keptOptions}
  NoesisButton {text:"Follow active activity";visible:pane.isKept&&pane.keptOptions;onClicked:pane.followActivity()}
  NoesisButton {text:"Refresh kept context";visible:pane.isKept&&pane.keptOptions;enabled:NoesisController.windowOpen&&pane.keptOwnerAvailable&&!pane.keptProtected&&!pane.keptLoading;onClicked:pane.refreshKept(true)}
  NoesisButton {text:"Open kept activity on main";visible:pane.isKept&&pane.keptOptions;enabled:pane.keptReady&&!pane.workspace?.contextLoading&&!NoesisController.working;onClicked:pane.workspace.openWork(pane.contentWorkspace.selected)}
 }
 Text {textFormat:Text.PlainText;visible:pane.isKept;Layout.fillWidth:true;text:"Kept · "+(pane.kept.owner||"Owning vault")+" · "+(pane.keptResult.display_title||pane.kept.title||"Activity")+(pane.keptProtected?" · concealed":pane.keptError?" · unavailable":pane.keptLoading?" · refreshing":" · read only");wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;renderType:Text.NativeRendering}
 ScrollView {
  id:sourceScroll;objectName:"studySource-"+pane.paneKey;visible:pane.view==="source"||pane.view==="reference";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;contentWidth:availableWidth
  ColumnLayout {width:sourceScroll.availableWidth;spacing:NoesisStyle.md
   Text {font.hintingPreference:Font.PreferFullHinting;visible:pane.blocks.length===0;Layout.fillWidth:true;text:pane.isKept&&!pane.keptReady?pane.keptMessage:pane.contentWorkspace?.referenceHidden&&(!pane.problem||pane.view==="reference")?"Reference is protected. Reveal it deliberately from the main working page.":pane.contentWorkspace?.contextLoading?"Loading the selected activity…":pane.contentWorkspace?.selected.id?"No native preview is available. Open the original or complete note.":"Choose an activity on the main display. Its source preview will follow here.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
   NoesisDocument {Layout.fillWidth:true;framed:false;blocks:pane.blocks;originalAvailable:!pane.isKept&&!pane.contentWorkspace?.referenceHidden;onOpenOriginal:if(!pane.isKept&&!pane.contentWorkspace?.referenceHidden)NoesisController.note(pane.workspace.selected.path)}
  }
 }
 ScrollView {
  id:contextScroll;visible:pane.view==="context";Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true
  ColumnLayout {width:contextScroll.availableWidth;spacing:NoesisStyle.md
   Text {font.hintingPreference:Font.PreferFullHinting;text:"Prerequisites & assignments";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;font.bold:true;renderType:Text.NativeRendering}
   Text {font.hintingPreference:Font.PreferFullHinting;visible:!(pane.contentWorkspace?.learningContext?.prerequisites?.length||pane.contentWorkspace?.learningContext?.assignments?.length||pane.contentWorkspace?.learningContext?.parents?.length);Layout.fillWidth:true;text:pane.isKept&&!pane.keptReady?pane.keptMessage:"No linked prerequisites or assignments for this activity.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.uiText;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
   NoesisLearningContext {Layout.fillWidth:true;context:pane.contentWorkspace?.learningContext||({});busy:pane.isKept||NoesisController.working;onOpenContext:row=>pane.workspace.openWork(row);onReviewReadiness:row=>pane.workspace.reviewPrerequisite(row)}
   Text {font.hintingPreference:Font.PreferFullHinting;text:"Current work";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;font.bold:true;renderType:Text.NativeRendering}
   Text {font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:pane.isKept?"Supporting context is read only. Open the kept activity on the main display to edit or assess it.":pane.problem?(pane.workspace?.activeAttempt?"Independent attempt in progress":"No active attempt")+(pane.contentWorkspace?.referenceHidden?" · reference protected":" · reference revealed"):"Continue reading, deriving or recording evidence on the main display.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.uiText;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
  }
 }
 ColumnLayout {
  visible:pane.view==="notes";Layout.fillWidth:true;Layout.fillHeight:true;spacing:NoesisStyle.sm
  Text {font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Draft for "+(pane.workspace?.selected.title||"the active activity")+" · shared with the main page";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
  ScrollView {id:notesScroll;Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true
   NoesisEditor {objectName:"studyNotes-"+pane.paneKey;width:notesScroll.availableWidth;enabled:NoesisController.windowOpen&&!!pane.workspace?.selected.id;text:pane.workspace?.evidence.text||"";placeholderText:"Write your reasoning, questions or derivation…";onTextChanged:if(pane.workspace?.selected.id&&text!==pane.workspace.evidence.text)pane.workspace.evidence.text=text;Accessible.name:"Shared activity draft"}
  }
 }
 ScrollView {
  id:figuresScroll;visible:pane.view==="figures";Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true
  ColumnLayout {width:figuresScroll.availableWidth;spacing:NoesisStyle.md
   Text {font.hintingPreference:Font.PreferFullHinting;visible:pane.contentWorkspace?.referenceHidden||!(pane.contentWorkspace?.workflow.artifacts||[]).length;Layout.fillWidth:true;text:pane.isKept&&!pane.keptReady?pane.keptMessage:pane.contentWorkspace?.referenceHidden?"Reference artifacts are protected. Reveal deliberately from the main page.":"No linked figures or artifacts for this activity. Connect existing artifacts from Lab; complete maps and rich diagrams open in Obsidian.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
   Repeater {model:pane.contentWorkspace?.referenceHidden?[]:(pane.contentWorkspace?.workflow.artifacts||[]).slice().sort((a,b)=>Number(!!b.figure_url)-Number(!!a.figure_url));delegate:ColumnLayout {required property var modelData;property bool fullFigure:false;Layout.fillWidth:true;spacing:NoesisStyle.sm
    NoesisRow {Layout.fillWidth:true;title:modelData.title;subtitle:modelData.preview_status||modelData.availability||"Inspect artifact";onClicked:{NoesisController.open();pane.workspace.openWork(modelData);}}
    NoesisButton {visible:!!modelData.figure_url;text:parent.fullFigure?"Fit figure in pane":"Read figure at full width";onClicked:parent.fullFigure=!parent.fullFigure}
    Image {visible:!!modelData.figure_url;Layout.fillWidth:true;Layout.preferredHeight:visible?(parent.fullFigure?width*implicitHeight/Math.max(1,implicitWidth):Math.max(120,Math.min(240,figuresScroll.availableHeight-80))):0;source:modelData.figure_url||"";sourceSize.width:2048;sourceSize.height:1200;fillMode:Image.PreserveAspectFit;asynchronous:true;cache:false;Accessible.name:modelData.title}
   }}
  }
 }
 }
}
