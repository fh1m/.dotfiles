import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;title:"ScreenPad / one useful context";implicitWidth:752
 property real maximumBodyHeight:380
 property bool pendingRefresh:false
 property var snapshot:({cards:[],projects:[]});property string error:"";property string operation:"snapshot"
 function refresh(){if(worker.running){pendingRefresh=true;return;}operation="snapshot";worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-instrument",ShellState.instrumentMode].concat(ShellState.instrumentProject?["--project",ShellState.instrumentProject]:[]);worker.running=true;}
 function act(name){if(name==="preflight"&&ShellState.instrumentProject){if(worker.running)return;operation="preflight";worker.command=[Quickshell.env("HOME")+"/.local/bin/sensei-actions","run","project.preflight","--params",JSON.stringify({project:ShellState.instrumentProject})];worker.running=true;return;}if(name==="den"){ShellState.systemPage=5;ShellState.openDropdown("system");}else if(name==="calendar")ShellState.openDropdown("calendar");else if(name==="terminal")Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-terminal"]);else {ShellState.engineeringSelectedAction=name==="preflight"?"project.preflight":name==="capture"?"evidence.capture":"";ShellState.openDropdown("engineering");}}
 Component.onCompleted:refresh()
 Connections {target:ShellState;function onInstrumentModeChanged(){root.refresh();}function onInstrumentProjectChanged(){root.refresh();}}
 ScrollView {width:parent.width;height:Math.min(contextBody.implicitHeight,root.maximumBodyHeight);contentWidth:availableWidth;clip:true
 Column {id:contextBody;width:parent.width;spacing:12
 Row {width:parent.width;spacing:8
  Repeater {model:["normal","simulation","coding","hardware","drawing"]
   ControlTile {required property string modelData;implicitWidth:(parent.width-32)/5;label:modelData.charAt(0).toUpperCase()+modelData.slice(1);selected:ShellState.instrumentMode===modelData;onActivated:ShellState.instrumentMode=modelData}
  }
 }
 DeskComboBox {visible:ShellState.instrumentMode!=="drawing";width:parent.width;model:[{id:"",title:"Choose a registered project"}].concat(root.snapshot.projects);textRole:"title";currentIndex:Math.max(0,model.findIndex(p=>p.id===ShellState.instrumentProject));onActivated:ShellState.instrumentProject=model[currentIndex].id}
 Loader {width:parent.width;active:ShellState.instrumentMode==="drawing";visible:active;sourceComponent:Component {DrawingControls {width:parent.width}}}
 Grid {visible:ShellState.instrumentMode!=="drawing";width:parent.width;columns:2;spacing:8
  Repeater {model:root.snapshot.cards
   Rectangle {required property var modelData;width:(parent.width-8)/2;height:94;color:Theme.surfaceOne;border.color:Theme.rule;radius:5
    Column {anchors.fill:parent;anchors.margins:12;spacing:6
     Text {text:modelData.title;font.family:Appearance.font.ui;font.pixelSize:12;font.letterSpacing:1;color:Theme.widgetAccent}
     Text {width:parent.width;text:modelData.value;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:15;color:Theme.widgetText}
     Text {width:parent.width;text:modelData.detail;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
    }
    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.act(parent.modelData.action)}
   }
  }
 }
 Row {spacing:8;ControlTile {implicitWidth:120;label:"Refresh";enabled:!worker.running;onActivated:root.refresh()}ControlTile {implicitWidth:120;label:"Return";onActivated:ShellState.releaseInstrument()}}
 Text {width:parent.width;text:root.error||root.snapshot.note||"";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
 }
 }
 Process {id:worker;onExited:{if(root.pendingRefresh){root.pendingRefresh=false;Qt.callLater(root.refresh);}}stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);if(d.error)root.error=d.error;else if(root.operation==="preflight"){root.error=(d.ok?"Preflight passed: ":"Preflight needs attention: ")+(d.checks||[]).map(c=>c.name+" · "+c.detail).join("; ");}else if(d.mode===ShellState.instrumentMode){root.snapshot=d;root.error="";}else root.pendingRefresh=true;}catch(e){root.error="Context unavailable; your project is unchanged.";}}}}
 Timer {interval:15000;repeat:true;running:root.visible&&ShellState.instrumentPinned;onTriggered:root.refresh()}
}
