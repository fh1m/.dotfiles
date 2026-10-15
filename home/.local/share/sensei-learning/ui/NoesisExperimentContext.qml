import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property var context:({})
 property bool detailsVisible:true
 signal openArtifact(var row)
 readonly property int loadedFigures:{let count=0;for(let i=0;i<artifacts.count;i++){if(artifacts.itemAt(i)?.figureLoaded)count++;}return count;}
 spacing:NoesisStyle.lg
 function observedLabel(value){if(!value||typeof value!=="object")return value||"";if(Object.prototype.hasOwnProperty.call(value,"exit_code"))return value.status+" · "+(value.exit_code===null?"exit status unconfirmed":"exit code "+value.exit_code)+" · hypothesis not judged";if(value.actual)return "Implementation "+value.actual.join(", ")+" · oracle "+(value.oracle||[]).join(", ")+" · "+(value.agrees?"matched this case":"disagrees");if(value.outputs)return "Computed outputs: "+value.outputs.join(", ");return "Structured measurements retained; open their evidence artifact.";}
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:root.detailsVisible&&!!root.context.code;text:{let code=root.context.code;if(!code)return "";return "Recorded code · "+(code.commit?code.commit.slice(0,12):"uncommitted revision")+(code.dirty?" · changes were present":"")+"
"+(code.observed_at?Qt.formatDateTime(new Date(code.observed_at),"d MMM yyyy, hh:mm"):"");}Layout.fillWidth:true;wrapMode:Text.Wrap;font.family:NoesisStyle.codeFont;font.pixelSize:NoesisStyle.label;color:NoesisStyle.secondary}
 ColumnLayout {visible:!!root.context.hypothesis;Layout.fillWidth:true;spacing:NoesisStyle.sm
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Original prediction";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.subheading;color:NoesisStyle.secondary}
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:root.context.hypothesis||"";Layout.fillWidth:true;wrapMode:Text.Wrap;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.ink}
 }
 ColumnLayout {visible:root.detailsVisible&&(root.context.configuration||[]).length>0;Layout.fillWidth:true;spacing:NoesisStyle.sm
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Configuration";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.subheading;color:NoesisStyle.secondary}
  Repeater {model:root.context.configuration||[];delegate:Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;required property var modelData;text:modelData.name+" · "+modelData.value;Layout.fillWidth:true;wrapMode:Text.Wrap;font.family:NoesisStyle.codeFont;font.pixelSize:NoesisStyle.label;color:NoesisStyle.ink}}
 }
 ColumnLayout {visible:!!root.context.latest_comparison;Layout.fillWidth:true;spacing:NoesisStyle.sm
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Latest comparison";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.subheading;color:NoesisStyle.secondary}
  Repeater {model:[{label:"Expected",value:root.context.latest_comparison?.predicted||root.context.latest_comparison?.prediction},{label:"Observed",value:root.observedLabel(root.context.latest_comparison?.observed)},{label:"Units",value:root.context.latest_comparison?.units},{label:"Uncertainty",value:root.context.latest_comparison?.uncertainty},{label:"Conclusion",value:root.context.latest_comparison?.conclusion},{label:"Next test",value:root.context.latest_comparison?.next_experiment}];delegate:Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;required property var modelData;visible:!!modelData.value;text:modelData.label+" · "+(modelData.value||"");Layout.fillWidth:true;wrapMode:Text.Wrap;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.ink}}
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:(root.context.latest_comparison?.execution?"Execution receipt recorded · ":"Learner-reported comparison · ")+(root.context.latest_comparison?.timestamp?Qt.formatDateTime(new Date(root.context.latest_comparison.timestamp),"d MMM yyyy, hh:mm"):"")+" · "+root.context.comparison_count+" preserved comparisons";Layout.fillWidth:true;wrapMode:Text.Wrap;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;color:NoesisStyle.secondary}
 }
 ColumnLayout {visible:(root.context.artifacts||[]).length>0;Layout.fillWidth:true;spacing:NoesisStyle.sm
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Data and figures";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.subheading;color:NoesisStyle.secondary}
  Repeater {id:artifacts;model:(root.context.artifacts||[]).slice().sort((a,b)=>Number(!!b.figure_url)-Number(!!a.figure_url));delegate:ColumnLayout {
   required property var modelData
   property bool fullFigure:false
   readonly property bool figureLoaded:figure.status===Image.Ready
   Layout.fillWidth:true;spacing:NoesisStyle.sm
   NoesisRow {Layout.fillWidth:true;title:modelData.title;subtitle:modelData.preview_status||modelData.availability;onClicked:root.openArtifact(modelData)}
   NoesisButton {visible:!!modelData.figure_url;text:parent.fullFigure?"Fit figure in page":"Read figure at full width";onClicked:parent.fullFigure=!parent.fullFigure}
   Image {id:figure;visible:!!modelData.figure_url;Layout.fillWidth:true;Layout.preferredHeight:visible?(parent.fullFigure?width*implicitHeight/Math.max(1,implicitWidth):240):0;source:modelData.figure_url||"";sourceSize.width:1200;sourceSize.height:600;fillMode:Image.PreserveAspectFit;asynchronous:true;Accessible.name:modelData.title}
  }}
 }
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:!!root.context.artifacts_truncated||(root.context.artifact_errors||[]).length>0;text:"Some artifact references need attention. Their histories remain intact.";Layout.fillWidth:true;wrapMode:Text.Wrap;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;color:NoesisStyle.secondary}
}
