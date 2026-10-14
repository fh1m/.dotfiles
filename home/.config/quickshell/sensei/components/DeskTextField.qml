import QtQuick
import QtQuick.Controls
import qs.config
import qs.components
TextField {
 id:root
 Accessible.name:placeholderText
 height:36
 hoverEnabled:true;selectByMouse:true
 font.family:Appearance.font.data;font.pixelSize:13
 color:Theme.widgetText;placeholderTextColor:Theme.widgetFaint
 selectionColor:Theme.widgetAccent;selectedTextColor:Theme.widgetText
 leftPadding:12;rightPadding:12;topPadding:7;bottomPadding:7
 background:ChamferPanel {scanlines:false;chamfer:6;fillColor:root.activeFocus?Theme.widgetRaised:Theme.widgetSurface;borderColor:root.activeFocus?Theme.widgetAccent:root.hovered?Theme.widgetMuted:Theme.widgetBorder;borderWidth:1
 Behavior on fillColor {ColorAnimation {duration:150}}
 Behavior on borderColor {ColorAnimation {duration:150}}
 }
}
