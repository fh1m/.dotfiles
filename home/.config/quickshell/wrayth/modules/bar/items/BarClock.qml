import QtQuick
import Quickshell
import qs.services
import qs.config
import qs.components

Item {
    id: root
    function publish(){const center=root.mapToItem(null,0,0).x+root.width/2;ShellState.publishAnchor("calendar",center);ShellState.publishAnchor("weather",center);}
    Component.onCompleted: Qt.callLater(publish)
    onWidthChanged: Qt.callLater(publish)
    implicitWidth: 400
    implicitHeight: 38
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 16
        Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: Qt.formatDateTime(clock.date, "hh:mm AP"); font.family: Appearance.font.display; font.pixelSize: 18; font.weight: 600; color: Theme.bright }
        Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: Qt.formatDateTime(clock.date, "dddd, dd MMM"); font.family: Appearance.font.data; font.pixelSize: 13; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: event => { ShellState.dropdownAnchorX=parent.mapToItem(null,0,0).x + parent.width/2; ShellState.toggleDropdown(event.button===Qt.RightButton?"weather":"calendar"); } }
    Ticker {anchors.left:parent.left;anchors.right:focusLabel.visible?focusLabel.left:parent.right;anchors.rightMargin:focusLabel.visible?8:0;anchors.bottom:parent.bottom;height:15;text:WeatherDesk.glyph(WeatherDesk.current.weather_code)+"  "+WeatherDesk.summary+"  ·  "+CalendarDesk.barSummary;pixelSize:10;foreground:Theme.dim;scrollOnlyOverflow:true;loopGap:24;speed:26;fade:10}
    Text {id:focusLabel;anchors.right:parent.right;anchors.bottom:parent.bottom;width:104;height:15;visible:CalendarDesk.focusReadout!=='';text:CalendarDesk.focusReadout;horizontalAlignment:Text.AlignRight;font.family:Appearance.font.data;font.pixelSize:10;font.weight:600;font.features:{"tnum":1};color:Theme.signal}
}
