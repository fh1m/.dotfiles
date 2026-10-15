import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property var context:({})
 property var source:({})
 property var notesPreview:({blocks:[]})
 property bool busy:false
 property bool detailsOpen:false
 readonly property int loadedFigures:experiment.loadedFigures
 signal openArtifact(var row)
 signal openCode()
 signal recordComparison()
 signal beginRun()
 signal connectArtifact()
 spacing:NoesisStyle.lg
 Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
  NoesisButton {text:root.context.kind==="project"?"Begin a run":"Next run";primary:root.context.kind==="project";enabled:!root.busy;onClicked:root.beginRun()}
  NoesisButton {text:"Record comparison";primary:true;visible:root.context.kind==="experiment";enabled:!root.busy;onClicked:root.recordComparison()}
  NoesisButton {text:"Open code ↗";visible:!root.source.scratch_directory&&(!!root.source.repository||!!root.source.code_snapshot?.repository);enabled:!root.busy;onClicked:root.openCode()}
  NoesisButton {text:"Connect artifact";enabled:!root.busy;onClicked:root.connectArtifact()}
  NoesisButton {text:root.detailsOpen?"Hide run details":"Run details";highlighted:root.detailsOpen;onClicked:root.detailsOpen=!root.detailsOpen}
 }
 Text {visible:!!root.context.unfinished_scan_truncated;Layout.fillWidth:true;text:"The latest 200 capture files were inspected. Use Inspect run files for earlier unfinished outputs.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
 Text {visible:!!root.context.latest_comparison?.execution?.code_changed;Layout.fillWidth:true;text:"Code changed or became unavailable during capture. Inspect the saved code and outputs before attributing this result to a revision.";wrapMode:Text.Wrap;color:NoesisStyle.warning;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
 Repeater {model:root.context.unfinished_executions||[];delegate:Text {required property var modelData;Layout.fillWidth:true;text:"Unfinished capture · "+(modelData.started_at||"")+"\n"+modelData.message;wrapMode:Text.Wrap;color:NoesisStyle.warning;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}}
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:!root.context.hypothesis;text:root.context.kind==="project"?"Begin a run to preserve a prediction, configuration and code revision before measuring.":"No original prediction is recorded for this run. Preserve its limitations alongside any comparison.";wrapMode:Text.Wrap;Layout.fillWidth:true;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
 NoesisDocument {visible:root.context.kind==="project"&&!root.detailsOpen;Layout.fillWidth:true;Layout.maximumWidth:NoesisStyle.readingWidth;framed:false;blocks:(root.notesPreview.blocks||[]).slice(0,2);onOpenOriginal:NoesisController.note(root.source.path)}
 ColumnLayout {visible:!!root.context.output_preview||!!root.context.error_preview;Layout.fillWidth:true;spacing:NoesisStyle.sm
  Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Actual captured output"+(root.context.output_truncated?" · bounded preview; full text in run files":"");color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.subheading;wrapMode:Text.Wrap}
  ScrollView {id:outputScroll;Layout.fillWidth:true;Layout.preferredHeight:Math.min(220*NoesisStyle.interfaceScale,Math.max(36,outputText.implicitHeight+12));contentWidth:availableWidth;clip:true
   TextEdit {id:outputText;width:outputScroll.availableWidth;readOnly:true;selectByMouse:true;textFormat:TextEdit.PlainText;text:(root.context.output_preview||"")+(root.context.error_preview?"\n"+root.context.error_preview:"");wrapMode:TextEdit.Wrap;renderType:TextEdit.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.family:NoesisStyle.codeFont;font.pixelSize:NoesisStyle.label;color:root.context.error_preview?NoesisStyle.warning:NoesisStyle.ink}
  }
 }
 NoesisExperimentContext {id:experiment;Layout.fillWidth:true;context:root.context;detailsVisible:root.detailsOpen;onOpenArtifact:row=>root.openArtifact(row)}
 NoesisDocument {visible:root.detailsOpen;Layout.fillWidth:true;Layout.maximumWidth:NoesisStyle.readingWidth;framed:false;blocks:root.notesPreview.blocks||[];onOpenOriginal:NoesisController.note(root.source.path)}
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;visible:root.context.kind==="experiment"&&!root.context.latest_comparison;text:"No comparison recorded. A planned check or linked output does not establish that this run was performed.";wrapMode:Text.Wrap;Layout.fillWidth:true;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
}
