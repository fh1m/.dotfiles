import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
 id:root
 property var workspace
 property var record:({})
 property bool protectedReference:false
 property bool busy:false
 property var frontier:({items:[]})
 property var learningContext:({})
 property var observedHistory:workspace?.history||[]
 onObservedHistoryChanged:{if(!initialized||protectedReference)return;let c=configuration();let saved=observedHistory.slice().reverse().find(e=>e.demo==="convolution-1d"&&e.event==="comparison"&&e.prediction===prediction.text&&JSON.stringify(e.observed?.configuration)===JSON.stringify(c));if(saved)result=saved;}
 property var lastAssessment:({})
 property string attemptId:""
 property string notes:""
 property string previousKey:""
 property bool initialized:false
 property bool sourceExpanded:false
 signal connectPrerequisite()
 property string stage:"play"
 property bool reasoningOnly:false
 property var result:({})
 property var implementation:({})
 property var buildResult:({})
 property int buildSerial:0
 property string actionToken:""
 property string actionOwner:""
 property string actionRecord:""
 property real savedScroll:0
 readonly property bool compact:width<1000*NoesisStyle.interfaceScale
 readonly property string draftKey:(record.vault||"")+":convolution:"+(record.id||"")
 readonly property bool valid:configuration()!==null&&prediction.text.trim().length>0
 readonly property var linkedImplementations:(frontier.items||[]).filter(row=>row.type==="experiment"&&row.id!==record.id)
 readonly property var actual:result.observed?.outputs||[]
 readonly property var step:result.observed?.steps?.[stepChoice.currentIndex]||({terms:[]})
 signal notesEdited(string value)
 signal preserveNote()
 signal openMember(var row)
 signal openNote()
 signal askQuestion(string details)
 signal startChanged(var config)
 signal evaluateAttempt()
 signal showHistory()
 signal reviewEvidence()
 signal investigateFailure()
 signal revealReference()
 spacing:NoesisStyle.md
 Shortcut {sequence:"Ctrl+Return";enabled:root.visible&&!root.workspace?.modalOpen&&!root.busy&&(root.attemptId?root.notes.trim()!=="":root.compact&&root.reasoningOnly?root.notes.trim()!==""&&!root.protectedReference:root.valid&&!root.protectedReference);onActivated:{if(root.attemptId)root.evaluateAttempt();else if(root.compact&&root.reasoningOnly)root.preserveNote();else primaryAction.clicked();}}
 function numbers(text){let parts=text.trim().split(/[\s,]+/);if(!text.trim()||parts.some(p=>!/^[-+]?(\d+(\.\d*)?|\.\d+)$/.test(p)))return null;let values=parts.map(Number);return values.every(n=>isFinite(n)&&Math.abs(n)<=100)?values:null;}
 function configuration(){let x=numbers(signalField.text),k=numbers(kernelField.text);return x&&k&&x.length>=3&&x.length<=8&&[1,3,5].includes(k.length)?{signal:x,kernel:k,boundary:boundary.currentIndex?"edge":"zero",stride:stride.currentIndex+1,convention:convention.currentIndex?"correlation":"convolution"}:null;}
 function describe(c){return c?"Signal ["+c.signal.join(", ")+"] · kernel ["+c.kernel.join(", ")+"] · "+(c.boundary==="edge"?"repeat edge samples":"zero padding")+" · stride "+c.stride+" · "+c.convention:"Choose a valid signal and odd kernel";}
 function invalidate(){if(!initialized)return;result=({});saveState();}
 function saveState(){if(!initialized||!record.id)return;saveTimer.restart();}
 function stash(){if(!initialized||!previousKey)return;let drafts=Object.assign({},NoesisController.drafts);drafts[previousKey]=JSON.stringify({signal:signalField.text,kernel:kernelField.text,boundary:boundary.currentIndex,stride:stride.currentIndex,convention:convention.currentIndex,prediction:prediction.text,stage:stage,implementation:implementation,scroll:playScroll.contentItem.contentY});NoesisController.drafts=drafts;NoesisController.savePreferences();}
 function loadState(){if(record.type!=="concept"||!(record.learning_demo==="convolution-1d"||/^convolution(\b|\s|·)/i.test(record.title||""))){stash();initialized=false;previousKey="";buildSerial=0;return;}if(previousKey===draftKey)return;stash();initialized=false;previousKey=draftKey;signalField.text="1, 2, 4, 2, 1";kernelField.text="0.25, 0.5, 0.25";boundary.currentIndex=0;stride.currentIndex=0;convention.currentIndex=0;prediction.text="";stage="play";result=({});implementation=({});buildResult=({});actionToken="";reasoningOnly=false;savedScroll=0;try{let s=JSON.parse(NoesisController.drafts[draftKey]||"null");if(s){signalField.text=s.signal;kernelField.text=s.kernel;boundary.currentIndex=s.boundary;stride.currentIndex=s.stride;convention.currentIndex=s.convention;prediction.text=s.prediction;stage=s.stage||"play";implementation=s.implementation||({});savedScroll=s.scroll||0;}}catch(error){}initialized=true;Qt.callLater(()=>{loadBuild();playScroll.contentItem.contentY=savedScroll;});}
 function request(action){if(!valid||busy||protectedReference||attemptId)return;stash();let id=action==="check"?implementation.id:record.id;if(!id)return;NoesisController.run(["convolution-"+action,id,"--configuration",JSON.stringify(configuration()),"--prediction",prediction.text]);actionToken=NoesisController.operationId;actionOwner=record.vault;actionRecord=record.id;}
 function loadBuild(){if(initialized&&implementation.id&&implementation.vault===NoesisController.activeVault&&workspace?.send)buildSerial=workspace.send("record",{record_id:implementation.id});}
 function gap(){let c=configuration();askQuestion("## What is confusing?\n\n\n## Predicted case\n"+prediction.text+"\n\n## Configuration\n"+describe(c)+"\n\n## Observed output\n"+(actual.length?JSON.stringify(actual):"Not revealed")+"\n\n## Next test\n\n");}
 function changed(){if(busy||attemptId)return;signalField.text="2, 0, -1, 3, 1";kernelField.text="2, 1, -1";boundary.currentIndex=1;stride.currentIndex=1;convention.currentIndex=0;prediction.text="";result=({});stage="play";stash();startChanged(configuration());}
 onRecordChanged:if(record.id)loadState()
 onStageChanged:saveState()
 onProtectedReferenceChanged:if(protectedReference){result=({});buildResult=({});}
 Timer {id:resultScroll;interval:50;onTriggered:if(calculation.visible)playScroll.contentItem.contentY=Math.max(0,calculation.mapToItem(playScroll.contentItem,0,0).y+playScroll.contentItem.contentY);}
 Timer {id:saveTimer;interval:400;onTriggered:root.stash()}
 Connections {target:NoesisController;function onFlushRequested(){saveTimer.stop();root.stash();}function onWindowOpenChanged(){if(NoesisController.windowOpen)Qt.callLater(root.loadBuild);}function onFinished(ok){if(root.actionToken&&root.actionToken===NoesisController.operationId){let same=root.actionOwner===root.record.vault&&root.actionRecord===root.record.id;root.actionToken="";if(ok&&same){let value=NoesisController.operationResult;if(value.type==="experiment"){root.implementation=Object.assign({},value,{vault:root.record.vault,vault_id:root.record.vault_id});root.stage="build";root.stash();root.loadBuild();}else if(value.target?.record_id===root.record.id){root.result=value;stepChoice.currentIndex=0;resultScroll.restart();}else if(value.target?.record_id===root.implementation.id){root.buildResult=value;root.loadBuild();}}}}}
 Connections {target:root.workspace;function onContextLoadingChanged(){if(!root.workspace.contextLoading&&!root.protectedReference)Qt.callLater(root.loadBuild);}function onSupportingResponse(response){if(response.request_id!==root.buildSerial||!root.buildSerial)return;root.buildSerial=0;if(response.error)return;let value=response.result;if(response.vault!==root.implementation.vault||value.owner?.vault_id!==root.implementation.vault_id||value.props?.id!==root.implementation.id)return;root.implementation=Object.assign({},value.props,{path:value.path,vault:response.vault,vault_id:value.owner.vault_id});if(!root.protectedReference&&value.overview?.latest_comparison)root.buildResult=value.overview.latest_comparison;}}
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:root.record.title||"Convolution";textFormat:Text.PlainText;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.title;wrapMode:Text.Wrap}
 Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Question → Play → Build → Test → Explain → Next · illustrative signals; no learning award";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
 Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
  NoesisButton {text:root.stage==="build"?"Return to the signal":"Build a minimal version";variant:"secondary";enabled:!root.protectedReference&&!root.busy;onClicked:root.stage=root.stage==="build"?"play":"build"}
  NoesisButton {text:root.attemptId?"Record the changed-case attempt":"Try a changed case without notes";enabled:!root.busy;onClicked:root.attemptId?root.evaluateAttempt():root.changed()}
  NoesisButton {text:"Keep a question";enabled:!root.busy;onClicked:root.gap()}
  NoesisButton {text:root.reasoningOnly?"Show the experiment":"Show reasoning";visible:root.compact;onClicked:root.reasoningOnly=!root.reasoningOnly}
 }
 SplitView {id:panes;Layout.fillWidth:true;Layout.fillHeight:true;orientation:Qt.Horizontal;handle:Item {implicitWidth:NoesisStyle.lg}
  ColumnLayout {visible:!root.compact||!root.reasoningOnly;SplitView.preferredWidth:panes.width*.62;SplitView.fillWidth:root.compact;SplitView.minimumWidth:0;spacing:NoesisStyle.sm
  ScrollView {id:playScroll;objectName:"convolution-play-scroll";Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true;padding:NoesisStyle.lg;background:Rectangle {color:NoesisStyle.canvas;radius:NoesisStyle.radius}
   ColumnLayout {width:playScroll.availableWidth;spacing:NoesisStyle.lg
    ColumnLayout {visible:!root.protectedReference;Layout.fillWidth:true;spacing:NoesisStyle.sm
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"How can one small rule detect a local pattern?";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Think of a small stencil sliding along measurements. The same weights blend neighbors at every position. A smoothing stencil softens a spike; a difference stencil responds to change. On an image, the neighbors are pixels.";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap}
    }
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:root.protectedReference;Layout.fillWidth:true;text:"Changed-case reconstruction · reference protected. Predict the outputs and explain the boundary before computing. Your work and any deliberate reference exposure remain in history.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap}
    ColumnLayout {visible:root.stage==="play";Layout.fillWidth:true;spacing:NoesisStyle.md
     RowLayout {Layout.fillWidth:true
      NoesisButton {text:"Smoothing stencil";visible:!root.protectedReference;onClicked:{kernelField.text="0.25, 0.5, 0.25";root.invalidate();}}
      NoesisButton {text:"Change detector";visible:!root.protectedReference;onClicked:{kernelField.text="1, 0, -1";root.invalidate();}}
     }
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Example signal · 3–8 samples";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
     NoesisField {id:signalField;objectName:"convolution-signal";Layout.fillWidth:true;enabled:!root.attemptId&&!root.busy;Accessible.name:"Signal samples";onTextChanged:root.invalidate()}
     Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm;Repeater {model:root.numbers(signalField.text)||[];delegate:Rectangle {required property real modelData;required property int index;width:Math.max(48,65*NoesisStyle.interfaceScale);height:72*NoesisStyle.interfaceScale;radius:NoesisStyle.radius;color:NoesisStyle.hover;Column {anchors.centerIn:parent;spacing:4;Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;anchors.horizontalCenter:parent.horizontalCenter;text:"x["+index+"]";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;anchors.horizontalCenter:parent.horizontalCenter;text:modelData;color:NoesisStyle.ink;font.family:NoesisStyle.codeFont;font.pixelSize:NoesisStyle.sectionHeading}}}}}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Kernel · 1, 3 or 5 weights";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
     NoesisField {id:kernelField;objectName:"convolution-kernel";Layout.fillWidth:true;enabled:!root.attemptId&&!root.busy;Accessible.name:"Kernel weights";onTextChanged:root.invalidate()}
     GridLayout {Layout.fillWidth:true;columns:playScroll.availableWidth>650*NoesisStyle.interfaceScale?3:1;columnSpacing:NoesisStyle.md;rowSpacing:NoesisStyle.sm
      ColumnLayout {Layout.fillWidth:true;Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Outside the signal";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}NoesisSelect {id:boundary;objectName:"convolution-boundary";Layout.fillWidth:true;model:["Zero padding","Repeat edge sample"];enabled:!root.attemptId&&!root.busy;Accessible.name:"Boundary condition";onActivated:root.invalidate()}}
      ColumnLayout {Layout.fillWidth:true;Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Kernel convention";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}NoesisSelect {id:convention;Layout.fillWidth:true;model:["Convolution · reverse","Correlation · as written"];enabled:!root.attemptId&&!root.busy;Accessible.name:"Kernel convention";onActivated:root.invalidate()}}
      ColumnLayout {Layout.fillWidth:true;Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Sample every";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}NoesisSelect {id:stride;Layout.fillWidth:true;model:["1 position","2 positions","3 positions"];enabled:!root.attemptId&&!root.busy;Accessible.name:"Output stride";onActivated:root.invalidate()}}
     }
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!root.protectedReference;Layout.fillWidth:true;text:"Centered odd kernel. Pad by half its width, take valid outputs, then subsample. Convolution reverses the weights; correlation keeps them as written. Use an asymmetric kernel to expose the difference.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
     ColumnLayout {id:calculation;visible:root.actual.length>0&&!root.protectedReference;Layout.fillWidth:true;spacing:NoesisStyle.md
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Computed output";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
      Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm;Repeater {model:root.actual;delegate:NoesisButton {required property real modelData;required property int index;text:"center "+(root.result.observed?.steps?.[index]?.center??index)+" → "+Number(modelData.toFixed(5));highlighted:stepChoice.currentIndex===index;onClicked:stepChoice.currentIndex=index}}}
      NoesisSelect {id:stepChoice;objectName:"convolution-step";Layout.fillWidth:true;model:(root.result.observed?.steps||[]).map(s=>"Calculate center "+s.center);Accessible.name:"Inspect an output calculation"}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Align at x["+(root.step.center??0)+"] · multiply each sample by its aligned weight";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
      Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm;Repeater {model:root.step.terms||[];delegate:Rectangle {required property var modelData;width:Math.max(125,140*NoesisStyle.interfaceScale);height:94*NoesisStyle.interfaceScale;radius:NoesisStyle.radius;color:NoesisStyle.hover;Column {anchors.fill:parent;anchors.margins:NoesisStyle.sm;spacing:NoesisStyle.sm;Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"x["+modelData.index+"]"+(modelData.outside?" · padded":"");color:modelData.outside?NoesisStyle.warning:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption}Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:modelData.sample+" × "+modelData.weight;color:NoesisStyle.ink;font.family:NoesisStyle.codeFont;font.pixelSize:NoesisStyle.sectionHeading}Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"= "+Number(modelData.product.toFixed(5));color:NoesisStyle.ink;font.family:NoesisStyle.codeFont;font.pixelSize:NoesisStyle.label}}}}}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:(root.step.terms||[]).map(t=>Number(t.product.toFixed(5))).join(" + ")+" = "+Number((root.step.output||0).toFixed(5));color:NoesisStyle.accent;font.family:NoesisStyle.codeFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap}
      Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Prediction: "+(root.result.prediction||"")+"\nThe calculation is saved separately. Does your explanation account for the disagreement?";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
     }
    }
    ColumnLayout {visible:root.stage==="build"&&!root.protectedReference;Layout.fillWidth:true;spacing:NoesisStyle.md
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Rebuild the stencil in code · supplied example";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Create a small local Git implementation and a linked Lab experiment. The supplied starter is labelled as Noesis-authored. Replace it from memory, commit your revision, then compare the exact same padding, reversal and stride.";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!root.valid&&!root.implementation.id;Layout.fillWidth:true;text:"Return to the signal and preserve a prediction first.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
     Text {visible:root.linkedImplementations.length>0;Layout.fillWidth:true;text:"Continue a connected implementation";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;renderType:Text.NativeRendering}
     Repeater {model:root.linkedImplementations;delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title;subtitle:"Existing Lab · preserve code and evidence";enabled:!root.busy;onClicked:{root.implementation=modelData;root.buildResult=({});root.stash();root.loadBuild();}}}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!!root.implementation.id;Layout.fillWidth:true;text:root.implementation.title||"Convolution experiment";color:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap}
     Flow {visible:!!root.implementation.id;Layout.fillWidth:true;spacing:NoesisStyle.sm
      NoesisButton {text:"Edit convolution.py ↗";enabled:!root.busy;onClicked:{root.stash();NoesisController.run(["open-project",root.implementation.id]);}}
      NoesisButton {text:"Inspect evidence in Lab";enabled:!root.busy;onClicked:root.openMember(root.implementation)}
     }
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!!root.implementation.id;Layout.fillWidth:true;text:"Run executes this local convolution.py explicitly, with a 15-second limit. It records the current commit, dirty status, file checksum and real NumPy output. No paper code is run automatically. Matching this case does not prove understanding.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!!root.buildResult.observed;Layout.fillWidth:true;text:root.buildResult.observed?("Executed result · "+(root.buildResult.observed.agrees?"matches this oracle":"disagrees with this oracle")+"\nImplementation: "+JSON.stringify(root.buildResult.observed.actual)+"\nNumPy: "+JSON.stringify(root.buildResult.observed.oracle)+"\nRevision: "+String(root.buildResult.observed.code_snapshot?.commit||"no commit").slice(0,12)+(root.buildResult.observed.code_snapshot?.dirty?" · uncommitted edits":" · clean")+"\nNumPy "+root.buildResult.observed.numpy_version+" · code checksum retained in Lab"):"";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;wrapMode:Text.Wrap}
    }
    ColumnLayout {visible:!root.protectedReference;Layout.fillWidth:true;spacing:NoesisStyle.sm
     NoesisButton {text:root.sourceExpanded?"Hide my concept notes":"Read my concept notes";onClicked:root.sourceExpanded=!root.sourceExpanded}
     NoesisDocument {visible:root.sourceExpanded;Layout.fillWidth:true;framed:false;blocks:root.workspace?.documentPreview?.blocks||[];onOpenOriginal:root.openNote()}
     NoesisButton {text:"Connect a deeper mechanism";enabled:!root.busy;onClicked:root.connectPrerequisite()}
    }
    NoesisLearningContext {visible:!root.protectedReference;Layout.fillWidth:true;context:Object.assign({},root.learningContext,{parents:[]});prerequisiteHeading:"Go beneath the mechanism";scopeLabel:"this experiment";busy:root.busy;onOpenContext:row=>root.openMember(row)}
    ColumnLayout {visible:!root.protectedReference;Layout.fillWidth:true;spacing:NoesisStyle.sm
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Build upward";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"The stencil extends to image neighborhoods for smoothing and edges. Neural networks learn weights across channels; common Conv2d layers use cross-correlation. Nonlinearities, learning, detection heads and losses are separate mechanisms. Convolution alone does not establish YOLO understanding.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
     Repeater {model:(root.frontier.items||[]).filter(r=>r.id!==root.record.id&&!["capability","experiment"].includes(r.type));delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.title;subtitle:modelData.type==="question"?"Unanswered mechanism · return through Back":"Connected context · exact owner";onClicked:root.openMember(modelData)}}
    }
   }
  }
  ColumnLayout {Layout.fillWidth:true;spacing:NoesisStyle.sm
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:"Predict the output · before computing";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;Layout.fillWidth:true;wrapMode:Text.Wrap}
     NoesisField {id:prediction;objectName:"convolution-prediction";Layout.fillWidth:true;placeholderText:"Your predicted values and boundary reasoning";Accessible.name:"Prediction before computing";onTextChanged:root.invalidate()}
     Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;visible:!root.configuration();Layout.fillWidth:true;text:"Use finite values within ±100, separated by commas. The signal needs 3–8 samples and the kernel 1, 3 or 5 weights.";color:NoesisStyle.error;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
     NoesisButton {id:primaryAction;hint:"Ctrl+Enter";Layout.fillWidth:true;objectName:"convolution-observe";text:root.stage==="build"?(root.implementation.id?"Run local comparison":"Create local implementation & Lab"):root.actual.length?"Save another prediction & compute":"Save prediction & reveal output";primary:true;enabled:root.valid&&!root.busy&&!root.protectedReference&&!root.attemptId;onClicked:root.request(root.stage==="build"?(root.implementation.id?"check":"prepare"):"observe")}
  }
  }
  ColumnLayout {visible:!root.compact||root.reasoningOnly;SplitView.fillWidth:true;SplitView.minimumWidth:0;spacing:NoesisStyle.sm
  ScrollView {id:reasoning;Layout.fillWidth:true;Layout.fillHeight:true;contentWidth:availableWidth;clip:true;padding:NoesisStyle.lg;background:Rectangle {color:NoesisStyle.canvas;radius:NoesisStyle.radius}
   ColumnLayout {width:reasoning.availableWidth;spacing:NoesisStyle.md
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Explain what changed";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading;wrapMode:Text.Wrap}
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:root.attemptId?"Protected attempt · predict, calculate by hand and explain. Save failure or uncertainty honestly before revealing the computed answer.":"Why did the edge differ? What did reversal change? Could you reconstruct the rule with the reference closed? Keep the mechanism, not just the matching numbers.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
    NoesisEditor {objectName:"convolution-reasoning";Layout.fillWidth:true;Layout.minimumHeight:Math.max(140,Math.min(250*NoesisStyle.interfaceScale,reasoning.availableHeight*.38));text:root.notes;placeholderText:"Your reasoning and revised explanation…";onTextChanged:if(text!==root.notes)root.notesEdited(text);Accessible.name:"Convolution reasoning"}
    Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
     NoesisButton {text:"Open rich derivation in Obsidian ↗";visible:!root.protectedReference;enabled:!root.busy;onClicked:{root.stash();root.openNote();}}
     NoesisButton {text:"Review attempts & evidence";enabled:!root.busy;onClicked:root.showHistory()}
     NoesisButton {visible:!root.attemptId&&!!root.lastAssessment.id;text:"Assess this evidence deliberately";enabled:!root.busy&&!root.protectedReference;onClicked:root.reviewEvidence()}
     NoesisButton {visible:!root.attemptId&&["failed","partial"].includes(root.lastAssessment.outcome);text:"Investigate the failed attempt";enabled:!root.busy;onClicked:root.investigateFailure()}
     NoesisButton {visible:root.attemptId;text:"Reveal reference deliberately";enabled:root.protectedReference&&!root.busy;onClicked:root.revealReference()}
    }
    Text {renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;Layout.fillWidth:true;text:"Execution, learner reasoning, assistance and an understanding claim are separate evidence. Nothing here awards mastery automatically.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap}
   }
  }
  NoesisButton {Layout.fillWidth:true;text:root.attemptId?"Record changed-case attempt":"Save reasoning as a study note";primary:!!root.attemptId||root.compact&&root.reasoningOnly;enabled:!root.busy&&root.notes.trim()!=="";onClicked:root.attemptId?root.evaluateAttempt():root.preserveNote()}
  }
 }
}
