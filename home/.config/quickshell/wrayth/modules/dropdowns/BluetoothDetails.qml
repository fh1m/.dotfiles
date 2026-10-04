import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services
Column {
 id:root
 property var selectedDevice:null
 property var adapter:Bluetooth.defaultAdapter
 readonly property int page:BluetoothDesk.page
 readonly property string address:selectedDevice?.address||''
 readonly property var info:BluetoothDesk.device(address)
 readonly property var card:BluetoothDesk.card(address)
 readonly property var codec:BluetoothDesk.codec(address)
 readonly property var profiles:Object.entries(card.profiles||{}).map(([id,p])=>({id:id,description:p.description,available:p.available}))
 readonly property bool routed:(Audio.sink?.name||'').indexOf(address.replace(/:/g,'_'))>=0
 spacing:10
 Row {
  width:parent.width;spacing:6
  Repeater {model:[['Device','\uf2db'],['Audio','\uf028'],['Adapter','\uf294'],['Tools','\uf0ad']]
   ControlTile {required property var modelData;required property int index;width:(root.width-18)/4;label:modelData[0];glyph:modelData[1];selected:root.page===index;navigation:true;onActivated:BluetoothDesk.page=index}
  }
 }
 ChamferPanel {
  width:parent.width;height:root.page===0?250:root.page===1?326:root.page===2?226:218
  fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
  Column {anchors.fill:parent;anchors.margins:12;spacing:10
   Text {width:parent.width;text:root.page===0?(root.selectedDevice?.name||'Choose a device above'):root.page===1?'Music quality and routing':root.page===2?'Bluetooth controller':'Sensei, your Bluetooth toolbox';color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:14;font.bold:true;elide:Text.ElideRight}
   Text {width:parent.width;text:root.page===0?(root.info.Connected?'Connected · ':'Disconnected · ')+(root.info.Trusted?'trusted':'ask before reconnecting'):root.page===1?(root.codec.codec?root.codec.codec.toUpperCase()+' · '+(root.codec.formats?.[0]?.rate||'—')+' Hz · stereo':'No audio transport for this device'):root.page===2?'Intel AX200 · paired devices appear without a scan':'Diagnostics and recovery tools run only when requested.';color:Theme.widgetMuted;font.family:Appearance.font.data;font.pixelSize:12;wrapMode:Text.WordWrap}
   Column {width:parent.width;spacing:10;visible:root.page===0
    Text {width:parent.width;wrapMode:Text.WordWrap;text:`Address  ${root.address||'—'}\nBattery  ${root.info.battery===null||root.info.battery===undefined?'not reported':root.info.battery+'%'}   ·   Type  ${root.info.Icon||'Bluetooth device'}\nRadio  ${root.info.RSSI===undefined?'not reported':root.info.RSSI+' dBm (last discovery)'}   ·   Services  ${(root.info.UUIDs||[]).length}`;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;lineHeight:1.45}
    Row {width:parent.width;spacing:6
     ControlTile {width:(parent.width-12)/3;label:root.selectedDevice?.trusted?'Trusted':'Trust';glyph:'\uf00c';selected:root.selectedDevice?.trusted??false;enabled:!!root.selectedDevice;onActivated:root.selectedDevice.trusted=!root.selectedDevice.trusted}
     ControlTile {width:(parent.width-12)/3;label:root.info.WakeAllowed?'Wake on':'Wake off';glyph:'\uf0e7';selected:root.info.WakeAllowed??false;enabled:!!root.address&&!BluetoothDesk.busy;onActivated:BluetoothDesk.action('wake',root.address,root.info.WakeAllowed?'false':'true')}
     ControlTile {width:(parent.width-12)/3;label:root.selectedDevice?.blocked?'Unblock':'Block';glyph:'\uf05e';selected:root.selectedDevice?.blocked??false;enabled:!!root.selectedDevice;onActivated:root.selectedDevice.blocked=!root.selectedDevice.blocked}
    }
    Row {width:parent.width;spacing:6
     DeskTextField {id:aliasField;width:parent.width-90;placeholderText:'Device nickname';text:root.info.Alias||'';onAccepted:BluetoothDesk.action('alias',root.address,text)}
     ControlTile {width:84;label:'Save';glyph:'\uf0c7';enabled:!!root.address&&!BluetoothDesk.busy;onActivated:BluetoothDesk.action('alias',root.address,aliasField.text)}
    }
   }
   Column {width:parent.width;spacing:9;visible:root.page===1
    Text {width:parent.width;text:root.routed?(Cava.live?'♫ Music is flowing to this device':'Selected output · paused or quiet'):'This device is not the default audio output';font.family:Appearance.font.data;font.pixelSize:12;color:root.routed?Theme.widgetAccent:Theme.widgetMuted;wrapMode:Text.WordWrap}
    Flow {width:parent.width;spacing:6
     Repeater {model:root.profiles.filter(p=>p.id!=='off');ControlTile {required property var modelData;width:(root.width-36)/2;label:modelData.id.indexOf('sbc_xq')>=0?'SBC-XQ · experimental':modelData.id==='a2dp-sink'?'SBC · stereo':modelData.id.indexOf('headset')>=0?'Hands-free · microphone':modelData.description;detail:root.card.active_profile===modelData.id?'Active profile':'Choose profile';selected:root.card.active_profile===modelData.id;enabled:modelData.available&&!BluetoothDesk.busy;onActivated:BluetoothDesk.action('profile',root.address,modelData.id)}}
    }
    Row {width:parent.width;spacing:6
     ControlTile {width:(parent.width-6)/2;label:'Use as output';glyph:'\uf025';enabled:!!root.codec.node;selected:root.routed;onActivated:BluetoothDesk.tool(['pactl','set-default-sink',root.codec.node])}
     ControlTile {width:(parent.width-6)/2;label:Audio.muted?'Unmute':'Mute';glyph:'\uf028';enabled:root.routed;onActivated:if(Audio.sink?.audio)Audio.sink.audio.muted=!Audio.muted}
    }
    ControlSlider {visible:root.routed;title:'Headset volume';glyph:'\uf028';level:Audio.volume*100;maximum:100;onEdited:v=>{if(Audio.sink?.audio)Audio.sink.audio.volume=v/100}}
    Text {width:parent.width;wrapMode:Text.WordWrap;text:'Quality-first selection is enabled. This headset tested best with SBC; SBC-XQ produced packet drops. Hands-free trades stereo quality for microphone access. Bluetooth is lossy; unsupported codecs cannot be added by a setting.';font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted;lineHeight:1.35}
   }
   Column {width:parent.width;spacing:10;visible:root.page===2
    Text {width:parent.width;text:(BluetoothDesk.data.adapters?.[0]?.Address||'—')+' · '+(BluetoothDesk.data.adapters?.[0]?.PowerState||'off')+'\nDiscovery stops after 20 seconds or when this panel closes.';font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;wrapMode:Text.WordWrap;lineHeight:1.4}
    Row {width:parent.width;spacing:6
     ControlTile {width:(parent.width-12)/3;label:root.adapter?.enabled?'Power on':'Power off';glyph:'\uf011';selected:root.adapter?.enabled??false;onActivated:if(root.adapter)root.adapter.enabled=!root.adapter.enabled}
     ControlTile {width:(parent.width-12)/3;label:root.adapter?.discoverable?'Visible':'Hidden';glyph:'\uf06e';selected:root.adapter?.discoverable??false;onActivated:if(root.adapter){root.adapter.discoverableTimeout=180;root.adapter.discoverable=!root.adapter.discoverable}}
     ControlTile {width:(parent.width-12)/3;label:root.adapter?.pairable?'Pairing on':'Pairing off';glyph:'\uf0c1';selected:root.adapter?.pairable??false;onActivated:if(root.adapter)root.adapter.pairable=!root.adapter.pairable}
    }
    ControlTile {width:parent.width;label:root.adapter?.discovering?'Stop scanning':'Find nearby devices';glyph:'\uf002';selected:root.adapter?.discovering??false;onActivated:if(root.adapter)root.adapter.discovering=!root.adapter.discovering}
   }
   Column {width:parent.width;spacing:8;visible:root.page===3
    Row {width:parent.width;spacing:6
     ControlTile {width:(parent.width-6)/2;label:'Audio mixer';glyph:'\uf1de';onActivated:BluetoothDesk.tool(['pavucontrol'])}
     ControlTile {width:(parent.width-6)/2;label:'Controller status';glyph:'\uf120';onActivated:BluetoothDesk.tool(['sensei-terminal','--title','Bluetooth diagnostics','sh','-c','bluetoothctl show; printf "\\nPress Enter to close"; read line'])}
    }
    Row {width:parent.width;spacing:6
     ControlTile {width:(parent.width-6)/2;label:'Audio health';glyph:'\uf201';onActivated:BluetoothDesk.tool(['sensei-terminal','--title','Bluetooth audio health','pw-top'])}
     ControlTile {width:(parent.width-6)/2;label:'Refresh details';glyph:'\uf021';onActivated:BluetoothDesk.refresh()}
    }
    Text {width:parent.width;wrapMode:Text.WordWrap;text:'Sensei, use 5 GHz Wi-Fi for music. Your headset has a dedicated transport buffer; other devices keep their defaults. Disconnect pauses music intentionally. Pair, connect and forget controls remain in each device row.';font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted;lineHeight:1.4}
   }
  }
 }
 Text {width:parent.width;visible:BluetoothDesk.error!=='';text:BluetoothDesk.error;wrapMode:Text.WordWrap;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetAccent}
}
