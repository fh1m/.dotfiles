import QtQuick
import Quickshell
import qs.config
import qs.services

Item {
    id: root
    implicitHeight: Appearance.metrics.barHeight

    Accessible.name: "fh1m · Code and agents"
    implicitWidth: 60
    // A small field robot: asymmetric eye, antenna and an open circuit frame.
    Image {
        anchors.centerIn: parent
        width: 38; height: 30
        source: Qt.resolvedUrl("../../assets/fh1m-field-mark.svg")
        opacity: badgeHover.containsMouse || ShellState.dropdown === "code" ? 1 : .86
        Behavior on opacity {NumberAnimation {duration:100}}
    }
    MouseArea {
        id: badgeHover
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                ShellState.publishAnchor("comic", 12);
                ShellState.toggleDropdown("comic");
            } else if (event.button === Qt.MiddleButton || (event.modifiers & Qt.ShiftModifier)) {
                ShellState.publishAnchor("ident", 12);
                ShellState.toggleDropdown("ident");
            } else {
                ShellState.publishAnchor("code", root.mapToItem(null, 0, 0).x);
                ShellState.toggleDropdown("code");
            }
        }
    }
}
