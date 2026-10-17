import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// The wallpaper layer, one surface per screen, below everything else.
Variants {
    model: ShellState.screens

    PanelWindow {
        id:wallpaperWindow
        required property ShellScreen modelData

        screen: modelData
        readonly property bool story:StoryWallpapers.outputs.includes(modelData.name)
        visible:!story||!StoryWallpapers.nativePlayback
        color: story?"transparent":Theme.deep

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "sensei-background"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Wallpaper {
            visible:!wallpaperWindow.story
            // The saved per-display choices arrive asynchronously. Never show
            // a bundled theme wallpaper in the gap before that file is read.
            source: Wallpapers.loaded ? Wallpapers.displaySource((modelData?.name ?? (MachineProfile.primaryOutput||"DP-3"))) : Wallpapers.startupSource(ShellState.isExternalOutput(modelData?.name ?? (MachineProfile.primaryOutput||"DP-3"))?(MachineProfile.primaryOutput||"DP-3"):(modelData?.name ?? (MachineProfile.primaryOutput||"DP-3")))
            imageFillMode: Wallpapers.displayMode((modelData?.name ?? (MachineProfile.primaryOutput||"DP-3")))
            anchors.fill: parent

            // Crisp wallpaper with a mild static dim behind workspaces.
            dim: 0.2
        }

        Repeater {model:wallpaperWindow.story&&!StoryWallpapers.panorama&&!StoryWallpapers.reduced?3:0
            Rectangle {required property int index;width:2;height:2;x:parent.width*(.24+index*.27);y:parent.height*(.16+index*.08);color:"#f23d70";opacity:.15
                SequentialAnimation on opacity {loops:Animation.Infinite;running:visible
                    NumberAnimation {to:.4;duration:1800+index*450}
                    NumberAnimation {to:.08;duration:2400+index*450}
                    PauseAnimation {duration:3500}
                }
            }
        }
        // Only under EVERYTHING. This surface is behind every window, so lines
        // on it never touch window content whatever the exclusion says.
        Scanlines {
            surface: "wallpaper"
        }
    }
}
