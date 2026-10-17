import QtQuick
import "ZondoGames.js" as Games
import qs.config
import qs.services
Column {
 id:root;width:parent.width;spacing:10
 onVisibleChanged:if(!visible){playing=false;reactionStart=0;}
 property var board:["","","","","","","","",""]
 property string game:"rps"
 property double reactionStart:0
 property double reactionReady:0
 property int reactionTaps:0
 property int reactionMs:0
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
 Row {width:parent.width;spacing:8
  ControlTile {implicitWidth:(parent.width-16)/3;label:"Rock / paper / scissors";onActivated:root.game="rps"}
  ControlTile {implicitWidth:(parent.width-16)/3;label:"Tic-tac-toe";onActivated:root.game="ttt"}
  ControlTile {implicitWidth:(parent.width-16)/3;label:"Reaction · 30s";onActivated:{root.game="reaction";root.reactionStart=Date.now();root.reactionReady=Date.now()+600+Math.random()*1600;root.reactionTaps=0;root.reactionMs=0;}}
 }
 Row {visible:root.game==="rps";spacing:8
  Repeater {model:["rock","paper","scissors"];ControlTile {required property string modelData;implicitWidth:140;label:modelData;onActivated:{const other=["rock","paper","scissors"][Math.floor(Math.random()*3)];root.feedback="Zondo: "+other+". "+Games.rps(modelData,other)+". Best of absolutely no pressure.";Den.companion("activity","highfive");}}}
 }
 Column {visible:root.game==="ttt";spacing:8
  Grid {columns:3;spacing:6;Repeater {model:9;ControlTile {required property int index;implicitWidth:54;label:root.board[index]||"·";enabled:!root.board[index]&&!Games.winner(root.board);onActivated:{let b=root.board.slice();b[index]="X";root.board=Games.reply(b);const result=Games.winner(root.board);root.feedback=result?(result==="draw"?"A peaceful stalemate.":result+" wins. Rematch whenever you like."):"Your move, engineer.";}}}}
  ControlTile {implicitWidth:170;label:"Fresh board";onActivated:root.board=["","","","","","","","",""]}
 }
 ControlTile {visible:root.game==="reaction";width:parent.width;label:root.reactionStart===0?"Start another 30-second round":root.beat>=root.reactionReady?"NOW · tap":"Wait for the cue";selected:root.reactionStart>0&&root.reactionReady<=root.beat;onActivated:{const now=Date.now();if(root.reactionStart===0){root.reactionStart=now;root.reactionReady=now+600+Math.random()*1600;}else if(now>=root.reactionReady){root.reactionTaps++;root.reactionMs+=now-root.reactionReady;root.feedback=root.reactionTaps+" taps · average "+Math.round(root.reactionMs/root.reactionTaps)+" ms";root.reactionReady=now+600+Math.random()*1600;}else root.feedback="Early! No penalty. Watch for the cue.";}}
 Timer {interval:100;repeat:true;running:root.visible&&root.game==="reaction"&&root.reactionStart>0;onTriggered:{root.beat=Date.now();if(root.beat-root.reactionStart>=30000){root.reactionStart=0;root.feedback="Break complete. "+root.reactionTaps+" taps; no leaderboard required.";}}}
 ControlTile {width:parent.width;label:"Hide-and-seek across the Den";onActivated:{Den.companion("hide-seek","");root.feedback="Find Zondo on the available wallpaper, then tap him. Quiet/fullscreen rules still apply.";}}
 Text {width:parent.width;text:root.puzzles[root.puzzle].question;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paper}
 Row {spacing:8
  Repeater {model:root.puzzles[root.puzzle].answers
   ControlTile {required property string modelData;required property int index;implicitWidth:120;label:modelData;onActivated:root.feedback=(index===root.puzzles[root.puzzle].correct?"Yes. ":"Try the mechanism: ")+root.puzzles[root.puzzle].why}
  }
  ControlTile {implicitWidth:150;label:"Next puzzle";onActivated:{root.puzzle=(root.puzzle+1)%root.puzzles.length;root.feedback="Make a prediction before choosing."}}
 }
 Row {spacing:8
  ControlTile {label:root.playing?"Stop rhythm":"Silent rhythm";selected:root.playing;onActivated:{root.playing=!root.playing;root.pulses=0;root.beat=Date.now();}}
  ControlTile {label:"Tap on the pulse";enabled:root.playing;selected:root.pulses%2===1;onActivated:{const delta=Math.abs(Date.now()-root.beat);root.feedback=delta<140?"Together. Tiny drummer approves.":"No penalty. Aim for the next visual pulse.";Den.companion("activity","drums");}}
 }
 Timer {interval:700;repeat:true;running:root.playing;onTriggered:{root.beat=Date.now();root.pulses++;if(root.pulses>=24)root.playing=false;}}
 Text {width:parent.width;text:root.feedback;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paperMuted}
 Component.onDestruction:root.playing=false
}
