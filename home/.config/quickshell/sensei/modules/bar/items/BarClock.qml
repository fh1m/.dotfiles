import QtQuick
import Quickshell
import qs.services
import qs.config
import qs.components

Item {
    id: root
    function publish(){const center=root.mapToItem(null,0,0).x+root.width/2;ShellState.publishAnchor("calendar",center,root.QsWindow.window?.screen?.name??"");ShellState.publishAnchor("weather",center,root.QsWindow.window?.screen?.name??"");}
    Component.onCompleted: Qt.callLater(publish)
    onWidthChanged: Qt.callLater(publish)
    implicitWidth: 400
    implicitHeight: 38
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 16
        Text { textFormat: Text.PlainText; renderType: Text.QtRendering; renderTypeQuality: 104; text: Qt.formatDateTime(clock.date, "hh:mm AP"); font.family: Appearance.font.display; font.pixelSize: 18; font.weight: 600; color: Theme.bright }
        Text { textFormat: Text.PlainText; renderType: Text.QtRendering; renderTypeQuality: 104; text: Qt.formatDateTime(clock.date, "dddd, dd MMMM"); font.family: Appearance.font.barUi; font.pixelSize: 13; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: clockPointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: event => { ShellState.dropdownAnchorX=parent.mapToItem(null,0,0).x + parent.width/2; ShellState.toggleDropdownOn(event.button===Qt.RightButton?"weather":"calendar",root.QsWindow.window?.screen?.name??""); } }
    Row {
        anchors.horizontalCenter:parent.horizontalCenter
        anchors.bottom:parent.bottom
        height:15
        spacing:12
        Row {
            spacing:5
            Text { textFormat: Text.PlainText;anchors.verticalCenter:parent.verticalCenter;text:WeatherDesk.glyph(WeatherDesk.current.weather_code);font.family:Appearance.font.icons;font.pixelSize:11;color:Theme.paperMuted}
            Text { textFormat: Text.PlainText;anchors.verticalCenter:parent.verticalCenter;text:WeatherDesk.current.temperature_2m!==undefined?Math.round(WeatherDesk.current.temperature_2m)+"°C":"—";font.family:Appearance.font.telemetry;font.pixelSize:10;color:Theme.paperMuted}
            Text { textFormat: Text.PlainText;anchors.verticalCenter:parent.verticalCenter;width:Math.min(implicitWidth,90);elide:Text.ElideRight;text:WeatherDesk.description(WeatherDesk.current.weather_code);font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.paperMuted}
        }
        Rectangle {visible:CalendarDesk.barSummary!==''||CalendarDesk.focusReadout!=='';width:3;height:3;radius:1.5;anchors.verticalCenter:parent.verticalCenter;color:Theme.rule}
        Text { textFormat: Text.PlainText;visible:CalendarDesk.barSummary!=='';width:Math.min(implicitWidth,115);elide:Text.ElideRight;text:CalendarDesk.barSummary;font.family:Appearance.font.barUi;font.pixelSize:10;color:Theme.paperMuted}
        Text { textFormat: Text.PlainText;visible:CalendarDesk.focusReadout!=='';text:CalendarDesk.focusReadout;font.family:Appearance.font.telemetry;font.pixelSize:10;font.features:{"tnum":1};color:Theme.signalRed}
    }
}
