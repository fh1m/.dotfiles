import QtQuick
import QtQuick.Controls
import qs.config
import qs.components
ComboBox {
 id:root
 hoverEnabled:true
 font.family:Appearance.font.data;font.pixelSize:13
 background:ChamferPanel {scanlines:false;chamfer:6;fillColor:root.down?Theme.widgetRaised:Theme.widgetSurface;borderColor:root.activeFocus?Theme.widgetAccent:root.hovered?Theme.widgetMuted:Theme.widgetBorder;Behavior on borderColor {ColorAnimation {duration:150}} }
 contentItem:Text {leftPadding:9;rightPadding:23;text:root.displayText;elide:Text.ElideRight;verticalAlignment:Text.AlignVCenter;font:root.font;color:Theme.widgetText}
 indicator:Text {x:root.width-20;y:0;height:root.height;text:"⌄";verticalAlignment:Text.AlignVCenter;color:Theme.widgetAccent;font:root.font}
 delegate:ItemDelegate {required property var modelData;width:root.width;height:34;contentItem:Text {text:root.textRole?modelData[root.textRole]:String(modelData);font:root.font;color:Theme.widgetText;elide:Text.ElideRight}background:ChamferPanel {scanlines:false;chamfer:6;fillColor:parent.hovered||parent.highlighted?Theme.blend(Theme.widgetSurface,Theme.widgetAccent,.18):Theme.widgetSurface}}
 popup:Popup {y:root.height+3;width:root.width;implicitHeight:Math.min(250,contentItem.implicitHeight+8);padding:5;enter:Transition {NumberAnimation {property:"opacity";from:0;to:1;duration:140}}exit:Transition {NumberAnimation {property:"opacity";to:0;duration:100}}background:ChamferPanel {scanlines:false;chamfer:6;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder;}contentItem:ListView {clip:true;implicitHeight:contentHeight;model:root.popup.visible?root.delegateModel:null;currentIndex:root.highlightedIndex;ScrollBar.vertical:ScrollBar {}}}
}
