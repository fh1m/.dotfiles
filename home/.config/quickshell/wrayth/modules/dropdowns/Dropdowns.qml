import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// The layer the bar dropdowns live on. The surface is sized to the panel and
// nothing more: the `wrayth-popup` layer rule blurs whatever it covers
// (Caelestia's decoration sets ignore_opacity, so alpha does not limit it), so a
// full-screen surface would frost the whole screen. It anchors top-left with a
// zero exclusive zone, which puts its origin on the bar's, and slides down from
// under the bar in QML — Hyprland's own layer animation is off for this
// namespace, see external/hypr-wrayth.lua.
Variants {
    model: ShellState.screens

    PanelWindow {
        id: popup

        required property ShellScreen modelData

        // Keep-off-the-edge margin, and the gap below the bar.
        readonly property real edge: 12
        readonly property real gap: 8
        readonly property bool bottomPanel: current === "monitor" || current === "clipboard" || current === "usb" || current === "phone"
        readonly property real surfaceInset: bottomPanel ? 0 : 6

        // Which panel the loader holds, and where the surface sits. Both lag
        // ShellState: `current` so the panel stays drawn while it slides back
        // up, `anchorX` so the surface never moves under a panel that is still
        // on screen — binding it straight to ShellState.dropdownAnchorX made a
        // swap teleport the outgoing panel to the incoming readout first.
        property string current: ""
        property real cachedHeight: 0
        property real anchorX: ShellState.dropdownAnchorX
        // The surface is sized to the panel, but a panel that animates its own
        // height between two inner views exposes a stable `surfaceHeight` (the
        // taller of the two) so the *surface* never reconfigures mid-animation
        // -- only the visible panel inside it grows and shrinks. Reconfiguring
        // the layer every frame is exactly what made the height animation
        // stutter; see implicitHeight below.
        // Allocate an approximate surface immediately while a heavy QML view
        // compiles asynchronously. Before this, Loader.Ready gated the *whole*
        // popup: measured cold opens took 0.5–1.2 s to show any response.
        readonly property real loadingHeight: {
            if (bottomPanel) return 490;
            switch (current) {
            case "spotify": return 834;
            case "docker": return 800;
            case "calendar": case "weather": return 862;
            case "system": return 696;
            case "sound": return 616;
            case "wifi": return 1008;
            default: return 520;
            }
        }
        readonly property real panelHeight: content.item?.surfaceHeight ?? content.item?.implicitHeight ?? loadingHeight

        // 0 hidden, 1 fully out. This only slides the panel *inside* the
        // surface; the surface's own fade is the compositor's, from the
        // `animation = fade` layer rule.
        property real reveal: 0
        property real measuredHeight: 0
        property int stableFrames: 0
        property bool surfaceReady: false

        // Hyprland refocuses the pointer the moment a focus grab starts. When
        // that lands with the pointer still on the bar, the bar loses its hover
        // state until the mouse moves, so the readout just clicked stops looking
        // clickable. The grab is only there to catch clicks outside the bar and
        // making one of those means moving off the bar first, so it holds until
        // the pointer leaves and then stays armed until the dropdown closes.
        property bool grabArmed: false
        // How far above its resting place the panel starts, i.e. how much of it
        // is still behind the bar at the start of the slide.
        readonly property real slide: 12

        IpcHandler {target:"popupmotion-"+popup.modelData.name;function contentState():string {let texts=[];function walk(n,a){if(!n)return;let opacity=a*(n.opacity===undefined?1:n.opacity);if(n.visible===false||opacity<0.8)return;if(typeof n.text==='string'&&n.text.trim())texts.push(n.text.slice(0,160));for(let c of (n.children||[]))walk(c,opacity);}walk(content.item,1);return JSON.stringify({current:popup.current,texts:texts});}function state():string {return JSON.stringify({current:popup.current,reveal:popup.reveal,ready:popup.surfaceReady,width:popup.width,height:popup.height,open:openAnim.running,close:closeAnim.running,swap:swapAnim.running});}}
        screen: modelData
        color: "transparent"
        mask: Region { width: ShellState.dropdown === popup.current ? popup.width : 0; height: popup.height }
        visible: current !== "" && surfaceReady && !ShellState.externalDialogOpen

        implicitWidth: Math.min(modelData.width - 2 * edge, 2 * surfaceInset + (current === "monitor" || current === "clipboard" || current === "usb" || current === "phone" ? 1040 : current === "docker" || current === "spotify" ? 1080 : current === "sound" ? 780 : current === "bluetooth" ? 620 : (current === "calendar" || current === "weather") ? 1080 : current === "comic" ? 740 : current === "displays" ? 740 : current === "system" || current === "ident" ? 596 : 380))
        // Fixed to the panel. Animating this instead would reconfigure the layer
        // surface on every frame, which Hyprland cannot keep up with — that is
        // what made the slide stutter.
        implicitHeight: Math.max(1, Math.min(modelData.height - Appearance.metrics.barHeight - 2 * gap, Math.round(panelHeight + 2 * surfaceInset)))

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wrayth-popup"
        // OnDemand plus the focus grab below: the grab hands the surface the
        // keyboard while it is up, so Escape and the passphrase field get keys
        // without the surface stealing them from everything else.
        WlrLayershell.keyboardFocus: ShellState.dropdown === popup.current ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        exclusionMode: (current === "calendar" || current === "weather") ? ExclusionMode.Ignore : ExclusionMode.Normal
        exclusiveZone: 0

        anchors {
            top: !(popup.current === "monitor" || popup.current === "clipboard" || popup.current === "usb" || popup.current === "phone")
            bottom: popup.current === "monitor" || popup.current === "clipboard" || popup.current === "usb" || popup.current === "phone"
            left: true
        }

        margins.top: (current === "calendar" || current === "weather") ? Appearance.metrics.barHeight + gap - surfaceInset : (current === "monitor" || current === "clipboard" || current === "usb" || current === "phone") ? 0 : gap
        margins.bottom: (current === "monitor" || current === "clipboard" || current === "usb" || current === "phone") ? gap : 0
        // Under the readout that opened it, pulled back in if that would hang
        // the panel off the right edge. Both windows share an origin, so the
        // bar's x maps straight across.
        margins.left: {
            const avail = popup.screen.width;
            if (popup.current === "calendar" || popup.current === "weather") return Math.round(Math.max(popup.edge,Math.min((popup.anchorX>0?popup.anchorX:avail/2)-popup.implicitWidth/2,avail-popup.implicitWidth-popup.edge)));
            if (popup.current === "spotify") return Math.round((avail-popup.implicitWidth)/2);
            return Math.round(Math.max(popup.edge, Math.min(popup.anchorX, avail - popup.implicitWidth - popup.edge)));
        }

        // Open, close and swap are three explicit animations rather than one
        // Behavior on `reveal`. A swap has to take the old panel out, change the
        // panel underneath, and bring the new one back in; a Behavior only ever
        // sees the end value, which is why switching dropdowns used to flash.
        NumberAnimation {
            id: openAnim

            target: popup
            property: "reveal"
            to: 1
            duration: 220
            easing.type: Easing.OutCubic
            onFinished: popup.cachedHeight = popup.panelHeight
        }

        Timer {
            id: presentTimer
            interval: 16
            onTriggered: {
                if (popup.current === "" || ShellState.dropdown !== popup.current) return;
                // Wait for the compositor to acknowledge the newly sized surface.
                if (popup.panelHeight <= 0) { restart(); return; }
                const h = Math.round(popup.panelHeight);
                if (h !== popup.measuredHeight) { popup.measuredHeight=h; popup.stableFrames=0; restart(); return; }
                if (++popup.stableFrames < 2) { restart(); return; }
                if (!popup.surfaceReady) { popup.surfaceReady=true; restart(); return; }
                if (Math.round(popup.width) !== Math.round(popup.implicitWidth) || Math.round(popup.height) !== Math.round(popup.implicitHeight)) { restart(); return; }
                openAnim.start();
            }
        }

        SequentialAnimation {
            id: closeAnim
            NumberAnimation { target: popup; property: "reveal"; to: 0; duration: 170; easing.type: Easing.InCubic }
            // Keep the last panel instantiated: rebuilding a large QML tree on
            // every click was costing hundreds of milliseconds.
            ScriptAction { script: popup.surfaceReady=false }
        }

        SequentialAnimation {
            id: swapAnim

            property string next: ""
            property real nextX: 0

            NumberAnimation {
                target: popup
                property: "reveal"
                to: 0
                duration: 110
                easing.type: Easing.InCubic
            }
            // The surface moves and resizes to the incoming panel here, with
            // nothing drawn in it.
            ScriptAction {
                script: {
                    popup.anchorX = swapAnim.nextX;
                    popup.surfaceReady=false;
                    popup.cachedHeight=0;
                    popup.current = swapAnim.next;
                }
            }
            ScriptAction { script: presentTimer.restart() }
        }

        Connections {
            target: ShellState

            function onDropdownChanged(): void {
                const requested = ShellState.dropdown;
                const bottom = requested === "monitor" || requested === "clipboard" || requested === "usb" || requested === "phone";
                const wantedScreen = (bottom ? ShellState.bottomBarScreens[0] : ShellState.barScreens[0])?.name;
                const want = popup.modelData.name === wantedScreen ? requested : "";

                // **The ID editor arms at once.** It is typed into the moment
                // it opens, from a click on the bar -- and with the pointer
                // still over the bar, an unarmed grab left the surface without
                // the keyboard (measured: the editor's window went active and
                // lost it again 4 ms later, and a key typed then never arrived)
                // until the pointer moved into the panel. The other panels are
                // reached by moving into them first, and keep the wait.
                popup.grabArmed = want !== "" && (!ShellState.barHovered || want === "ident" || want === "comic" || want === "clipboard" || want === "monitor");

                outsideClose.stop();
                popup.stableFrames=0; popup.measuredHeight=0;
                presentTimer.stop();
                openAnim.stop();
                swapAnim.stop();
                closeAnim.stop();

                if (want === "") {
                    // Complete the content transition before unmapping its surface.
                    if (popup.current !== "") closeAnim.start();
                } else if (popup.current === want && !popup.surfaceReady && popup.cachedHeight > 0 && Math.abs(popup.panelHeight - popup.cachedHeight) < 1) {
                    // The cached panel already has geometry. Map it and start
                    // moving on the next scene-graph turn instead of loading it.
                    popup.anchorX = ShellState.dropdownAnchorX;
                    popup.reveal = 0;
                    popup.surfaceReady = true;
                    Qt.callLater(() => { if (ShellState.dropdown === popup.current) openAnim.start(); });
                } else if (popup.current === "" || popup.current === want || !popup.surfaceReady) {
                    // Nothing showing, or the same panel caught mid-close.
                    popup.anchorX = ShellState.dropdownAnchorX;
                    if (popup.current !== want) popup.cachedHeight = 0;
                    if (popup.current === "" || !popup.surfaceReady) {popup.reveal = 0; popup.surfaceReady=false;}
                    popup.current = want;
                    // Let the new surface and loader acquire their final size first.
                    presentTimer.restart();
                } else {
                    swapAnim.next = want;
                    swapAnim.nextX = ShellState.dropdownAnchorX;
                    swapAnim.start();
                }
            }

            function onExternalDialogOpenChanged(): void {
                popup.grabArmed = false;
                if(ShellState.externalDialogOpen) focusReturn.stop();
                else if(popup.current!=="") focusReturn.restart();
            }

            function onBarHoveredChanged(): void {
                if (!ShellState.barHovered && popup.current !== "" && !ShellState.externalDialogOpen && !focusReturn.running)
                    popup.grabArmed = true;
            }
        }

        // A click anywhere outside closes. The bar is in the list so clicking
        // another readout reaches it and switches dropdowns in one go.
        HyprlandFocusGrab {
            active: popup.grabArmed && popup.reveal > 0.99 && !openAnim.running && !swapAnim.running && !presentTimer.running && ShellState.dropdown === popup.current && !ShellState.externalDialogOpen
            windows: [popup, ShellState.barWindow, ShellState.bottomBarWindow].filter(w => w !== null)
            onCleared: if (popup.current !== "" && ShellState.dropdown === popup.current && popup.grabArmed && !ShellState.externalDialogOpen && popup.reveal > 0.99 && !openAnim.running && !swapAnim.running && !presentTimer.running && !focusReturn.running) outsideClose.restart()
        }

        Timer { id: focusReturn; interval: 260; onTriggered: if(popup.current!==""&&!ShellState.externalDialogOpen) popup.grabArmed=true }

        Timer { id: outsideClose; interval: 0; onTriggered: if (!ShellState.externalDialogOpen && popup.reveal > 0.99) ShellState.dropdown = "" }

        Item {
            id: holder

            focus: true
            // Soft elevation without rendering the entire popup into another texture.

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: popup.surfaceInset
            anchors.rightMargin: popup.surfaceInset
            height: popup.panelHeight
            opacity: popup.reveal
            enabled: ShellState.dropdown === popup.current && popup.reveal > 0.85
            // Slides down into place from under the bar. Whatever is still above
            // the surface top is simply not drawn, so the bar hides it.
            y: popup.surfaceInset + (popup.current === "monitor" || popup.current === "clipboard" || popup.current === "usb" || popup.current === "phone" ? 1 : -1) * popup.slide * (1 - popup.reveal)

            // A dropdown that has an inner view open (the Wi-Fi settings view)
            // takes Escape to step back out of it first; otherwise Escape
            // closes the dropdown.
            Keys.onEscapePressed: {
                if (content.item && content.item.canGoBack === true)
                    content.item.goBack();
                else
                    ShellState.dropdown = "";
            }

            // Below a short view the surface is sized to the taller one, so
            // there is transparent space under the visible panel; a click there
            // closes the dropdown like any click off it. Zero-height, and so
            // inert, for a panel that fills the surface.
            MouseArea {
                anchors.top: content.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                onClicked: ShellState.dropdown = ""
            }

            // The compositor can slide a real, styled surface into view while
            // the expensive panel tree is still being instantiated. Fade the
            // content over it when ready, instead of flashing a new surface.
            ChamferPanel {
                anchors.fill: parent
                visible: opacity > 0
                opacity: content.status === Loader.Ready ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                scanlines: false
                chamfer: Appearance.chamfer.panel
                fillColor: Theme.widgetGlass
                borderColor: Theme.widgetBorder
                Column {
                    anchors.centerIn: parent
                    spacing: 9
                    Text { text: "SENSEI // " + popup.current.toUpperCase(); color: Theme.widgetText; font.family: Appearance.font.data; font.pixelSize: 17; font.bold: true }
                    Text { text: content.status === Loader.Error ? "Panel failed to load" : "Preparing controls…"; color: Theme.widgetMuted; font.family: Appearance.font.data; font.pixelSize: 12 }
                }
            }

            Loader {
                id: content
                // Heavy panels instantiate over multiple event-loop turns so
                // clicking a readout never blocks the bar's first response.
                asynchronous: true
                opacity: status === Loader.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                width: parent.width
                active: popup.current !== ""

                sourceComponent: {
                    switch (popup.current) {
                    case "docker": return dockerPanel;
                    case "usb": return usbPanel;
                    case "phone": return phonePanel;
                    case "comic": return comicPanel;
                    case "spotify": return spotifyPanel;
                    case "sound": return soundPanel;
                    case "weather": return weatherPanel;
                    case "calendar": return calendarPanel;
                    case "displays": return displaysPanel;
                    case "monitor": return monitorPanel;
                    case "clipboard": return clipboardPanel;
                    case "ident":
                        return identPanel;
                    case "wifi":
                        return wifiPanel;
                    case "bluetooth":
                        return bluetoothPanel;
                    case "power":
                        return powerPanel;
                    case "system":
                        return systemPanel;
                    default:
                        return null;
                    }
                }
            }

            Component {
                id: identPanel

                OperatorDropdown {
                    width: holder.width
                }
            }

            Component {
                id: wifiPanel

                WifiDropdown {
                    width: holder.width
                }
            }

            Component {
                id: bluetoothPanel

                BluetoothDropdown {
                    width: holder.width
                }
            }

            Component { id: dockerPanel; DockerDropdown { width: holder.width } }
            Component { id: usbPanel; UsbDropdown { width: holder.width } }
            Component { id: phonePanel; PhoneDropdown { width: holder.width } }
            Component { id: comicPanel; ComicDropdown { width: holder.width } }
            Component { id: spotifyPanel; SpotifyDropdown { width: holder.width } }
            Component { id: soundPanel; SoundDropdown { width: holder.width } }
            Component { id: weatherPanel; WeatherDropdown { width: holder.width } }
            Component { id: calendarPanel; CalendarDropdown { width: holder.width } }
            Component { id: displaysPanel; DisplayWallpapers { width: holder.width } }
            Component { id: monitorPanel; MonitorDropdown { width: holder.width } }
            Component { id: clipboardPanel; ClipboardDropdown { width: holder.width } }
            Component {
                id: systemPanel
                SystemDropdown { width: holder.width }
            }

            Component {
                id: powerPanel

                PowerDropdown {
                    width: holder.width
                }
            }
        }
    }
}
