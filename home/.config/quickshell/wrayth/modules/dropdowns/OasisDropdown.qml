import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
ChamferPanel {
 id: panel
 implicitHeight: 490
 chamfer: Theme.radiusPanel
 scanlines: false
 fillColor: Theme.widgetGlass
 property string section:"Subjects"
 readonly property var rows: section==="Subjects"?Oasis.state.vaults:section==="Reviews"?Oasis.state.reviews:section==="Experiments"?Oasis.state.labs:section==="Sources"?Oasis.state.sources:Oasis.state.gates
 ColumnLayout {
  anchors.fill:parent;anchors.margins:18;spacing:12
  RowLayout {
   Layout.fillWidth:true;spacing:12
   Text {text:"Oasis";color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:22;font.bold:true}
   Text {text:panel.section==="Subjects"?"Learn anything · keep the evidence":Oasis.state.vault||"Select a subject";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;elide:Text.ElideRight;Layout.fillWidth:true}
   ActionButton {text:"Refresh";usable:!Oasis.working;onClicked:Oasis.refresh()}
  }
  Text {text:Oasis.error||"Sensei, build something your model can get wrong.";color:Oasis.error?Theme.widgetAccent:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;wrapMode:Text.Wrap;Layout.fillWidth:true}
  RowLayout {
   spacing:8
   Repeater {model:["Subjects","Frontier","Reviews","Experiments","Sources"];ActionButton {required property string modelData;text:modelData;glyph:modelData==="Subjects"?"\uf02d":modelData==="Frontier"?"\uf14e":modelData==="Reviews"?"\uf1da":modelData==="Experiments"?"\uf0c3":"\uf02e";accented:panel.section===modelData;onClicked:panel.section=modelData}}
   Item {Layout.fillWidth:true}
  }
  Rectangle {Layout.fillWidth:true;height:1;color:Theme.widgetBorder}
  RowLayout {
   Layout.fillWidth:true;Layout.fillHeight:true;spacing:20
   ColumnLayout {
    Layout.preferredWidth:360;Layout.fillHeight:true;spacing:10
    Text {text:panel.section==="Subjects"?"Capability before curriculum":"Current question";color:Theme.widgetAccent;font.family:Appearance.font.data;font.pixelSize:12;font.bold:true}
    Text {text:panel.section==="Subjects"?"What do you want to be able to do?":Oasis.state.question||"Choose a capability in Current Frontier.";color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:16;wrapMode:Text.Wrap;Layout.fillWidth:true}
    Text {text:panel.section==="Subjects"?"Your learning loop":"Next experiment";color:Theme.widgetAccent;font.family:Appearance.font.data;font.pixelSize:12;font.bold:true}
    Text {text:panel.section==="Subjects"?"Choose a subject. Predict, build, measure, correct, reconstruct. Gates stay small; curiosity stays welcome.":Oasis.state.next_experiment||"Write a prediction, choose a small test, keep the evidence.";color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:13;wrapMode:Text.Wrap;Layout.fillWidth:true}
    Text {visible:panel.section!=="Subjects";text:(Oasis.state.questions||[]).length+" open questions · "+(Oasis.state.reviews||[]).length+" due reviews";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12}
    Item {Layout.fillHeight:true}
    RowLayout {spacing:8;ActionButton {text:"Frontier";usable:!Oasis.working;onClicked:Oasis.run(["frontier"])}ActionButton {text:"Today";usable:!Oasis.working;onClicked:Oasis.run(["today"])}ActionButton {text:"Home";usable:!Oasis.working;onClicked:Oasis.run(["open"])}}
   }
   Rectangle {Layout.fillHeight:true;width:1;color:Theme.widgetBorder}
   ColumnLayout {
    Layout.fillWidth:true;Layout.fillHeight:true;spacing:8
    Text {text:panel.section==="Frontier"?"Active gates":panel.section==="Subjects"?"Independent vaults":panel.section;color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:15;font.bold:true}
    ListView {
     Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:8;model:panel.rows||[]
     delegate:Rectangle {
      required property var modelData
      width:ListView.view.width;height:58;radius:Theme.radiusPanel;color:pointer.containsMouse?Theme.widgetRaised:Theme.widgetSurface
      Column {anchors.fill:parent;anchors.margins:10;spacing:4
       Text {width:parent.width;text:modelData.name;color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:13;elide:Text.ElideRight}
       Text {text:panel.section==="Subjects"?(modelData.active?"Selected · ":"")+(modelData.managed?"First-principles structure":"Existing vault · preserved"):(modelData.status||"")+(modelData.review?" · review "+modelData.review:"");color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:11}
      }
      MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;enabled:!Oasis.working;onClicked:{if(panel.section==="Subjects"){Oasis.choose(modelData.path);panel.section="Frontier";}else Oasis.note(modelData.path);}}
     }
     Text {anchors.centerIn:parent;visible:!panel.rows?.length;text:"No entries here yet. Evidence first.";color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12}
    }
    DeskTextField {id:capture;Layout.fillWidth:true;placeholderText:panel.section==="Subjects"?"New subject (any field)…":"Capture a question or observation…";onAccepted:{if(text.trim()&&!Oasis.working){Oasis.run(panel.section==="Subjects"?["init",text]:["capture",text]);text="";}}}
   }
  }
 }
}
