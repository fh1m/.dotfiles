import QtQuick
import qs.components
import qs.config
Rectangle {
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
 readonly property int inset:width<100?7:10
 readonly property int iconWidth:width<100?17:23
 readonly property bool down:pointer.pressed||keyHeld
 signal activated()
 implicitWidth:184;implicitHeight:38
 radius:Theme.radiusSmall
 activeFocusOnTab:true
 Accessible.role:Accessible.Button
 Accessible.name:label
 Accessible.onPressAction:if(enabled)activated()
 color:down?Theme.surfaceTwo:selected?Theme.surfaceTwo:pointer.containsMouse||activeFocus?Theme.surfaceOne:Theme.ink
 border.color:activeFocus?accentColor:pointer.containsMouse||selected?Theme.paperMuted:Theme.rule
 border.width:1
 opacity:enabled?1:.38
 scale:down?.985:1
 Behavior on color {ColorAnimation {duration:Theme.motionAck}}
 Behavior on scale {NumberAnimation {duration:Theme.motionAck;easing.type:Easing.OutCubic}}
 Behavior on opacity {NumberAnimation {duration:140}}
 Rectangle {visible:root.selected&&root.navigation;anchors.left:parent.left;anchors.leftMargin:4;anchors.verticalCenter:parent.verticalCenter;width:2;height:15;radius:1;color:root.accentColor}
 Row {x:root.inset;width:root.width-2*root.inset;anchors.verticalCenter:parent.verticalCenter;spacing:root.label===""?0:root.width<100?4:7
 Item { id: iconCell; visible:root.glyph!=="";width:root.iconWidth;height:26;anchors.verticalCenter:parent.verticalCenter
 Text {anchors.centerIn:parent;text:root.glyph;font.family:Appearance.font.icons;font.pixelSize:root.width<100?16:root.height>=38?20:18;color:root.selected||pointer.containsMouse?root.accentColor:Theme.widgetMuted;Behavior on color {ColorAnimation {duration:Theme.motionAck}}}
 }
  Column {visible:root.label!==""&&root.label!=="‹"&&root.label!=="›"&&root.label!=="←"&&root.label!=="→";anchors.verticalCenter:parent.verticalCenter;width:Math.max(0,parent.width-(iconCell.visible?iconCell.width+parent.spacing:0));spacing:2
 NrLabel {width:parent.width;elide:Text.ElideRight;centred:false;tracked:false;pixelSize:root.width<100?10:root.width>=130&&root.height>=36?12:11;font.family:Appearance.font.ui;font.capitalization:Font.MixedCase;font.weight:root.selected?Font.DemiBold:Font.Medium;font.letterSpacing:0;text:root.label;color:root.navigation&&root.selected?root.accentColor:Theme.widgetText}
 Text {id:tileDetail;visible:root.detail!=="";width:parent.width;text:root.detail;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:9;color:Theme.widgetMuted}
 }
 }

 Keys.onPressed:event=>{if(!event.isAutoRepeat&&(event.key===Qt.Key_Space||event.key===Qt.Key_Return||event.key===Qt.Key_Enter)){root.keyHeld=true;event.accepted=true;}}
 Keys.onReleased:event=>{if(root.keyHeld&&(event.key===Qt.Key_Space||event.key===Qt.Key_Return||event.key===Qt.Key_Enter)){root.keyHeld=false;root.activated();event.accepted=true;}}
 onActiveFocusChanged:if(!activeFocus)keyHeld=false
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:root.enabled?Qt.PointingHandCursor:Qt.ArrowCursor;onClicked:root.activated()}
}
