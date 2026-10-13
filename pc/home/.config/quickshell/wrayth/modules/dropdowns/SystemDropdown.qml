import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services

DropdownFrame {
    id: root
    title: "\uf1de System"
    katakana: "УПРАВЛЕНИЕ"
    implicitWidth: 596
    function action(name, value = ""): void {
        Quickshell.execDetached(value === "" ? ["/home/fh1m/.local/bin/sensei-desktop-control", name] : ["/home/fh1m/.local/bin/sensei-desktop-control", name, value]);
        refresh.restart();
    }
    function launch(args): void { ShellState.dropdown = ""; Quickshell.execDetached(args); }
    Column {
        width: parent.width
        spacing: 12
        Row {
            spacing: 8
            ControlTile { implicitWidth: 106; label: "Quick"; navigation:true;selected: ShellState.systemPage === 0; onActivated: ShellState.systemPage = 0 }
            ControlTile { implicitWidth: 106; label: "Hardware"; navigation:true;selected: ShellState.systemPage === 1; onActivated: ShellState.systemPage = 1 }
            ControlTile { implicitWidth: 106; label: "Robotics"; navigation:true;selected: ShellState.systemPage === 2; onActivated: ShellState.systemPage = 2 }
            ControlTile {implicitWidth: 106;label:"Network";navigation:true;selected:ShellState.systemPage===3;onActivated:ShellState.systemPage=3}
            ControlTile {implicitWidth: 106;label:"Packages";navigation:true;selected:ShellState.systemPage===4;onActivated:ShellState.systemPage=4}
        }
        Rectangle { width: parent.width; height: 1; color: Theme.widgetBorder }
        Loader {width:parent.width;active:ShellState.systemPage===3;visible:active;height:active?(item?.implicitHeight??0):0;sourceComponent:Component {NetworkSection {width:parent.width}}}
        Loader {width:parent.width;active:ShellState.systemPage===4;visible:active;height:active?(item?.implicitHeight??0):0;sourceComponent:Component {PackagesSection {width:parent.width}}}
        Column { id: systemPageEnter0Container
            width: parent.width; spacing: 10; visible: ShellState.systemPage === 0
            WidgetSection { width: parent.width; title: "Connections"; subtitle: Machine.netInterface ? "Network · " + Machine.netInterface : "No network interface"; glyph: "\uf1eb"
                Grid { columns: 3; spacing: 8
                    ControlTile { implicitWidth: 176; visible: MachineProfile.facts.hasWireless ?? false; label: "Wi-Fi"; glyph: "\uf1eb"; selected: Networking.wifiEnabled; onActivated: Networking.wifiEnabled = !Networking.wifiEnabled }
                    ControlTile { implicitWidth: 176; label: "Bluetooth"; glyph: "\uf293"; enabled: Bluetooth.defaultAdapter !== null; selected: Bluetooth.defaultAdapter?.enabled ?? false; onActivated: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
                    ControlTile { implicitWidth: 176; visible: false; label: "Airplane"; glyph: "\uf072"; selected: RobotBench.data.airplaneMode ?? false; onActivated: root.action("airplane") }
                    ControlTile { implicitWidth: 176; label: Audio.muted ? "Unmute" : "Mute"; glyph: Audio.muted ? "\uf026" : "\uf028"; selected: !Audio.muted; onActivated: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) }
                    ControlTile { implicitWidth: 176; label: Audio.micMuted ? "Mic on" : "Mic off"; glyph: "\uf130"; selected: !Audio.micMuted; onActivated: { if (Audio.source?.audio) Audio.source.audio.muted = !Audio.micMuted; } }
                    ControlTile { implicitWidth: 176; label: "Keep awake"; glyph: "\uf186"; selected: Idle.hold; onActivated: Idle.toggle() }
                }
            }
            WidgetSection { width: parent.width; title: "Levels"; subtitle: ""; glyph: "\uf1de"
                Column { width: parent.width; spacing: 3
                    ControlSlider { title: "Speaker volume"; glyph: "\uf028"; level: Audio.volume * 100; onEdited: percent => { if (Audio.sink?.audio) Audio.sink.audio.volume = Math.min(1, percent / 100); } }
                    ControlSlider { title: "Microphone gain"; maximum: 200; glyph: "\uf130"; level: Audio.micVolume * 100; onEdited: percent => { if (Audio.source?.audio) Audio.source.audio.volume = Math.min(2, percent / 100); } }
                }
            }
            WidgetSection { width: parent.width; title: "Power"; subtitle: Power.note; glyph: "\uf240"
                Row { spacing: 8
                    ControlTile { implicitWidth: 176; enabled: Power.controlsAvailable; label: "Eco"; glyph: "\uf06c"; selected: Power.profile === PowerProfile.PowerSaver; onActivated: Power.setProfile("power-saver") }
                    ControlTile { implicitWidth: 176; enabled: Power.controlsAvailable; label: "Balanced"; glyph: "\uf24e"; selected: Power.profile === PowerProfile.Balanced; onActivated: Power.setProfile("balanced") }
                    ControlTile { implicitWidth: 176; label: "Performance"; glyph: "\uf135"; enabled: Power.hasPerformance; selected: Power.profile === PowerProfile.Performance; onActivated: Power.setProfile("performance") }
                }
            }
            WidgetSection { width: parent.width; title: "Tools"; glyph: "\uf0b1"
                Grid { columns: 2; spacing: 8
                    ActionRow { implicitWidth: 268; label: "Bluetooth devices"; detail: "Pair and connect"; glyph: "\uf293"; onActivated: { ShellState.dropdownAnchorX = ShellState.anchorFor("bluetooth"); ShellState.dropdown = "bluetooth"; } }
                    ActionRow { implicitWidth: 268; label: "Audio mixer"; detail: "Per-app levels"; glyph: "\uf1de"; onActivated: root.launch(["pavucontrol"]) }
                    ActionRow { implicitWidth: 268; label: "Shortcuts"; detail: "Search every binding"; glyph: "\uf11c"; onActivated: ShellState.openExclusive("shortcuts") }
                    ActionRow { implicitWidth: 268; label: "Processes"; detail: "Open btop"; glyph: "\uf201"; onActivated: root.launch(["/home/fh1m/.local/bin/sensei-terminal", "--title", "System-Monitor", "btop"]) }
                    ActionRow { implicitWidth: 268; label: "Lock"; detail: "Secure this session"; glyph: "\uf023"; onActivated: { ShellState.dropdown = ""; ShellState.locked = true; } }
                    ActionRow { implicitWidth: 268; label: "Power menu"; detail: "Suspend or shut down"; glyph: "\uf011"; onActivated: { ShellState.dropdown = ""; ShellState.openExclusive("power"); } }
                    ActionRow { implicitWidth: 268; label: "Windows"; detail: "Restart once · Revenger"; glyph: "\uf17a"; onActivated: root.launch(["/home/fh1m/.local/bin/sensei-boot-windows"]) }
                    ActionRow { implicitWidth: 268; label: "Choose OS"; detail: "Linux / Windows / Misc"; glyph: "\uf108"; onActivated: root.launch(["/home/fh1m/.local/bin/sensei-boot-menu"]) }
                }
            }
            Text { width: parent.width; visible: (Power.error + ServicesControl.error).length > 0; text: Power.error || ServicesControl.error; color: Theme.widgetAccent; wrapMode: Text.WordWrap; font.family: Appearance.font.ui; font.pixelSize: 12 }
        }
        Column {
            width: parent.width; spacing: 12; visible: ShellState.systemPage === 1
            WidgetSection { width: parent.width; title: "Desktop hardware"; glyph: "\uf108"
                Column {width:parent.width;spacing:10
                    Text {text: MachineProfile.cpuName; font.family: Appearance.font.ui; font.pixelSize:13; color:Theme.widgetText}
                    Text {text: MachineProfile.gpuName; font.family: Appearance.font.ui; font.pixelSize:13; color:Theme.widgetText}
                    Text {text: MachineProfile.primaryOutput + " · NVIDIA display output"; font.family: Appearance.font.ui; font.pixelSize:13; color:Theme.widgetMuted}
                    Text {text: "CPU " + (RobotBench.data.cpuTemperature ?? "—") + "°C · Free storage " + (RobotBench.data.diskFreeGiB ?? "—") + " GiB"; font.family: Appearance.font.ui; font.pixelSize:13; color:Theme.widgetText}
                    ControlTile {label:"Animations";selected:RobotBench.data.animationsEnabled ?? true;onActivated:root.action("animations")}
                    Text {width:parent.width;wrapMode:Text.WordWrap;text:"Monitor brightness uses the display's own controls. CPU and fan policy remain at verified firmware defaults.";font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
                }
            }
        }
        Column {id:systemPageEnter2Container;
            width: parent.width; spacing: 12; visible: ShellState.systemPage === 2

            Row {spacing:8
                ControlTile {label:"Containers";glyph:"\uf308";detail:"Docker / Distrobox";implicitWidth:278;implicitHeight:48;onActivated:ShellState.dropdown="docker"}
                ControlTile {label:"Projects";glyph:"\uf07b";detail:"Search / resume";implicitWidth:278;implicitHeight:48;onActivated:root.launch(["/home/fh1m/.local/bin/sensei-terminal","--title","Project navigator","-e","/home/fh1m/.local/bin/sensei-project-picker"])}
            }
            Row {
                spacing: 8
                ControlTile { label: "Training mode"; glyph: "\uf135"; selected: RobotBench.data.trainingMode ?? false; onActivated: root.action("training", (RobotBench.data.trainingMode ?? false) ? "off" : "on") }
                ControlTile { label: "NVIDIA terminal"; glyph: "\uf120"; onActivated: root.launch(["/home/fh1m/.local/bin/sim-console"]) }
                ControlTile { label: "GPU monitor"; glyph: "\uf201"; onActivated: root.launch(["/home/fh1m/.local/bin/sensei-terminal", "--title", "GPU-Monitor", "nvtop"]) }
            }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: "Training mode keeps the session awake and restores the prior idle choice when finished. NVIDIA remains available for graphics and CUDA; running apps are never moved or stopped."; font.family: Appearance.font.ui; font.pixelSize: 12; color: Theme.widgetMuted }
            NrLabel { pixelSize: 13; color: (RobotBench.data.gpu.computeCount ?? 0) > 0 ? Theme.widgetAccent : Theme.widgetAccent; text: RobotBench.data.gpu.state === "sleep" ? "NVIDIA · SLEEP · 0%" : (RobotBench.data.gpu.state === "active" ? `GPU ${Math.round(RobotBench.data.gpu.usage)}% · ${Math.round(RobotBench.data.gpu.temperature)}°C` : "GPU · DATA UNAVAILABLE") }
            Text { width: parent.width; text: RobotBench.data.gpu.state === "active" ? `VRAM ${Math.round(RobotBench.data.gpu.memoryUsedMiB ?? 0)} / ${Math.round(RobotBench.data.gpu.memoryTotalMiB ?? 0)} MiB` : "No GPU workload while sleeping"; font.family: Appearance.font.ui; font.pixelSize: 13; color: Theme.widgetText }
            SegmentMeter { width: parent.width; segments: 40; segmentWidth: 11; segmentHeight: 8; value: (RobotBench.data.gpu.memory ?? 0) / 100; litColor: Theme.widgetAccent; hotThreshold: 0.85 }
            Column {
                width: parent.width; spacing: 6
                Repeater {
                    model: (RobotBench.data.gpu.processes ?? []).slice(0, 6)
                    Text { required property var modelData; width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: `${modelData.type.includes("C") ? "COMPUTE" : "GRAPHICS"}  ${modelData.name}  · PID ${modelData.pid} · ${modelData.memoryMiB ?? "--"} MiB`; font.family: Appearance.font.ui; font.pixelSize: 13; color: modelData.type.includes("C") ? Theme.widgetAccent : Theme.widgetAccent }
                }
                Text { visible: (RobotBench.data.gpu.processes ?? []).length === 0; text: RobotBench.data.gpu.processesKnown ? "No dedicated GPU processes" : "GPU process list unavailable"; font.family: Appearance.font.ui; font.pixelSize: 12; color: Theme.widgetMuted }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.widgetBorder }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: `USB serial devices: ${RobotBench.data.boardCount} · Simulators: ${RobotBench.data.simCount}\nCPU ${RobotBench.data.cpuTemperature ?? "--"}°C · Fans ${(RobotBench.data.fans ?? []).join("/")} RPM · Free disk ${RobotBench.data.diskFreeGiB ?? "--"} GiB`; font.family: Appearance.font.ui; font.pixelSize: 13; color: Theme.widgetText; lineHeight: 1.5 }
            Repeater {
                model: (RobotBench.data.boards ?? []).slice(0, 3)
                Text { required property string modelData; width: parent.width; elide: Text.ElideMiddle; textFormat: Text.PlainText; text: "\uf287 " + modelData; font.family: Appearance.font.ui; font.pixelSize: 12; color: Theme.widgetAccent }
            }
            Grid {
                columns: 3; spacing: 8
                ControlTile { label: "USB / serial"; glyph: "\uf287"; onActivated: root.launch(["/home/fh1m/.local/bin/sensei-terminal", "--title", "USB-Devices", "/home/fh1m/.local/bin/robot-bench-data", "--watch"]) }
                ControlTile { label: "Screenshot"; glyph: "\uf030"; onActivated: root.launch(["/home/fh1m/.local/bin/desktop-capture", "screenshot", "area"]) }
                ControlTile { label: RobotBench.data.recording ? "Stop recording" : "Record screen"; glyph: RobotBench.data.recording ? "\uf04d" : "\uf03d"; selected: RobotBench.data.recording ?? false; onActivated: root.launch(["/home/fh1m/.local/bin/desktop-capture", "record", "output"]) }
                ControlTile { label: "Screenshots"; glyph: "\uf07b"; onActivated: root.launch(["nautilus", "/home/fh1m/Pictures/Screenshots"]) }
                ControlTile { label: "Screencasts"; glyph: "\uf07b"; onActivated: root.launch(["nautilus", "/home/fh1m/Videos/Screencasts"]) }
                ControlTile { label: "Shortcuts"; detail:"Key bindings"; glyph: "\uf11c"; onActivated: ShellState.openExclusive("shortcuts") }
            }
        }
    }
    Timer { id: refresh; interval: 500; onTriggered: RobotBench.refresh() }
}
