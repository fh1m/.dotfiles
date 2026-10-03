import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// The notification stack lives above the ScreenPad bar, newest at the bottom.
// Separate surfaces rather than one column because the blur layer rule ignores
// alpha, and a single surface would frost the gaps between cards too.
Variants {
    model: Notifications.list

    PanelWindow {
        id: card

        required property var modelData

        // Looked up by id rather than by identity: a model entry does not
        // necessarily arrive as the same object it went in as.
        readonly property int index: Math.max(0, Notifications.list.findIndex(entry => entry.id === modelData.id))
        // How far the card starts to the right of where it settles. This is
        // movement inside the surface, not the surface arriving -- the
        // compositor fades the surface itself.
        readonly property real slide: 18

        property real reveal: 0

        screen: ShellState.bottomBarScreens[0] ?? ShellState.barScreens[0] ?? null
        color: "transparent"

        implicitWidth: 480
        implicitHeight: content.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wrayth-notifications"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // Ignore rather than Normal: the card is placed at absolute screen
        // coordinates against the active window, so it must not also be pushed
        // below the bar's exclusive zone.
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        anchors {
            bottom: true
            right: true
        }

        margins.bottom: Appearance.metrics.barHeight + 16 + Notifications.offsetOf(index)
        margins.right: 24

        onImplicitHeightChanged: Notifications.setHeight(modelData.id, implicitHeight)
        Component.onCompleted: {
            Notifications.setHeight(modelData.id, implicitHeight);
            entry.start();
        }

        Behavior on margins.bottom {
            NumberAnimation {
                duration: Appearance.duration.panel
                easing.type: Easing.OutCubic
            }
        }

        NumberAnimation {
            id: entry

            target: card
            property: "reveal"
            from: 0
            to: 1
            duration: Appearance.duration.enter
            easing.type: Easing.OutCubic
        }

        NumberAnimation { id: exitAnimation; target: card; property: "reveal"; to: 0; duration: 170; easing.type: Easing.InCubic; onFinished: card.modelData.dismiss() }

        NotificationCard {
            id: content

            width: parent.width
            notification: card.modelData

            // The same 16 px cut as the window. Both diagonals run at 45
            // degrees whatever their length, so an equal cut on a corner inset
            // by the border width is parallel to the window's and sits just
            // inside it, with an even gap the whole way along.
            chamferTopRight: Appearance.chamfer.panel

            opacity: card.reveal
            // Slides in from the right with a brief shear, settling as it lands.
            transform: [
                Matrix4x4 {
                    property real skew: 0
                    matrix: Qt.matrix4x4(1, Math.tan(skew * Math.PI / 180), 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                },
                Translate {
                    x: (1 - card.reveal) * card.slide
                }
            ]

            onDismissed: {entry.stop();exitAnimation.start();}
        }
    }
}
