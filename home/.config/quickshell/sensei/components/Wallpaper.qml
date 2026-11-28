import QtQuick
import qs.config
import qs.services

// The wallpaper, crossfading whenever it changes. Backdrops are dimmed rather
// than blurred so no offscreen image effect runs on either high-resolution panel.
//
// **The default source is the one the shell is showing**, not the profile's
// file: which wallpaper that is -- the profile's own, one of its pool, or a
// locked one the profile no longer governs -- is `Wallpapers`' business, and
// routing every surface through it is what makes "nothing ever cuts or blinks"
// a property of the shell rather than a thing each caller remembers.
Item {
    id: root

    property url source: Wallpapers.displayed
    property int imageFillMode: Image.PreserveAspectCrop
    property bool decodeInBackground: false

    // 0 = full brightness, 0.58 gives the spec's "about 42% brightness".
    property real dim: 0

    // The pool's own fade, so a slow shuffle drifts rather than cuts.
    property int fadeDuration: Wallpapers.fadeDuration

    // Dim changes still settle smoothly without an offscreen blur pass.
    Behavior on dim {
        NumberAnimation {
            duration: Appearance.duration.panel
            easing.type: Easing.OutCubic
        }
    }

    // `front` is the image being shown; `back` is the one fading out under it.
    property url frontSource: source
    property url backSource: source
    property real mix: 1

    onSourceChanged: root.swapIfIdle()

    function swapIfIdle(): void {
        // Keep the currently visible blend intact. Rapid choices coalesce
        // to the most recent source when this transition settles.
        if (source === frontSource || mix < 1)
            return;
        backSource = frontSource;
        mix = 0;
        frontSource = source;
        Qt.callLater(root.startFadeIfReady);
    }

    function startFadeIfReady(): void {
        if (root.mix < 1 && (front.status === Image.Ready || front.status === Image.Error || front.status === Image.Null) && !fade.running)
            fade.start();
    }

    Item {
        id: layers

        anchors.fill: parent

        Image {
            anchors.fill: parent
            visible: root.mix < 1
            source: root.width>0&&root.height>0 ? root.backSource : ""
            fillMode: root.imageFillMode
            sourceSize: Qt.size(root.width, root.height)
            // Synchronous: an async image inside a card layer never paints.
            asynchronous: false
            cache: true
        }

        Image {
            id: front

            anchors.fill: parent
            source: root.width>0&&root.height>0 ? root.frontSource : ""
            fillMode: root.imageFillMode
            sourceSize: Qt.size(root.width, root.height)
            asynchronous: root.decodeInBackground
            cache: true
            opacity: root.mix

            // Only start the crossfade once the new image is actually decoded,
            // so a swap never flashes the layer underneath.
            // A file that fails to load fades in too, so the old wallpaper
            // never stays on screen for a profile it no longer belongs to.
            onStatusChanged: Qt.callLater(root.startFadeIfReady)
        }
    }

    NumberAnimation {
        id: fade

        target: root
        property: "mix"
        to: 1
        duration: Theme.reducedMotion ? 0 : root.fadeDuration
        easing.type: Easing.OutCubic
        onFinished: {
            root.backSource = root.frontSource;
            Qt.callLater(root.swapIfIdle);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.dim
    }
}
