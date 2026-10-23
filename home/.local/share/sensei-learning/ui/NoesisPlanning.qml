import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
NoesisDialog {
 id:plan
 parent:Overlay.overlay;anchors.centerIn:parent
 width:Math.min(1000,parent.width-48);height:Math.min(800,parent.height-48)
 title:"Planning · Academic & Explore"
 property var state:({})
 property string error:""
 property var editing:({})
 function edit(record){editing=record;titleField.text=(record.properties.Title?.title||[]).map(t=>t.plain_text||t.text?.content||"").join("");date.text=record.properties.When?.date?.start||"";collection.currentIndex=collection.model.indexOf(record.collection);planState.currentIndex=Math.max(0,planState.model.indexOf(record.properties.State?.select?.name||"Planned"));}
 function newPlan(){editing=({});titleField.clear();date.clear();planState.currentIndex=0;}
 function refresh(){read.running=true}
 onOpened:refresh()
 Process {id:read;command:["@HOME@/.local/bin/noesis","planning","status"];stdout:StdioCollector {onStreamFinished:{try{plan.state=JSON.parse(text)}catch(e){plan.error=String(e)}}}}
 Process {id:write;stdinEnabled:true;property string secret:"";onStarted:if(secret){write(secret+"\n");secret="";}stdout:StdioCollector {onStreamFinished:plan.refresh()}stderr:StdioCollector {onStreamFinished:if(text.trim())plan.error=text.trim()}}
 function run(action){error="";write.command=["@HOME@/.local/bin/noesis","planning",action];write.running=true}
 function enqueue(){let fields={Area:area.currentText,State:planState.currentText,When:date.text.trim()?{start:date.text.trim()}:null};write.command=["@HOME@/.local/bin/noesis","planning","enqueue","--title",titleField.text,"--collection",collection.currentText,"--fields",JSON.stringify(fields),"--operation-id",controller.operationUuid()];if(editing.id)write.command=write.command.concat(["--remote-id",editing.id,"--base-revision",editing.last_edited_time]);write.running=true}
 ColumnLayout {anchors.fill:parent;spacing:NoesisStyle.md
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:plan.state.message||"";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:(plan.state.pending||0)+" pending · "+(plan.state.cache_source==="notion-connector"?"Connector snapshot ":"Last sync ")+(plan.state.last_sync||"not yet")+" · Plans do not award competence";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.ink}
  RowLayout {NoesisButton {text:"Open Notion ↗";onClicked:plan.run("open")}NoesisButton {text:"Sync now";enabled:!write.running&&plan.state.connection==="connected";onClicked:plan.run("sync")}NoesisButton {text:"Set up collections";enabled:!write.running&&plan.state.connection==="connected";onClicked:plan.run("setup")}}
  TabBar {id:tabs;Layout.fillWidth:true;TabButton {text:"Academic"}TabButton {text:"Explore"}TabButton {text:"Connection"}}
  ListView {visible:tabs.currentIndex<2;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:(plan.state.records||[]).filter(r=>r.properties?.Area?.select?.name===(tabs.currentIndex===0?"Academic":"Explore")).slice(0,200);delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:(modelData.properties.Title?.title||[]).map(t=>t.plain_text||t.text?.content||"").join("");subtitle:modelData.collection+" · "+(modelData.properties.State?.select?.name||"Unknown")+" · "+(modelData.properties.When?.date?.start||"Unscheduled");onClicked:{if(modelData.read_only)Qt.openUrlExternally(modelData.url);else plan.edit(modelData)}}ScrollBar.vertical:ScrollBar {}}
  Text {visible:tabs.currentIndex<2&&!!plan.editing.id;Layout.fillWidth:true;text:"Editing an existing plan · remote changes are checked before submission";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.caption;color:NoesisStyle.secondary}
  ListView {visible:tabs.currentIndex<2&&(plan.state.pending_records||[]).length>0;Layout.fillWidth:true;Layout.preferredHeight:Math.min(150,contentHeight);clip:true;model:(plan.state.pending_records||[]).filter(r=>r.fields.Area===(tabs.currentIndex===0?"Academic":"Explore"));delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.title;subtitle:modelData.conflict||"Pending acknowledgement · saved locally"}}
  ColumnLayout {visible:tabs.currentIndex===2;Layout.fillWidth:true;Layout.fillHeight:true;spacing:NoesisStyle.md
   Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:"Sign in to Notion, use the existing private Noesis workspace root, and grant a scoped internal connection access to it. Paste the page ID and connection token below. The token is sent through stdin and stored only in your private configuration; it is never a command-line argument or copied to the other machine.";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
   NoesisField {id:parentId;Layout.fillWidth:true;placeholderText:"Private parent page UUID"}
   NoesisField {id:token;Layout.fillWidth:true;echoMode:TextInput.Password;placeholderText:"Scoped Notion connection token"}
   NoesisButton {text:"Connect private workspace";enabled:!write.running&&parentId.text.length>=32&&token.text.length>0;onClicked:{write.secret=token.text;token.clear();write.command=["@HOME@/.local/bin/noesis","planning","connect","--parent-id",parentId.text,"--token-stdin"];write.running=true}}
   Item {Layout.fillHeight:true}
  }
  Flow {visible:tabs.currentIndex<2;Layout.fillWidth:true;spacing:NoesisStyle.sm
   NoesisField {id:titleField;width:260;placeholderText:"What do you plan to study or do?"}
   NoesisSelect {id:collection;model:["Tasks","Goals/Paths","Terms","Course Enrollments","Schedule"]}
   NoesisSelect {id:area;model:["Academic","Explore"];currentIndex:tabs.currentIndex===1?1:0}
   NoesisSelect {id:planState;model:["Planned","Active","Done","Parked","Abandoned"]}
   NoesisButton {text:"New plan";visible:!!plan.editing.id;onClicked:plan.newPlan()}
   NoesisField {id:date;width:180;placeholderText:"Due date YYYY-MM-DD"}
   NoesisButton {text:plan.editing.id?"Queue changes":"Save plan";primary:true;enabled:!write.running&&!!titleField.text.trim();onClicked:plan.enqueue()}
  }
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;visible:!!plan.error;text:plan.error;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.ink}
  RowLayout {Item {Layout.fillWidth:true}NoesisButton {text:"Close";onClicked:plan.close()}}
 }
}
