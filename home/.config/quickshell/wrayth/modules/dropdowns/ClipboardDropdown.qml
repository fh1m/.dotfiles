import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 headerAccent:Theme.widgetAccent
 id:root;title:"\uf0ea Clipboard vault";katakana:"АРХИВ";implicitWidth:1040
 property var selected:ClipboardVault.detail
 Column {
 width:parent.width;spacing:8
 Row {spacing:8
 DeskTextField {id:search;width:270;height:32;placeholderText:"Search text, files, snippets…";text:ClipboardVault.query;onTextEdited:ClipboardVault.query=text;color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:13;selectByMouse:true}
 Repeater {model:[{name:"All",key:"all"},{name:"Text / code",key:"text"},{name:"Images",key:"image"},{name:"Files",key:"files"},{name:"Pinned",key:"pinned"},{name:"Archive",key:"archived"}];ControlTile {required property var modelData;implicitWidth:112;implicitHeight:32;label:modelData.name;navigation:true;selected:ClipboardVault.filter===modelData.key;onActivated:ClipboardVault.filter=modelData.key}}
 }
 Row {
 spacing:12;width:parent.width;height:292
 ChamferPanel {width:300;height:parent.height;fillColor:Theme.widgetSurface;borderColor:Theme.alpha(Theme.widgetText,.08);chamfer:8;scanlines:false
 ListView {id:list;anchors.fill:parent;anchors.margins:5;clip:true;spacing:4;model:ClipboardVault.items;ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property var modelData;width:list.width-10;height:57;chamfer:5;scanlines:false;fillColor:ClipboardVault.selected===modelData.id?Theme.blend(Theme.widgetRaised,Theme.widgetAccent,.13):pointer.containsMouse?Theme.widgetRaised:Theme.widgetSurface;borderColor:Theme.alpha(Theme.widgetText,.07)
 Image {x:6;y:7;width:43;height:43;source:modelData.kind==="image"?"file://"+modelData.path:"";visible:modelData.kind==="image";fillMode:Image.PreserveAspectFit;sourceSize.width:100;asynchronous:true}
 NrLabel {x:15;y:18;visible:modelData.kind!=="image";text:modelData.pinned?"\uf08d":modelData.kind==="files"?"\uf15b":"\uf121";pixelSize:20;color:Theme.widgetAccent}
 NrLabel {x:58;y:8;width:parent.width-65;text:modelData.title;pixelSize:13;elide:Text.ElideRight;maximumLineCount:1;tracked:false;font.capitalization:Font.MixedCase;font.family:Appearance.font.ui;color:Theme.widgetText}
 NrLabel {x:58;y:32;width:parent.width-65;text:Qt.formatDateTime(new Date(modelData.last*1000),"MMM d · hh:mm AP")+" · ×"+modelData.copies;pixelSize:11;color:Theme.widgetMuted;elide:Text.ElideRight;tracked:false;font.capitalization:Font.MixedCase;font.family:Appearance.font.ui}
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:ClipboardVault.select(modelData.id);onDoubleClicked:{ClipboardVault.select(modelData.id);ClipboardVault.action("copy");}}
 }
 }
 NrLabel {anchors.centerIn:parent;visible:ClipboardVault.items.length===0;text:"No matching entries";pixelSize:12;color:Theme.widgetMuted}
 }
 ChamferPanel {width:parent.width-312;height:parent.height;fillColor:Theme.widgetSurface;borderColor:Theme.alpha(Theme.widgetText,.08);chamfer:8;scanlines:false
 Column {anchors.fill:parent;anchors.margins:10;spacing:6
 Row {spacing:8;NrLabel {width:480;tracked:false;font.capitalization:Font.MixedCase;font.family:Appearance.font.heading;font.weight:Font.DemiBold;text:root.selected.kind==="image"?"Image preview":root.selected.kind==="files"?"Files · "+(root.selected.fileCount??0):(root.selected.lexer??"Text preview");pixelSize:14;color:Theme.widgetAccent;elide:Text.ElideRight}NrLabel {text:root.selected.pinned?"\uf08d PINNED":"";pixelSize:11;color:Theme.widgetAccent}}
 Flickable {id:preview;width:parent.width;height:222;clip:true;contentWidth:width;contentHeight:root.selected.kind==="files"?Math.max(height,filePreview.implicitHeight):root.selected.kind==="image"?height:code.height;boundsBehavior:Flickable.StopAtBounds;ScrollBar.vertical:DeskScrollBar {}
 Image {id:imagePreview;anchors.fill:parent;visible:root.selected.kind==="image";source:visible&&root.selected.path?"file://"+root.selected.path:"";fillMode:Image.PreserveAspectFit;sourceSize.width:1100;asynchronous:true}
 NrLabel {anchors.centerIn:parent;visible:root.selected.kind==="image"&&imagePreview.status===Image.Error;text:"Preview unavailable · open original";pixelSize:12;color:Theme.widgetMuted}
 Text {id:code;width:parent.width;visible:root.selected.kind==="text";textFormat:Text.RichText;text:"<pre>"+(root.selected.rich??"")+"</pre>";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;wrapMode:Text.WrapAnywhere;onLinkActivated:()=>{} }
 Column {id:filePreview;width:parent.width;spacing:4;visible:root.selected.kind==="files"
 Repeater {model:root.selected.files??[];Rectangle {required property var modelData;width:filePreview.width;height:44;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Image {x:5;y:3;width:38;height:38;visible:modelData.image&&modelData.exists;source:visible?"file://"+modelData.path:"";fillMode:Image.PreserveAspectFit;sourceSize.width:76;asynchronous:true}
 NrLabel {x:14;y:13;visible:!modelData.image||!modelData.exists;text:modelData.exists?"\uf15b":"\uf071";pixelSize:17;color:modelData.exists?Theme.widgetAccent:Theme.uiWarning}
 NrLabel {x:51;anchors.verticalCenter:parent.verticalCenter;width:parent.width-60;text:modelData.name+(modelData.exists?"":" · missing on disk");pixelSize:12;elide:Text.ElideMiddle;color:modelData.exists?Theme.widgetText:Theme.uiWarning}
 }}
 }
 }
 NrLabel {width:parent.width;text:root.selected.id?(Math.round((root.selected.bytes??0)/1024*10)/10+" KiB · "+(root.selected.copies??1)+" copies · "+(root.selected.truncated?"Preview truncated; original retained":"Original preserved")):"Select an entry";pixelSize:10;color:Theme.widgetMuted;elide:Text.ElideRight}
 }
 }
 }
 Row {spacing:7
 Repeater {model:[{label:"Copy",action:"copy",glyph:"\uf0c5"},{label:root.selected.pinned?"Unpin":"Pin snippet",action:"pin",glyph:"\uf08d"},{label:root.selected.archived?"Restore":"Archive",action:"archive",glyph:"\uf187"},{label:"Shell quote",action:"quote",glyph:"\uf120"},{label:"Format JSON",action:"pretty",glyph:"\uf121"}];ControlTile {required property var modelData;implicitWidth:145;implicitHeight:30;label:modelData.label;glyph:modelData.glyph;enabled:!!root.selected.id&&(modelData.action!=="quote"&&modelData.action!=="pretty"||root.selected.kind==="text");onActivated:ClipboardVault.action(modelData.action)}}
 ControlTile {implicitWidth:145;implicitHeight:30;label:"Open original";glyph:"\uf07c";enabled:!!root.selected.path;onActivated:Quickshell.execDetached(["xdg-open",root.selected.path])}
 }
 Row {spacing:10
 NrLabel {width:805;text:ClipboardVault.error || (ClipboardVault.count+" unique items · "+ClipboardVault.events+" copies · "+(ClipboardVault.bytes/1048576).toFixed(1)+" MiB · ~/.clipboard · no automatic deletion");pixelSize:10;color:ClipboardVault.error?Theme.widgetAccent:Theme.widgetMuted;elide:Text.ElideRight}
 ControlTile {implicitWidth:180;implicitHeight:25;label:ClipboardVault.items.length>=ClipboardVault.limit?"Load more":"Archive folder";onActivated:{if(ClipboardVault.items.length>=ClipboardVault.limit){ClipboardVault.limit+=150;ClipboardVault.refresh();}else Quickshell.execDetached(["xdg-open","@HOME@/.clipboard"]);}}
 }
 }
 Keys.onReturnPressed:ClipboardVault.action("copy")
 Connections {target:ShellState;function onDropdownChanged(){if(ShellState.dropdown==="clipboard")search.forceActiveFocus();}}
}
