import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
NoesisDialog {
 id:root
 property var records:[]
 property string serverId:""
 property string error:""
 property string querySent:""
 property string vaultScope:""
 property bool importing:false
 signal imported(var record)
 modal:true;width:620;height:480
 title:"From Zotero"
 onOpened:{vaultScope=Oasis.activeVault;records=[];error="";search.text="";refresh();search.forceActiveFocus();}
 function refresh(){if(reader.running)return;querySent=search.text;reader.command=["@HOME@/.local/bin/noesis","zotero-search",querySent];reader.running=true;}
 background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
 contentItem:ColumnLayout {spacing:NoesisStyle.md
  Text {text:"Bibliography and original annotations remain in Zotero.";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;Layout.fillWidth:true;wrapMode:Text.Wrap}
  NoesisField {id:search;placeholderText:"Search your Zotero library";Layout.fillWidth:true;onTextChanged:debounce.restart()}
  Text {text:root.error|| (reader.running?"Searching Zotero…":"Select a source to import");color:root.error?NoesisStyle.accent:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label;wrapMode:Text.Wrap;Layout.fillWidth:true}
  ListView {Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.records
   delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.title;subtitle:modelData.type;enabled:!Oasis.working;onClicked:{root.importing=true;Oasis.run(["zotero-import",modelData.key,"--server-id",root.serverId]);}}
   ScrollBar.vertical:ScrollBar {}
  }
  RowLayout {Layout.fillWidth:true
   NoesisButton {text:"Open Zotero";onClicked:Quickshell.execDetached(["@HOME@/.local/bin/zotero"])}
   NoesisButton {text:"Refresh";onClicked:root.refresh()}
   Item {Layout.fillWidth:true}
   NoesisButton {text:"Close";onClicked:root.close()}
  }
 }
 Timer {id:debounce;interval:200;onTriggered:if(root.opened)root.refresh()}
 Process {id:reader;stdout:StdioCollector {onStreamFinished:{if(root.vaultScope!==Oasis.activeVault||root.querySent!==search.text)return;try{let result=JSON.parse(text);root.records=result.records;root.serverId=result.server_id;root.error="";}catch(e){root.error="Could not read Zotero results.";}}}stderr:StdioCollector {onStreamFinished:if(text.trim())root.error=text.trim()}onExited:if(root.opened&&root.querySent!==search.text)Qt.callLater(root.refresh)}
 Connections {target:Oasis;function onActiveVaultChanged(){root.close();}function onFinished(ok){if(root.importing){root.importing=false;if(ok){root.imported(Oasis.operationResult);root.close();}else root.error=Oasis.error;}}}
}
