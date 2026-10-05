import QtQuick
import qs.components
import qs.config
import qs.services
BarSurface {
 id:root;property bool condensed:false;property bool playing:Cava.live&&Audio.audible;implicitWidth:condensed?48:96;implicitHeight:34;clip:true;grouped:condensed;selected:ShellState.dropdown==="sound";hovered:hover.containsMouse;pressed:hover.pressed
 Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
 Row {anchors.left:parent.left;anchors.leftMargin:8;anchors.verticalCenter:parent.verticalCenter;spacing:7
 NrLabel {id:soundGlyph;centred:true;anchors.verticalCenter:parent.verticalCenter;pixelSize:24;color:Audio.muted?Theme.dim:Theme.signalRed;text:Audio.muted?"\uf6a9":Audio.volume<.33?"\uf026":Audio.volume<.67?"\uf027":"\uf028";scale:Cava.live&&Audio.audible?1.05:1;opacity:1
 SequentialAnimation on opacity {running:ShellState.ambientMotion&&root.playing&&soundGlyph.visible;loops:Animation.Infinite;NumberAnimation {from:1;to:.75;duration:240;easing.type:Easing.InOutSine}NumberAnimation {from:.75;to:1;duration:240;easing.type:Easing.InOutSine}}
 }
 Rectangle { anchors.left:parent.left; anchors.leftMargin:8; anchors.bottom:parent.bottom; width:root.condensed&&!Audio.muted?31*Math.min(1,Audio.volume):0; height:2; color:Theme.signalRed }
 Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
 Text {text:"Audio";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
 Text {text:Audio.muted?"Muted":Math.round(Audio.volume*100)+"%";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
 }
 }
 MouseArea {id:hover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;acceptedButtons:Qt.LeftButton|Qt.RightButton;onClicked:e=>{if(e.button===Qt.RightButton&&Audio.sink?.audio)Audio.sink.audio.muted=!Audio.muted;else{ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown("sound");}}onWheel:e=>{if(Audio.sink?.audio)Audio.sink.audio.volume=Math.min(1.5,Math.max(0,Audio.volume+(e.angleDelta.y>0?.03:-.03)));e.accepted=true;}}
}
