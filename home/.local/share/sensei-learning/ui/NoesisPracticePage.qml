import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
 id:root
 color:NoesisStyle.canvas;radius:NoesisStyle.radius
 property string attemptId:""
 function showStatement(){thinking=false;}
 function showReasoning(){thinking=true;evidence.forceActiveFocus();}
 property string statement:""
 property var statementPreview:({blocks:[]})
 property bool originalProblemAvailable:false
 signal openOriginalProblem()
 property bool referenceHidden:true
 property bool compact:false
 property bool externalStatement:false
 readonly property bool contextOpen:problemContext.opened
 property bool thinking:false
 onAttemptIdChanged:if(attemptId)thinking=true
 property bool busy:false
 property string contextTitle:""
 property string settingsLabel:""
 property alias editor:evidence
 readonly property real statementHeight:statementScroll.height
 readonly property real reasoningViewportHeight:reasoningScroll.height
 readonly property real minimumWorkingHeight:200+(attemptLabel.visible?attemptLabel.implicitHeight:0)+controls.implicitHeight+(contextHeading.visible?contextHeading.implicitHeight:0)+(surfaceSwitch.visible?surfaceSwitch.implicitHeight:0)+reasonHeading.implicitHeight+editorGuide.implicitHeight+NoesisStyle.md*5+NoesisStyle.lg*2
 signal draftChanged()
 signal startAttempt()
 signal saveAttempt()
 signal revealReference()
 signal planCheck()
 signal showActions()
 signal configureAttempt()
 ColumnLayout {anchors.fill:parent;anchors.margins:NoesisStyle.lg;spacing:NoesisStyle.md
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;id:contextHeading;visible:!!root.contextTitle&&!root.compact;Layout.fillWidth:true;textFormat:Text.PlainText;text:root.contextTitle;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.title;font.bold:true}
      Label {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;id:attemptLabel;visible:!root.compact;text:root.attemptId?root.referenceHidden?"Independent attempt in progress · reference protected":"Attempt in progress · reference revealed; exposure remains recorded":"Predict first. Preserve the reasoning before checking it.";color:NoesisStyle.secondary;wrapMode:Text.Wrap;Layout.fillWidth:true;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
      RowLayout {id:surfaceSwitch;Layout.fillWidth:true;spacing:NoesisStyle.sm;visible:root.compact||root.externalStatement
       NoesisSelect {Layout.fillWidth:true;Layout.minimumWidth:(root.width-2*NoesisStyle.lg-NoesisStyle.sm)*.52;model:["Problem statement","Your reasoning"];currentIndex:root.thinking?1:0;Accessible.name:"Thinking surface";onActivated:root.thinking=currentIndex===1}
       NoesisButton {text:"Problem & attempt";Layout.fillWidth:true;Layout.minimumWidth:0;Layout.maximumWidth:(root.width-2*NoesisStyle.lg-NoesisStyle.sm)*.4;variant:"secondary";onClicked:problemContext.open();Accessible.name:"Problem title and attempt context"}
      }
      SplitView {id:practiceSplit;property real storedRatio:Math.min(.65,Math.max(.25,NoesisController.layouts.Practice?.statement_ratio||.42));onResizingChanged:if(!resizing){let ratio=orientation===Qt.Horizontal?statementPane.width/width:statementPane.height/height;NoesisController.layouts=Object.assign({},NoesisController.layouts,{Practice:{statement_ratio:Math.min(.65,Math.max(.25,ratio))}});NoesisController.savePreferences();}Layout.fillWidth:true;Layout.fillHeight:true;orientation:width>=900*Math.max(NoesisStyle.interfaceScale,NoesisStyle.readingScale)?Qt.Horizontal:Qt.Vertical
       handle:Rectangle {implicitWidth:24;implicitHeight:24;color:NoesisStyle.canvas;Rectangle {anchors.centerIn:parent;width:2;height:parent.height;color:parent.SplitHandle.hovered?NoesisStyle.rule:"transparent"}}
       ColumnLayout {id:statementPane;visible:!!root.statement&&(!(root.compact||root.externalStatement)||!root.thinking);SplitView.fillWidth:root.compact||root.externalStatement;SplitView.fillHeight:root.compact||root.externalStatement;SplitView.preferredWidth:practiceSplit.width*practiceSplit.storedRatio;SplitView.preferredHeight:practiceSplit.height*practiceSplit.storedRatio;SplitView.minimumHeight:80;SplitView.minimumWidth:Math.min(280,practiceSplit.width);spacing:NoesisStyle.sm
        Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;textFormat:Text.PlainText;text:"Problem statement";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
        ScrollView {id:statementScroll;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius}
         NoesisDocument {id:statementText;width:statementScroll.availableWidth;blocks:root.statementPreview.blocks||[];originalAvailable:root.originalProblemAvailable||!root.referenceHidden;originalAction:root.originalProblemAvailable?"Open original problem ↗":"View in complete note ↗";onOpenOriginal:if(root.originalProblemAvailable)root.openOriginalProblem();else if(!root.referenceHidden)NoesisController.note(NoesisController.currentContext.path)}
        }
       }
       ColumnLayout {visible:!(root.compact||root.externalStatement)||root.thinking;SplitView.fillWidth:true;SplitView.fillHeight:true;SplitView.minimumHeight:120;SplitView.minimumWidth:Math.min(320,practiceSplit.width);spacing:NoesisStyle.sm
        Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;id:reasonHeading;textFormat:Text.PlainText;text:"Your reasoning";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap;Layout.fillWidth:true}
        ScrollView {id:reasoningScroll;Layout.fillWidth:true;Layout.fillHeight:true;clip:true
         NoesisEditor {id:evidence;width:reasoningScroll.availableWidth;placeholderText:"Prediction, reasoning, derivation or observed discrepancy…";onTextChanged:root.draftChanged()}
        }
        Text {id:editorGuide;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:root.attemptId?"Ctrl+Tab leaves the editor · Ctrl+Enter records the attempt":"Ctrl+Tab leaves the editor · Ctrl+Enter starts an independent attempt";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}
       }
      }
      NoesisButton {id:settings;visible:false;text:root.settingsLabel;Layout.fillWidth:true;textAlignment:Text.AlignLeft;onClicked:root.configureAttempt();Accessible.name:"Attempt settings"}
      Flow {id:controls;Layout.fillWidth:true;spacing:NoesisStyle.sm
       NoesisButton {text:"Start independent attempt";hint:"Ctrl+Enter";primary:true;visible:!root.attemptId;enabled:!root.busy;onClicked:root.startAttempt()}
       NoesisButton {text:"Record attempt outcome";hint:"Ctrl+Enter";primary:true;visible:!!root.attemptId;enabled:!root.busy&&evidence.text.trim()!=="";onClicked:root.saveAttempt()}
       NoesisButton {visible:!root.compact;text:root.referenceHidden?"Reveal reference":"Hide reference";enabled:!root.busy;onClicked:root.revealReference()}
       NoesisButton {text:"Plan a check";visible:!root.compact;onClicked:root.planCheck()}
       NoesisButton {text:"Outcome & assistance";visible:!!root.attemptId&&!root.compact;onClicked:root.configureAttempt()}
       NoesisButton {text:root.compact?"Attempt options":"History & next steps";onClicked:root.showActions();hint:"Ctrl+."}
      }
     }
 NoesisDialog {id:problemContext;parent:Overlay.overlay;anchors.centerIn:parent;width:Math.min(560,(parent?.width||600)-32);height:Math.min(480,(parent?.height||600)-32);title:"Problem & attempt";modal:true
  contentItem:ScrollView {clip:true;contentWidth:availableWidth;ColumnLayout {width:parent.availableWidth;spacing:NoesisStyle.lg
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;textFormat:Text.PlainText;text:root.contextTitle;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.title}
   Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;textFormat:Text.PlainText;text:root.attemptId?(root.referenceHidden?"Attempt in progress · reference protected":"Attempt in progress · reference revealed"):"No active attempt";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisButton {text:root.referenceHidden?"Reveal reference":"Hide reference";enabled:!root.busy;onClicked:{problemContext.close();root.revealReference();}}
  }}
  footer:NoesisButton {text:"Return to thinking";onClicked:problemContext.close()}
 }
}
