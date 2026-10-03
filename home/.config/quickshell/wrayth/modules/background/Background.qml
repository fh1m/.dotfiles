import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// The wallpaper layer, one surface per screen, below everything else.
Variants {
    model: ShellState.screens

    PanelWindow {
        required property ShellScreen modelData

        screen: modelData
        color: Theme.deep

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "wrayth-background"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Wallpaper {
            // The saved per-display choices arrive asynchronously. Never show
            // a bundled theme wallpaper in the gap before that file is read.
            source: Wallpapers.loaded ? Wallpapers.displaySource(modelData.name) : Wallpapers.startupSource(modelData.name)
            imageFillMode: Wallpapers.displayMode(modelData.name)
            anchors.fill: parent

            // Crisp wallpaper with a mild static dim behind workspaces.
            dim: 0.2
        }

        // Only under EVERYTHING. This surface is behind every window, so lines
        // on it never touch window content whatever the exclusion says.
        Scanlines {
            surface: "wallpaper"
        }
    }
}
