import QtQuick
import qs.components
import qs.config
import qs.services
Item {
 id:root
 property bool condensed:false
 implicitWidth:condensed?48:112;implicitHeight:34
 Behavior on implicitWidth {NumberAnimation {duration:Theme.motionTravel;easing.type:Easing.OutCubic}}
 BarSurface {anchors.fill:parent;grouped:root.condensed;selected:ShellState.dropdown==="power";hovered:pointer.containsMouse;pressed:pointer.pressed}
 Row {anchors.centerIn:parent;spacing:7
  Item {width:24;height:30
  InstrumentIcon {id:mark;anchors.horizontalCenter:parent.horizontalCenter;y:root.condensed?-2:3;kind:Power.onBattery?"battery":"ac";level:Power.charge/100;ink:Power.charge<15&&Power.onBattery?Theme.paper:Theme.signalRed}
  Text {visible:root.condensed;anchors.horizontalCenter:parent.horizontalCenter;y:22;text:Power.present?Math.round(Power.charge)+"%":"AC";font.family:Appearance.font.barUi;font.pixelSize:8;color:Theme.paperMuted}
  }
  Column {visible:!root.condensed;anchors.verticalCenter:parent.verticalCenter;spacing:-1
   Text {text:"Battery";font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
   Text {text:Math.round(Power.charge)+"% · "+(Power.onBattery?"Battery":"AC");font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.paperMuted}
  }
 }
 SequentialAnimation {running:!Power.onBattery&&root.visible&&ShellState.ambientMotion;loops:Animation.Infinite;onRunningChanged:if(!running)mark.opacity=1
  NumberAnimation {target:mark;property:"opacity";from:1;to:.55;duration:1300}
  NumberAnimation {target:mark;property:"opacity";from:.55;to:1;duration:1300}
 }
 function publish():void {ShellState.publishAnchor("power",root.mapToItem(null,0,0).x);}
 onXChanged:publish()
 Component.onCompleted:Qt.callLater(publish)
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:{root.publish();ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdown("power");}}
}
