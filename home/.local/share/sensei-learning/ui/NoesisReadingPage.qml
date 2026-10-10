import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:page
 property var record:({})
 property var preview:({blocks:[]})
 property string notes:""
 property string savedPlace:""
 property string locationKind:"location"
 property var questions:[]
 property bool busy:false
 property bool protectedReference:false
 property bool notesOnly:false
 property bool placeOpen:false
 property string previousIdentity:""
 readonly property bool compact:width<1000*Math.max(NoesisStyle.interfaceScale,NoesisStyle.readingScale)
 readonly property bool hasSource:!!(record.source||record.local_file||record.zotero_attachment_key)
 readonly property real sourceAnchor:sourceScroll.ScrollBar.vertical.position
 readonly property real notesAnchor:notesScroll.ScrollBar.vertical.position
 signal openSource()
 signal openNote()
 signal notesEdited(string value)
 signal preserveNotes()
 signal askQuestion()
 signal openQuestion(var row)
 signal savePlace(string value,string kind)
 onRecordChanged:{let identity=(record.vault||"")+":"+(record.id||"");if(identity!==previousIdentity){notesOnly=false;placeOpen=false;previousIdentity=identity;}}
 function restoreAnchors(view){notesOnly=view.reading_notes_only===true;Qt.callLater(()=>{sourceScroll.ScrollBar.vertical.position=Math.max(0,Math.min(1-sourceScroll.ScrollBar.vertical.size,view.reading_anchor||0));notesScroll.ScrollBar.vertical.position=Math.max(0,Math.min(1-notesScroll.ScrollBar.vertical.size,view.reading_notes_anchor||0));});}
 spacing:NoesisStyle.md
 Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
  NoesisButton {visible:page.hasSource;text:page.savedPlace?"Resume source ↗":"Open original source ↗";primary:true;enabled:!page.busy&&!page.protectedReference;onClicked:page.openSource()}
  NoesisButton {text:"Edit complete note in Obsidian ↗";enabled:!page.busy&&!page.protectedReference;onClicked:page.openNote()}
  NoesisButton {visible:page.compact;text:page.notesOnly?"Show reading":"Show notes & questions";highlighted:page.notesOnly;onClicked:page.notesOnly=!page.notesOnly}
 }
 SplitView {id:panes;Layout.fillWidth:true;Layout.fillHeight:true;orientation:Qt.Horizontal;handle:Item {implicitWidth:NoesisStyle.lg}
  ScrollView {id:sourceScroll;visible:!page.compact||!page.notesOnly;SplitView.preferredWidth:panes.width*.57;SplitView.minimumWidth:0;SplitView.fillWidth:page.compact;clip:true;contentWidth:availableWidth;padding:NoesisStyle.xl;background:Rectangle {color:NoesisStyle.canvas;radius:NoesisStyle.radius}
   ColumnLayout {width:sourceScroll.availableWidth;spacing:NoesisStyle.lg
    Text {Layout.fillWidth:true;text:"Reading";textFormat:Text.PlainText;color:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;renderType:Text.NativeRendering}
    NoesisDocument {Layout.fillWidth:true;Layout.maximumWidth:NoesisStyle.readingWidth;framed:false;blocks:page.protectedReference?[]:page.preview.blocks||[];originalAvailable:!page.protectedReference&&!page.busy;onOpenOriginal:page.openNote()}
    Text {visible:page.protectedReference||!(page.preview.blocks||[]).length;Layout.fillWidth:true;text:page.protectedReference?"Reference protected for this attempt. Reveal it deliberately from the working page.":"Open the original source for authoritative reading. Use the notes beside it to record your explanation and questions.";textFormat:Text.PlainText;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;renderType:Text.NativeRendering}
    Text {visible:!!page.preview.truncated;Layout.fillWidth:true;text:"This is a bounded preview. The complete note remains available in Obsidian.";textFormat:Text.PlainText;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;renderType:Text.NativeRendering}
   }
  }
  ScrollView {id:notesScroll;visible:!page.compact||page.notesOnly;SplitView.fillWidth:true;SplitView.minimumWidth:0;clip:true;contentWidth:availableWidth;padding:NoesisStyle.xl;background:Rectangle {color:NoesisStyle.canvas;radius:NoesisStyle.radius}
   ColumnLayout {width:notesScroll.availableWidth;spacing:NoesisStyle.md
    Text {Layout.fillWidth:true;text:"Your notes & questions";textFormat:Text.PlainText;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;renderType:Text.NativeRendering}
    Text {Layout.fillWidth:true;text:"Keep your own explanation separate from the source. Save a study note to preserve it in this activity’s history.";textFormat:Text.PlainText;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;renderType:Text.NativeRendering}
    NoesisEditor {objectName:"reading-reasoning";Layout.fillWidth:true;Layout.preferredHeight:300*NoesisStyle.readingScale;text:page.notes;placeholderText:"What is the claim?\n\nHow would I explain or reconstruct it?\n\nWhat is still unclear?";Accessible.name:"Reading notes draft";onTextChanged:if(text!==page.notes)page.notesEdited(text)}
    Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
     NoesisButton {text:"Save study note";primary:page.notes.trim()!=="";enabled:!page.busy&&page.notes.trim()!=="";onClicked:page.preserveNotes()}
     NoesisButton {text:"Ask a source-linked question";enabled:!page.busy;onClicked:page.askQuestion()}
     NoesisButton {text:page.placeOpen?"Hide reading place":page.savedPlace?"Reading place · "+page.savedPlace:"Set a reading place";onClicked:page.placeOpen=!page.placeOpen}
    }
    ColumnLayout {visible:page.placeOpen;Layout.fillWidth:true;spacing:NoesisStyle.sm
     Text {Layout.fillWidth:true;text:"Where should you resume?";textFormat:Text.PlainText;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;renderType:Text.NativeRendering}
     NoesisSelect {id:kind;objectName:"reading-place-kind";Layout.fillWidth:true;model:["Location","Page","Section","Exercise","Timestamp"];currentIndex:Math.max(0,["location","page","section","exercise","timestamp"].indexOf(page.locationKind));Accessible.name:"Reading place kind"}
     NoesisField {id:place;objectName:"reading-place";Layout.fillWidth:true;text:page.savedPlace;placeholderText:"Page, section or timestamp";Accessible.name:"Reading resume position"}
     NoesisButton {text:"Save reading place";enabled:!page.busy&&place.text.trim()!=="";onClicked:page.savePlace(place.text,["location","page","section","exercise","timestamp"][kind.currentIndex])}
    }
    Text {visible:page.questions.length>0;Layout.fillWidth:true;text:"Questions about this source";textFormat:Text.PlainText;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;renderType:Text.NativeRendering}
    Repeater {model:page.protectedReference?[]:page.questions;delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.other_title||"Linked question";subtitle:modelData.other_status||"Open question";enabled:!!modelData.other_path&&!page.busy;onClicked:page.openQuestion(modelData)}}
   }
  }
 }
}
