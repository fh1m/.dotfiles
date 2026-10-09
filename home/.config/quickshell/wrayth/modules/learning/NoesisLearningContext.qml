import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

ColumnLayout {
 id:root
 property var context:({})
 property bool busy:false
 signal openContext(var row)
 signal reviewReadiness(var row)
 spacing:NoesisStyle.md
 function assessmentLabel(row){let result=row.assessment;if(!result)return "Not assessed";let support=(result.assistance||["unknown"]);return (result.outcome==="succeeded"?"Reported success":result.outcome==="failed"?"Previous attempt failed":result.outcome==="partial"?"Partial result":"Unfinished assessment")+" · "+(JSON.stringify(support)==='["none"]'?"independent":support.includes("unknown")?"assistance unknown":"assisted: "+support.join(", "));}
 ColumnLayout {
  Layout.fillWidth:true
  Repeater {model:root.context.parents||[];delegate:NoesisButton {required property var modelData;text:"← "+modelData.title;enabled:!root.busy;hint:"Ctrl+Alt+Left · return to outline";onClicked:root.openContext(modelData)}}
 }
 Repeater {
  model:[{title:"Before this lesson",rows:root.context.prerequisites||[],kind:"prerequisite"},{title:"Exercises and assignments",rows:root.context.assignments||[],kind:"assignment"}]
  delegate:ColumnLayout {
   required property var modelData
   visible:modelData.rows.length>0
   Layout.fillWidth:true
   spacing:NoesisStyle.sm
   Text {text:modelData.title;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.subheading}
   Repeater {model:modelData.rows;delegate:NoesisRow {
    required property var modelData
    Layout.fillWidth:true
    title:modelData.title
    rightPadding:modelData.role==="gate"?140:NoesisStyle.md
    NoesisButton {anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;visible:modelData.role==="gate";hint:"Ctrl+Alt+R · review first blocking prerequisite";text:modelData.readiness==="passed"?"Review readiness":"Ready to continue?";enabled:!root.busy;onClicked:root.reviewReadiness(modelData)}
    subtitle:(modelData.readiness==="passed"?"Ready for this lesson · ":modelData.role?({gate:"Blocking prerequisite",parallel:"Study alongside", "deep-descent":"Optional deeper study"})[modelData.role]+(modelData.reason?" · "+modelData.reason:"")+" · ":"")+root.assessmentLabel(modelData)
    enabled:!root.busy
    onClicked:root.openContext(modelData)
   }}
  }
 }
 NoesisButton {visible:!!root.context.next_lesson;text:"Next lesson · "+(root.context.next_lesson?.title||"");hint:"Ctrl+Alt+Up";enabled:!root.busy;onClicked:root.openContext(root.context.next_lesson)}
 Text {visible:!!root.context.truncated||(root.context.unavailable||[]).length>0;text:"Some related material is unavailable or beyond this preview. Open Connections or the outline for more context.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
}
