import QtQuick
import qs.components
import qs.config
import qs.services
import qs.modules.dropdowns
ChamferPanel {
 id:root;signal poolsRequested;implicitWidth:390;implicitHeight:444;fillColor:Theme.panel2;borderColor:Theme.hair
 Column {anchors.fill:parent;anchors.margins:14;spacing:11
 Text {text:"Sensei, make both displays yours.";font.family:Appearance.font.data;font.pixelSize:13;color:Theme.signal}
 Row {width:parent.width;spacing:10;NrLabel {text:"Follow theme";font.capitalization:Font.MixedCase;tracked:false;pixelSize:11;anchors.verticalCenter:parent.verticalCenter}ToggleButton {on:Wallpapers.dynamic;onToggled:Wallpapers.setDynamic(!Wallpapers.dynamic)}}
 Repeater {model:[{output:"eDP-1",name:"Main"},{output:"DP-2",name:"ScreenPad"}]
 Rectangle {id:displayRow;required property var modelData;width:parent.width;height:119;color:Theme.alpha(Theme.barBg,.65);border.color:Theme.hair
 Image {x:8;y:9;width:100;height:100;source:Wallpapers.displaySource(displayRow.modelData.output);fillMode:Wallpapers.displayMode(displayRow.modelData.output);asynchronous:true}
 Column {x:119;y:10;width:parent.width-129;spacing:8
 Text {text:displayRow.modelData.name+" · "+displayRow.modelData.output;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.signal}
 Row {spacing:5;ControlTile {implicitWidth:105;implicitHeight:25;label:"Choose image";onActivated:WallpaperChooser.open(displayRow.modelData.output)}ControlTile {implicitWidth:105;implicitHeight:25;label:"Theme image";onActivated:Wallpapers.setDisplay(displayRow.modelData.output,"",Image.PreserveAspectCrop)}}
 Row {spacing:4;Repeater {model:[{name:"Fill",mode:2},{name:"Fit",mode:1},{name:"Stretch",mode:0},{name:"Tile",mode:3}];ControlTile {required property var modelData;implicitWidth:modelData.name==="Stretch"?75:45;implicitHeight:25;label:modelData.name;selected:Wallpapers.displayMode(displayRow.modelData.output)===modelData.mode;onActivated:Wallpapers.setDisplay(displayRow.modelData.output,Wallpapers.displays[displayRow.modelData.output]?.file||"",modelData.mode)}}}
 }
 }
 }
 InputField {width:parent.width;text:Paths.display(Wallpapers.folder);placeholder:"Wallpaper library folder";onAccepted:Wallpapers.setFolder(Paths.expand(text))}
 Row {spacing:6;ControlTile {implicitWidth:175;implicitHeight:29;label:"Manage theme pools";onActivated:root.poolsRequested()}ControlTile {implicitWidth:175;implicitHeight:29;label:"Open library folder";onActivated:Wallpapers.openFolder()}}
 }
}
