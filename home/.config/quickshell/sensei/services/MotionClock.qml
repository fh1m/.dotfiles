pragma Singleton
import QtQuick

// One shared 30 Hz beat for tiny bar motions. Separate infinite animations
// used to wake the compositor at unrelated times across both 4K panels.
QtObject {
    id: root
    property double ms: Date.now()
    property Timer tick: Timer {
        interval: 33
        repeat: true
        running: true
        onTriggered: root.ms = Date.now()
    }
}
