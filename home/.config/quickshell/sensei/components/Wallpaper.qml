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

    onSourceChanged: {
        if (source === frontSource)
            return;
        // **Nothing may leave the new wallpaper hidden under the old one.** The
        // old image moves to the back first, then `mix` drops, and only then
        // does the front take the new source: a cached image can report Ready
        // during that assignment, and the fade below starts only while `mix`
        // is below 1. A cached image can also be Ready with no status change
        // at all, so the fade is checked once more after the change settles.
        backSource = frontSource;
        mix = 0;
        frontSource = source;
        Qt.callLater(root.startFadeIfReady);
    }

    function startFadeIfReady(): void {
        if (root.mix < 1 && (front.status === Image.Ready || front.status === Image.Error) && !fade.running)
            fade.restart();
    }

    Item {
        id: layers

        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: root.backSource
            fillMode: root.imageFillMode
            sourceSize: Qt.size(root.width, root.height)
            asynchronous: true
            cache: true
        }

        Image {
            id: front

            anchors.fill: parent
            source: root.frontSource
            fillMode: root.imageFillMode
            sourceSize: Qt.size(root.width, root.height)
            asynchronous: true
            cache: true
            opacity: root.mix

            // Only start the crossfade once the new image is actually decoded,
            // so a swap never flashes the layer underneath.
            // A file that fails to load fades in too, so the old wallpaper
            // never stays on screen for a profile it no longer belongs to.
            onStatusChanged: {
                if ((status === Image.Ready || status === Image.Error) && root.mix < 1)
                    fade.restart();
            }
        }
    }

    NumberAnimation {
        id: fade

        target: root
        property: "mix"
        to: 1
        duration: root.fadeDuration
        easing.type: Easing.OutCubic
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.dim
    }
}
