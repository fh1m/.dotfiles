import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
 id:root
 property var context:({})
 property bool quiet:false
 property bool collectionScope:false
 property bool pathScoped:false
 property bool busy:false
 signal openContext(var row)
 signal toggleQuiet()
 signal clearPathScope()
 signal start(string kind)
 signal browse()
 function focusQuiet(){quietButton.forceActiveFocus();}
 clip:true
 contentWidth:availableWidth
 ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
 ColumnLayout {width:root.availableWidth;spacing:NoesisStyle.lg
  Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:root.context.continue?"Continue your work":root.context.empty_reason==="no-records"?"Begin with something worth understanding":"Choose a thread to continue";wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.title}
  NoesisRow {Layout.fillWidth:true;visible:!!root.context.continue;title:root.context.continue?.title||"";subtitle:(root.context.continue?.vault_name?root.context.continue.vault_name+" · ":"")+(root.context.continue?.unfinished_attempt?"Unfinished attempt · reasoning and exposure preserved":root.context.continue?.position||"Resume this working context");trailing:"Resume →";onClicked:root.openContext(root.context.continue)}
  Text {Layout.fillWidth:true;visible:!root.context.continue;textFormat:Text.PlainText;text:root.context.empty_reason==="data-unavailable"?"Some registered storage is unavailable. Its saved work remains owned by that vault.":root.context.empty_reason==="no-records"?"Start with a source, a question or a prediction. Progress will come from your recorded work.":"Saved material remains available even when no next action is due.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
  Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
   Text {textFormat:Text.PlainText;text:"Next actions";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
   NoesisButton {id:quietButton;text:root.quiet?"Show suggestions":"Quiet suggestions";onClicked:root.toggleQuiet()}
   NoesisButton {text:"All paths";visible:root.pathScoped;onClicked:root.clearPathScope()}
  }
  Text {Layout.fillWidth:true;visible:root.quiet||!(root.context.records||[]).length;textFormat:Text.PlainText;text:root.quiet?"Suggestions are quiet. Your resume context and paths remain available.":"No next action is due. Choose a path or start something you want to understand.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
  Repeater {model:root.context.records||[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title||modelData.path;subtitle:(modelData.vault_name?modelData.vault_name+" · ":"")+(modelData.reason||"Learner-selected context");trailing:"Open →";onClicked:root.openContext(modelData)}}
  Text {Layout.fillWidth:true;visible:(root.context.paths||[]).length>0;textFormat:Text.PlainText;text:"Active paths and courses";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
  Repeater {model:root.context.paths||[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title;subtitle:(modelData.vault_name?modelData.vault_name+" · ":"")+"Open outline · assessment remains separate";trailing:"Open →";onClicked:root.openContext(modelData)}}
  Repeater {model:root.context.scope_errors||[];delegate:Text {required property var modelData;Layout.fillWidth:true;textFormat:Text.PlainText;text:"Unavailable owner: "+modelData.vault+" · "+modelData.message;wrapMode:Text.Wrap;color:NoesisStyle.warning;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}}
  Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:root.collectionScope?"Across the selected managed learning collection. Opening work selects its owner; saves retain that owner.":"This vault’s learning context. Use the scope control to view your managed collection.";wrapMode:Text.Wrap;color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
  Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:"Start something";wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
  Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
   NoesisButton {text:"Learning path";enabled:!root.busy;onClicked:root.start("path")}
   NoesisButton {text:"Course or book";enabled:!root.busy;onClicked:root.start("resource")}
   NoesisButton {text:"Research paper";enabled:!root.busy;onClicked:root.start("paper")}
   NoesisButton {text:"Practice problem";enabled:!root.busy;onClicked:root.start("task")}
   NoesisButton {text:"Experiment";enabled:!root.busy;onClicked:root.start("experiment")}
   NoesisButton {text:"Browse library";onClicked:root.browse()}
  }
 }
}
