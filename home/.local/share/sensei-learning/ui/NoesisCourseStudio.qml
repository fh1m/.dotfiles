import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Course composition owns presentation; the workspace adapter retains queries,
// exact owner, drafts and receipt-backed mutations.
Rectangle {
 id:root
 color:NoesisStyle.canvas
 radius:NoesisStyle.radius
 property var course:({})
 property var lesson:({})
 property var rows:[]
 property var preview:({blocks:[]})
 property var learningContext:({})
 property string summary:""
 property string cursor:""
 property string notes:""
 property string savedPlace:""
 property bool busy:false
 property bool supportOpen:false
 readonly property bool lessonOpen:lesson.type==="unit"&&lesson.unit_kind!=="module"
 readonly property bool narrow:width<1040*Math.max(NoesisStyle.interfaceScale,NoesisStyle.readingScale)
 property alias expandedModule:outline.expandedModule
 readonly property real pageAnchor:pageScroll.ScrollBar.vertical.position
 readonly property real outlineAnchor:outlineScroll.ScrollBar.vertical.position
 readonly property real lessonAnchor:lessonScroll.ScrollBar.vertical.position
 function restoreAnchors(value){let clamp=(bar,anchor)=>bar.position=Math.max(0,Math.min(1-bar.size,Number(anchor)||0));clamp(pageScroll.ScrollBar.vertical,value.page_anchor);clamp(outlineScroll.ScrollBar.vertical,value.outline_anchor);clamp(lessonScroll.ScrollBar.vertical,value.lesson_anchor);}
 property alias moduleRows:outline.moduleRows
 property alias moduleCursor:outline.moduleCursor
 property alias editing:outline.editing
 property alias currentIndex:outline.currentIndex
 readonly property bool listFocused:outline.listFocused
 function expand(row){outline.expandedModule=row.id;}
 signal openMember(var row)
 signal expandModule(var row,bool more)
 signal moveMember(string identity,string direction)
 signal loadMore()
 signal importOutline()
 signal showActions()
 signal openSource()
 signal returnOutline()
 signal notesEdited(string value)
 signal preserveNotes()
 signal savePlace(string value)
 signal reviewReadiness(var row)
 ScrollView {id:pageScroll;implicitWidth:0;implicitHeight:0;ScrollBar.horizontal.policy:ScrollBar.AlwaysOff;anchors.fill:parent;anchors.margins:NoesisStyle.xl;clip:true;contentWidth:availableWidth;contentHeight:pageColumn.height
 ColumnLayout {id:pageColumn
  width:pageScroll.availableWidth;height:Math.max(pageScroll.availableHeight,600*Math.max(NoesisStyle.interfaceScale,NoesisStyle.readingScale));spacing:NoesisStyle.lg
  Flow {id:courseHeading;Layout.fillWidth:true;spacing:NoesisStyle.sm
   Text {visible:!root.lessonOpen;text:"Course overview";color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
   NoesisButton {visible:root.lessonOpen;text:"← Course outline";variant:"tertiary";onClicked:root.returnOutline();enabled:!root.busy}
   NoesisButton {text:"Course options";variant:"tertiary";onClicked:root.showActions()}
  }
  Text {id:courseTitle;Layout.fillWidth:true;textFormat:Text.PlainText;text:(root.lessonOpen?root.lesson.title:root.course.title||root.lesson.title)||"";wrapMode:Text.Wrap;color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.title;font.bold:true}
  Text {id:progress;Layout.fillWidth:true;visible:!root.lessonOpen&&root.summary!=="";textFormat:Text.PlainText;text:root.summary;wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
  Flow {id:courseActions;Layout.fillWidth:true;spacing:NoesisStyle.sm
   NoesisButton {text:root.lessonOpen?(root.savedPlace?"Resume lecture ↗":"Open lecture ↗"):"Continue learning";primary:true;enabled:!root.busy&&(root.lessonOpen?!!(root.lesson.source||root.lesson.local_file):root.rows.length>0);onClicked:{if(root.lessonOpen)root.openSource();else {let row=root.rows.find(row=>!["read","complete","passed","replaced"].includes(row.status))||root.rows[0];if(root.moduleRows.length)root.openMember(root.moduleRows[0]);else if(row)root.openMember(row);}}}
   NoesisButton {text:root.supportOpen?"Hide outline & context":"Outline & prerequisites";visible:root.lessonOpen&&root.narrow;highlighted:root.supportOpen;onClicked:root.supportOpen=!root.supportOpen}
   NoesisButton {text:"Edit complete note ↗";visible:root.lessonOpen;variant:"tertiary";onClicked:NoesisController.note(root.lesson.path)}
  }
  SplitView {
   id:panes;Layout.fillWidth:true;Layout.fillHeight:true;orientation:root.narrow&&!root.lessonOpen?Qt.Vertical:Qt.Horizontal
   onResizingChanged:if(!resizing&&orientation===Qt.Horizontal&&outlineScroll.visible&&lessonScroll.visible){NoesisController.layouts=Object.assign({},NoesisController.layouts,{Course:{outline_ratio:Math.min(.5,Math.max(.25,outlineScroll.width/width))}});NoesisController.savePreferences();}
   handle:Rectangle {implicitWidth:8;color:SplitHandle.hovered?NoesisStyle.rule:NoesisStyle.canvas}
   ScrollView {
    id:outlineScroll;visible:!root.lessonOpen||!root.narrow||root.supportOpen;SplitView.preferredWidth:Math.min(panes.width*Math.min(.5,Math.max(.25,NoesisController.layouts.Course?.outline_ratio||.32)),420*NoesisStyle.interfaceScale);SplitView.minimumWidth:Math.min(240*NoesisStyle.interfaceScale,panes.width);SplitView.preferredHeight:260;SplitView.minimumHeight:160;SplitView.fillWidth:root.narrow&&root.supportOpen;clip:true;contentWidth:availableWidth
    ColumnLayout {width:outlineScroll.availableWidth;spacing:NoesisStyle.lg
     Text {Layout.fillWidth:true;visible:root.lessonOpen;textFormat:Text.PlainText;text:root.course.title||"Learning context";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
     NoesisCourseOutline {id:outline;activeLesson:root.lessonOpen?root.lesson.id:"";Layout.fillWidth:true;rows:root.rows;parentId:root.course.id||"";cursor:root.cursor;busy:root.busy;headingLabel:"Modules & lessons";onOpenMember:row=>root.openMember(row);onExpandModule:(row,more)=>root.expandModule(row,more);onMoveMember:(identity,direction)=>root.moveMember(identity,direction);onLoadMore:root.loadMore();onImportOutline:root.importOutline()}
     NoesisLearningContext {Layout.fillWidth:true;context:root.learningContext;busy:root.busy;onOpenContext:row=>root.openMember(row);onReviewReadiness:row=>root.reviewReadiness(row)}
    }
   }
   ScrollView {
    id:lessonScroll;visible:!(root.lessonOpen&&root.narrow&&root.supportOpen);SplitView.fillWidth:true;SplitView.fillHeight:true;SplitView.minimumHeight:180;SplitView.minimumWidth:Math.min(360*NoesisStyle.interfaceScale,panes.width);clip:true;contentWidth:availableWidth
    ColumnLayout {width:lessonScroll.availableWidth;spacing:NoesisStyle.lg
     Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:root.lessonOpen?"Learning objective & source":"What you will learn";color:NoesisStyle.accent;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
     Repeater {model:root.preview.blocks||[];delegate:TextEdit {required property var modelData;Layout.fillWidth:true;Layout.maximumWidth:NoesisStyle.readingWidth;text:modelData.text;readOnly:true;selectByMouse:true;textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap;color:NoesisStyle.ink;font.family:modelData.kind==="code"?NoesisStyle.codeFont:NoesisStyle.uiFont;font.pixelSize:modelData.kind==="heading"?NoesisStyle.sectionHeading:NoesisStyle.body;font.bold:modelData.kind==="heading"}}
     Text {Layout.fillWidth:true;visible:!(root.preview.blocks||[]).length;textFormat:Text.PlainText;text:root.lessonOpen?"Open the lecture, preserve your explanation, then try its assigned exercise.":"Choose a module. Keep reading progress separate from independently demonstrated understanding.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.body}
     ColumnLayout {visible:root.lessonOpen;Layout.fillWidth:true;spacing:NoesisStyle.md
      Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:"Your reasoning & notes";color:NoesisStyle.ink;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.sectionHeading}
      Text {Layout.fillWidth:true;textFormat:Text.PlainText;text:"Draft saved locally. Preserve a learning note when it is ready for your history.";wrapMode:Text.Wrap;color:NoesisStyle.secondary;font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label}
      ScrollView {id:notesScroll;Layout.fillWidth:true;Layout.preferredHeight:Math.max(220,NoesisStyle.control*4);clip:true;NoesisEditor {width:notesScroll.availableWidth;text:root.notes;placeholderText:"Explain the idea in your own words. Where does the derivation still break?";Accessible.name:"Lesson reasoning draft";onTextChanged:if(text!==root.notes)root.notesEdited(text)}}
      NoesisButton {text:"Preserve learning note";enabled:!root.busy&&root.notes.trim()!=="";onClicked:root.preserveNotes()}
      Flow {Layout.fillWidth:true;spacing:NoesisStyle.sm
       NoesisField {id:place;width:Math.min(320,parent.width);text:root.savedPlace;placeholderText:"Page, section or lecture timestamp";Accessible.name:"Lesson resume location"}
       NoesisButton {text:"Save reading place";enabled:!root.busy;onClicked:root.savePlace(place.text)}
      }
      NoesisButton {text:"Next lesson · "+(root.learningContext.next_lesson?.title||"");visible:!!root.learningContext.next_lesson;enabled:!root.busy;onClicked:root.openMember(root.learningContext.next_lesson)}
     }
    }
   }
  }
 }
 }
}
