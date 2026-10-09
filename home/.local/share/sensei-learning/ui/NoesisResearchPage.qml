import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property var context:({})
 property string displayTitle:""
 property var preview:({blocks:[]})
 property real viewportHeight:600
 property var revisions:[]
 property string revisionCursor:""
 property string revisionNewerCursor:""
 property string currentProjection:""
 readonly property var bibliography:context.bibliographic_summary||({})
 function focusRevision(){revisionSelect.forceActiveFocus();}
 signal pageAnnotations(var cursor)
 signal chooseSnapshot(string path)
 signal pageRevisions(var cursor)
 spacing:NoesisStyle.md
 Text {Layout.fillWidth:true;visible:!!root.bibliography.title&&root.bibliography.title!==root.displayTitle;textFormat:Text.PlainText;text:root.bibliography.title||"";wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
 Text {Layout.fillWidth:true;visible:text!=="";textFormat:Text.PlainText;text:(root.bibliography.author||[]).map(author=>author.literal||[author.given,author.family].filter(Boolean).join(" ")).join(", ")+(root.bibliography.issued?.["date-parts"]?.[0]?" · "+root.bibliography.issued["date-parts"][0].join("-"):"");wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
 Text {Layout.fillWidth:true;visible:!!root.context.bibliography_error;textFormat:Text.PlainText;text:root.context.bibliography_error||"";wrapMode:Text.Wrap;color:NoesisStyle.error;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
 Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm;visible:root.revisions.length>1||!!root.revisionCursor||!!root.revisionNewerCursor
  Text {textFormat:Text.PlainText;text:"Source snapshot";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  NoesisSelect {id:revisionSelect;model:root.revisions.map(row=>"Revision "+(row.source_version??"unknown")+(row.current?" · current":" · preserved"));currentIndex:root.revisions.findIndex(row=>row.path===root.context.projection);Accessible.name:"Preserved source snapshot";onActivated:if(root.revisions[currentIndex])root.chooseSnapshot(root.revisions[currentIndex].path)}
  NoesisButton {text:"Older snapshots";visible:!!root.revisionCursor;onClicked:root.pageRevisions(root.revisionCursor)}
  NoesisButton {text:"Newer snapshots";visible:!!root.revisionNewerCursor;onClicked:root.pageRevisions(root.revisionNewerCursor)}
  NoesisButton {text:"Current snapshot";visible:!!root.context.historical_snapshot;onClicked:root.chooseSnapshot(root.currentProjection)}
 }
 SplitView {id:split;Layout.fillWidth:true;Layout.preferredHeight:Math.max(360,root.viewportHeight*.8)*Math.max(NoesisStyle.interfaceScale,NoesisStyle.readingScale);orientation:width>=1000*Math.max(NoesisStyle.interfaceScale,NoesisStyle.readingScale)?Qt.Horizontal:Qt.Vertical
  handle:Rectangle {implicitWidth:8;implicitHeight:8;color:SplitHandle.hovered?NoesisStyle.rule:NoesisStyle.surface}
  ColumnLayout {SplitView.fillWidth:true;SplitView.fillHeight:true;SplitView.minimumWidth:Math.min(360,split.width);SplitView.minimumHeight:180;spacing:NoesisStyle.sm
   Text {textFormat:Text.PlainText;text:"Purpose, questions and reconstruction";Layout.fillWidth:true;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   ScrollView {id:analysis;Layout.fillWidth:true;Layout.fillHeight:true;clip:true
    Column {width:analysis.availableWidth;spacing:NoesisStyle.lg
     Repeater {model:root.preview.blocks||[];delegate:TextEdit {required property var modelData;width:Math.min(parent.width,NoesisStyle.readingWidth);text:modelData.text;readOnly:true;selectByMouse:true;textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap;color:modelData.kind==="caption"?NoesisStyle.secondary:NoesisStyle.ink;font.family:modelData.kind==="code"?NoesisStyle.codeFont:NoesisStyle.uiFont;font.pixelSize:modelData.kind==="heading"?NoesisStyle.sectionHeading:modelData.kind==="code"?NoesisStyle.label:NoesisStyle.body;font.bold:modelData.kind==="heading";Accessible.name:"Learner analysis preview"}}
     Text {width:parent.width;textFormat:Text.PlainText;visible:(root.preview.specialist_features||[]).length>0||!!root.preview.truncated;text:"Open the note for the complete document, equations and diagrams.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
    }
   }
  }
  ColumnLayout {SplitView.preferredWidth:360*NoesisStyle.readingScale;SplitView.preferredHeight:split.height*.5;SplitView.minimumWidth:Math.min(280,split.width);SplitView.minimumHeight:180;spacing:NoesisStyle.sm
   Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:"Annotation notebook · imported source";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:root.context.projection_error||((root.context.annotation_count||0)+" annotations · snapshot "+(root.context.source_version??"unavailable")+(root.context.historical_snapshot?" · preserved history":""));wrapMode:Text.Wrap;color:root.context.projection_error?NoesisStyle.error:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
   Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
    NoesisButton {text:"Previous";visible:!!root.context.newer_cursor;onClicked:root.pageAnnotations(root.context.newer_cursor);Accessible.name:"Previous annotation page"}
    NoesisButton {text:"More annotations";visible:!!root.context.cursor;onClicked:root.pageAnnotations(root.context.cursor)}
    NoesisButton {text:"Reload snapshot";visible:!!root.context.newer_cursor||!!root.context.projection_error;onClicked:root.pageAnnotations(null)}
   }
   ScrollView {id:notebook;Layout.fillWidth:true;Layout.fillHeight:true;clip:true
    Column {width:notebook.availableWidth;spacing:NoesisStyle.lg
     Text {width:parent.width;visible:!(root.context.annotations||[]).length;textFormat:Text.PlainText;text:root.context.projection_error?"The preserved import needs inspection. Your analysis remains available.":"No source annotations imported. Capture your questions independently or import the selected Zotero paper.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
     Repeater {model:root.context.annotations||[];delegate:Column {required property var modelData;width:parent.width;spacing:NoesisStyle.sm
      Text {width:parent.width;textFormat:Text.PlainText;text:(modelData.page_label?"Page "+modelData.page_label:modelData.native_id)+" · revision "+(modelData.source_version??"unknown");wrapMode:Text.Wrap;color:NoesisStyle.quiet;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
      TextEdit {width:parent.width;visible:text!=="";text:modelData.text||"";readOnly:true;selectByMouse:true;textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;Accessible.name:"Imported annotation"}
      TextEdit {width:parent.width;visible:text!=="";text:modelData.comment?"Source comment: "+modelData.comment:"";readOnly:true;selectByMouse:true;textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
      Text {width:parent.width;visible:!modelData.attachment_key;textFormat:Text.PlainText;text:modelData.availability||"";wrapMode:Text.Wrap;color:NoesisStyle.warning;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
     }}
    }
   }
  }
 }
}
