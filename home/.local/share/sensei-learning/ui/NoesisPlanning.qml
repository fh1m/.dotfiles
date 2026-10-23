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
 function refresh(){read.running=true}
 onOpened:refresh()
 Process {id:read;command:["@HOME@/.local/bin/noesis","planning","status"];stdout:StdioCollector {onStreamFinished:{try{plan.state=JSON.parse(text)}catch(e){plan.error=String(e)}}}}
 Process {id:write;stdinEnabled:true;property string secret:"";onStarted:if(secret){write(secret+"\n");secret="";}stdout:StdioCollector {onStreamFinished:plan.refresh()}stderr:StdioCollector {onStreamFinished:if(text.trim())plan.error=text.trim()}}
 function run(action){error="";write.command=["@HOME@/.local/bin/noesis","planning",action];write.running=true}
 function enqueue(){let fields={Area:area.currentText,State:"Planned"};if(date.text.trim())fields.When={start:date.text.trim()};write.command=["@HOME@/.local/bin/noesis","planning","enqueue","--title",titleField.text,"--collection",collection.currentText,"--fields",JSON.stringify(fields),"--operation-id",controller.operationUuid()];write.running=true}
 ColumnLayout {anchors.fill:parent;spacing:NoesisStyle.md
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:plan.state.message||"";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:(plan.state.pending||0)+" pending · Last sync "+(plan.state.last_sync||"not yet")+" · Plans do not award competence";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.ink}
  RowLayout {NoesisButton {text:"Open Notion ↗";onClicked:plan.run("open")}NoesisButton {text:"Sync now";enabled:!write.running&&plan.state.connection==="connected";onClicked:plan.run("sync")}NoesisButton {text:"Set up collections";enabled:!write.running&&plan.state.connection==="connected";onClicked:plan.run("setup")}}
  TabBar {id:tabs;Layout.fillWidth:true;TabButton {text:"Academic"}TabButton {text:"Explore"}TabButton {text:"Connection"}}
  ListView {visible:tabs.currentIndex<2;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:(plan.state.records||[]).filter(r=>r.properties?.Area?.select?.name===(tabs.currentIndex===0?"Academic":"Explore")).slice(0,200);delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:(modelData.properties.Title?.title||[]).map(t=>t.plain_text||t.text?.content||"").join("");subtitle:modelData.collection+" · "+(modelData.properties.State?.select?.name||"Unknown")+" · "+(modelData.properties.When?.date?.start||"Unscheduled");onClicked:Qt.openUrlExternally(modelData.url)}ScrollBar.vertical:ScrollBar {}}
  ColumnLayout {visible:tabs.currentIndex===2;Layout.fillWidth:true;Layout.fillHeight:true;spacing:NoesisStyle.md
   Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:"Sign in to Notion, create a private Noesis page, and grant a scoped internal connection access to it. Paste the page ID and connection token below. The token is sent through stdin and stored only in your private configuration; it is never a command-line argument or copied to the other machine.";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
   NoesisField {id:parentId;Layout.fillWidth:true;placeholderText:"Private parent page UUID"}
   NoesisField {id:token;Layout.fillWidth:true;echoMode:TextInput.Password;placeholderText:"Scoped Notion connection token"}
   NoesisButton {text:"Connect private workspace";enabled:!write.running&&parentId.text.length>=32&&token.text.length>0;onClicked:{write.secret=token.text;token.clear();write.command=["@HOME@/.local/bin/noesis","planning","connect","--parent-id",parentId.text,"--token-stdin"];write.running=true}}
   Item {Layout.fillHeight:true}
  }
  Flow {visible:tabs.currentIndex<2;Layout.fillWidth:true;spacing:NoesisStyle.sm
   NoesisField {id:titleField;width:260;placeholderText:"What do you plan to study or do?"}
   NoesisSelect {id:collection;model:["Tasks","Goals/Paths","Terms","Course Enrollments","Schedule"]}
   NoesisSelect {id:area;model:["Academic","Explore"];currentIndex:tabs.currentIndex===1?1:0}
   NoesisField {id:date;width:180;placeholderText:"Due date YYYY-MM-DD"}
   NoesisButton {text:"Save plan";primary:true;enabled:!write.running&&!!titleField.text.trim();onClicked:plan.enqueue()}
  }
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;visible:!!plan.error;text:plan.error;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.ink}
  RowLayout {Item {Layout.fillWidth:true}NoesisButton {text:"Close";onClicked:plan.close()}}
 }
}
