import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
Column {
 id:root;spacing:12
 property string feedback:"Choose a visitor. You can pause, skip or close every card."
 property bool showFeedback:true
 property var settings:({})
 property var catalog:({guests:[],sources:{}})
 readonly property int excerptCount:(catalog.guests||[]).reduce((n,g)=>n+(g.quotes||[]).length,0)
 readonly property int storyCount:(catalog.guests||[]).reduce((n,g)=>n+(g.topics||[]).length,0)
 FileView {path:Quickshell.env("HOME")+"/.local/share/sensei-companion/guests/catalog.json";printErrors:false;onLoaded:{try{root.catalog=JSON.parse(text());}catch(e){}}}
 FileView {path:Quickshell.env("HOME")+"/.config/sensei-den/companion.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.settings=JSON.parse(text());}catch(e){}}}
 Text {width:parent.width;text:"GUESTS / A SMALL CONVERSATION";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.section;color:Theme.signalRed}
 Text {width:parent.width;text:"Real sourced excerpts, illustrated visits. Zondo listens sideways, then asks the awkward useful question. Visits wait for clear wallpaper and respect quiet mode.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted}
 Text {width:parent.width;text:root.excerptCount+" real excerpts · "+root.storyCount+" sourced stories · "+root.storyCount*9+" original workshop variations";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
 Flow {width:parent.width;spacing:8
  Repeater {model:root.catalog.guests||[]
   ControlTile {required property var modelData;implicitWidth:(root.width-8)/2;label:modelData.name;onActivated:{Den.companion("guest",modelData.id);root.feedback="Invitation sent. A visit needs clear wallpaper on Zondo's current display."}}
  }
 }
 Flow {width:parent.width;spacing:8
  Repeater {model:[{id:"mixed",name:"Mixed visits"},{id:"quotes",name:"Real excerpts"},{id:"stories",name:"Stories"},{id:"workshop",name:"Original workshop"}]
   ControlTile {required property var modelData;implicitWidth:(root.width-8)/2;label:modelData.name;selected:(root.settings.guestMode||"mixed")===modelData.id;onActivated:{Den.companion("guest-mode",modelData.id);root.feedback="Visit style: "+modelData.name+". Invite someone above."}}
  }
 }
 Row {spacing:8
  ControlTile {label:"Occasional visits on";selected:root.settings.guestsEnabled!==false;onActivated:{Den.companion("guests","on");root.feedback="Visitors welcome, at most once per chosen interval, when the desktop has room."}}
  ControlTile {label:"Visits off";selected:root.settings.guestsEnabled===false;onActivated:{Den.companion("guests","off");root.feedback="Guests off. Zondo keeps his ordinary desk routine."}}
 }
 Row {width:parent.width;spacing:8
  Repeater {model:[{minutes:5,label:"Often · 5 min"},{minutes:10,label:"Regular · 10 min"},{minutes:30,label:"Occasional · 30 min"}]
   ControlTile {required property var modelData;implicitWidth:(root.width-16)/3;label:modelData.label;selected:Number(root.settings.guestMinutes||10)===modelData.minutes;onActivated:{Den.companion("guest-frequency",String(modelData.minutes));root.feedback="Visits every "+modelData.minutes+" minutes when there's room. Quiet mode and fullscreen still take priority."}}
  }
 }
 Text {visible:root.showFeedback;width:parent.width;text:root.feedback;wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted}
}
