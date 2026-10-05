import QtQuick
import qs.components
import qs.config
ChamferPanel {
 id:root
 property string label:""
 // Every action gets a visual anchor, including legacy text-only panels.
 // Explicit glyphs still override the semantic fallback.
 property string glyph:Appearance.iconFor(label)

 property bool selected:false
 property bool navigation:false
 property bool danger:/^(delete|remove|shutdown|reboot|power off)/i.test(label)
 property color accentColor:danger?Theme.alert:Theme.widgetAccent
 property string detail:""
 property bool keyHeld:false
 readonly property bool down:pointer.pressed||keyHeld
 signal activated()
 implicitWidth:184;implicitHeight:38
 chamfer:5;scanlines:false
 activeFocusOnTab:true
 Accessible.role:Accessible.Button
 Accessible.name:label
 Accessible.onPressAction:if(enabled)activated()
 fillColor:down?Theme.blend(Theme.widgetRaised,accentColor,.22):selected?Theme.blend(Theme.widgetRaised,accentColor,navigation?.10:.10):pointer.containsMouse||activeFocus?Theme.blend(Theme.widgetRaised,Theme.widgetText,.035):Theme.widgetRaised
 borderColor:activeFocus?accentColor:pointer.containsMouse?Theme.alpha(accentColor,.20):"transparent"
 borderWidth:1
 opacity:enabled?1:.38
 scale:down?.982:1
 Behavior on fillColor {ColorAnimation {duration:root.down?65:150}}
 Behavior on borderColor {ColorAnimation {duration:140}}
 Behavior on scale {NumberAnimation {duration:root.down?70:170;easing.type:Easing.OutCubic}}
 Behavior on opacity {NumberAnimation {duration:140}}
 Rectangle {visible:root.selected&&root.navigation;anchors.left:parent.left;anchors.leftMargin:4;anchors.verticalCenter:parent.verticalCenter;width:2;height:15;radius:1;color:root.accentColor}
 Row {x:root.navigation?(root.width-width)/2:14;anchors.verticalCenter:parent.verticalCenter;spacing:root.label===""?0:8
 Item { visible:root.glyph!=="";width:25;height:26;anchors.verticalCenter:parent.verticalCenter
 Text {anchors.centerIn:parent;text:root.glyph;font.family:Appearance.font.icons;font.pixelSize:root.height>=38?23:20;color:root.selected||pointer.containsMouse?root.accentColor:Theme.widgetMuted;Behavior on color {ColorAnimation {duration:150}}}
 }
  Column {visible:root.label!==""&&root.label!=="‹"&&root.label!=="›"&&root.label!=="←"&&root.label!=="→";anchors.verticalCenter:parent.verticalCenter;spacing:2
 NrLabel {width:Math.min(Math.max(implicitWidth,tileDetail.implicitWidth),root.width-12-(root.glyph?37:0));elide:Text.ElideRight;centred:false;tracked:false;pixelSize:root.width>=130&&root.height>=36?12:11;font.family:Appearance.font.ui;font.capitalization:Font.MixedCase;font.weight:root.selected?Font.DemiBold:Font.Medium;font.letterSpacing:0;text:root.label;color:root.navigation&&root.selected?root.accentColor:Theme.widgetText}
 Text {id:tileDetail;visible:root.detail!=="";width:parent.width;text:root.detail;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:9;color:Theme.widgetMuted}
 }
 }

 Keys.onPressed:event=>{if(!event.isAutoRepeat&&(event.key===Qt.Key_Space||event.key===Qt.Key_Return||event.key===Qt.Key_Enter)){root.keyHeld=true;event.accepted=true;}}
 Keys.onReleased:event=>{if(root.keyHeld&&(event.key===Qt.Key_Space||event.key===Qt.Key_Return||event.key===Qt.Key_Enter)){root.keyHeld=false;root.activated();event.accepted=true;}}
 onActiveFocusChanged:if(!activeFocus)keyHeld=false
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:root.enabled?Qt.PointingHandCursor:Qt.ArrowCursor;onClicked:root.activated()}
}
