import QtQuick
import QtQuick.Controls
import qs.components
import qs.config
import qs.services
Column {
 id:root;width:parent.width;spacing:10
 property bool updatesOnly:true
 property var selected:({})
 readonly property var rows:(updatesOnly?(DesktopExtras.packages.updates||[]):(DesktopExtras.packages.installed||[])).filter(p=>p.name.toLowerCase().includes(filter.text.toLowerCase()))
 Component.onCompleted:{DesktopExtras.loadPackages();DesktopExtras.loadPackageJob();}
 // Removing a package and upgrading the whole system are one press to arm, one to run.
 property string armed:''
 function confirm(key,action,name){if(armed===key){armed='';armTimer.stop();DesktopExtras.packageAction(action,name||'');}else{armed=key;armTimer.restart();}}
 Timer {id:armTimer;interval:4000;onTriggered:root.armed=''}
 Text { textFormat: Text.PlainText;width:parent.width;text:'󰏖 '+(DesktopExtras.packages.total||0)+' installed · '+(DesktopExtras.packages.official||0)+' pacman · '+(DesktopExtras.packages.foreign||0)+' AUR/local';font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText;wrapMode:Text.Wrap}
 Row {spacing:7
  ControlTile {implicitWidth:132;label:DesktopExtras.packagesLoading?'Checking…':'Check';enabled:!DesktopExtras.packagesLoading;onActivated:DesktopExtras.loadPackages(true)}
  ControlTile {implicitWidth:132;label:root.armed==='all'?'Confirm update':'Update all';selected:root.armed==='all';enabled:!DesktopExtras.packageBusy;onActivated:root.confirm('all','all')}
  ControlTile {implicitWidth:132;label:'Repositories';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('repo')}
  ControlTile {implicitWidth:132;label:'AUR';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('aur')}
 }
 Row {spacing:7
  ControlTile {implicitWidth:170;label:'Updates · '+(DesktopExtras.packages.updates||[]).length;selected:root.updatesOnly;onActivated:root.updatesOnly=true}
  ControlTile {implicitWidth:170;label:'Installed';selected:!root.updatesOnly;onActivated:root.updatesOnly=false}
  ControlTile {implicitWidth:170;label:'Transaction log';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('log')}
 }
 DeskTextField {placeholderTextColor:Theme.widgetMuted;selectionColor:Theme.widgetAccent;selectedTextColor:Theme.widgetText;id:filter;width:parent.width;height:36;placeholderText:'Filter packages or enter a package to install';color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:12;}
 Text { textFormat: Text.PlainText;width:parent.width;text:DesktopExtras.packagesError||(DesktopExtras.packages.checked?'Last check: '+Qt.formatDateTime(new Date(DesktopExtras.packages.checked*1000),'ddd, d MMM yyyy · hh:mm AP'):'Sensei, check updates to fetch current repository and AUR versions.');font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;wrapMode:Text.Wrap}
 ListView {width:parent.width;height:DesktopExtras.packageJob.status==='idle'?300:150;clip:true;spacing:5;model:root.rows;ScrollBar.vertical:DeskScrollBar {}
  delegate:ChamferPanel {id:item;required property var modelData;width:ListView.view.width;height:48;fillColor:root.selected.name===modelData.name?Theme.alpha(Theme.widgetAccent,.14):Theme.widgetSurface;borderColor:root.selected.name===modelData.name?Theme.widgetAccent:Theme.widgetBorder;chamfer:6;scanlines:false
   Column {anchors.fill:parent;anchors.margins:7;spacing:3
    Text { textFormat: Text.PlainText;width:parent.width;text:item.modelData.name+' · '+item.modelData.source;color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:13;elide:Text.ElideRight}
    Text { textFormat: Text.PlainText;width:parent.width;text:item.modelData.version+(item.modelData.new?' → '+item.modelData.new:'');color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:11;elide:Text.ElideRight}
   }
   MouseArea {anchors.fill:parent;onClicked:root.selected=item.modelData}
  }
 }
 Text { textFormat: Text.PlainText;width:parent.width;text:root.selected.name?'Selected: '+root.selected.name:'Select a package for details, update or removal';font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetAccent;elide:Text.ElideRight}
 Row {spacing:7
  ControlTile {implicitWidth:132;label:'Update';enabled:!!root.selected.name&&!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('selected',root.selected.name)}
  ControlTile {implicitWidth:132;label:'Details';enabled:!!root.selected.name&&!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('info',root.selected.name)}
  ControlTile {implicitWidth:132;label:root.armed==='remove'?'Confirm remove':'Remove';selected:root.armed==='remove';enabled:!!root.selected.name&&!DesktopExtras.packageBusy;onActivated:root.confirm('remove','remove',root.selected.name)}
  ControlTile {implicitWidth:132;label:'Install';enabled:!!filter.text.trim()&&!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('install',filter.text.trim())}
 }
 Row {spacing:7;ControlTile {implicitWidth:170;label:'List orphans';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('orphans')}ControlTile {implicitWidth:170;label:'Clean cache';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('clean')}ControlTile {implicitWidth:170;label:'Remove orphans';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('orphan-clean')}}
 Flow {width:parent.width;spacing:7
  ControlTile {implicitWidth:170;label:'Flatpak updates';glyph:'\uf1b2';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('flatpak')}
  ControlTile {implicitWidth:170;label:'Firmware updates';glyph:'\uf2db';enabled:!DesktopExtras.packageBusy;onActivated:DesktopExtras.packageAction('firmware')}
 }
 Column {width:parent.width;spacing:8;visible:DesktopExtras.packageJob.status!=='idle'||DesktopExtras.packageJobError!==''
  Text {width:parent.width;text:DesktopExtras.packageJobError||((DesktopExtras.packageJob.action||'Update')+' · '+(DesktopExtras.packageJob.phase||'Starting'));textFormat:Text.PlainText;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.signalRed;wrapMode:Text.WordWrap}
  ProgressBar {width:parent.width;height:5;visible:DesktopExtras.packageBusy;indeterminate:true}
  ScrollView {id:transactionLog;width:parent.width;height:160;clip:true;contentWidth:availableWidth
   TextArea {id:logText;readOnly:true;onTextChanged:Qt.callLater(()=>{if(transactionLog.contentItem)transactionLog.contentItem.contentY=Math.max(0,transactionLog.contentItem.contentHeight-transactionLog.height);});text:DesktopExtras.packageJob.log||'Starting background transaction…';textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap;font.family:Appearance.font.telemetry;font.pixelSize:10;color:Theme.paper;background:Rectangle{color:Theme.surfaceOne}}
  }
  Rectangle {width:parent.width;height:promptLabel.implicitHeight+18;color:Theme.surfaceTwo;radius:3;visible:DesktopExtras.packageBusy&&!!DesktopExtras.packageJob.prompt
   Text {id:promptLabel;anchors.left:parent.left;anchors.right:parent.right;anchors.margins:9;y:9;text:DesktopExtras.packageJob.prompt||'';textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.paper}
  }
  Row {spacing:7;visible:DesktopExtras.packageBusy
   DeskTextField {id:answer;width:240;height:36;placeholderText:'Response to package prompt';color:Theme.paper;font.pixelSize:12;onAccepted:{DesktopExtras.packageAnswer(text);text='';}}
   ControlTile {implicitWidth:92;label:'Send';glyph:'\uf00c';onActivated:{DesktopExtras.packageAnswer(answer.text);answer.text='';}}
   ControlTile {implicitWidth:155;label:'Request stop';glyph:'\uf04d';onActivated:DesktopExtras.packageCancel()}
  }
  Row {spacing:7;visible:DesktopExtras.packageBusy
   ControlTile {implicitWidth:150;label:'Use default';glyph:'\uf061';onActivated:DesktopExtras.packageAnswer('')}
   ControlTile {implicitWidth:150;label:'Confirm (y)';glyph:'\uf00c';onActivated:DesktopExtras.packageAnswer('y')}
   ControlTile {implicitWidth:150;label:'Decline (n)';glyph:'\uf00d';onActivated:DesktopExtras.packageAnswer('n')}
  }
 }
 Text { textFormat: Text.PlainText;width:parent.width;text:'Review transaction output and answer prompts here. Authentication uses a password dialog. Updates continue if this panel closes; a notification reports completion.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
}
