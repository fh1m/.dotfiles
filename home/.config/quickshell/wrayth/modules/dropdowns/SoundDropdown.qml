import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 headerAccent:Theme.widgetAccent
 id:root;title:"\uf028 Sound studio";katakana:"ЗВУК";implicitWidth:780;fillColor:Theme.widgetGlass
 property int page:SoundDesk.page
 onPageChanged:SoundDesk.page=page
 Connections {target:SoundDesk;function onPageChanged(){root.page=SoundDesk.page;}}
 function kind(){return page===0?"sinks":page===1?"sources":page===2?"sink-inputs":"source-outputs";}
 function nodes(){return page===0?SoundDesk.data.sinks:page===1?SoundDesk.data.sources.filter(n=>!n.name.endsWith('.monitor')):page===2?SoundDesk.data['sink-inputs']:SoundDesk.data['source-outputs'];}
 Column {width:parent.width;spacing:10
 Row {spacing:6;Repeater {model:["Outputs","Microphones","Applications","Capture apps","Devices","Channels"];ControlTile {required property string modelData;required property int index;implicitWidth:118;implicitHeight:30;label:modelData;navigation:true;selected:root.page===index;onActivated:root.page=index}}}
 Row {spacing:10;ControlTile {label:Audio.muted?"Unmute output":"Mute output";glyph:"\uf028";onActivated:if(Audio.sink?.audio)Audio.sink.audio.muted=!Audio.muted}ControlTile {label:Audio.micMuted?"Unmute microphone":"Mute microphone";glyph:"\uf130";onActivated:if(Audio.source?.audio)Audio.source.audio.muted=!Audio.micMuted}ControlTile {label:"Advanced mixer";glyph:"\uf1de";onActivated:Quickshell.execDetached(["pavucontrol"])} }
 Row {width:parent.width;spacing:10;Repeater {model:[{label:"Active output",kind:"sinks",name:SoundDesk.data.defaultSink},{label:"Active microphone",kind:"sources",name:SoundDesk.data.defaultSource}]
 ChamferPanel {required property var modelData;property var device:(SoundDesk.data[modelData.kind]||[]).find(n=>n.name===modelData.name)||{};width:(root.width-38)/2;height:62;fillColor:Theme.alpha(Theme.widgetSurface,.8);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 Column {anchors.fill:parent;anchors.margins:10;spacing:5;Text {text:modelData.label+" · "+(device.state||"ready");font.family:Appearance.font.data;font.pixelSize:10;color:Theme.widgetMuted}Text {width:parent.width;text:device.description||modelData.name||"No device";elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText}}
 }
 }}
 Flickable {width:parent.width;height:Math.max(88,Math.min(500,audioRows.height));clip:true;contentHeight:audioRows.height;ScrollBar.vertical:DeskScrollBar {}
 Column {id:audioRows;width:parent.width;spacing:10
 Repeater {model:root.page<4?SoundDesk.ids[root.kind()]:[]
 ChamferPanel {id:nodeRow;required property int modelData;property var node:SoundDesk.node(root.kind(),modelData);property bool stream:root.page>=2;property bool source:root.page===1||root.page===3;readonly property bool isDefault:!stream&&node.name===(source?SoundDesk.data.defaultSource:SoundDesk.data.defaultSink);property string volAction:stream?(source?"capturevolume":"appvolume"):(source?"micvolume":"volume");width:audioRows.width;height:164;fillColor:Theme.alpha(Theme.widgetSurface,.6);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 Column {anchors.fill:parent;anchors.margins:12;spacing:8
 Text {width:parent.width;text:nodeRow.node.properties?.['application.name']||nodeRow.node.description||nodeRow.node.name||"Audio stream";font.family:Appearance.font.data;font.pixelSize:14;color:Theme.widgetAccent;elide:Text.ElideRight}
 Text {width:parent.width;text:(nodeRow.isDefault?"Active device · ":"")+(nodeRow.node.properties?.['media.name']||nodeRow.node.sample_specification||"")+" · "+(nodeRow.node.state||"stream")+" · "+(nodeRow.node.channel_map||"");font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted;elide:Text.ElideRight}
 ControlSlider {title:nodeRow.source?"Input gain":"Volume";level:SoundDesk.level(nodeRow.node);maximum:nodeRow.source?200:150;onEdited:v=>SoundDesk.action(nodeRow.volAction,nodeRow.node.index,Math.round(v)+"%")}
 Row {spacing:7;ControlTile {implicitWidth:125;implicitHeight:28;label:nodeRow.node.mute?"Unmute":"Mute";onActivated:SoundDesk.action(nodeRow.stream?(nodeRow.source?"capturemute":"appmute"):(nodeRow.source?"micmute":"mute"),nodeRow.node.index,nodeRow.node.mute?"0":"1")}
 ControlTile {visible:!nodeRow.stream;implicitWidth:145;implicitHeight:28;label:nodeRow.isDefault?"Active device":"Use as default";selected:nodeRow.isDefault;onActivated:SoundDesk.action(nodeRow.source?"input":"output",nodeRow.node.name,"")}
 DeskComboBox {visible:nodeRow.stream;width:375;height:28;model:nodeRow.source?SoundDesk.routeInputs:SoundDesk.routeOutputs;currentIndex:model.findIndex(n=>n.index===nodeRow.node[nodeRow.source?"source":"sink"]);textRole:"description";onActivated:SoundDesk.action(nodeRow.source?"capture-route":"route",nodeRow.node.index,model[currentIndex].name);font.family:Appearance.font.data;font.pixelSize:11}
 }
 }
 }
 }
 Repeater {model:root.page===4?SoundDesk.ids.cards:[]
 Rectangle {id:profileRow;required property int modelData;property var node:SoundDesk.node("cards",modelData);property var choices:[];onNodeChanged:{const next=Object.keys(node.profiles??{}).filter(k=>node.profiles[k].available!=="no");if(JSON.stringify(next)!==JSON.stringify(choices))choices=next;}width:audioRows.width;height:97;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:12;spacing:10
 Text {width:parent.width;text:node.properties?.['device.description']||node.name||"Audio device";font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetAccent;elide:Text.ElideRight}
 DeskComboBox {width:parent.width;height:30;model:profileRow.choices;id:profileSelect;Component.onCompleted:currentIndex=profileRow.choices.indexOf(profileRow.node.active_profile);Connections {target:profileRow;function onNodeChanged(){profileSelect.currentIndex=profileRow.choices.indexOf(profileRow.node.active_profile);}} onActivated:SoundDesk.action("profile",node.name,model[currentIndex]);font.family:Appearance.font.data;font.pixelSize:11}
 }
 }
 }
 Repeater {model:root.page===4?SoundDesk.ids.ports:[]
 Rectangle {id:portRow;required property string modelData;property var node:SoundDesk.node(modelData.split(":")[0],parseInt(modelData.split(":")[1]));property var choices:[];onNodeChanged:{const next=Object.keys(node.ports??{});if(JSON.stringify(next)!==JSON.stringify(choices))choices=next;}width:audioRows.width;height:90;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:12;spacing:8;Text {width:parent.width;text:node.description+" · ports";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetAccent;elide:Text.ElideRight}DeskComboBox {width:parent.width;height:30;model:portRow.choices;id:portSelect;Component.onCompleted:currentIndex=portRow.choices.indexOf(portRow.node.active_port);Connections {target:portRow;function onNodeChanged(){portSelect.currentIndex=portRow.choices.indexOf(portRow.node.active_port);}} onActivated:SoundDesk.action(node._source?"inputport":"port",node.name,model[currentIndex]);font.family:Appearance.font.data;font.pixelSize:11}}
 }
 }
 Repeater {model:root.page===5?SoundDesk.ids.sinks:[]
 Rectangle {id:channelRow;required property int modelData;property var node:SoundDesk.node("sinks",modelData);property var channelKeys:[];onNodeChanged:{const next=Object.keys(node.volume??{});if(JSON.stringify(next)!==JSON.stringify(channelKeys))channelKeys=next;}width:audioRows.width;height:channelColumn.implicitHeight+24;color:Theme.alpha(Theme.widgetSurface,.6);border.color:Theme.widgetBorder
 Column {id:channelColumn;anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top;anchors.margins:12;spacing:10
 Text {width:parent.width;text:channelRow.node.description+" · channel balance";font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetAccent;elide:Text.ElideRight}
 Repeater {model:channelRow.channelKeys;ControlSlider {required property string modelData;title:modelData;level:parseInt(channelRow.node.volume[modelData].value_percent)||0;maximum:150;onEdited:v=>SoundDesk.channel(channelRow.node,modelData,v)}}
 }
 }
 }
 Text {visible:root.page>=2&&root.page<4&&root.nodes().length===0;text:"Sensei, no applications are using this audio direction right now.";font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted}
 }
 }
 Text {width:parent.width;text:SoundDesk.error||"Sensei, wheel the sound badge to adjust volume; right-click it to mute. Levels above 100% amplify audio.";font.family:Appearance.font.data;font.pixelSize:11;color:SoundDesk.error?Theme.widgetAccent:Theme.widgetMuted;wrapMode:Text.Wrap}
 }
}
