import QtQuick
import QtQuick.Controls
import qs.components
import qs.config
Item {
 id:root
 property string title:""
 property color accentColor:Theme.widgetAccent
 property string glyph:""
 property real level:0
 property real maximum:100
 property real pendingLevel:-1
 readonly property real shownLevel:pendingLevel>=0?pendingLevel:level
 readonly property real displayed:trim.pressed?trim.value:knob.pressed?knob.value:shownLevel
 function adjust(v){pendingLevel=v;settle.restart();edited(v);}
 onLevelChanged:if(pendingLevel>=0&&Math.abs(level-pendingLevel)<1)pendingLevel=-1
 Timer {id:settle;interval:1800;onTriggered:root.pendingLevel=-1}
 signal edited(real percent)
 width:parent.width
 implicitHeight:46;height:implicitHeight
 Dial {
  id:knob;width:42;height:42;anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter
  from:0;to:root.maximum;stepSize:1;inputMode:Dial.Vertical;wheelEnabled:true
  Accessible.name:root.title
  Binding {target:knob;property:"value";value:root.shownLevel;when:!knob.pressed;restoreMode:Binding.RestoreNone}
  onMoved:root.adjust(value)
  background:Canvas {
   anchors.fill:parent
   property real fraction:Math.max(0,Math.min(1,root.displayed/root.maximum))
   onFractionChanged:if(visible)requestPaint()
   onVisibleChanged:if(visible)requestPaint()
   onPaint:{const c=getContext('2d');c.reset();const start=-230*Math.PI/180;c.lineWidth=2;c.lineCap='round';c.strokeStyle=Theme.widgetBorder;c.beginPath();c.arc(width/2,height/2,width/2-4,start,start+280*Math.PI/180);c.stroke();c.strokeStyle=root.accentColor;c.beginPath();c.arc(width/2,height/2,width/2-4,start,start+280*Math.PI/180*fraction);c.stroke();}
  }
  handle:Rectangle {width:4;height:4;radius:2;color:Theme.widgetText;x:knob.width/2+17*Math.cos((knob.angle-90)*Math.PI/180)-2;y:knob.height/2+17*Math.sin((knob.angle-90)*Math.PI/180)-2}
  Text {anchors.centerIn:parent;text:root.glyph||'◉';font.family:root.glyph?Appearance.font.icons:Appearance.font.data;font.pixelSize:13;color:knob.pressed||knob.activeFocus?root.accentColor:Theme.widgetMuted}
  Rectangle {anchors.fill:parent;radius:21;color:'transparent';border.color:knob.activeFocus?Theme.alpha(root.accentColor,.6):'transparent'}
 }
 Text {x:54;y:5;width:parent.width-118;elide:Text.ElideRight;text:root.title;font.family:Appearance.font.data;font.pixelSize:12;font.weight:Font.DemiBold;color:Theme.widgetText}
 Text {anchors.right:parent.right;y:5;text:Math.round(root.displayed)+'%';font.family:Appearance.font.data;font.pixelSize:13;font.weight:Font.DemiBold;color:root.accentColor}
 Slider {
  id:trim;x:54;y:25;width:Math.max(30,parent.width-54);height:18
  from:0;to:root.maximum;stepSize:1
  Accessible.name:root.title+' fine adjustment'
  Binding {target:trim;property:'value';value:root.shownLevel;when:!trim.pressed;restoreMode:Binding.RestoreNone}
  onMoved:root.adjust(value)
  background:Rectangle {x:trim.leftPadding;y:trim.topPadding+trim.availableHeight/2-1;width:trim.availableWidth;height:2;radius:1;color:Theme.widgetBorder
   Rectangle {width:trim.visualPosition*parent.width;height:2;radius:1;color:Theme.alpha(root.accentColor,.72)}
  }
  handle:Rectangle {x:trim.leftPadding+trim.visualPosition*(trim.availableWidth-width);y:trim.topPadding+trim.availableHeight/2-height/2;width:trim.pressed?7:5;height:trim.pressed?7:5;radius:4;color:root.accentColor;Behavior on width {NumberAnimation {duration:90}}Behavior on height {NumberAnimation {duration:90}}}
 }
}
