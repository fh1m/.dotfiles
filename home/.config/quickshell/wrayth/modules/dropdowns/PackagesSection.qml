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
 Component.onCompleted:DesktopExtras.loadPackages()
 Text {width:parent.width;text:'󰏖 '+(DesktopExtras.packages.total||0)+' installed · '+(DesktopExtras.packages.official||0)+' pacman · '+(DesktopExtras.packages.foreign||0)+' AUR/local';font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText;wrapMode:Text.Wrap}
 Row {spacing:7
  ControlTile {implicitWidth:132;label:DesktopExtras.packagesLoading?'Checking…':'Check updates';enabled:!DesktopExtras.packagesLoading;onActivated:DesktopExtras.loadPackages(true)}
  ControlTile {implicitWidth:132;label:'Upgrade all';onActivated:DesktopExtras.packageAction('all')}
  ControlTile {implicitWidth:132;label:'Pacman only';onActivated:DesktopExtras.packageAction('repo')}
  ControlTile {implicitWidth:132;label:'AUR only';onActivated:DesktopExtras.packageAction('aur')}
 }
 Row {spacing:7
  ControlTile {implicitWidth:170;label:'Updates · '+(DesktopExtras.packages.updates||[]).length;selected:root.updatesOnly;onActivated:root.updatesOnly=true}
  ControlTile {implicitWidth:170;label:'Installed';selected:!root.updatesOnly;onActivated:root.updatesOnly=false}
  ControlTile {implicitWidth:170;label:'Transaction log';onActivated:DesktopExtras.packageAction('log')}
 }
 DeskTextField {placeholderTextColor:Theme.widgetMuted;selectionColor:Theme.widgetAccent;selectedTextColor:Theme.widgetText;id:filter;width:parent.width;height:36;placeholderText:'Filter packages or enter a package to install';color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:12;}
 Text {width:parent.width;text:DesktopExtras.packagesError||(DesktopExtras.packages.checked?'Last check: '+new Date(DesktopExtras.packages.checked*1000).toLocaleString():'Sensei, check updates to fetch current repository and AUR versions.');font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;wrapMode:Text.Wrap}
 ListView {width:parent.width;height:300;clip:true;spacing:5;model:root.rows;ScrollBar.vertical:DeskScrollBar {}
  delegate:ChamferPanel {id:item;required property var modelData;width:ListView.view.width;height:48;fillColor:root.selected.name===modelData.name?Theme.alpha(Theme.widgetAccent,.14):Theme.widgetSurface;borderColor:root.selected.name===modelData.name?Theme.widgetAccent:Theme.widgetBorder;chamfer:6;scanlines:false
   Column {anchors.fill:parent;anchors.margins:7;spacing:3
    Text {width:parent.width;text:item.modelData.name+' · '+item.modelData.source;color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:13;elide:Text.ElideRight}
    Text {width:parent.width;text:item.modelData.version+(item.modelData.new?' → '+item.modelData.new:'');color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:11;elide:Text.ElideRight}
   }
   MouseArea {anchors.fill:parent;onClicked:root.selected=item.modelData}
  }
 }
 Text {width:parent.width;text:root.selected.name?'Selected: '+root.selected.name:'Select a package for details, update or removal';font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetAccent;elide:Text.ElideRight}
 Row {spacing:7
  ControlTile {implicitWidth:132;label:'Update selected';enabled:!!root.selected.name;onActivated:DesktopExtras.packageAction('selected',root.selected.name)}
  ControlTile {implicitWidth:132;label:'Details';enabled:!!root.selected.name;onActivated:DesktopExtras.packageAction('info',root.selected.name)}
  ControlTile {implicitWidth:132;label:'Remove';enabled:!!root.selected.name;onActivated:DesktopExtras.packageAction('remove',root.selected.name)}
  ControlTile {implicitWidth:132;label:'Install typed';enabled:!!filter.text.trim();onActivated:DesktopExtras.packageAction('install',filter.text.trim())}
 }
 Row {spacing:7;ControlTile {implicitWidth:170;label:'List orphans';onActivated:DesktopExtras.packageAction('orphans')}ControlTile {implicitWidth:170;label:'Clean cache';onActivated:DesktopExtras.packageAction('clean')}ControlTile {implicitWidth:170;label:'Remove orphans';onActivated:DesktopExtras.packageAction('orphan-clean')}}
 Text {width:parent.width;text:'Transactions open in Kitty for review. Selected AUR packages update individually; selected pacman packages include a full repository upgrade.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
}
