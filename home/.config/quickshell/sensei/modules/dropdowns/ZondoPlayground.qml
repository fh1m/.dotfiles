import QtQuick
import qs.config
import qs.services
Column {
 id:root;width:parent.width;spacing:10
 onVisibleChanged:if(!visible)playing=false
 property int puzzle:0
 property string feedback:"No scores, no streaks. Just a small detour."
 property double beat:0
 property int pulses:0
 property bool playing:false
 readonly property var puzzles:[{question:"A=1, B=0. What is A XOR B?",answers:["0","1"],correct:1,why:"XOR is true when exactly one input is true."},{question:"Rotate (1,0) by +90° in a right-handed xy plane. Result?",answers:["(0,1)","(0,-1)","(1,1)"],correct:0,why:"Counterclockwise rotation maps positive x to positive y."}]
 Text {width:parent.width;text:"ZONDO / OFF DUTY";font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.signalRed}
 Row {spacing:8
  ControlTile {label:"High five";onActivated:{Den.companion("activity","highfive");root.feedback="Tiny palm. Very enthusiastic."}}
  ControlTile {label:"Make a boat";onActivated:{Den.companion("activity","paperboat");root.feedback="A research vessel with a wonderfully small budget."}}
  ControlTile {label:"Tea break";onActivated:{Den.companion("activity","tea");root.feedback="The tea is imaginary. The permission to pause is not."}}
 }
 Text {width:parent.width;text:root.puzzles[root.puzzle].question;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paper}
 Row {spacing:8
  Repeater {model:root.puzzles[root.puzzle].answers
   ControlTile {required property string modelData;required property int index;implicitWidth:120;label:modelData;onActivated:root.feedback=(index===root.puzzles[root.puzzle].correct?"Yes. ":"Try the mechanism: ")+root.puzzles[root.puzzle].why}
  }
  ControlTile {implicitWidth:112;label:"Next puzzle";onActivated:{root.puzzle=(root.puzzle+1)%root.puzzles.length;root.feedback="Make a prediction before choosing."}}
 }
 Row {spacing:8
  ControlTile {label:root.playing?"Stop rhythm":"Start silent rhythm";selected:root.playing;onActivated:{root.playing=!root.playing;root.pulses=0;root.beat=Date.now();}}
  ControlTile {label:"Tap on the pulse";enabled:root.playing;selected:root.pulses%2===1;onActivated:{const delta=Math.abs(Date.now()-root.beat);root.feedback=delta<140?"Together. Tiny drummer approves.":"No penalty. Aim for the next visual pulse.";Den.companion("activity","drums");}}
 }
 Timer {interval:700;repeat:true;running:root.playing;onTriggered:{root.beat=Date.now();root.pulses++;if(root.pulses>=24)root.playing=false;}}
 Text {width:parent.width;text:root.feedback;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
 Component.onDestruction:root.playing=false
}
