import QtQuick
import QtQuick.Controls
import qs.config
import qs.components
TextArea {
 id:root
 Accessible.name:placeholderText
 font.family:Appearance.font.data;font.pixelSize:13
 color:Theme.widgetText;placeholderTextColor:Theme.widgetFaint
 selectionColor:Theme.widgetAccent;selectedTextColor:Theme.widgetText
 padding:12;wrapMode:Text.Wrap
 background:ChamferPanel {scanlines:false;chamfer:6;fillColor:root.activeFocus?Theme.widgetRaised:Theme.widgetSurface;borderColor:root.activeFocus?Theme.widgetAccent:Theme.widgetBorder;Behavior on borderColor {ColorAnimation {duration:150}}}
}
