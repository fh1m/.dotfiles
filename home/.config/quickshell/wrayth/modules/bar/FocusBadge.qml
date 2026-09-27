import QtQuick
import qs.components
import qs.config
import qs.services
Rectangle {
 id:root;implicitWidth:94;implicitHeight:30;radius:3
 color:CalendarDesk.focusState.running?Theme.alpha(Theme.signal,.16):"transparent"
 border.color:CalendarDesk.focusState.running?Theme.signal:Theme.hair
 Row {anchors.centerIn:parent;spacing:5
 NrLabel {centred:true;pixelSize:14;text:"\uf2f2";color:Theme.signal}
 NrLabel {centred:true;pixelSize:11;text:CalendarDesk.focusState.running?CalendarDesk.barSummary.split('  /  ').find(s=>s.startsWith('Focus ')||s.startsWith('Break '))?.split(' ').pop()??"FOCUS":"FOCUS";color:Theme.text;tracked:false}
 }
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;acceptedButtons:Qt.LeftButton|Qt.RightButton
 onClicked:e=>{if(e.button===Qt.RightButton)CalendarDesk.focusAction(CalendarDesk.focusState.running?"pause":"resume",{});else if(ShellState.dropdown==="calendar"&&CalendarDesk.page===2)ShellState.dropdown="";else{CalendarDesk.page=2;ShellState.dropdownAnchorX=root.mapToItem(null,0,0).x;ShellState.dropdown="calendar";}}
 }
}
