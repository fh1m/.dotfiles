import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services
ChamferPanel {
 id:panel
 implicitHeight:800;chamfer:Theme.radiusPanel;scanlines:false;fillColor:"#000000"
 FileDialog {id:filePicker;title:"Select learning material";property var destination:null;onAccepted:{if(destination)destination.text=decodeURIComponent(selectedFile.toString().replace(/^file:\/\//,""));}}
 function pick(field){filePicker.destination=field;filePicker.open();}
 property string section:"Today"
 property var selected:({})
 property string folder:""
 property string captureSubmission:""
 property string roleFilter:"All"
 property string kind:"note"
 readonly property var sections:["Today","Library","Daily","Resources","Papers","Courses","Practice","Experiments","Builds","Connections","Recall","Questions","Snippets","Vaults","Files","Create","Import"]
 function fuzzy(text,part){let i=0;for(let c of text){if(c===part[i])i++;if(i===part.length)return true;}return false;}
 function glyph(name){return ({Overview:"\uf14e",Vaults:"\uf02d",Notes:"\uf15c",Daily:"\uf073",Connections:"\uf542",Builds:"\uf0ad",Experiments:"\uf0c3",Recall:"\uf1da",Questions:"\uf059",Sources:"\uf02e",Files:"\uf07b",Create:"\uf067"})[name]||"\uf15c";}
 readonly property var rows:{
  let s=Oasis.state;let rows=[];
  if(section==="Resources")rows=s.sources||[];
  else if(section==="Papers")rows=(s.notes||[]).filter(n=>n.type==="paper");
  else if(section==="Courses")rows=(s.notes||[]).filter(n=>n.type==="course");
  else if(section==="Practice")rows=(s.notes||[]).filter(n=>n.type==="problem");
  else if(section==="Snippets")rows=(s.notes||[]).filter(n=>n.type==="snippet");
  else if(section==="Vaults")rows=s.vaults||[];
  else if(section==="Builds")rows=s.projects||[];
  else if(section==="Experiments")rows=s.labs||[];
  else if(section==="Recall")rows=s.reviews||[];
  else if(section==="Questions")rows=s.questions||[];
  else if(section==="Sources")rows=s.sources||[];
  else if(section==="Today")rows=s.gates||[];
  else if(section==="Connections")rows=(s.notes||[]).filter(n=>n.path!==selected.path&&((selected.links||[]).some(l=>l.path===n.path)||(n.links||[]).some(l=>l.path===selected.path)));
  else if(section==="Files"){
   let files=s.files||[];let dirs={};let prefix=folder?folder+"/":"";
   for(let f of files){if(!f.path.startsWith(prefix))continue;let rest=f.path.slice(prefix.length);if(rest.includes("/")){let name=rest.split("/")[0];dirs[name]={name:name,path:prefix+name,folder:prefix+name,isFolder:true};}else rows.push(f);}
   rows=Object.values(dirs).concat(rows);
  }else rows=(s.notes||[]).filter(n=>section!=="Daily"||n.type==="daily"||/\/Daily\/|^Daily\/|^91 Daily\//.test(n.path));
  if(roleFilter!=="All"&&section!=="Files"&&section!=="Vaults")rows=rows.filter(n=>n.type===roleFilter);
  let q=search.text.trim().toLowerCase();if(q){let parts=q.split(/\s+/);rows=rows.filter(n=>parts.every(p=>panel.fuzzy((n.name+" "+n.path+" "+(n.type||"")+" "+(n.status||"")+" "+(n.domain||"")+" "+(Array.isArray(n.tags)?n.tags.join(" "):String(n.tags||""))).toLowerCase(),p)));}
  return rows;
 }
 Connections {target:Oasis;function onActiveVaultChanged(){panel.selected=({});panel.folder="";}function onFinished(ok){if(ok&&capture.text===panel.captureSubmission)capture.text="";panel.captureSubmission="";}}
 onSectionChanged:{search.text="";roleFilter="All";role.currentIndex=0;if(section!=="Connections"&&section!=="Import")selected=({});}
 ColumnLayout {
  anchors.fill:parent;anchors.margins:16;spacing:10
  RowLayout {Layout.fillWidth:true;spacing:12
   Text {text:"Workspace";color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:22;font.bold:true}
   Text {text:Oasis.state.vault?("Vault · "+Oasis.state.vault):"Learn anything · connect the evidence";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;Layout.fillWidth:true;elide:Text.ElideRight}
   ActionButton {text:"Today";glyph:"\uf073";usable:!Oasis.working;onClicked:Oasis.run(["today"])}
   ActionButton {text:"Views";glyph:"\uf0ce";usable:!Oasis.working;onClicked:Oasis.note((Oasis.state.home==="Home.md"?"Views/":"93 Bases/")+"Library.base")}
   ActionButton {text:"Graph";glyph:"\uf0e8";usable:!Oasis.working;onClicked:Oasis.run(["cli","command","id=graph:open"])}
   ActionButton {text:"Refresh";usable:!Oasis.working;onClicked:Oasis.refresh()}
  }
  Text {text:Oasis.error||(Oasis.working?"Working… your window stays responsive.":Oasis.message)||"Sensei, connect an idea to a prediction, a build, and a test.";color:Oasis.error?Theme.widgetAccent:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;Layout.fillWidth:true;elide:Text.ElideRight}
  ActionButton {visible:Oasis.working;text:"Cancel action";glyph:"\uf00d";onClicked:Oasis.cancel()}
  Rectangle {height:1;Layout.fillWidth:true;color:Theme.widgetBorder}
  RowLayout {Layout.fillHeight:true;Layout.fillWidth:true;spacing:14
   ListView {Layout.preferredWidth:164;Layout.fillHeight:true;clip:true;spacing:3;model:panel.sections
    delegate:Rectangle {required property string modelData;width:164;height:35;radius:3;color:panel.section===modelData?Theme.widgetRaised:"transparent"
     Text {anchors.left:parent.left;anchors.leftMargin:12;anchors.verticalCenter:parent.verticalCenter;text:modelData;color:panel.section===modelData?Theme.widgetAccent:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:14;font.bold:panel.section===modelData}
     Rectangle {visible:panel.section===modelData;width:2;height:15;anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;color:Theme.widgetAccent}
     MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:panel.section=modelData}
    }
   }
   Rectangle {width:1;Layout.fillHeight:true;color:Theme.widgetBorder}
   ColumnLayout {Layout.fillWidth:true;Layout.fillHeight:true;spacing:8
    RowLayout {Layout.fillWidth:true
     Text {text:panel.section==="Today"?"Next meaningful move":panel.section;color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:16;font.bold:true;Layout.fillWidth:true}
     Text {text:panel.rows.length+" entries";visible:panel.section!=="Create"&&panel.section!=="Import";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:11}
     ActionButton {visible:panel.section==="Files"&&panel.folder!=="";text:"Up";glyph:"\uf062";onClicked:panel.folder=panel.folder.split("/").slice(0,-1).join("/")}
    }
    DeskComboBox {id:role;visible:panel.section==="Library";Layout.fillWidth:true;model:["All","concept","paper","course","problem","resource","lab","project","question","error","branch","snippet","review","daily","note"];onActivated:panel.roleFilter=currentText}
    DeskTextField {id:search;visible:panel.section!=="Create"&&panel.section!=="Import";Layout.fillWidth:true;placeholderText:panel.section==="Files"?(panel.folder||"Vault files")+" · filter":"Find by name, topic, tag or path…"}
    Text {visible:panel.section==="Today";text:(Oasis.state.question||"Choose what you want to be able to do.")+"\n\n"+(Oasis.state.next_experiment||"Make a prediction; choose the smallest useful test.");wrapMode:Text.Wrap;color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:14;Layout.fillWidth:true}
    RowLayout {visible:panel.section==="Today";spacing:6
     ActionButton {text:"Frontier";onClicked:Oasis.run(["frontier"])}ActionButton {text:"Home";onClicked:Oasis.run(["open"])}ActionButton {text:"Backup";glyph:"\uf0c7";usable:!Oasis.working;onClicked:Oasis.run(["backup"])}
    }
    ColumnLayout {visible:panel.section==="Create";Layout.fillWidth:true;Layout.fillHeight:true;spacing:8
     Flow {Layout.fillWidth:true;spacing:5;Repeater {model:["note","concept","paper","course","problem","resource","snippet","question","lab","project","error","map"];ActionButton {required property string modelData;text:modelData;accented:panel.kind===modelData;onClicked:panel.kind=modelData}}}
     DeskTextField {id:title;Layout.fillWidth:true;placeholderText:"Title · templates are optional scaffolding"}
     DeskTextField {id:destination;Layout.fillWidth:true;placeholderText:"Folder (optional; write where you want)"}
     RowLayout {ActionButton {text:"Create note";glyph:"\uf067";usable:!Oasis.working&&title.text.trim()!=="";onClicked:{let a=["new",panel.kind,title.text,"--open"];if(destination.text.trim())a=a.concat(["--folder",destination.text]);Oasis.run(a);}}
      ActionButton {text:"Canvas";glyph:"\uf0e8";usable:!Oasis.working&&title.text.trim()!=="";onClicked:Oasis.run(["canvas",title.text])}}
     Text {text:"Free notes, equations, diagrams, sketches and code.\nOpen in Obsidian for full editing and rendering.";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;wrapMode:Text.Wrap;Layout.fillWidth:true}
     DeskComboBox {id:resourceKind;Layout.fillWidth:true;model:["paper","book","article","docs","lecture","playlist","course","dataset","other"]}
     DeskTextField {id:resourceUrl;Layout.fillWidth:true;placeholderText:"Resource URL (optional)"}
     DeskTextField {id:resourceFile;Layout.fillWidth:true;placeholderText:"Local PDF / material path (optional; no duplicate copy)"}
     ActionButton {text:"Choose Material file";glyph:"\uf07b";onClicked:panel.pick(resourceFile)}
     ActionButton {text:"Register resource";glyph:"\uf02e";usable:!Oasis.working&&title.text.trim()!=="";onClicked:{let a=["resource",title.text,"--kind",resourceKind.currentText,"--url",resourceUrl.text];if(resourceFile.text.trim())a=a.concat(["--file",resourceFile.text]);Oasis.run(a);}}
     Text {text:"Create note uses its template. Register resource links real reading material. Neither claims you learned it.";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;wrapMode:Text.Wrap;Layout.fillWidth:true}
     Item {Layout.fillHeight:true}
    }
    ColumnLayout {visible:panel.section==="Import";Layout.fillHeight:true;Layout.fillWidth:true;spacing:12
     Text {text:"Bring sources in; keep your reasoning yours.";color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:16;wrapMode:Text.Wrap;Layout.fillWidth:true}
     DeskTextField {id:exportFile;Layout.fillWidth:true;placeholderText:"CSL JSON export file from Zotero"}
     ActionButton {text:"Choose CSL JSON file";glyph:"\uf07b";onClicked:panel.pick(exportFile)}
     ActionButton {text:"Import references";glyph:"\uf093";usable:!Oasis.working&&exportFile.text.trim()!=="";onClicked:Oasis.run(["import-csl",exportFile.text])}
     DeskTextField {id:annotationFile;Layout.fillWidth:true;placeholderText:"Markdown annotation export file"}
     ActionButton {text:"Choose Annotations file";glyph:"\uf07b";onClicked:panel.pick(annotationFile)}
     Text {text:panel.selected.path?"Selected resource: "+panel.selected.name:"Select a resource in Library or Papers, then return here.";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:13;wrapMode:Text.Wrap;Layout.fillWidth:true}
     ActionButton {text:"Import annotations";glyph:"\uf093";usable:!Oasis.working&&annotationFile.text.trim()!==""&&!!panel.selected.id;onClicked:Oasis.run(["import-notes",annotationFile.text,"--resource",panel.selected.path])}
     Text {text:"Imports retain citation/page links and generated excerpts. Repeated imports preserve your synthesis. Zotero exports are not backups of its database.";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:13;wrapMode:Text.Wrap;Layout.fillWidth:true}
     ActionButton {text:"Open Zotero";glyph:"\uf02d";onClicked:Quickshell.execDetached(["@HOME@/.local/bin/zotero"])}
     Item {Layout.fillHeight:true}
    }
    RowLayout {visible:panel.section==="Files";spacing:6
     DeskTextField {id:localfile;Layout.fillWidth:true;placeholderText:"Local file path to copy into attachments"}
     ActionButton {text:"Choose file";glyph:"\uf07b";onClicked:panel.pick(localfile)}
     ActionButton {text:"Import";glyph:"\uf093";usable:localfile.text.trim()!==""&&!Oasis.working;onClicked:{let a=["attach",localfile.text];if(panel.selected.path?.endsWith(".md"))a=a.concat(["--note",panel.selected.path]);Oasis.run(a);}}
     ActionButton {text:"Folder";glyph:"\uf07b";onClicked:Quickshell.execDetached(["xdg-open",Oasis.activeVault+"/"+panel.folder])}
    }
    ListView {id:entries;visible:panel.section!=="Create"&&panel.section!=="Import";Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:4;model:panel.rows
     delegate:Rectangle {required property var modelData;width:entries.width;height:58;radius:3;color:panel.selected.path===modelData.path?Theme.widgetRaised:hover.containsMouse?Theme.widgetSurface:"transparent"
      Column {anchors.fill:parent;anchors.margins:7;spacing:3
       Text {width:parent.width;text:(modelData.isFolder?"▸ ":"")+modelData.name;color:panel.selected.path===modelData.path?Theme.widgetAccent:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:14;elide:Text.ElideRight}
       Text {width:parent.width;text:panel.section==="Vaults"?(modelData.active?"Selected · ":"")+"Independent vault":(modelData.type||modelData.ext||"")+" · "+(modelData.status||modelData.folder||modelData.path);color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;elide:Text.ElideRight}
      }
      MouseArea {id:hover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:{if(panel.section==="Vaults"){Oasis.choose(modelData.path);}else if(modelData.isFolder){panel.folder=modelData.path;}else{panel.selected=modelData;if(modelData.path.endsWith(".md"))Oasis.preview(modelData.path);}}onDoubleClicked:if(panel.section!=="Vaults"&&!modelData.isFolder)Oasis.note(modelData.path)}
     }
     Text {visible:!panel.rows.length;anchors.centerIn:parent;text:panel.section==="Connections"?"Select a note, then explore its links.":"No matching entries. Keep only useful state.";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:11}
    }
    DeskTextField {id:capture;Layout.fillWidth:true;placeholderText:panel.section==="Vaults"?"New subject · any field":"Quick observation / question → Inbox";onAccepted:if(text.trim()&&!Oasis.working){panel.captureSubmission=text;Oasis.run(panel.section==="Vaults"?["init",text]:["capture",text]);}}
   }
   Rectangle {width:1;Layout.fillHeight:true;color:Theme.widgetBorder}
   ColumnLayout {Layout.preferredWidth:Math.min(460,panel.width*.36);Layout.fillHeight:true;spacing:8
    Text {text:panel.selected.name||"Tools for understanding";color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:14;font.bold:true;Layout.fillWidth:true;elide:Text.ElideRight}
    RowLayout {ActionButton {text:"Open";usable:!!panel.selected.path&&panel.section!=="Vaults"&&!Oasis.working;onClicked:Oasis.note(panel.selected.path)}ActionButton {text:"Links";glyph:"\uf0e8";usable:!!panel.selected.path&&panel.section!=="Vaults";onClicked:panel.section="Connections"}}
    ScrollView {Layout.fillWidth:true;Layout.fillHeight:true;clip:true
     TextArea {readOnly:true;selectByMouse:true;wrapMode:TextEdit.Wrap;textFormat:TextEdit.PlainText;background:null;color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:14;text:panel.selected.path===Oasis.previewPath?Oasis.previewText:"Capture freely. Connect related ideas.\n\nUse links and maps to explain relationships, not just collect nodes.\n\nReconstruct from memory; preserve evidence and failed predictions.\n\nOpen Graph / Canvas / notes in Obsidian. LaTeX and drawings use its full renderer."}
    }
    ColumnLayout {visible:!!panel.selected.path;Layout.fillWidth:true;spacing:8
    RowLayout {spacing:5
     ActionButton {text:"Local graph";glyph:"\uf0e8";usable:!!panel.selected.path&&panel.selected.path.endsWith(".md")&&!Oasis.working;onClicked:Oasis.run(["cli","eval","code=(async()=>{const f=app.vault.getAbstractFileByPath("+JSON.stringify(panel.selected.path)+");await app.workspace.getLeaf(false).openFile(f);app.commands.executeCommandById('graph:open-local');return 'Local graph opened'})()"])}
     ActionButton {text:"Draw";glyph:"\uf040";usable:!Oasis.working;onClicked:{if((Oasis.state.commands||[]).includes("obsidian-excalidraw-plugin:excalidraw-autocreate"))Oasis.run(["cli","command","id=obsidian-excalidraw-plugin:excalidraw-autocreate"]);else Oasis.run(["enable-drawing"]);}}
    }
    RowLayout {spacing:6
     ActionButton {text:"Read";glyph:"\uf02d";usable:!!panel.selected.path&&!Oasis.working;onClicked:Oasis.run(["read-resource",panel.selected.path])}
     ActionButton {text:"Zotero";glyph:"\uf02e";usable:!!panel.selected.path&&!Oasis.working;onClicked:Oasis.run(["read-resource",panel.selected.path,"--reader","zotero"])}
    }
    DeskTextField {id:position;Layout.fillWidth:true;placeholderText:"Resume: page / lecture / timestamp / milestone"}
    ActionButton {text:"Save study position";glyph:"\uf0c7";usable:!!panel.selected.path&&!Oasis.working&&position.text.trim()!=="";onClicked:Oasis.run(["progress",panel.selected.path,"--position",position.text])}
    RowLayout {Layout.fillWidth:true;DeskComboBox {id:result;Layout.fillWidth:true;model:["blocked","hinted","solved","reproduced","failed","transferred"]}DeskTextField {id:hint;Layout.preferredWidth:140;placeholderText:"Hints used"}}
    DeskTextField {id:attemptEvidence;Layout.fillWidth:true;placeholderText:"Attempt evidence / why blocked / what changed"}
    ActionButton {text:"Record attempt";glyph:"\uf040";usable:!!panel.selected.path&&!Oasis.working&&attemptEvidence.text.trim()!=="";onClicked:Oasis.run(["attempt",panel.selected.path,"--result",result.currentText,"--evidence",attemptEvidence.text,"--hint",hint.text||"none"])}
    DeskTextField {id:status;Layout.fillWidth:true;placeholderText:"Status (working, active, resolved…)"}
    ActionButton {text:"Update status";usable:!!panel.selected.path&&panel.selected.path.endsWith(".md")&&status.text.trim()!==""&&!Oasis.working;onClicked:Oasis.run(["update",panel.selected.path,"status",status.text])}
    RowLayout {DeskTextField {id:confidence;Layout.preferredWidth:70;placeholderText:"0–5";validator:IntValidator {bottom:0;top:5}}DeskTextField {id:days;Layout.preferredWidth:70;text:"7";placeholderText:"Days";validator:IntValidator {bottom:1;top:3650}}DeskTextField {id:evidence;Layout.fillWidth:true;placeholderText:"Recall evidence"}}
    ActionButton {text:"Record recall";glyph:"\uf1da";usable:!!panel.selected.path&&panel.selected.path.endsWith(".md")&&confidence.acceptableInput&&confidence.text!==""&&days.acceptableInput&&evidence.text.trim()!==""&&!Oasis.working;onClicked:Oasis.run(["review",panel.selected.path,"--confidence",confidence.text,"--days",days.text,"--evidence",evidence.text])}
    }
   }
  }
 }
}
