import QtQuick
import qs.components
import qs.config
ChamferPanel {
 id:root
 property string label:""
 property string glyph:""
 property bool selected:false
 property bool navigation:false
 property bool danger:/^(delete|remove|shutdown|reboot|power off)/i.test(label)
 property color accentColor:navigation||danger?Theme.widgetAccent:Theme.widgetAccent
 property string detail:""
 property bool keyHeld:false
 readonly property bool down:pointer.pressed||keyHeld
 signal activated()
 implicitWidth:184;implicitHeight:38
 chamfer:6;scanlines:false
 activeFocusOnTab:true
 Accessible.role:Accessible.Button
 Accessible.name:label
 Accessible.onPressAction:if(enabled)activated()
 fillColor:down?Theme.alpha(accentColor,.19):selected?Theme.alpha(accentColor,navigation?.12:.08):pointer.containsMouse||activeFocus?Theme.widgetRaised:Theme.widgetSurface
 borderColor:activeFocus?accentColor:selected?Theme.alpha(accentColor,.55):pointer.containsMouse?Theme.alpha(Theme.widgetText,.32):Theme.widgetBorder
 borderWidth:1
 opacity:enabled?1:.38
 scale:down?.982:1
 Behavior on fillColor {ColorAnimation {duration:root.down?65:150}}
 Behavior on borderColor {ColorAnimation {duration:140}}
 Behavior on scale {NumberAnimation {duration:root.down?70:170;easing.type:Easing.OutCubic}}
 Behavior on opacity {NumberAnimation {duration:140}}
 Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.margins:1;height:1;radius:1;color:Theme.alpha(Theme.widgetText,pointer.containsMouse?.12:.045)}
 Rectangle {visible:root.navigation;anchors.bottom:parent.bottom;anchors.bottomMargin:3;anchors.horizontalCenter:parent.horizontalCenter;width:root.selected?Math.min(32,parent.width*.32):0;height:2;radius:1;color:root.accentColor;Behavior on width {NumberAnimation {duration:180;easing.type:Easing.OutCubic}}}
 Row {anchors.centerIn:parent;spacing:root.label===""?0:8
 ChamferPanel {scanlines:false;chamfer:4;visible:root.glyph!=="";width:22;height:22;fillColor:root.label===""?"transparent":root.selected?Theme.alpha(root.accentColor,.16):Theme.alpha("#000000",.24);borderColor:root.label===""?"transparent":Theme.alpha(root.selected?root.accentColor:Theme.widgetText,.13);anchors.verticalCenter:parent.verticalCenter
 Text {anchors.centerIn:parent;text:root.glyph;font.family:Appearance.font.icons;font.pixelSize:13;color:root.selected||pointer.containsMouse?root.accentColor:Theme.widgetMuted;Behavior on color {ColorAnimation {duration:150}}}
 }
 Column {visible:root.label!=="";anchors.verticalCenter:parent.verticalCenter;spacing:2
 NrLabel {width:Math.min(Math.max(implicitWidth,tileDetail.implicitWidth),root.width-24-(root.glyph?30:0));elide:Text.ElideRight;centred:false;tracked:false;pixelSize:root.width>=130&&root.height>=36?13:12;font.capitalization:Font.MixedCase;font.weight:root.selected?Font.DemiBold:Font.Medium;font.letterSpacing:.15;text:root.label;color:root.selected?Theme.widgetText:Theme.alpha(Theme.widgetText,.90)}
 Text {id:tileDetail;visible:root.detail!=="";width:parent.width;text:root.detail;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:10;color:Theme.widgetMuted}
 }
 }

 Keys.onPressed:event=>{if(!event.isAutoRepeat&&(event.key===Qt.Key_Space||event.key===Qt.Key_Return||event.key===Qt.Key_Enter)){root.keyHeld=true;event.accepted=true;}}
 Keys.onReleased:event=>{if(root.keyHeld&&(event.key===Qt.Key_Space||event.key===Qt.Key_Return||event.key===Qt.Key_Enter)){root.keyHeld=false;root.activated();event.accepted=true;}}
 onActiveFocusChanged:if(!activeFocus)keyHeld=false
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:root.enabled?Qt.PointingHandCursor:Qt.ArrowCursor;onClicked:root.activated()}
}
