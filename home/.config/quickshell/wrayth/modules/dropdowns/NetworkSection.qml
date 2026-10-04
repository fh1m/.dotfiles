import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.utils
Column {
 id:root;width:parent.width;spacing:10
 readonly property int page:DesktopExtras.networkPage
 function action(name,value=''){Quickshell.execDetached(['sensei-terminal','--title','Sensei · Network','/home/fh1m/.local/bin/sensei-network-action',name,value]);}
 Component.onCompleted:DesktopExtras.loadNetwork()
 Row {spacing:7
  ControlTile {implicitWidth:170;label:'Wi-Fi';navigation:true;selected:DesktopExtras.networkPage===0;onActivated:DesktopExtras.networkPage=0}
  ControlTile {implicitWidth:170;label:'Connections / SSH';navigation:true;selected:DesktopExtras.networkPage===1;onActivated:DesktopExtras.networkPage=1}
  ControlTile {implicitWidth:170;label:'Diagnostics';navigation:true;selected:DesktopExtras.networkPage===2;onActivated:{DesktopExtras.networkPage=2;DesktopExtras.loadNetwork();}}
 }
 Text {width:parent.width;text:(Wifi.activeSsid|| (Wifi.wired?'Ethernet':'Disconnected'))+' ['+SysInfo.netInterfaces+']'+'  ·  ↑ '+Fmt.rateLong(SysInfo.netTxRate)+'  ↓ '+Fmt.rateLong(SysInfo.netRxRate);font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetAccent;elide:Text.ElideRight}
 ScrollView {width:parent.width;height:Math.min(550,wifiPanel.implicitHeight);clip:true;visible:DesktopExtras.networkPage===0
  WifiDropdown {id:wifiPanel;width:root.width;implicitWidth:root.width}
 }
 Column {width:parent.width;spacing:10;visible:DesktopExtras.networkPage===1
  Text {width:parent.width;text:'SSH server: '+(DesktopExtras.network.ssh||'unknown');color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:13}
  DeskTextField {placeholderTextColor:Theme.widgetMuted;selectionColor:Theme.widgetAccent;selectedTextColor:Theme.widgetText;id:host;width:parent.width;height:38;placeholderText:'user@robot.local or ~/.ssh/config alias';color:Theme.widgetText;font.family:Appearance.font.data;font.pixelSize:12;}
  Grid {columns:3;spacing:7
   ControlTile {implicitWidth:175;label:'SSH connect';enabled:!!host.text;onActivated:root.action('ssh',host.text.trim())}
   ControlTile {implicitWidth:175;label:'Ping host';enabled:!!host.text;onActivated:root.action('ping',host.text.trim())}
   ControlTile {implicitWidth:175;label:'SSH config';onActivated:root.action('ssh-config')}
   ControlTile {implicitWidth:175;label:'Start SSH server';onActivated:root.action('ssh-on')}
   ControlTile {implicitWidth:175;label:'Stop SSH server';onActivated:root.action('ssh-off')}
   ControlTile {implicitWidth:175;label:'Firewall status';onActivated:root.action('firewall')}
   ControlTile {implicitWidth:175;label:'Profiles / VPN / IP';onActivated:root.action('connections')}
   ControlTile {implicitWidth:175;label:'Refresh';onActivated:DesktopExtras.loadNetwork()}
   ControlTile {implicitWidth:175;label:'Server SSH config';onActivated:root.action('ssh-edit')}
   ControlTile {implicitWidth:175;label:'VPN / profile editor';onActivated:root.action('vpn')}
   ControlTile {implicitWidth:175;label:'Validate SSH config';onActivated:root.action('ssh-check')}
   ControlTile {implicitWidth:175;label:'Reload SSH server';onActivated:root.action('ssh-reload')}
  }
  Row {spacing:7
   DeskTextField {placeholderTextColor:Theme.widgetMuted;selectionColor:Theme.widgetAccent;selectedTextColor:Theme.widgetText;id:port;width:110;height:36;placeholderText:'Port';color:Theme.widgetText;validator:IntValidator {bottom:1;top:65535} }
   ControlTile {implicitWidth:100;label:'Allow';enabled:port.acceptableInput;onActivated:root.action('allow-port',port.text)}
   ControlTile {implicitWidth:100;label:'Deny';enabled:port.acceptableInput;onActivated:root.action('deny-port',port.text)}
   ControlTile {implicitWidth:100;label:'Firewall on';onActivated:root.action('firewall-on')}
   ControlTile {implicitWidth:100;label:'Firewall off';onActivated:root.action('firewall-off')}
  }
  ScrollView {width:parent.width;height:240;clip:true
   TextArea {readOnly:true;wrapMode:Text.Wrap;textFormat:TextEdit.PlainText;text:'Active connections\n'+(DesktopExtras.network.connections||'None')+'\n\nInterfaces\n'+(DesktopExtras.network.addresses||'');font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;background:ChamferPanel {fillColor:Theme.widgetSurface;chamfer:6;scanlines:false}}
  }
 }
 ScrollView {width:parent.width;height:550;clip:true;visible:DesktopExtras.networkPage===2
  TextArea {readOnly:true;wrapMode:Text.Wrap;textFormat:TextEdit.PlainText;text:'Routes\n'+(DesktopExtras.network.routes||'')+'\n\nDNS\n'+(DesktopExtras.network.dns||'')+'\n\nListening ports\n'+(DesktopExtras.network.listeners||'');font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;background:ChamferPanel {fillColor:Theme.widgetSurface;chamfer:6;scanlines:false}}
 }
}
