import QtQuick
import qs.components
import qs.config
import qs.services
BarSurface {
 id:root;property bool condensed:false;property bool playing:Cava.live&&Audio.audible;implicitWidth:condensed?44:96;implicitHeight:34;clip:true;grouped:condensed;selected:ShellState.dropdown==="sound";hovered:hover.containsMouse;pressed:hover.pressed
 Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
 Row {id:readout;anchors.left:parent.left;anchors.leftMargin:10;anchors.verticalCenter:parent.verticalCenter;spacing:7
 InstrumentIcon {id:soundGlyph;y:(readout.height-height)/2;kind:"audio";level:Audio.volume;muted:Audio.muted;ink:Audio.muted?Theme.alpha(Theme.signalRed,.55):Theme.signalRed;scale:Cava.live&&Audio.audible?1.05:1;opacity:1
 SequentialAnimation on opacity {running:ShellState.ambientMotion&&root.playing&&soundGlyph.visible;loops:Animation.Infinite;NumberAnimation {from:1;to:.75;duration:240;easing.type:Easing.InOutSine}NumberAnimation {from:.75;to:1;duration:240;easing.type:Easing.InOutSine}}
 }
 Column {visible:!root.condensed;y:(readout.height-height)/2;spacing:-1
 Text {text:"Audio";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
 Text {text:Audio.muted?"Muted":Math.round(Audio.volume*100)+"%";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
 }
 }
 MouseArea {id:hover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;acceptedButtons:Qt.LeftButton|Qt.RightButton;onClicked:e=>{if(e.button===Qt.RightButton&&Audio.sink?.audio)Audio.sink.audio.muted=!Audio.muted;else{ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown("sound");}}onWheel:e=>{if(Audio.sink?.audio)Audio.sink.audio.volume=Math.min(1.5,Math.max(0,Audio.volume+(e.angleDelta.y>0?.03:-.03)));e.accepted=true;}}
}
