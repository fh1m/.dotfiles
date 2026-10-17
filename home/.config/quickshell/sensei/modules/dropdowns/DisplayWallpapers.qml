import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;title:"Displays / layout & wallpapers";katakana:"ОБОИ";implicitWidth:740
 property string selectedOutput:MachineProfile.primaryOutput

 Column {width:parent.width;spacing:12
 Rectangle {id:map;width:parent.width;height:180;color:Theme.surfaceOne;radius:8
  readonly property var monitors:ExternalDisplays.layout
  readonly property real leftEdge:Math.min(0,...monitors.map(m=>m.x))
  readonly property real topEdge:Math.min(0,...monitors.map(m=>m.y))
  readonly property real spanX:Math.max(1,...monitors.map(m=>m.x+m.width/m.scale))-leftEdge
  readonly property real spanY:Math.max(1,...monitors.map(m=>m.y+m.height/m.scale))-topEdge
  readonly property real factor:Math.min((width-40)/spanX,(height-30)/spanY)
  Repeater {model:map.monitors
   Rectangle {required property var modelData;x:20+(modelData.x-map.leftEdge)*map.factor;y:15+(modelData.y-map.topEdge)*map.factor;width:modelData.width/modelData.scale*map.factor;height:modelData.height/modelData.scale*map.factor;radius:3;color:Theme.surfaceTwo;border.color:Theme.signalRed;border.width:1
    Text {anchors.centerIn:parent;text:parent.modelData.name;font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.paper}
   }
  }
 }
 Row {spacing:8
  ControlTile {label:"Arrange displays";glyph:"\uf108";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-display-arrange"])}
  ControlTile {label:"Restore Den layout";glyph:"\uf0e2";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-display-arrange","reset"])}
 }
 Text {width:parent.width;text:Den.online?"Digital Den linked · Arete ↔ Homie · editor changes this host only":"Standalone desk · saved profiles travel with your preferences";font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.signalRed}
 Text {width:parent.width;text:"Drag, rotate, mirror, set resolution/refresh/scale, and save profiles in the graphical editor. Saved arrangements take priority over automatic docking defaults.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.paperMuted}

 Text { textFormat: Text.PlainText;width:parent.width;text:"Set independent images and layouts, or let either screen follow your theme's wallpaper pool.";color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:12;wrapMode:Text.Wrap}
 Repeater {model:ShellState.screens.map(screen=>({output:screen.name,name:screen.name===MachineProfile.primaryOutput?"Main display":screen.name}))
 Rectangle {required property var modelData;width:parent.width;height:169;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Image {x:10;y:10;width:230;height:147;source:Wallpapers.displaySource(modelData.output);sourceSize:Qt.size(512,328);fillMode:Wallpapers.displayMode(modelData.output);asynchronous:true}
 Column {x:253;y:10;width:parent.width-263;spacing:9
 Text { textFormat: Text.PlainText;text:modelData.name+" · "+modelData.output;font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.widgetAccent}
 Text { textFormat: Text.PlainText;width:parent.width;elide:Text.ElideMiddle;text:Wallpapers.displays[modelData.output]?.file || "Follows theme / shared wallpaper";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 Row {spacing:8;ControlTile {implicitWidth:165;implicitHeight:30;label:"Choose image";glyph:"\uf03e";onActivated:{root.selectedOutput=modelData.output;WallpaperChooser.open(root.selectedOutput)}}ControlTile {implicitWidth:165;implicitHeight:30;label:"Follow theme";onActivated:Wallpapers.setDisplay(modelData.output,"",Image.PreserveAspectCrop)}}
 Row {spacing:5;Repeater {model:[{name:"Fill",mode:Image.PreserveAspectCrop},{name:"Fit",mode:Image.PreserveAspectFit},{name:"Stretch",mode:Image.Stretch},{name:"Tile",mode:Image.Tile}];ControlTile {required property var modelData;implicitWidth:80;implicitHeight:28;label:modelData.name;selected:Wallpapers.displayMode(parent.parent.parent.modelData.output)===modelData.mode;onActivated:{let output=parent.parent.parent.modelData.output;Wallpapers.setDisplay(output,Wallpapers.displays[output]?.file||"",modelData.mode)}}}}
 }
 }
 }
 Row {spacing:8;ControlTile {label:"Themes / pools";glyph:"\uf53f";onActivated:ShellState.openExclusive("picker")}Text { textFormat: Text.PlainText;text:"Super+W opens themes and wallpaper pools";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;anchors.verticalCenter:parent.verticalCenter}}
 }
}
