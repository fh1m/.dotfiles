import QtQuick
// QS_NO_RELOAD_POPUP is supplied by the Hyprland session launcher.

import Quickshell
import qs.modules.background
import qs.modules.bar
import qs.modules.deck
import qs.modules.deck.hud
import qs.modules.dropdowns
import qs.modules.notifications
import qs.modules.launcher
import qs.modules.lock
import qs.modules.picker
import qs.modules.popups
import qs.modules.session
import qs.modules.status
import qs.modules.navigation
import "modules/shortcuts" as ShortcutUi
import qs.services

ShellRoot {
    Background {}
    ScanlineLayer {}
    Bar {}
    BottomBar {}
    BarEdges {}
    Dropdowns {}
    DeckOverlay {}
    NotificationLayer {}
    OsdLayer {}
    LauncherOverlay {}
    SessionOverlay {}
    // The theme editor and wallpaper pool contain many previews. Construct on demand.
    Loader {
        id: pickerLoader
        active: ShellState.pickerOpen
        sourceComponent: Component { PickerOverlay {} }
        Connections {target:ShellState;function onPickerOpenChanged(){if(ShellState.pickerOpen){pickerUnload.stop();pickerLoader.active=true;}else pickerUnload.restart();}}
        Timer {id:pickerUnload;interval:360;onTriggered:pickerLoader.active=false}
    }
    DaemonLibrary {}
    LockScreen {}
    StatusCache {}
    FontCheck {}
    ScreenCheck {}
    NavigationOverlay {}
    ShortcutUi.ShortcutsOverlay {}
    // Native window border indicates focus without a flashing overlay.
    Ipc {}
}
