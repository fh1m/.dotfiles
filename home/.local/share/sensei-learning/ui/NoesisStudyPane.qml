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
 readonly property var surfaces:["source","context","notes","figures","reference"]
 readonly property string surfaceLabel:surfaceChoice.currentText
 readonly property bool problem:workspace?.section==="Practice"
 readonly property var blocks:!workspace?.selected.id?[]:view==="reference"?(workspace?.referenceHidden?[]:workspace?.documentPreview.blocks||[]):problem?(workspace?.workflow.statement_preview?.blocks||[]):workspace?.referenceHidden?[]:(workspace?.documentPreview.blocks||[])
 readonly property string identity:(workspace?.selected.vault||"")+":"+(workspace?.selected.id||"")
 property var positions:({})
 property string previousIdentity:""
 onIdentityChanged:{if(previousIdentity)positions[previousIdentity]=sourceScroll.contentItem.contentY;previousIdentity=identity;Qt.callLater(()=>sourceScroll.contentItem.contentY=Math.min(positions[identity]||0,Math.max(0,sourceScroll.contentItem.contentHeight-sourceScroll.availableHeight)));}
 signal layoutEdited()
 ColumnLayout {
 anchors.fill:parent;anchors.margins:NoesisStyle.md;spacing:NoesisStyle.sm
 RowLayout {
  Layout.fillWidth:true;spacing:NoesisStyle.md
  NoesisSelect {id:surfaceChoice;onModelChanged:Qt.callLater(()=>surfaceChoice.currentIndex=Qt.binding(()=>pane.surfaces.indexOf(pane.view)));objectName:"studySurface-"+pane.paneKey;Layout.preferredWidth:Math.min(240*NoesisStyle.interfaceScale,pane.width*.55);Layout.maximumWidth:pane.width*.55;model:[pane.problem?"Problem statement":"Source","Context","Notes & reasoning","Figures & artifacts",pane.workspace?.referenceHidden?"Reference (protected)":"Reference preview"];currentIndex:pane.surfaces.indexOf(pane.view);Accessible.name:pane.paneKey+" study pane";onActivated:{pane.view=pane.surfaces[currentIndex];pane.layoutEdited();}}
  Item {Layout.fillWidth:true}
  NoesisButton {Layout.maximumWidth:pane.width*.4;text:pane.view==="notes"?"Open complete note ↗":"Open original ↗";variant:"tertiary";visible:!!pane.workspace?.selected.id&&(pane.view==="notes"||pane.view!=="context"&&!!(pane.workspace?.selected.source||pane.workspace?.selected.local_file||pane.workspace?.selected.zotero_attachment_key));enabled:!pane.workspace?.referenceHidden&&!NoesisController.working;onClicked:if(pane.view==="notes")NoesisController.note(pane.workspace.selected.path);else pane.workspace.openSource()}

 }
 ScrollView {
  id:sourceScroll;visible:pane.view==="source"||pane.view==="reference";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;contentWidth:availableWidth
  ColumnLayout {width:sourceScroll.availableWidth;spacing:NoesisStyle.md
   Text {font.hintingPreference:Font.PreferFullHinting;visible:pane.blocks.length===0;Layout.fillWidth:true;text:pane.workspace?.referenceHidden&&(!pane.problem||pane.view==="reference")?"Reference is protected. Reveal it deliberately from the main working page.":pane.workspace?.contextLoading?"Loading the selected activity…":pane.workspace?.selected.id?"No native preview is available. Open the original or complete note.":"Choose an activity on the main display. Its source preview will follow here.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
   NoesisDocument {Layout.fillWidth:true;framed:false;blocks:pane.blocks;originalAvailable:!pane.workspace?.referenceHidden;onOpenOriginal:if(!pane.workspace?.referenceHidden)NoesisController.note(pane.workspace.selected.path)}
  }
 }
 ScrollView {
  id:contextScroll;visible:pane.view==="context";Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true
  ColumnLayout {width:contextScroll.availableWidth;spacing:NoesisStyle.md
   Text {font.hintingPreference:Font.PreferFullHinting;text:"Prerequisites & assignments";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;font.bold:true;renderType:Text.NativeRendering}
   Text {font.hintingPreference:Font.PreferFullHinting;visible:!(pane.workspace?.learningContext?.prerequisites?.length||pane.workspace?.learningContext?.assignments?.length||pane.workspace?.learningContext?.parents?.length);Layout.fillWidth:true;text:"No linked prerequisites or assignments for this activity.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.uiText;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
   NoesisLearningContext {Layout.fillWidth:true;context:pane.workspace?.learningContext||({});busy:NoesisController.working;onOpenContext:row=>pane.workspace.openWork(row);onReviewReadiness:row=>pane.workspace.reviewPrerequisite(row)}
   Text {font.hintingPreference:Font.PreferFullHinting;text:"Current work";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;font.bold:true;renderType:Text.NativeRendering}
   Text {font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:pane.problem?(pane.workspace?.activeAttempt?"Independent attempt in progress":"No active attempt")+(pane.workspace?.referenceHidden?" · reference protected":" · reference revealed"):"Continue reading, deriving or recording evidence on the main display.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.uiText;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
  }
 }
 ColumnLayout {
  visible:pane.view==="notes";Layout.fillWidth:true;Layout.fillHeight:true;spacing:NoesisStyle.sm
  Text {font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Activity draft · shared with the main page";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
  ScrollView {id:notesScroll;Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true
   NoesisEditor {objectName:"studyNotes-"+pane.paneKey;width:notesScroll.availableWidth;enabled:!!pane.workspace?.selected.id;text:pane.workspace?.evidence.text||"";placeholderText:"Write your reasoning, questions or derivation…";onTextChanged:if(pane.workspace?.selected.id&&text!==pane.workspace.evidence.text)pane.workspace.evidence.text=text;Accessible.name:"Shared activity draft"}
  }
 }
 ScrollView {
  id:figuresScroll;visible:pane.view==="figures";Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true
  ColumnLayout {width:figuresScroll.availableWidth;spacing:NoesisStyle.md
   Text {font.hintingPreference:Font.PreferFullHinting;visible:pane.workspace?.referenceHidden||!(pane.workspace?.workflow.artifacts||[]).length;Layout.fillWidth:true;text:pane.workspace?.referenceHidden?"Reference artifacts are protected. Reveal deliberately from the main page.":"No linked figures or artifacts for this activity. Connect existing artifacts from Lab; complete maps and rich diagrams open in Obsidian.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap;renderType:Text.NativeRendering}
   Repeater {model:pane.workspace?.referenceHidden?[]:(pane.workspace?.workflow.artifacts||[]);delegate:ColumnLayout {required property var modelData;Layout.fillWidth:true;spacing:NoesisStyle.sm
    NoesisRow {Layout.fillWidth:true;title:modelData.title;subtitle:modelData.availability||"Inspect artifact";onClicked:pane.workspace.openWork(modelData)}
    Image {visible:!!modelData.figure_url;Layout.fillWidth:true;Layout.preferredHeight:visible?Math.max(120,Math.min(240,figuresScroll.availableHeight-80)):0;source:modelData.figure_url||"";sourceSize.width:2048;sourceSize.height:1200;fillMode:Image.PreserveAspectFit;asynchronous:true;Accessible.name:modelData.title}
   }}
  }
 }
 }
}
