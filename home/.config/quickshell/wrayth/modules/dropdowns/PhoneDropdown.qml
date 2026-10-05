import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root
 title:"\uf10b Phone";katakana:"СВЯЗЬ"
 greeting:PhoneBridge.ready?"Sensei, your A52 is connected. Clipboard, files and remote control are within reach.":"Sensei, your A52 connection and permissions are managed here."
 implicitWidth:1040
 property int page:PhoneBridge.page
 onPageChanged:PhoneBridge.page=page
 IpcHandler {target:"phonepanel";function page(index:int):void{root.page=Math.max(0,Math.min(8,index));}function layout():string{let rows=[];function walk(n){if(n.visible===false)return;if(n.text){let p=n.mapToItem(root,0,0);rows.push({text:n.text.slice(0,60),x:p.x,y:p.y,w:n.width,h:n.height});}for(let c of n.children||[])walk(c);}walk(root);return JSON.stringify({height:root.height,rows:rows});}}
 readonly property var device:PhoneBridge.device
 readonly property var state:PhoneBridge.data
 readonly property bool ready:PhoneBridge.ready
 property string adbSerial:""
 property bool mirrorAudio:false
 property string fileMode:"kde"
 property string rsyncDestination:"~/storage/downloads/"
 readonly property var androidPeers:(root.state.vpn?.peers||[]).filter(p=>p.os==="android")
 property string taildropIp:""
 function chooseFile(mode){fileMode=mode;sendFile.open();}
 function act(name,args){PhoneBridge.action(name,args||[]);}
 function size(v){return v>=1073741824?(v/1073741824).toFixed(2)+" GiB":v>=1048576?(v/1048576).toFixed(1)+" MiB":Math.round(v||0)+" B";}
 FileDialog {id:sendFile;title:"Sensei, choose a file for Phone";onVisibleChanged:ShellState.externalDialogOpen=visible;onAccepted:{let f=decodeURIComponent(String(selectedFile).replace(/^file:\/\//,""));if(root.fileMode==="taildrop")root.act("taildrop-send",[f,root.taildropIp||root.androidPeers[0]?.ips[0]||""]);else if(root.fileMode==="rsync")root.act("rsync-send",[f,root.rsyncDestination]);else root.act("send-file",[f]);}onRejected:ShellState.externalDialogOpen=false}
 Column {width:parent.width;spacing:9
  Row {width:parent.width;spacing:8
   DeskComboBox {width:300;height:32;model:PhoneBridge.devices;textRole:"name";currentIndex:Math.max(0,PhoneBridge.devices.findIndex(d=>d.id===PhoneBridge.selectedId));onActivated:PhoneBridge.selectedId=PhoneBridge.devices[currentIndex].id}
   Text {anchors.verticalCenter:parent.verticalCenter;text:root.ready?"● Connected · "+(root.device.battery?.charge>=0?root.device.battery.charge+"% "+(root.device.battery.isCharging?"charging":"battery"):"battery pending"):root.device.id?(root.device.isPaired?"Offline":"Pairing required"):"Searching for your A52";font.family:Appearance.font.ui;font.pixelSize:12;color:root.ready?Theme.widgetAccent:Theme.widgetMuted}
   ControlTile {label:"Refresh";glyph:"\uf021";implicitWidth:100;implicitHeight:30;enabled:true;onActivated:{root.act("refresh");PhoneBridge.refresh();}}
   ControlTile {label:root.device.isPairRequestedByPeer?"Accept pairing":"Pair";glyph:"\uf0c1";implicitWidth:112;implicitHeight:30;visible:!root.device.isPaired;enabled:!!root.device.id;onActivated:root.act(root.device.isPairRequestedByPeer?"accept":"pair")}
  }
  Row {spacing:6;Repeater {model:["Overview","Clipboard","Files","Notifications","Calls / SMS","Control / SSH","Sync","Connection","Setup"];ControlTile {required property string modelData;required property int index;label:modelData;implicitWidth:107;implicitHeight:30;navigation:true;selected:root.page===index;onActivated:root.page=index}}}
  Flickable {id:scroll;width:parent.width;height:240;contentHeight:body.height;clip:true;boundsBehavior:Flickable.StopAtBounds;ScrollBar.vertical:DeskScrollBar {}
   Column {id:body;width:parent.width;spacing:12
    Loader { width:parent.width; active:root.page===0; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:12
     Row {width:parent.width;spacing:12
      ChamferPanel {width:316;height:126;scanlines:false;chamfer:10;fillColor:Theme.widgetSurface;borderColor:Theme.alpha(Theme.widgetText,.08)
       Column {x:14;y:12;width:parent.width-28;spacing:10
        Text {text:(root.device.name||"Samsung A52");font.family:Appearance.font.ui;font.pixelSize:17;font.bold:true;color:Theme.widgetText}
        Text {text:root.device.isPaired?"Trusted device · "+(root.device.isReachable?"reachable":"offline"):"Not paired · accept on your A52";font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
        Text {width:parent.width;text:(root.device.reachableAddresses||[]).join("\n")||"Waiting for discovery";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetAccent;wrapMode:Text.Wrap}
        Text {text:(root.device.activeProviderNames||[]).join(" · ")+" · "+(root.device.connectivity?.cellularNetworkType||"cellular unknown");font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
       }
      }
      ChamferPanel {width:316;height:126;scanlines:false;chamfer:10;fillColor:Theme.widgetSurface;borderColor:Theme.alpha(Theme.widgetText,.08)
       Column {x:14;y:12;width:parent.width-28;spacing:10
        Text {text:"Across networks";font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
        Text {text:"Tailscale · "+(root.state.vpn?.state||"Loading");font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetAccent}
        Text {width:parent.width;text:(root.state.vpn?.ips||[]).join("\n")||"Sign in from Connection";font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted;wrapMode:Text.Wrap}
        Text {text:"Private connection · no router port forwarding";font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.widgetMuted}
       }
      }
      ChamferPanel {width:parent.width-656;height:126;scanlines:false;chamfer:10;fillColor:Theme.widgetSurface;borderColor:Theme.alpha(Theme.widgetText,.08)
       Column {x:14;y:12;spacing:10
        Text {text:"Robotics handoff";font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
        Text {text:"Models · transfer inbox · remote commands";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
        ControlTile {label:"Open Phone folders";glyph:"\uf07c";implicitWidth:240;onActivated:Quickshell.execDetached(["xdg-open","/home/fh1m/Phone"])}
       }
      }
     }
     Row {width:parent.width;spacing:8
      ControlTile {label:root.ready?"KDE Connect · online":"KDE Connect · offline";glyph:"\uf0ac";implicitWidth:220;implicitHeight:34;selected:root.ready;onActivated:PhoneBridge.refresh()}
      ControlTile {label:PhoneBridge.phoneNearby?"Bluetooth · nearby":"Bluetooth · disconnected";glyph:"\uf293";implicitWidth:230;implicitHeight:34;selected:PhoneBridge.phoneNearby;onActivated:{if(PhoneBridge.phoneBluetooth&&!PhoneBridge.phoneNearby)PhoneBridge.phoneBluetooth.connect();else ShellState.dropdown="bluetooth";}}
      ControlTile {label:(root.state.adb||[]).some(d=>d.state==="device")?"USB debug · ready":"USB debug · unavailable";glyph:"\uf287";implicitWidth:230;implicitHeight:34;selected:(root.state.adb||[]).some(d=>d.state==="device");onActivated:root.page=5}
      Text {anchors.verticalCenter:parent.verticalCenter;text:PhoneBridge.phoneBluetooth?.batteryAvailable?Math.round(PhoneBridge.phoneBluetooth.battery*100)+"% phone battery":"";font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
     }
     Flow {width:parent.width;spacing:8
      ControlTile {label:"Find my phone";glyph:"\uf0f3";enabled:root.ready;onActivated:root.act("ring")}
      ControlTile {label:"Send clipboard";glyph:"\uf0ea";enabled:root.ready;onActivated:root.act("clipboard")}
      ControlTile {label:"Send a file";glyph:"\uf093";enabled:root.ready;onActivated:root.chooseFile("kde")}
      ControlTile {label:"Browse phone";glyph:"\uf07c";enabled:root.ready;onActivated:{root.page=2;root.act("browse");}}
      ControlTile {label:"Messages";glyph:"\uf075";enabled:root.ready;onActivated:Quickshell.execDetached(["kdeconnect-sms"])}
     }
     Text {width:parent.width;text:"Sensei, pairing protects the connection. Only the phone folders and features you authorize are accessible. Calls are shown as notifications; KDE Connect does not route cellular call audio through this laptop.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;lineHeight:1.3;color:Theme.widgetMuted}
    } } }
    Loader { width:parent.width; active:root.page===1; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:10
     Text {text:"Text, links and the clipboard";font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
     DeskTextArea {id:shareText;text:PhoneBridge.clipboardDraft;onTextChanged:PhoneBridge.clipboardDraft=text;width:parent.width;height:126;placeholderText:"Write text, paste a command or share a documentation link with your A52…"}
     Flow {width:parent.width;spacing:8
      ControlTile {label:"Send this text";glyph:"\uf1d8";enabled:root.ready&&shareText.text.trim()!=="";onActivated:root.act("send-text",[shareText.text])}
      ControlTile {label:"Open link on phone";glyph:"\uf0ac";enabled:root.ready&&/^https?:\/\//.test(shareText.text.trim());onActivated:root.act("send-url",[shareText.text.trim()])}
      ControlTile {label:"Send desktop clipboard";glyph:"\uf0ea";enabled:root.ready;onActivated:root.act("clipboard")}
      ControlTile {label:"Clipboard vault";glyph:"\uf187";onActivated:ShellState.toggleDropdown("clipboard")}
     }
     Text {width:parent.width;text:"Android restricts background clipboard reads. Use Send clipboard in the Android KDE Connect notification or keep it foreground. Received text enters your desktop clipboard and existing clipboard vault; images/files use Files.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
    } } }
    Loader { width:parent.width; active:root.page===2; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:10
     Flow {width:parent.width;spacing:8
      ControlTile {label:"Choose file / model";glyph:"\uf093";enabled:root.ready;onActivated:root.chooseFile("kde")}
      ControlTile {label:root.state.sshMounted?"SSH files · mounted":"Mount SSH files";glyph:"\uf07c";enabled:root.state.sshKeyExists;onActivated:root.act("ssh-mount")}
      ControlTile {label:"Open SSH files";glyph:"\uf07c";enabled:root.state.sshMounted;onActivated:Quickshell.execDetached(["xdg-open","/home/fh1m/Phone/Browse"])}
      ControlTile {label:"Unmount SSH files";enabled:root.state.sshMounted;onActivated:root.act("ssh-unmount")}
      ControlTile {label:"Mount phone folders";glyph:"\uf07c";enabled:root.ready;onActivated:root.act("browse")}
      ControlTile {label:"Refresh folders";glyph:"\uf021";onActivated:PhoneBridge.refresh()}
      ControlTile {label:"Transfer inbox";glyph:"\uf019";onActivated:Quickshell.execDetached(["xdg-open","/home/fh1m/Downloads"])}
     }
     Flow {width:parent.width;spacing:8
      ControlTile {label:"Send through Taildrop";glyph:"\uf0ac";implicitWidth:220;enabled:root.androidPeers.length>0;onActivated:root.chooseFile("taildrop")}
      ControlTile {label:"Collect Taildrop inbox";glyph:"\uf019";implicitWidth:220;enabled:root.state.vpn?.state==="Running";onActivated:root.act("taildrop-receive")}
      ControlTile {label:"Upload through rsync";glyph:"\uf093";implicitWidth:220;enabled:!!root.state.config?.host;onActivated:root.chooseFile("rsync")}
     }
     Row {spacing:8;DeskComboBox {width:350;height:34;model:root.androidPeers;textRole:"name";onActivated:root.taildropIp=model[currentIndex].ips.find(ip=>ip.indexOf(":")<0)||model[currentIndex].ips[0]}DeskTextField {id:rsyncDest;onTextChanged:root.rsyncDestination=text;width:500;placeholderText:"Termux destination directory";text:root.rsyncDestination}}
     Text {width:parent.width;text:"Taildrop transfers work independently of KDE Connect when the Android peer is online. Rsync resumes efficiently over your verified Termux SSH connection; it requires rsync on the phone and access to the chosen destination.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
     Repeater {model:root.state.jobs||[]
      ChamferPanel {required property var modelData;width:body.width;height:94;scanlines:false;chamfer:7;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
       Text {x:12;y:9;width:parent.width-160;text:modelData.label+" · "+modelData.state;font.family:Appearance.font.ui;font.pixelSize:13;font.bold:true;color:modelData.state==="failed"?Theme.widgetAccent:Theme.widgetText;elide:Text.ElideRight}
       Flickable {x:12;y:32;width:parent.width-24;height:50;clip:true;contentHeight:jobText.implicitHeight;Text {id:jobText;width:parent.width;text:modelData.output||modelData.error||"Waiting for transfer output…";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;textFormat:Text.PlainText;wrapMode:Text.Wrap}}
       ControlTile {anchors.right:parent.right;anchors.rightMargin:10;y:5;label:"Cancel";implicitWidth:110;implicitHeight:28;visible:modelData.state==="running";enabled:true;onActivated:root.act("cancel-transfer",[modelData.id])}
      }
     }
     Repeater {model:Object.entries(root.device.directories||{});ControlTile {required property var modelData;label:modelData[0];detail:modelData[1];glyph:"\uf07c";implicitWidth:440;implicitHeight:48;onActivated:Quickshell.execDetached(["xdg-open",String(modelData[1])])}}
     Text {width:parent.width;text:Object.keys(root.device.directories||{}).length?"Browse opens the mounted folder in your file manager, with native image previews and file operations.":"Enable Filesystem expose on your A52, then select folders in Android’s file picker. Mount here and refresh. Android app-private files remain protected.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted}
     Text {width:parent.width;text:"For repeatable model delivery, use Sync with ~/Phone/Models. For arbitrary Termux files and robotics commands, set up SSH under Control. No entire home directory is synchronized.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
    } } }
    Loader { width:parent.width; active:root.page===3; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:10
     Row {spacing:8;DeskTextField {id:notificationSearch;text:PhoneBridge.notificationQuery;onTextChanged:PhoneBridge.notificationQuery=text;width:380;placeholderText:"Filter notifications · app, title, message"}DeskTextField {id:reply;text:PhoneBridge.replyDraft;onTextChanged:PhoneBridge.replyDraft=text;width:624;placeholderText:"Reply text for a notification that supports replies"}}
     ListView {id:phoneNotifications;width:parent.width;height:254;clip:true;spacing:10;reuseItems:true;cacheBuffer:80;model:(PhoneBridge.notificationRows).filter(n=>!notificationSearch.text||((n.appName||"")+" "+(n.title||"")+" "+(n.text||"")).toLowerCase().indexOf(notificationSearch.text.toLowerCase())>=0)
      delegate:ChamferPanel {id:notificationCard;property bool expanded:false;required property var modelData;width:phoneNotifications.width;height:notificationText.implicitHeight+72;scanlines:false;chamfer:8;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
       Image {x:12;y:12;width:36;height:36;sourceSize.width:72;sourceSize.height:72;source:modelData.iconPath?"file://"+modelData.iconPath:"";fillMode:Image.PreserveAspectFit}
       Text {id:notificationText;x:60;y:10;width:parent.width-74;text:Notifications.safeBody((modelData.appName||"Phone")+" · "+(modelData.title||"")+"\n"+(modelData.text||modelData.ticker||""));textFormat:Text.RichText;wrapMode:Text.Wrap;maximumLineCount:notificationCard.expanded?1000:6;elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:13;lineHeight:1.3;color:Theme.widgetText}
       Row {x:60;y:notificationText.height+20;spacing:8
        ControlTile {label:notificationCard.expanded?"Less":"More";implicitWidth:80;implicitHeight:30;onActivated:notificationCard.expanded=!notificationCard.expanded}
        ControlTile {label:"Dismiss";implicitWidth:112;implicitHeight:30;enabled:modelData.dismissable;onActivated:root.act("notification-dismiss",[modelData.path])}
        ControlTile {label:"Send reply";implicitWidth:130;implicitHeight:30;enabled:!!modelData.replyId&&reply.text.trim()!=="";onActivated:root.act("notification-reply",[modelData.path,reply.text])}
       }
      }
     }
     Text {visible:!(PhoneBridge.notificationRows).length;width:parent.width;text:"No phone notifications available. Pair first and grant notification access to KDE Connect on your A52. New notifications update this panel through D-Bus without polling.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted}
    } } }
    Loader { width:parent.width; active:root.page===4; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:12
     Text {text:"Messages and incoming calls";font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
     ControlTile {label:"Open message conversations";glyph:"\uf075";implicitWidth:290;enabled:root.ready;onActivated:Quickshell.execDetached(["kdeconnect-sms"])}
     ControlTile {label:"Notification / call feed";glyph:"\uf095";implicitWidth:290;onActivated:root.page=3}
     Text {width:parent.width;text:"The KDE Connect message app provides conversations, contact selection and SMS composition. Sending a message remains an explicit action there. Grant SMS/contact permissions on Android. Incoming calls and supported notification replies appear in Notifications; answering a cellular call with laptop audio is not provided by KDE Connect.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;lineHeight:1.35;color:Theme.widgetMuted}
    } } }
    Loader { width:parent.width; active:root.page===5; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:10
     Row {spacing:8;ControlTile {label:root.state.remoteInput?"Disable phone mouse / keyboard":"Enable phone mouse / keyboard";glyph:"\uf11c";implicitWidth:315;enabled:root.ready;selected:!!root.state.remoteInput;onActivated:root.act("remote-input",[root.state.remoteInput?"off":"on"])}Text {anchors.verticalCenter:parent.verticalCenter;text:root.state.remoteInput?"Allowed for this login · turn off to end sessions":"Off · enable before using Remote input on the A52";font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}}
     Text {text:"Screen control · authorized Android debugging";font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
     Row {spacing:8
      DeskComboBox {id:adbChoice;width:470;height:34;model:root.state.adb||[];textRole:"detail";onActivated:root.adbSerial=model[currentIndex].serial}
      ControlTile {label:"Mirror / control";glyph:"\uf108";implicitWidth:180;enabled:(root.state.adb||[]).some(d=>d.state==="device");onActivated:root.act("mirror",[root.adbSerial||(root.state.adb||[]).find(d=>d.state==="device")?.serial||"",root.mirrorAudio?"audio":"silent"])}
      ControlTile {label:"Live rear camera";glyph:"\uf030";implicitWidth:180;enabled:(root.state.adb||[]).some(d=>d.state==="device");onActivated:Quickshell.execDetached(["scrcpy","-s",root.adbSerial||(root.state.adb||[]).find(d=>d.state==="device")?.serial||"","--video-source=camera","--camera-facing=back","--no-audio","--max-size=1280"])}
     }
     ControlTile {label:root.mirrorAudio?"Mirror phone audio: on":"Mirror phone audio: off";glyph:"\uf028";selected:root.mirrorAudio;implicitWidth:260;implicitHeight:30;onActivated:root.mirrorAudio=!root.mirrorAudio}
     Row {spacing:8;DeskTextField {id:adbHost;width:310;placeholderText:"Private IP:port · Wireless debugging"}DeskTextField {id:adbCode;width:145;placeholderText:"Pairing code";echoMode:TextInput.Password}ControlTile {label:"Pair debugging";implicitWidth:175;enabled:adbHost.text!==""&&adbCode.text!=="";onActivated:root.act("adb-pair",[adbHost.text,adbCode.text])}ControlTile {label:"Connect";implicitWidth:118;enabled:adbHost.text!=="";onActivated:root.act("adb-connect",[adbHost.text])}}
     Text {width:parent.width;text:"USB debugging needs your A52’s authorization. Wireless debugging uses different pairing and connection ports. Across networks it also depends on Android keeping that service enabled; Termux SSH is the more dependable robotics path. No public ADB port is opened here.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
     Text {text:"Phone media player";font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
     Row {spacing:10
      Image {width:64;height:64;sourceSize.width:128;sourceSize.height:128;source:root.device.media?.localAlbumArtUrl||"";fillMode:Image.PreserveAspectFit}
      Column {spacing:8;width:body.width-74
       Text {width:parent.width;text:(root.device.media?.title||"No phone media session")+" · "+(root.device.media?.artist||"");elide:Text.ElideRight;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText}
       Row {spacing:7;DeskComboBox {width:225;height:32;model:root.device.media?.playerList||[];onActivated:root.act("phone-player",[model[currentIndex]])}ControlTile {label:"Previous";implicitWidth:100;implicitHeight:30;enabled:!!root.device.media?.player;onActivated:root.act("phone-media",["Previous"])}ControlTile {label:root.device.media?.isPlaying?"Pause":"Play";implicitWidth:90;implicitHeight:30;enabled:!!root.device.media?.player;onActivated:root.act("phone-media",["PlayPause"])}ControlTile {label:"Next";implicitWidth:90;implicitHeight:30;enabled:!!root.device.media?.player;onActivated:root.act("phone-media",["Next"])}ControlTile {label:"Vol −";implicitWidth:85;implicitHeight:30;enabled:!!root.device.media?.player;onActivated:root.act("phone-volume",[String(Math.max(0,(root.device.media?.volume||0)-5))])}ControlTile {label:"Vol +";implicitWidth:85;implicitHeight:30;enabled:!!root.device.media?.player;onActivated:root.act("phone-volume",[String(Math.min(100,(root.device.media?.volume||0)+5))])}}
      }
     }
     Text {text:"Termux SSH · remote robotics workbench";font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
     Row {spacing:8;DeskTextField {id:sshHost;width:260;placeholderText:"Phone Tailscale IP / hostname";Component.onCompleted:text=PhoneBridge.data.config?.host||root.androidPeers[0]?.ips.find(ip=>ip.indexOf(":")<0)||""}DeskTextField {id:sshUser;width:160;placeholderText:"Termux username";Component.onCompleted:text=PhoneBridge.data.config?.user||""}DeskTextField {id:sshPort;width:80;placeholderText:"8022";text:"8022";Component.onCompleted:text=String(PhoneBridge.data.config?.port||8022)}ControlTile {label:"Save target";implicitWidth:140;enabled:true;onActivated:root.act("save-ssh",[sshHost.text,sshUser.text,sshPort.text])}ControlTile {label:"Trust / shell";implicitWidth:155;enabled:!!root.state.config?.host;onActivated:root.act("ssh-trust")}}
     Row {spacing:8;ControlTile {label:"Create Phone SSH key";glyph:"\uf084";implicitWidth:240;enabled:!root.state.sshKeyExists;onActivated:root.act("ssh-key")}ControlTile {label:"Install public key on Phone";implicitWidth:275;enabled:!!root.state.sshKeyExists&&!!root.state.config?.host;onActivated:root.act("ssh-install-key")}}
     Row {spacing:8;DeskTextField {id:remoteCmd;text:PhoneBridge.commandDraft;onTextChanged:PhoneBridge.commandDraft=text;width:630;placeholderText:"Explicit remote command · e.g. df -h; uname -a"}ControlTile {label:"Run on Phone";glyph:"\uf120";implicitWidth:180;enabled:!!root.state.config?.host&&remoteCmd.text.trim()!=="";onActivated:root.act("ssh-run",[remoteCmd.text])}}
     Repeater {model:root.device.commands||[];ControlTile {required property var modelData;label:modelData.name||modelData.id;detail:"Configured phone command";implicitWidth:360;enabled:root.ready;onActivated:root.act("command",[modelData.id])}}
    } } }
    Loader { width:parent.width; active:root.page===6; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:10
     Text {width:parent.width;text:"Syncthing device ID · "+(root.state.sync?.deviceId||"Loading");wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetAccent}
     Flow {width:parent.width;spacing:8
      ControlTile {label:"Sync settings / pair phone";glyph:"\uf021";implicitWidth:258;onActivated:Quickshell.execDetached(["xdg-open","http://127.0.0.1:8384"])}
      ControlTile {label:"Create Models folder";implicitWidth:220;enabled:!(root.state.sync?.folders||[]).some(f=>f.id==="sensei-phone-models");onActivated:root.act("sync-folder",["models"])}
      ControlTile {label:"Create Transfers folder";implicitWidth:220;enabled:!(root.state.sync?.folders||[]).some(f=>f.id==="sensei-phone-transfers");onActivated:root.act("sync-folder",["transfers"])}
     }
     Repeater {model:root.state.sync?.folders||[]
      ChamferPanel {required property var modelData;width:body.width;height:78;scanlines:false;chamfer:8;fillColor:Theme.widgetSurface;borderColor:Theme.alpha(Theme.widgetText,.08)
       Column {x:12;y:10;spacing:8;Text {text:modelData.label+" · "+(modelData.paused?"paused":modelData.state||"unknown");font.family:Appearance.font.ui;font.pixelSize:14;font.bold:true;color:Theme.widgetText}Text {text:modelData.path+" · "+(modelData.files||0)+" files · "+root.size(modelData.bytes)+" · pending "+root.size(modelData.needBytes)+" · errors "+(modelData.errors||0);font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}}
       ControlTile {anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;label:modelData.paused?"Resume":"Pause";implicitWidth:110;enabled:true;onActivated:root.act("sync-pause",[modelData.id,String(!modelData.paused)])}
      }
     }
     Text {width:parent.width;text:(root.state.sync?.error||"")+"\nOnly selected folders synchronize after you pair the Android Syncthing device ID. Syncthing can relay encrypted transfers across the internet; Models and Transfers keep ten previous versions when created here. Use Termux’s native Syncthing or an Android client from Syncthing’s community list.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
     Row {spacing:8;ControlTile {label:"Refresh phone sync";glyph:"\uf021";implicitWidth:220;enabled:root.state.sshKeyExists;onActivated:root.act("phone-sync-status")}Text {anchors.verticalCenter:parent.verticalCenter;text:root.state.phoneSync?.connected?"Phone sync · connected":"Phone sync · refresh for status";font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}}
     Repeater {model:root.state.phoneSync?.folders||[];ControlTile {required property var modelData;label:"Phone · "+modelData.label;detail:modelData.paused?"Paused · click to resume":"Ready · click to pause";implicitWidth:420;implicitHeight:46;selected:!modelData.paused;onActivated:root.act("phone-sync-pause",[modelData.id,String(!modelData.paused)])}}
    } } }
    Loader { width:parent.width; active:root.page===7; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:10
     Text {width:parent.width;text:"KDE Connect route · "+((root.device.reachableAddresses||[]).some(ip=>ip.indexOf("100.")===0)?"private Tailscale link":root.device.isReachable?"local LAN link — remote route still needs verification":"offline")+" · "+(root.device.reachableAddresses||[]).join(" / ");font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetAccent;wrapMode:Text.Wrap}
     Text {width:parent.width;text:"Tailscale · "+(root.state.vpn?.state||"Loading")+" · laptop "+(root.state.vpn?.ips||[]).join(" / ");wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:14;font.bold:true;color:Theme.widgetText}
     Flow {width:parent.width;spacing:8
      ControlTile {label:root.state.vpn?.state==="Running"?"Mesh connected":"Sign in / connect";glyph:"\uf0ac";implicitWidth:220;enabled:root.state.vpn?.state!=="Running";onActivated:root.act("vpn-login")}
      ControlTile {label:"Open sign-in page";implicitWidth:205;enabled:!!root.state.vpn?.authUrl;onActivated:Quickshell.execDetached(["xdg-open",root.state.vpn.authUrl])}
      ControlTile {label:"Disconnect mesh";implicitWidth:190;enabled:root.state.vpn?.state==="Running";onActivated:root.act("vpn-disconnect")}
      ControlTile {label:"Test private tunnel";implicitWidth:190;enabled:root.androidPeers.length>0;onActivated:root.act("vpn-test")}
      ControlTile {label:"Tailscale devices";implicitWidth:190;onActivated:Quickshell.execDetached(["xdg-open","https://login.tailscale.com/admin/machines"])}
     }
     Repeater {model:root.state.vpn?.peers||[];Text {required property var modelData;width:body.width;text:(modelData.online?"● ":"○ ")+modelData.name+" · "+modelData.os+" · "+modelData.ips.join(" / ")+"\n"+(modelData.address?"Direct path "+modelData.address:"Relay / idle: "+(modelData.relay||"not established"));font.family:Appearance.font.ui;font.pixelSize:12;color:modelData.online?Theme.widgetText:Theme.widgetMuted;wrapMode:Text.Wrap}}
     Row {spacing:8;DeskTextField {id:phoneIp;width:440;placeholderText:"Phone’s private Tailscale IP · 100.x.x.x"}ControlTile {label:"Add phone address";implicitWidth:220;enabled:phoneIp.text!=="";onActivated:root.act("add-address",[phoneIp.text])}}
     Text {width:parent.width;text:"Android tailnet addresses are added to desktop KDE Connect discovery when Phone refreshes. On your A52: KDE Connect → Add devices by IP → add this laptop’s 100.x address. Both Tailscale apps must be connected to the same account/tailnet. Internet availability alone is not enough without the VPN and Android permissions.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
     Row {spacing:8;ControlTile {label:"Enable laptop Tailscale SSH";implicitWidth:285;enabled:root.state.vpn?.state==="Running";onActivated:root.act("vpn-ssh",["on"])}ControlTile {label:"Disable Tailscale SSH";implicitWidth:230;enabled:true;onActivated:root.act("vpn-ssh",["off"])}}
     Text {width:parent.width;text:"Tailscale SSH controls access through your tailnet policy; it does not enable a public OpenSSH listener. Use it from Termux on the phone to access this laptop.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
    } } }
    Loader { width:parent.width; active:root.page===8; visible:active; asynchronous:true; sourceComponent:Component { Column {width:parent.width;spacing:12
     Text {width:parent.width;text:"Sensei, finish these once on your Samsung A52:\n\n1  Pair KDE Connect and compare the verification keys.\n2  Allow notifications, SMS/contacts and selected filesystem folders as needed.\n3  Install Tailscale, sign into the laptop’s account and add both private IPs in KDE Connect.\n4  Samsung Settings → Battery → Background usage limits → Never sleeping apps: KDE Connect and Tailscale. Set both apps Battery → Unrestricted, allow background data, and enable Tailscale Always-on VPN in Android VPN settings. Keep KDE Connect included in Tailscale; avoid an exit node unless you need one.\n5  Optional screen control: enable Developer options and authorize USB debugging for this laptop.\n6  Optional robotics terminal: install Termux from its official source; install openssh, rsync and syncthing, then use SSH keys.\n\nTermux preparation:\npkg update && pkg install openssh rsync syncthing\ntermux-setup-storage\nwhoami\npasswd\nsshd\n\nThe SSH port is normally 8022. Use the username from whoami in Control. Verify the host fingerprint in Trust / shell before running widget commands. Start Syncthing on the phone and pair its device ID under Sync.";font.family:Appearance.font.ui;font.pixelSize:12;lineHeight:1.4;color:Theme.widgetText;wrapMode:Text.Wrap;textFormat:Text.PlainText}
     Flow {width:parent.width;spacing:8
      ControlTile {label:"KDE Connect settings";implicitWidth:230;onActivated:Quickshell.execDetached(["kdeconnect-app"])}
      ControlTile {label:"Termux official install";implicitWidth:230;onActivated:Quickshell.execDetached(["xdg-open","https://github.com/termux/termux-app#installation"])}
      ControlTile {label:"Termux boot services";implicitWidth:230;onActivated:Quickshell.execDetached(["xdg-open","https://github.com/termux/termux-boot#usage"])}
      ControlTile {label:"Android sync clients";implicitWidth:230;onActivated:Quickshell.execDetached(["xdg-open","https://docs.syncthing.net/users/contrib.html"])}
     }
     Text {text:"Laptop plugin permissions";font.family:Appearance.font.ui;font.pixelSize:14;font.bold:true;color:Theme.widgetAccent}
     Flow {width:parent.width;spacing:6;Repeater {model:root.device.supportedPlugins||[];ControlTile {required property string modelData;label:modelData.replace("kdeconnect_","");selected:(root.device.plugins||[]).indexOf(modelData)>=0;implicitWidth:190;implicitHeight:32;enabled:root.device.isPaired;onActivated:root.act("plugin",[modelData,String((root.device.plugins||[]).indexOf(modelData)<0)])}}}
    } } }
   }
  }
  ChamferPanel {width:parent.width;height:PhoneBridge.message?60:34;scanlines:false;chamfer:6;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
   Flickable {anchors.fill:parent;anchors.margins:8;contentHeight:result.implicitHeight;clip:true;Text {id:result;width:parent.width;text:PhoneBridge.message||"Sensei, device updates are live. Phone polling stops when this panel closes.";textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:PhoneBridge.success?Theme.widgetMuted:Theme.widgetAccent}}
  }
 }
}
