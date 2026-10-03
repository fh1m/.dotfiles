import QtQuick
import qs.components
import qs.config
import qs.services
Rectangle {
 id:root;property bool playing:Cava.live&&Audio.audible;implicitWidth:96;implicitHeight:30;radius:2;color:hover.containsMouse?Theme.alpha(Theme.signal,.12):"transparent";border.color: "#26282d"
 Row {anchors.centerIn:parent;spacing:7
 NrLabel {id:soundGlyph;centred:true;anchors.verticalCenter:parent.verticalCenter;pixelSize:16;color:Audio.muted?Theme.dim:Theme.signal;text:Audio.muted?"\uf6a9":Audio.volume<.33?"\uf026":Audio.volume<.67?"\uf027":"\uf028";scale:Cava.live&&Audio.audible?1.05:1;opacity:1
 SequentialAnimation on opacity {running:ShellState.ambientMotion&&root.playing&&soundGlyph.visible;loops:Animation.Infinite;NumberAnimation {from:1;to:.75;duration:240;easing.type:Easing.InOutSine}NumberAnimation {from:.75;to:1;duration:240;easing.type:Easing.InOutSine}}
 }
 NrLabel {centred:true;anchors.verticalCenter:parent.verticalCenter;text:Audio.muted?"Mute":Math.round(Audio.volume*100)+"%";font.capitalization:Font.MixedCase;tracked:false;pixelSize:12;color:Theme.text}
 }
 MouseArea {id:hover;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;acceptedButtons:Qt.LeftButton|Qt.RightButton;onClicked:e=>{if(e.button===Qt.RightButton&&Audio.sink?.audio)Audio.sink.audio.muted=!Audio.muted;else{ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown("sound");}}onWheel:e=>{if(Audio.sink?.audio)Audio.sink.audio.volume=Math.min(1.5,Math.max(0,Audio.volume+(e.angleDelta.y>0?.03:-.03)));e.accepted=true;}}
}
