import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
import "../../services" as LearningBridge
BarSurface {
 id:root
 property bool condensed:false
 clip:true
 property int page: -1
 property string target:"monitor"
 property string label:"Monitor"
 property string glyph:"\uf080"
 property string detail:target==="monitor"?"Telemetry":""
 implicitWidth:(condensed?44:target==="monitor"?112:124)+(target==="oasis"?24:0);implicitHeight:34
 Behavior on implicitWidth { NumberAnimation { duration: Theme.motionTravel; easing.type: Easing.OutCubic } }
 selectionRuleWidth:target==="oasis"&&!condensed?labelText.implicitWidth:24
 selectionRuleCenterX:target==="oasis"?(condensed?22:42+labelText.implicitWidth/2):width/2
 grouped:condensed
 selected:target==="oasis"?LearningBridge.NoesisBridge.windowOpen:ShellState.dropdown===target;hovered:pointer.containsMouse;pressed:pointer.pressed
 Row {anchors.left:parent.left;anchors.leftMargin:10;anchors.verticalCenter:parent.verticalCenter;spacing:8
     InstrumentIcon {visible:root.target==="monitor";kind:"monitor";anchors.verticalCenter:parent.verticalCenter}
     BarIcon {visible:root.target!=="monitor";glyph:root.glyph;anchors.verticalCenter:parent.verticalCenter;inkSize:18;ink:root.target==="phone"&&!PhoneBridge.ready?Theme.alpha(Theme.signalRed,.55):Theme.signalRed}
     Column {visible:!root.condensed;width:Math.max(1,root.width-42-(root.target==="oasis"?28:6));anchors.verticalCenter:parent.verticalCenter;spacing:1
         Text { textFormat: Text.PlainText;id:labelText;width:parent.width;elide:Text.ElideRight;text:root.label;font.family:Appearance.font.barUi;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.text}
         Text { textFormat: Text.PlainText;width:parent.width;elide:Text.ElideRight;text:root.detail;visible:root.detail!=="";font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.widgetMuted}
     }
 }
 MouseArea {id:pointer;anchors.fill:parent;anchors.rightMargin:root.target==="oasis"?24:0;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:{if(root.target==="oasis"){LearningBridge.NoesisBridge.open();return;}if(root.page>=0)ShellState.monitorPage=root.page;ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.toggleDropdownOn(root.target,root.QsWindow.window?.screen?.name??"");}}
 ToolButton {visible:root.target==="oasis";anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;width:24;height:34;Accessible.name:"Noesis start and capture";onClicked:learningMenu.visible=!learningMenu.visible;contentItem:Text { textFormat: Text.PlainText;text:"⌄";color:Theme.text;font.family:Appearance.font.barUi;font.pixelSize:14;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}background:Rectangle {color:parent.hovered?Theme.alpha(Theme.text,.08):"transparent";radius:4}
  TextMetrics {id:menuLabelMetrics;text:"Start learning";font.family:Appearance.font.barUi;font.pixelSize:14}
  PopupWindow {id:learningMenu;anchor.item:root;anchor.rect.y:root.height;grabFocus:true;visible:false;implicitWidth:Math.max(180,menuLabelMetrics.advanceWidth+32);implicitHeight:88;color:Theme.surfaceOne
   onVisibleChanged:if(visible)Qt.callLater(()=>startAction.forceActiveFocus())
   Column {objectName:"noesis-launch-actions";anchors.fill:parent;anchors.margins:4
    ToolButton {id:startAction;text:"Start learning";width:parent.width;height:40;Accessible.name:text;KeyNavigation.down:captureAction;KeyNavigation.tab:captureAction;onClicked:{learningMenu.visible=false;LearningBridge.NoesisBridge.startLearning();}contentItem:Text { textFormat: Text.PlainText;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:startAction.text;font.underline:startAction.activeFocus;color:Theme.text;font.family:Appearance.font.barUi;font.pixelSize:14;verticalAlignment:Text.AlignVCenter}background:Rectangle {color:startAction.hovered||startAction.activeFocus?Theme.surfaceTwo:"transparent"}}
    ToolButton {id:captureAction;text:"Quick capture";width:parent.width;height:40;Accessible.name:text;KeyNavigation.up:startAction;KeyNavigation.tab:startAction;onClicked:{learningMenu.visible=false;LearningBridge.NoesisBridge.capture();}contentItem:Text { textFormat: Text.PlainText;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;text:captureAction.text;font.underline:captureAction.activeFocus;color:Theme.text;font.family:Appearance.font.barUi;font.pixelSize:14;verticalAlignment:Text.AlignVCenter}background:Rectangle {color:captureAction.hovered||captureAction.activeFocus?Theme.surfaceTwo:"transparent"}}
   }
   Shortcut {sequence:"Escape";enabled:learningMenu.visible;onActivated:learningMenu.visible=false}
  }
 }
}
