import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;title:"\uf03e Display wallpapers";katakana:"ОБОИ";implicitWidth:740
 property string selectedOutput:"eDP-1"

 Column {width:parent.width;spacing:12
 Text {width:parent.width;text:"Set independent images and layouts, or let either screen follow your theme's wallpaper pool.";color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:12;wrapMode:Text.Wrap}
 Repeater {model:[{output:"eDP-1",name:"Main display"},{output:"DP-2",name:"ScreenPad"}]
 Rectangle {required property var modelData;width:parent.width;height:169;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Image {x:10;y:10;width:230;height:147;source:Wallpapers.displaySource(modelData.output);sourceSize:Qt.size(512,328);fillMode:Wallpapers.displayMode(modelData.output);asynchronous:true}
 Column {x:253;y:10;width:parent.width-263;spacing:9
 Text {text:modelData.name+" · "+modelData.output;font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.widgetAccent}
 Text {width:parent.width;elide:Text.ElideMiddle;text:Wallpapers.displays[modelData.output]?.file || "Follows theme / shared wallpaper";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 Row {spacing:8;ControlTile {implicitWidth:165;implicitHeight:30;label:"Choose image";glyph:"\uf03e";onActivated:{root.selectedOutput=modelData.output;WallpaperChooser.open(root.selectedOutput)}}ControlTile {implicitWidth:165;implicitHeight:30;label:"Follow theme";onActivated:Wallpapers.setDisplay(modelData.output,"",Image.PreserveAspectCrop)}}
 Row {spacing:5;Repeater {model:[{name:"Fill",mode:Image.PreserveAspectCrop},{name:"Fit",mode:Image.PreserveAspectFit},{name:"Stretch",mode:Image.Stretch},{name:"Tile",mode:Image.Tile}];ControlTile {required property var modelData;implicitWidth:80;implicitHeight:28;label:modelData.name;selected:Wallpapers.displayMode(parent.parent.parent.modelData.output)===modelData.mode;onActivated:{let output=parent.parent.parent.modelData.output;Wallpapers.setDisplay(output,Wallpapers.displays[output]?.file||"",modelData.mode)}}}}
 }
 }
 }
 Row {spacing:8;ControlTile {label:"Themes / pools";glyph:"\uf53f";onActivated:ShellState.openExclusive("picker")}Text {text:"Super+W opens themes and wallpaper pools";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;anchors.verticalCenter:parent.verticalCenter}}
 }
}
