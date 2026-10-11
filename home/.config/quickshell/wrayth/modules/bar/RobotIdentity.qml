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
    Image {
        anchors.centerIn: parent
        width: 28; height: 28
        source: Qt.resolvedUrl("../../assets/fh1m-autonomy.svg")
        opacity: badgeHover.containsMouse || ShellState.dropdown === "code" ? 1 : .86
        Behavior on opacity {NumberAnimation {duration:100}}
    }
    function publish():void {const x=root.mapToItem(null,0,0).x;for(let name of ["code","ident","comic"])ShellState.publishAnchor(name,x);}
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
                ShellState.toggleDropdown("comic");
            } else if (event.button === Qt.MiddleButton || (event.modifiers & Qt.ShiftModifier)) {
                root.publish();
                ShellState.toggleDropdown("ident");
            } else {
                root.publish();
                ShellState.toggleDropdown("code");
            }
        }
    }
}
