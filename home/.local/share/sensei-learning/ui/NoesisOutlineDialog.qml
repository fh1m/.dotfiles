import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Popup {
 id:root
 Overlay.modal:Rectangle {color:"#b3090807"}
 property string vaultScope:""
 property string operationId:""
 property string courseId:""
 property string courseTitle:""
 function begin(course){courseId=course?.id||"";courseTitle=course?.title||"";open();}
 property var review:({})
 property bool submitting:false
 signal imported(var course)
 function reviewOutline(){NoesisController.run(["course-import",file.text]);}
 function submit(){root.submitting=true;NoesisController.run(["course-import",file.text,"--apply","--operation-id",root.operationId,"--expected-digest",root.review.digest].concat(root.courseId?["--course-id",root.courseId]:[]));}
 Shortcut {sequence:"Ctrl+Return";enabled:root.opened&&!NoesisController.working&&root.vaultScope===NoesisController.activeVault&&file.text.trim()!=="";onActivated:root.review.digest?root.submit():root.reviewOutline()}
 width:Math.min(700,parent.width-48);height:Math.min(600,parent.height-48);anchors.centerIn:parent
 parent:Overlay.overlay
 modal:true;focus:true;closePolicy:Popup.CloseOnEscape
 background:Rectangle {color:NoesisStyle.canvas;radius:NoesisStyle.radius;}
 onOpened:{vaultScope=NoesisController.activeVault;operationId=NoesisController.operationUuid();review=({});file.forceActiveFocus();file.selectAll();}
 Connections {target:NoesisController;function onFinished(ok){if(!root.opened)return;if(!ok){root.submitting=false;return;}if(NoesisController.operationKind==="course-import"){if(root.submitting){root.submitting=false;root.imported(NoesisController.operationResult.course);root.close();}else root.review=NoesisController.operationResult;}}}
 ColumnLayout {anchors.fill:parent;anchors.margins:NoesisStyle.xl;spacing:NoesisStyle.md
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:root.courseId?"Add an outline to "+root.courseTitle:"Import a course outline";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;color:NoesisStyle.ink}
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Review lessons, readings and assignments before creating them. Retrying the same import preserves identities.";Layout.fillWidth:true;wrapMode:Text.Wrap;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
  NoesisField {id:file;Layout.fillWidth:true;placeholderText:"Course outline JSON file";onTextChanged:root.review=({});Accessible.name:"Course outline file"}
  NoesisButton {text:"Review outline";enabled:file.text.trim()!==""&&!NoesisController.working;onClicked:root.reviewOutline()}
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:root.review.title||"";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;color:NoesisStyle.ink}
  ListView {Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.review.entries||[];delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.title;subtitle:modelData.kind+" · "+modelData.parent} ScrollBar.vertical:ScrollBar {}}
  RowLayout {Layout.fillWidth:true
   Item {Layout.fillWidth:true}
   NoesisButton {text:"Cancel";onClicked:root.close()}
   NoesisButton {text:root.courseId?"Add to this course":"Create outline";primary:true;enabled:!!root.review.digest&&!NoesisController.working&&root.vaultScope===NoesisController.activeVault;onClicked:root.submit()}
  }
 }
}
