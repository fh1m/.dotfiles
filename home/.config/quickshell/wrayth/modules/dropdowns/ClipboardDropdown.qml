import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 headerAccent:Theme.widgetAccent
 id:root;title:"\uf0ea CLIPBOARD VAULT";katakana:"АРХИВ";implicitWidth:1040
 property var selected:ClipboardVault.detail
 Column {
 width:parent.width;spacing:8
 Row {spacing:8
 DeskTextField {id:search;width:330;height:32;placeholderText:"Search text, commands, snippets…";text:ClipboardVault.query;onTextEdited:ClipboardVault.query=text;color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:12;selectByMouse:true;Component.onCompleted:forceActiveFocus()}
 Repeater {model:[{name:"All",key:"all"},{name:"Text / code",key:"text"},{name:"Images",key:"image"},{name:"Pinned",key:"pinned"},{name:"Archive",key:"archived"}];ControlTile {required property var modelData;implicitWidth:120;implicitHeight:32;label:modelData.name;navigation:true;selected:ClipboardVault.filter===modelData.key;onActivated:ClipboardVault.filter=modelData.key}}
 }
 Row {
 spacing:12;width:parent.width;height:292
 Rectangle {width:300;height:parent.height;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 ListView {id:list;anchors.fill:parent;anchors.margins:5;clip:true;spacing:4;model:ClipboardVault.items;ScrollBar.vertical:DeskScrollBar {}
 delegate:Rectangle {required property var modelData;width:list.width-10;height:57;color:ClipboardVault.selected===modelData.id?Theme.alpha(Theme.widgetAccent,.16):pointer.containsMouse?Theme.alpha(Theme.widgetAccent,.07):"transparent";border.color:ClipboardVault.selected===modelData.id?Theme.widgetAccent:Theme.widgetBorder
 Image {x:6;y:7;width:43;height:43;source:modelData.kind==="image"?"file://"+modelData.path:"";visible:modelData.kind==="image";fillMode:Image.PreserveAspectFit;sourceSize.width:100;asynchronous:true}
 NrLabel {x:15;y:18;visible:modelData.kind!=="image";text:modelData.pinned?"\uf08d":"\uf121";pixelSize:20;color:Theme.widgetAccent}
 NrLabel {x:58;y:8;width:parent.width-65;text:modelData.title;pixelSize:12;elide:Text.ElideRight;maximumLineCount:1}
 NrLabel {x:58;y:31;width:parent.width-65;text:Qt.formatDateTime(new Date(modelData.last*1000),"MMM d · hh:mm AP")+" · ×"+modelData.copies;pixelSize:10;color:Theme.widgetMuted;elide:Text.ElideRight}
 MouseArea {id:pointer;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:ClipboardVault.select(modelData.id);onDoubleClicked:{ClipboardVault.select(modelData.id);ClipboardVault.action("copy");}}
 }
 }
 NrLabel {anchors.centerIn:parent;visible:ClipboardVault.items.length===0;text:"No matching entries";pixelSize:12;color:Theme.widgetMuted}
 }
 Rectangle {width:parent.width-312;height:parent.height;color:Theme.alpha(Theme.widgetSurface,.7);border.color:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:10;spacing:6
 Row {spacing:8;NrLabel {width:480;text:root.selected.kind==="image"?"IMAGE PREVIEW":(root.selected.lexer??"TEXT PREVIEW");pixelSize:12;color:Theme.widgetAccent;elide:Text.ElideRight}NrLabel {text:root.selected.pinned?"\uf08d PINNED":"";pixelSize:11;color:Theme.widgetAccent}}
 Flickable {id:preview;width:parent.width;height:222;clip:true;contentWidth:width;contentHeight:root.selected.kind==="image"?height:code.height;boundsBehavior:Flickable.StopAtBounds;ScrollBar.vertical:DeskScrollBar {}
 Image {anchors.fill:parent;visible:root.selected.kind==="image";source:visible&&root.selected.path?"file://"+root.selected.path:"";fillMode:Image.PreserveAspectFit;sourceSize.width:1100;asynchronous:true}
 Text {id:code;width:parent.width;visible:root.selected.kind==="text";textFormat:Text.RichText;text:"<pre>"+(root.selected.rich??"")+"</pre>";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;wrapMode:Text.WrapAnywhere;onLinkActivated:()=>{} }
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
}
