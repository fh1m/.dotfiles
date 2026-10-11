import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
NoesisDialog {
 id:root
 signal startLearning()
 signal searchRecords()
 title:"Noesis user guide"
 modal:true
 width:Math.min(900,parent?.width-32||900)
 height:Math.min(760,parent?.height-32||760)
 FileView {id:guide;path:Qt.resolvedUrl("user-guide.md");printErrors:false;onLoaded:document.text=text().replace(/\[([^\]]+)\]\((noesis:[^)]+)\)/g,'<a href="$2" style="color:'+NoesisStyle.accent+'">$1</a>');onLoadFailed:document.text="The user guide could not be loaded. Your learning records are unaffected."}
 contentItem:ScrollView {id:scroll;clip:true;contentWidth:availableWidth
  ColumnLayout {width:scroll.availableWidth;spacing:NoesisStyle.lg
  Text {id:document;Layout.fillWidth:true;textFormat:Text.MarkdownText;wrapMode:Text.Wrap;color:NoesisStyle.ink;linkColor:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;lineHeight:1.45;renderType:Text.NativeRendering;onLinkActivated:link=>{if(link==="noesis:start"){root.close();root.startLearning();}else if(link==="noesis:search"){root.close();root.searchRecords();}}}
  Repeater {model:[{file:"start-learning",label:"Start from a source or your own question"},{file:"documentation-workspace",label:"Keep the source, notes and questions connected"},{file:"prerequisite-question",label:"Investigate a mechanism and return to your question"},{file:"create-map",label:"Create an owned editable drawing in Obsidian"},{file:"executed-check",label:"Inspect actual captured output beside the prediction"}]
   delegate:ColumnLayout {required property var modelData;Layout.fillWidth:true;spacing:NoesisStyle.sm
    Text {Layout.fillWidth:true;text:modelData.label;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
    Image {Layout.fillWidth:true;Layout.preferredHeight:width*.61;source:root.visible?Qt.resolvedUrl("guide-images/"+modelData.file+".png"):"";sourceSize.width:Math.min(1600,Math.ceil(width*Screen.devicePixelRatio));fillMode:Image.PreserveAspectFit;asynchronous:true;Accessible.name:modelData.label+" · agent-labelled disposable native screenshot"}
    NoesisButton {text:"View full screenshot";onClicked:Quickshell.execDetached(["xdg-open",String(Qt.resolvedUrl("guide-images/"+modelData.file+".png"))])}
   }
  }
  }
 }
 footer:Flow {spacing:NoesisStyle.sm
  NoesisButton {text:"Start learning";primary:true;onClicked:{root.close();root.startLearning();}}
  NoesisButton {text:"Find existing work";onClicked:{root.close();root.searchRecords();}}
  NoesisButton {text:"Close guide";onClicked:root.close()}
 }
}
