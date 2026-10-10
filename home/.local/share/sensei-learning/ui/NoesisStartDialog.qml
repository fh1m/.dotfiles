import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
NoesisDialog {
 id:root
 property string vaultScope:""
 property bool restoring:false
 function stash(){if(restoring||!vaultScope)return;let drafts=Object.assign({},NoesisController.drafts);drafts[vaultScope+":start-learning"]=JSON.stringify({origin:origin.text,title:label.text,format:format.currentIndex});NoesisController.drafts=drafts;NoesisController.savePreferences();}
 signal beginLearning(string kind,string medium,string source,string title)
 signal zotero()
 modal:true
 title:"Start learning"
 width:Math.min(620,parent?.width-32||620)
 height:Math.min(620*NoesisStyle.interfaceScale,parent?.height-32||700)
 function begin(){restoring=true;vaultScope=NoesisController.activeVault;origin.text="";label.text="";format.currentIndex=7;try{let saved=JSON.parse(NoesisController.drafts[vaultScope+":start-learning"]||"null");if(saved){origin.text=saved.origin||"";label.text=saved.title||"";format.currentIndex=Math.max(0,Math.min(10,saved.format??7));}}catch(e){}restoring=false;open();origin.forceActiveFocus();}
 onClosed:stash()
 Connections {target:NoesisController;function onFlushRequested(){root.stash();}function onActiveVaultChanged(){root.close();}}
 function suggest(){let value=origin.text.trim();if(/^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\//i.test(value))format.currentIndex=value.includes("list=")?1:0;else if(/\.pdf($|[?#])/i.test(value)||/^https?:\/\/(arxiv\.org|doi\.org)\//i.test(value))format.currentIndex=3;else if(/^https?:\/\//i.test(value))format.currentIndex=5;}
 contentItem:ScrollView {id:scroll;clip:true;contentWidth:availableWidth
  ColumnLayout {width:scroll.availableWidth;spacing:NoesisStyle.lg
   Text {Layout.fillWidth:true;text:"What would you like to understand?";wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading}
   Text {Layout.fillWidth:true;text:"Start small. Add questions, lessons, code and evidence as you work.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
   Text {text:"URL, local file, question or topic";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisField {id:origin;objectName:"learning-origin";Layout.fillWidth:true;Accessible.name:"URL, local file, question or topic";placeholderText:"Paste a source or enter your question";onEditingFinished:root.suggest();onTextChanged:if(root.visible&&!root.restoring)draftSave.restart()}
   Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
    NoesisButton {text:"Choose a local file";onClicked:filePicker.open()}
    NoesisButton {text:"Choose from Zotero";onClicked:{root.close();root.zotero();}}
   }
   Text {text:"Start as";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisSelect {id:format;onCurrentIndexChanged:if(root.visible&&!root.restoring)draftSave.restart();objectName:"learning-format";Layout.fillWidth:true;model:["Video or lecture","Playlist","Course","Paper or PDF","Book or chapter","Article or guide","Documentation","Question","Concept or topic","Practice problem","Experiment"]}
   Text {Layout.fillWidth:true;text:"Title · your own wording";wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisField {id:label;onTextChanged:if(root.visible&&!root.restoring)draftSave.restart();objectName:"learning-title";Layout.fillWidth:true;placeholderText:"A title you will recognize later";Accessible.name:"Learning title"}
   Text {Layout.fillWidth:true;text:"Noesis identifies common links locally. It does not fetch titles, transcripts or course outlines. Choose the format and title yourself; the original source stays linked.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   Text {Layout.fillWidth:true;text:"Saved in: "+NoesisController.activeVault;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  }
 }
 footer:Flow {spacing:NoesisStyle.sm
  NoesisButton {text:"Cancel";onClicked:root.close()}
  NoesisButton {text:"Continue";primary:true;enabled:root.vaultScope===NoesisController.activeVault&&!!NoesisController.activeVault&&(label.text.trim()!==""||origin.text.trim()!=="");onClicked:{let index=format.currentIndex;let kind=index===7?"question":index===8?"concept":index===9?"task":index===10?"experiment":"resource";let medium=["video","playlist","course","paper","book","article","docs"][index]||"";let source=origin.text.trim();let title=label.text.trim()||source;root.close();root.beginLearning(kind,medium,kind==="resource"||kind==="task"?source:"",title);let drafts=Object.assign({},NoesisController.drafts);delete drafts[root.vaultScope+":start-learning"];NoesisController.drafts=drafts;NoesisController.savePreferences();}}
 }
 Timer {id:draftSave;interval:500;onTriggered:root.stash()}
 FileDialog {id:filePicker;title:"Choose material to learn from";onAccepted:{origin.text=decodeURIComponent(String(selectedFile).replace(/^file:\/\//,""));root.suggest();}}
}
