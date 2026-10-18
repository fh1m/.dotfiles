import QtQuick
import Quickshell
import qs.config
import qs.services

Item {
    id: root
    implicitHeight: Appearance.metrics.barHeight

    Accessible.name: "fh1m · Code and agents"
    implicitWidth: 44
    // Sensor frame + heading + three measured waypoints: autonomy across mediums.
    Column {
        anchors.centerIn: parent
        spacing:2
    Image {
        anchors.horizontalCenter:parent.horizontalCenter
        width: 24; height: 24
        source: Qt.resolvedUrl("../../assets/fh1m-autonomy.svg")
        opacity: badgeHover.containsMouse || ShellState.dropdown === "code" ? 1 : .86
        Behavior on opacity {NumberAnimation {duration:100}}
    }
    Text {
        anchors.horizontalCenter:parent.horizontalCenter
        text:(MachineProfile.host||"fh1m").toUpperCase()
        font.family:Appearance.font.ui;font.pixelSize:10;font.weight:Font.Medium;font.letterSpacing:.4
        color:Theme.widgetMuted
    }
    }
    function publish():void {const x=root.mapToItem(null,0,0).x;for(let name of ["code","ident","comic"])ShellState.publishAnchor(name,x,root.QsWindow.window?.screen?.name??"");}
    Component.onCompleted:Qt.callLater(publish)
    onXChanged:publish()
    MouseArea {
        id: badgeHover
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                root.publish();
                ShellState.toggleDropdownOn("comic",root.QsWindow.window?.screen?.name??"");
            } else if (event.button === Qt.MiddleButton || (event.modifiers & Qt.ShiftModifier)) {
                root.publish();
                ShellState.toggleDropdownOn("ident",root.QsWindow.window?.screen?.name??"");
            } else {
                root.publish();
                ShellState.toggleDropdownOn("code",root.QsWindow.window?.screen?.name??"");
            }
        }
    }
}
