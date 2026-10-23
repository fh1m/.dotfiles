import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
NoesisDialog {
 id:uni
 parent:Overlay.overlay
 anchors.centerIn:parent
 width:Math.min(1100,parent.width-48);height:Math.min(850,parent.height-48)
 title:"University · UIU BSCSE"
 signal openCourse(var course)
 Connections {target:controller;function onFinished(ok){if(ok&&uni.opened&&controller.operationKind==="academic"&&controller.operationResult.id){uni.openCourse(controller.operationResult);}}}
 property var summary:({})
 property var catalogue:[]
 property string error:""
 function refresh(){reader.command=["@HOME@/.local/bin/noesis","academic","audit","--vault",controller.activeVault];reader.running=true;}
 onOpened:{refresh();catalogReader.running=true;}
 Process {id:reader;stdout:StdioCollector {onStreamFinished:{try{uni.summary=JSON.parse(text)}catch(e){uni.error=String(e)}}}stderr:StdioCollector {onStreamFinished:if(text.trim())uni.error=text.trim()}}
 Process {id:catalogReader;command:["@HOME@/.local/bin/noesis","academic","catalog"];stdout:StdioCollector {onStreamFinished:{try{uni.catalogue=JSON.parse(text).courses}catch(e){uni.error=String(e)}}}}
 Process {id:writer;stdout:StdioCollector {onStreamFinished:uni.refresh()}stderr:StdioCollector {onStreamFinished:if(text.trim())uni.error=text.trim()}}
 function save(){try{let data=advanced.checked?JSON.parse(details.text):{course:courseCode.text,term:termField.text};if(!advanced.checked){if(kind.currentText==="enrollment")Object.assign(data,{status:enrollmentState.currentText,section:sectionField.text,instructor:instructorField.text});if(kind.currentText==="attendance")Object.assign(data,{date:dateField.text,state:attendanceState.currentText});if(kind.currentText==="result")Object.assign(data,{grade:gradeField.currentText,confirmed:confirmed.checked});if(kind.currentText==="assessment")Object.assign(data,{name:assessmentName.text,weight:Number(weightField.text),maximum:Number(maxField.text),score:scoreField.text.trim()?Number(scoreField.text):null});if(kind.currentText==="override")data.reason=reasonField.text;if(kind.currentText==="timetable")Object.assign(data,{day:dayField.currentIndex,start:startField.text,end:endField.text,room:roomField.text});}writer.command=["@HOME@/.local/bin/noesis","academic","record","--vault",controller.activeVault,"--kind",kind.currentText,"--data",JSON.stringify(data),"--operation-id",controller.operationUuid()];writer.running=true;}catch(e){error="Invalid record: "+String(e)}}
 ColumnLayout {anchors.fill:parent;spacing:NoesisStyle.md
  Text {Layout.fillWidth:true;text:"Fall 2026 · "+(uni.summary.earned_credits||0)+" / 141 credits · CGPA "+(uni.summary.cgpa===null||uni.summary.cgpa===undefined?"unknown":Number(uni.summary.cgpa).toFixed(2));font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.heading;color:NoesisStyle.ink}
  Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:"Degree progress and learning evidence stay separate. Suggested courses are not registrations. Official-source discrepancies remain flagged.";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
  TabBar {id:tabs;Layout.fillWidth:true;TabButton {text:"Degree & courses"}TabButton {text:"Current trimester"}TabButton {text:"Record & evidence"}}
  StackLayout {currentIndex:tabs.currentIndex;Layout.fillWidth:true;Layout.fillHeight:true
   ColumnLayout {
    NoesisField {id:filter;Layout.fillWidth:true;placeholderText:"Find a course, code, robotics or calculus…"}
    ListView {Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:uni.catalogue.filter(c=>(c.code+" "+c.title+" "+c.tracks.join(" ")).toLowerCase().includes(filter.text.toLowerCase()));delegate:NoesisRow {required property var modelData;width:ListView.view.width;title:modelData.display_code+" · "+modelData.title;subtitle:modelData.credits+" credits · "+modelData.bucket+" · prerequisites: "+(modelData.prerequisites.join(", ")||"none published");onClicked:{courseCode.text=modelData.code;details.text=JSON.stringify({course:modelData.code,term:"Fall 2026",status:"planned"},null,2);tabs.currentIndex=2}}ScrollBar.vertical:ScrollBar {}}
   }
   ScrollView {ColumnLayout {width:parent.width;spacing:NoesisStyle.md
    Repeater {model:uni.summary.enrollments||[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.course+" · "+modelData.term;subtitle:modelData.status+" · "+(modelData.section||"section unknown")+" · "+(modelData.instructor||"instructor unknown")}}
    Repeater {model:uni.summary.attendance||[];delegate:NoesisRow {required property var modelData;Layout.fillWidth:true;title:modelData.key;subtitle:"Attendance: "+(modelData.known_percent===null?"unknown":Number(modelData.known_percent).toFixed(0)+"% of recorded sessions")+(modelData.uncertain?" · incomplete attendance log":"")}}
    Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:JSON.stringify(uni.summary.warnings||[],null,2);font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
   }}
   ColumnLayout {
    NoesisSelect {id:kind;model:["enrollment","attendance","assessment","result","override","timetable"];onActivated:{let samples={enrollment:{course:"ENG1011",term:"Fall 2026",status:"planned"},attendance:{course:"ENG1011",term:"Fall 2026",date:new Date().toISOString().slice(0,10),state:"attended"},assessment:{course:"ENG1011",term:"Fall 2026",name:"Quiz 1",weight:10,maximum:10,score:null},result:{course:"ENG1011",term:"Fall 2026",grade:"A",confirmed:false},override:{course:"ENG1011",term:"Fall 2026",reason:""},timetable:{course:"ENG1011",term:"Fall 2026",day:0,start:"09:00",end:"10:20",room:""}};details.text=JSON.stringify(samples[currentText],null,2)}}
    Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:"Records are append-only. Results count only with confirmed:true. An override requires a reason. This structured editor preserves optional section, instructor, source and evidence fields.";font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.secondary}
    Flow {Layout.fillWidth:true;spacing:NoesisStyle.md
     NoesisField {id:courseCode;width:180;text:"ENG1011";placeholderText:"Course code"}
     NoesisField {id:termField;width:180;text:"Fall 2026";placeholderText:"Trimester"}
     NoesisSelect {id:enrollmentState;visible:kind.currentText==="enrollment";model:["planned","registered","withdrawn","completed","failed","waived"]}
     NoesisField {id:sectionField;visible:kind.currentText==="enrollment";width:140;placeholderText:"Section"}
     NoesisField {id:instructorField;visible:kind.currentText==="enrollment";width:240;placeholderText:"Instructor / contact"}
     NoesisField {id:dateField;visible:kind.currentText==="attendance";width:180;text:new Date().toLocaleDateString(Qt.locale("sv_SE"));placeholderText:"Date YYYY-MM-DD"}
     NoesisSelect {id:attendanceState;visible:kind.currentText==="attendance";model:["attended","absent","unknown","cancelled"]}
     NoesisSelect {id:gradeField;visible:kind.currentText==="result";model:["A","A-","B+","B","B-","C+","C","C-","D+","D","F"]}
     CheckBox {id:confirmed;visible:kind.currentText==="result";text:"Confirmed official result";font.family:NoesisStyle.uiFont}
     NoesisField {id:assessmentName;visible:kind.currentText==="assessment";width:200;placeholderText:"Assessment name"}
     NoesisField {id:weightField;visible:kind.currentText==="assessment";width:140;placeholderText:"Weight %"}
     NoesisField {id:maxField;visible:kind.currentText==="assessment";width:140;text:"100";placeholderText:"Maximum score"}
     NoesisField {id:scoreField;visible:kind.currentText==="assessment";width:140;placeholderText:"Score, or blank"}
     NoesisField {id:reasonField;visible:kind.currentText==="override";width:500;placeholderText:"Why is this exception justified?"}
     NoesisSelect {id:dayField;visible:kind.currentText==="timetable";model:["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]}
     NoesisField {id:startField;visible:kind.currentText==="timetable";width:130;text:"09:00";placeholderText:"Starts HH:MM"}
     NoesisField {id:endField;visible:kind.currentText==="timetable";width:130;text:"10:20";placeholderText:"Ends HH:MM"}
     NoesisField {id:roomField;visible:kind.currentText==="timetable";width:150;placeholderText:"Room"}
    }
    NoesisButton {text:"Open this course's learning workspace";enabled:!!courseCode.text&&!controller.working;onClicked:controller.run(["academic","study","--course",courseCode.text,"--term",termField.text])}
    CheckBox {id:advanced;text:"Advanced structured record";font.family:NoesisStyle.uiFont}
    ScrollView {visible:advanced.checked;Layout.fillWidth:true;Layout.fillHeight:true;TextArea {id:details;text:'{"course":"ENG1011","term":"Fall 2026","status":"planned"}';font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body;color:NoesisStyle.ink;wrapMode:TextEdit.Wrap}}
    NoesisButton {text:"Save academic record";enabled:!writer.running;primary:true;onClicked:uni.save()}
   }
  }
  Text {Layout.fillWidth:true;visible:!!uni.error;text:uni.error;wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
  RowLayout {NoesisButton {text:"Open Notion planning ↗";onClicked:controller.run(["planning","open"])}Item {Layout.fillWidth:true}NoesisButton {text:"Close";onClicked:uni.close()}}
 }
}
