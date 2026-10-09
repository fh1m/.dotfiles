import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property string attemptId:""
 property string statement:""
 property bool referenceHidden:true
 property bool compact:false
 property bool busy:false
 property string contextTitle:""
 property string settingsLabel:""
 property alias editor:evidence
 readonly property real statementHeight:statementScroll.height
 readonly property real reasoningViewportHeight:reasoningScroll.height
 readonly property real minimumWorkingHeight:200+attemptLabel.implicitHeight+controls.implicitHeight+(settings.visible?settings.implicitHeight:0)+(contextHeading.visible?contextHeading.implicitHeight:0)+NoesisStyle.md*4
 signal draftChanged()
 signal startAttempt()
 signal saveAttempt()
 signal revealReference()
 signal planCheck()
 signal showActions()
 signal configureAttempt()
 spacing:NoesisStyle.md
      Text {id:contextHeading;visible:root.compact&&!!root.contextTitle;Layout.fillWidth:true;textFormat:Text.PlainText;text:root.contextTitle;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
      Label {id:attemptLabel;text:root.attemptId?"Attempt "+root.attemptId.slice(0,8)+" · reference exposure stays in its history.":"Predict first. Preserve the reasoning before checking it.";color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
      SplitView {id:practiceSplit;property real storedRatio:Math.min(.65,Math.max(.25,NoesisController.layouts.Practice?.statement_ratio||.42));onResizingChanged:if(!resizing){let ratio=orientation===Qt.Horizontal?statementPane.width/width:statementPane.height/height;NoesisController.layouts=Object.assign({},NoesisController.layouts,{Practice:{statement_ratio:Math.min(.65,Math.max(.25,ratio))}});NoesisController.savePreferences();}Layout.fillWidth:true;Layout.fillHeight:true;orientation:width>=900*Math.max(NoesisStyle.interfaceScale,NoesisStyle.readingScale)?Qt.Horizontal:Qt.Vertical
       handle:Rectangle {implicitWidth:8;implicitHeight:8;color:SplitHandle.hovered?NoesisStyle.rule:NoesisStyle.surface}
       ColumnLayout {id:statementPane;visible:!!root.statement;SplitView.preferredWidth:practiceSplit.width*practiceSplit.storedRatio;SplitView.preferredHeight:practiceSplit.height*practiceSplit.storedRatio;SplitView.minimumHeight:80;SplitView.minimumWidth:Math.min(280,practiceSplit.width);spacing:NoesisStyle.sm
        Text {textFormat:Text.PlainText;text:"Statement";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
        ScrollView {id:statementScroll;Layout.fillWidth:true;Layout.fillHeight:true;clip:true
         TextEdit {id:statementText;width:statementScroll.availableWidth;text:root.statement||"";readOnly:true;selectByMouse:true;wrapMode:TextEdit.Wrap;textFormat:TextEdit.PlainText;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;Accessible.name:"Problem statement"}
        }
       }
       ColumnLayout {SplitView.fillWidth:true;SplitView.fillHeight:true;SplitView.minimumHeight:120;SplitView.minimumWidth:Math.min(320,practiceSplit.width);spacing:NoesisStyle.sm
        Text {textFormat:Text.PlainText;text:"Reasoning · Ctrl+Tab leaves the editor";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;wrapMode:Text.Wrap;Layout.fillWidth:true}
        ScrollView {id:reasoningScroll;Layout.fillWidth:true;Layout.fillHeight:true;clip:true
         NoesisEditor {id:evidence;width:reasoningScroll.availableWidth;placeholderText:"Prediction, reasoning, derivation or observed discrepancy…";onTextChanged:root.draftChanged()}
        }
       }
      }
      NoesisButton {id:settings;visible:!root.compact;text:root.settingsLabel;Layout.fillWidth:true;textAlignment:Text.AlignLeft;onClicked:root.configureAttempt();Accessible.name:"Attempt settings"}
      Flow {id:controls;Layout.fillWidth:true;spacing:NoesisStyle.sm
       NoesisButton {text:"Start attempt";hint:"Ctrl+Enter";primary:true;visible:!root.attemptId;enabled:!root.busy;onClicked:root.startAttempt()}
       NoesisButton {text:"Save outcome";hint:"Ctrl+Enter";primary:true;visible:!!root.attemptId;enabled:!root.busy&&evidence.text.trim()!=="";onClicked:root.saveAttempt()}
       NoesisButton {visible:!root.compact;text:root.referenceHidden?"Reveal reference":"Hide reference";enabled:!root.busy;onClicked:root.revealReference()}
       NoesisButton {text:"Plan a check";visible:!root.compact;onClicked:root.planCheck()}
       NoesisButton {text:"Attempt settings";visible:root.compact;onClicked:root.configureAttempt()}
       NoesisButton {text:"Actions";visible:root.compact;onClicked:root.showActions();hint:"Ctrl+."}
      }
     }
