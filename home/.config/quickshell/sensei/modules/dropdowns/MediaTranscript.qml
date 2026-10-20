import QtQuick
import QtQuick.Controls
import qs.config
import qs.components
import qs.services
ChamferPanel {
    id:root
    property string filter:""
    property bool follow:true
    fillColor:Theme.surfaceOne;borderColor:Theme.rule;chamfer:8;scanlines:false
    Column {anchors.fill:parent;anchors.margins:12;spacing:10
        Row {width:parent.width;spacing:6
            Text {width:parent.width-40;text:'Transcript';font.family:Appearance.font.heading;font.pixelSize:17;color:Theme.paper}
            MusicButton {implicitWidth:32;implicitHeight:28;glyph:'\uf00d';Accessible.name:'Close transcript';onActivated:YouTubeDesk.transcriptOpen=false}
        }
        Row {width:parent.width;spacing:6
            DeskComboBox {width:Math.max(80,parent.width-142);height:32;model:YouTubeDesk.captionLanguages.length?YouTubeDesk.captionLanguages:['en'];currentIndex:Math.max(0,model.indexOf(YouTubeDesk.captionLanguage));onActivated:{YouTubeDesk.captionLanguage=model[currentIndex];YouTubeDesk.loadTranscript();}Accessible.name:'Transcript language'}
            MusicButton {implicitWidth:44;implicitHeight:32;glyph:'\uf021';Accessible.name:'Load transcript';enabled:!YouTubeDesk.transcriptLoading;onActivated:YouTubeDesk.loadTranscript()}
            MusicButton {implicitWidth:86;implicitHeight:32;glyph:'';label:'Follow';selected:root.follow;onActivated:root.follow=!root.follow}
        }
        DeskTextField {width:parent.width;height:32;placeholderText:'Find in transcript…';onTextEdited:root.filter=text}
        Text {width:parent.width;text:YouTubeDesk.transcriptLoading?'Loading captions…':YouTubeDesk.transcriptNotice||'Select a line to seek.';wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.caption;color:Theme.paperMuted;maximumLineCount:3;elide:Text.ElideRight}
        ListView {id:lines;width:parent.width;height:Math.max(80,root.height-y-24);clip:true;spacing:6;model:YouTubeDesk.transcript.filter(r=>!root.filter||r.text.toLowerCase().includes(root.filter.toLowerCase()))
            ScrollBar.vertical:DeskScrollBar {}
            onDraggingChanged:if(dragging)root.follow=false
            delegate:Rectangle {required property var modelData;required property int index;width:lines.width;height:words.implicitHeight+32;radius:5;color:modelData.time===YouTubeDesk.transcript[YouTubeDesk.captionIndex]?.time?Theme.alpha(Theme.widgetAccent,.13):'transparent'
                Text {x:8;y:8;text:SpotifyDesk.fmt(modelData.time);font.family:Appearance.font.data;font.pixelSize:10;color:Theme.widgetAccent}
                Text {id:words;x:8;y:24;width:parent.width-16;text:modelData.text;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper}
                MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:YouTubeDesk.action('seek-to',[String(modelData.time)])}
            }
            Text {anchors.centerIn:parent;visible:!lines.count;width:parent.width-20;text:YouTubeDesk.transcriptLoading?'Looking for published captions…':'No published captions matched. Not every video provides a transcript.';wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted}
        }
    }
    Connections {target:YouTubeDesk;function onCaptionIndexChanged(){if(root.follow&&!root.filter&&YouTubeDesk.captionIndex>=0)lines.positionViewAtIndex(YouTubeDesk.captionIndex,ListView.Center);}}
}
