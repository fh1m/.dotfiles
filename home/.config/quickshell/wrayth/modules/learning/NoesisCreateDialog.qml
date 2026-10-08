import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
NoesisDialog {
 id:root
 property string kind:"resource"
 property string parentId:""
 property string vaultScope:""
 property bool submitting:false
 signal created(var record)
 modal:true
 width:560
 title:kind==="unit"?"Add a lesson or chapter":kind==="question"?"Preserve a question":kind==="task"?"Add a problem":kind==="experiment"?"Create an experiment":kind==="artifact"?"Connect data, a figure or code":kind==="path"?"Create a learning path":"Save a resource"
 closePolicy:Popup.CloseOnEscape
 function begin(recordKind,parent){vaultScope=Oasis.activeVault;kind=recordKind;parentId=parent||"";name.text="";details.text="";source.text="";revision.text="";submitting=false;open();name.forceActiveFocus();}
 background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
 contentItem:ColumnLayout {spacing:NoesisStyle.lg
  NoesisField {id:name;placeholderText:root.kind==="unit"?"Lesson or chapter title":"Title";Layout.fillWidth:true}
  NoesisSelect {id:medium;visible:root.kind==="resource"||root.kind==="unit";Layout.fillWidth:true;model:root.kind==="unit"?["lecture","reading","chapter","section","video","assignment"]:["paper","book","course","video","playlist","article","docs","dataset","other"]}
  NoesisField {id:source;visible:["resource","unit","artifact"].includes(root.kind);placeholderText:root.kind==="artifact"?"Existing file path or source URL":"Source URL or local PDF path · optional";Layout.fillWidth:true}
  NoesisField {id:revision;visible:root.kind==="artifact";Layout.fillWidth:true;placeholderText:"Code commit, dataset version or configuration · optional"}
  NoesisEditor {id:details;Layout.fillWidth:true;Layout.preferredHeight:140;placeholderText:root.kind==="question"?"What is unclear? Preserve your current explanation.":root.kind==="experiment"?"Your prediction, assumptions and what you want to measure…":"Why this matters now · optional"}
  Text {text:root.parentId?"Connected to your current context. Identity and history are automatic.":"You can add lessons, problems and evidence as you work.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
  RowLayout {Layout.fillWidth:true
   NoesisButton {text:"Cancel";onClicked:root.close()}
   Item {Layout.fillWidth:true}
   NoesisButton {text:"Save";primary:true;enabled:name.text.trim()!==""&&!Oasis.working&&root.vaultScope===Oasis.activeVault;onClicked:{let fields={};if(["resource","unit","artifact"].includes(root.kind)){if(root.kind==="resource")fields.source_kind=medium.currentText;let link=source.text.trim();if(/^https?:\/\//.test(link)){fields.source=link;fields.external_aliases=["url:"+link];if(/^https?:\/\/(dx\.)?doi\.org\//i.test(link)){fields.doi=link.replace(/^https?:\/\/(dx\.)?doi\.org\//i,"");fields.external_aliases.push("doi:"+fields.doi.toLowerCase());}}else if(/^10\.\d{4,9}\//.test(link)){fields.doi=link;fields.source="https://doi.org/"+link;fields.external_aliases=["doi:"+link.toLowerCase()];}else if(/^arxiv:/i.test(link)){fields.arxiv=link.slice(6);fields.source="https://arxiv.org/abs/"+fields.arxiv;}else if(link)fields.local_file=link;}if(root.kind==="unit")fields.unit_kind=medium.currentText;if(root.kind==="artifact"&&revision.text.trim())fields.revision=revision.text.trim();if(root.kind==="experiment")fields.hypothesis=details.text;let args=["record",root.kind,name.text,"--body",details.text,"--data",JSON.stringify(fields)];if(root.parentId)args.push("--parent-id",root.parentId,"--relation",root.kind==="task"?"assigns":"contains");root.submitting=true;Oasis.run(args);}}
  }
 }
 Connections {target:Oasis;function onFinished(ok){if(root.submitting){root.submitting=false;if(ok){root.created(Oasis.operationResult);root.close();}}}}
}
