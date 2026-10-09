import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
NoesisDialog {
 id:root
 property var target:({})
 property var expectedHead:null
 property string vaultScope:""
 property bool submitting:false
 property string errorMessage:""
 function begin(record,head){target=Object.assign({},record);expectedHead=head;vaultScope=NoesisController.activeVault;open();}
 title:"Replace lesson material"
 width:Math.min(540,parent.width-48)
 anchors.centerIn:parent
 onOpened:{errorMessage="";location.text="";reason.text="";sourceType.currentIndex=0;medium.currentIndex=Math.max(0,medium.model.indexOf(target.source_kind||"video"));location.forceActiveFocus();}
 contentItem:ColumnLayout {spacing:NoesisStyle.md
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:root.target.title||"Lesson";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;Layout.fillWidth:true}
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"The lesson and your notes stay intact. Previous material and positions remain in History. The new source starts unread, without a saved place.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
  RowLayout {Layout.fillWidth:true
   NoesisSelect {id:sourceType;model:["Source URL","Local document"];Layout.fillWidth:true;Accessible.name:"Replacement source location type"}
   NoesisSelect {id:medium;model:["video","pdf","article","documentation","book"];Layout.fillWidth:true;Accessible.name:"Replacement medium"}
  }
  NoesisField {id:location;placeholderText:sourceType.currentIndex===0?"https://…":"Path to the existing document";Layout.fillWidth:true;Accessible.name:"Replacement material location"}
  NoesisField {id:reason;placeholderText:"Why use this material instead?";Layout.fillWidth:true;Accessible.name:"Replacement reason"}
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:root.errorMessage!=="";text:root.errorMessage;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true;Accessible.name:"Replacement error"}
  NoesisButton {id:save;text:"Replace material";primary:true;hint:"Ctrl+Enter";enabled:location.text.trim()!==""&&reason.text.trim()!==""&&!NoesisController.working&&root.vaultScope===NoesisController.activeVault;onClicked:{let material={source_kind:medium.currentText};material[sourceType.currentIndex===0?"source":"local_file"]=location.text.trim();root.submitting=true;NoesisController.run(["event",root.target.path,"material-change","--target-id",root.target.id,"--evidence",reason.text.trim(),"--data",JSON.stringify({material:material,expected_head:root.expectedHead})]);}}
 }
 Shortcut {sequence:"Ctrl+Return";enabled:root.opened;onActivated:if(save.enabled)save.clicked()}
 Connections {target:NoesisController;function onFinished(ok){if(root.submitting){root.submitting=false;if(ok)root.close();else root.errorMessage=NoesisController.error||"Replacement failed; no change was acknowledged. Inspect the operation before retrying.";}}}
}
