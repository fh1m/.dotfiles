import QtQuick
import QtQuick.Controls
import qs.config
import qs.components
ComboBox {
 id:root
 hoverEnabled:true
 implicitHeight:36
 leftPadding:4
 rightPadding:4
 font.family:Appearance.font.ui;font.pixelSize:Appearance.textSize.control
 background:ChamferPanel {scanlines:false;chamfer:6;fillColor:root.down?Theme.widgetRaised:Theme.widgetSurface;borderColor:root.activeFocus?Theme.widgetAccent:root.hovered?Theme.widgetMuted:Theme.widgetBorder;Behavior on borderColor {ColorAnimation {duration:150}} }
 contentItem:Text { textFormat: Text.PlainText;leftPadding:9;rightPadding:23;text:root.displayText;elide:Text.ElideRight;verticalAlignment:Text.AlignVCenter;font:root.font;color:Theme.widgetText}
 indicator:Text { textFormat: Text.PlainText;x:root.width-20;y:0;height:root.height;text:"⌄";verticalAlignment:Text.AlignVCenter;color:Theme.widgetAccent;font:root.font}
 delegate:ItemDelegate {required property var modelData;width:Math.max(1,(ListView.view?.width??root.width));height:42;leftPadding:12;rightPadding:12;contentItem:Text {textFormat:Text.PlainText;text:root.textRole?modelData[root.textRole]:String(modelData);font:root.font;color:Theme.widgetText;elide:Text.ElideRight;verticalAlignment:Text.AlignVCenter}background:ChamferPanel {scanlines:false;chamfer:6;fillColor:parent.hovered||parent.highlighted?Theme.blend(Theme.widgetSurface,Theme.widgetAccent,.18):Theme.widgetSurface}}
 popup:Popup {
  y:root.height+4;width:root.width
  implicitHeight:Math.min(274,contentItem.implicitHeight+12);padding:6
  enter:Transition {NumberAnimation {property:"opacity";from:0;to:1;duration:Theme.reducedMotion?0:110}}
  exit:Transition {NumberAnimation {property:"opacity";to:0;duration:Theme.reducedMotion?0:80}}
  background:ChamferPanel {scanlines:false;chamfer:6;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder}
  contentItem:ListView {clip:true;implicitHeight:contentHeight;model:root.popup.visible?root.delegateModel:null;currentIndex:root.highlightedIndex;ScrollBar.vertical:DeskScrollBar {}}
 }
}
