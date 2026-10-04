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
    title: "\uf1de SYSTEM"
    katakana: "УПРАВЛЕНИЕ"
    implicitWidth: 596
    function action(name, value = ""): void {
        Quickshell.execDetached(value === "" ? ["/home/fh1m/.local/bin/zenbook-controls", name] : ["/home/fh1m/.local/bin/zenbook-controls", name, value]);
        refresh.restart();
    }
    function launch(args): void { ShellState.dropdown = ""; Quickshell.execDetached(args); }
    Column {
        width: parent.width
        spacing: 12
        Row {
            spacing: 8
            ControlTile { implicitWidth: 104; label: "Quick"; glyph: "\uf1de"; navigation:true;selected: ShellState.systemPage === 0; onActivated: ShellState.systemPage = 0 }
            ControlTile { implicitWidth: 104; label: "Hardware"; glyph: "\uf2db"; navigation:true;selected: ShellState.systemPage === 1; onActivated: ShellState.systemPage = 1 }
            ControlTile { implicitWidth: 104; label: "Robotics"; glyph: "\uf1b2"; navigation:true;selected: ShellState.systemPage === 2; onActivated: ShellState.systemPage = 2 }
            ControlTile {implicitWidth:104;label:"Network";glyph:"\uf1eb";navigation:true;selected:ShellState.systemPage===3;onActivated:ShellState.systemPage=3}
            ControlTile {implicitWidth:104;label:"Packages";glyph:"󰏖";navigation:true;selected:ShellState.systemPage===4;onActivated:ShellState.systemPage=4}
        }
        Rectangle { width: parent.width; height: 1; color: Theme.widgetBorder }
        Loader {width:parent.width;active:ShellState.systemPage===3;visible:active;height:active?(item?.implicitHeight??0):0;sourceComponent:Component {NetworkSection {width:parent.width}}}
        Loader {width:parent.width;active:ShellState.systemPage===4;visible:active;height:active?(item?.implicitHeight??0):0;sourceComponent:Component {PackagesSection {width:parent.width}}}
        Column {id:systemPageEnter0Container;
            width: parent.width; spacing: 12; visible: ShellState.systemPage === 0
            
            Grid {
                columns: 3; spacing: 8
                ControlTile { label: "Wi-Fi"; glyph: "\uf1eb"; selected: Networking.wifiEnabled; onActivated: Networking.wifiEnabled = !Networking.wifiEnabled }
                ControlTile { label: "Bluetooth"; glyph: "\uf293"; enabled: Bluetooth.defaultAdapter !== null; selected: Bluetooth.defaultAdapter?.enabled ?? false; onActivated: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
                ControlTile { label: "Airplane"; glyph: "\uf072"; selected: RobotBench.data.airplaneMode ?? false; onActivated: root.action("airplane") }
                ControlTile { label: Audio.muted ? "Unmute" : "Mute"; glyph: Audio.muted ? "\uf026" : "\uf028"; selected: !Audio.muted; onActivated: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]) }
                ControlTile { label: Audio.micMuted ? "Mic on" : "Mic off"; glyph: "\uf130"; selected: !Audio.micMuted; onActivated: {if(Audio.source?.audio)Audio.source.audio.muted=!Audio.micMuted;} }
                ControlTile { label: "Keep Awake"; glyph: "\uf186"; selected: Idle.hold; onActivated: Idle.toggle() }
            }
            ControlSlider { title: "Speaker volume"; glyph: "\uf028"; level: Audio.volume * 100; onEdited: percent => {if(Audio.sink?.audio)Audio.sink.audio.volume=Math.min(1,percent/100);} }
            ControlSlider { title: "Microphone gain"; maximum: 200; glyph: "\uf130"; level: Audio.micVolume * 100; onEdited: percent => {if(Audio.source?.audio)Audio.source.audio.volume=Math.min(2,percent/100);} }
            ControlSlider { title: "Main display"; glyph: "\uf108"; level: RobotBench.data.mainBrightness ?? 0; onEdited: percent => DisplayControls.setLevel("main", percent) }
            ControlSlider { title: "ScreenPad"; glyph: "\uf26c"; level: RobotBench.data.brightness ?? 0; onEdited: percent => DisplayControls.setLevel("screenpad", percent) }
            Row {
                spacing: 8
                ControlTile { label: "Eco"; glyph: "\uf06c"; selected: Power.profile === PowerProfile.PowerSaver; onActivated: Power.setProfile("power-saver") }
                ControlTile { label: "Balanced"; glyph: "\uf24e"; selected: Power.profile === PowerProfile.Balanced; onActivated: Power.setProfile("balanced") }
                ControlTile { label: "Performance"; glyph: "\uf135"; enabled: Power.hasPerformance; selected: Power.profile === PowerProfile.Performance; onActivated: Power.setProfile("performance") }
            }
            Grid {
                columns: 3; spacing: 8
                ControlTile { label: "Devices"; glyph: "\uf293"; onActivated: { ShellState.dropdownAnchorX = ShellState.anchorFor("bluetooth"); ShellState.dropdown = "bluetooth"; } }
                ControlTile { label: "Audio mixer"; detail:"Per-app levels"; glyph: "\uf1de"; onActivated: root.launch(["pavucontrol"]) }
                ControlTile { label: "Shortcuts"; detail:"Key bindings"; glyph: "\uf11c"; onActivated: root.launch(["/home/fh1m/.local/bin/desktop-shortcuts"]) }
                ControlTile { label: "Lock"; glyph: "\uf023"; onActivated: { ShellState.dropdown = ""; ShellState.locked = true; } }
                ControlTile { label: "Power menu"; glyph: "\uf011"; onActivated: { ShellState.dropdown = ""; ShellState.openExclusive("power"); } }
                ControlTile { label: "System load"; detail:"Live processes"; glyph: "\uf201"; onActivated: root.launch(["sensei-terminal", "--title", "System-Monitor", "btop"]) }
            }
            ControlTile {label:ServicesControl.remoteActive?"Stop remote access":"Start remote access";glyph:"\uf108";detail:"NoMachine · on demand";onActivated:ServicesControl.toggleRemote()}
            Text {width:parent.width;visible:(Power.error+ServicesControl.error).length>0;text:Power.error||ServicesControl.error;color:Theme.widgetAccent;wrapMode:Text.WordWrap;font.family:Appearance.font.data;font.pixelSize:12}
            NrLabel { pixelSize: 12; text: `${Math.round(Power.charge)}% BATTERY  //  ${Power.onBattery ? "BATTERY" : "AC POWER"}  // CAP ${RobotBench.data.chargeLimit ?? "--"}%`; color: Theme.widgetMuted }
        }
        Column {id:systemPageEnter1Container;
            width: parent.width; spacing: 12; visible: ShellState.systemPage === 1
            
            NrLabel { pixelSize: 12; color: Theme.widgetAccent; text: "\uf11c KEYBOARD BACKLIGHT" }
            Row {
                spacing: 8
                Repeater {
                    model: ["Off", "Low", "Medium", "High"]
                    ControlTile { required property int index; required property string modelData; implicitWidth: 136; label: modelData; selected: RobotBench.data.keyboardBrightness === index; onActivated: root.action("keyboard", String(index)) }
                }
            }
            NrLabel { pixelSize: 12; color: Theme.widgetAccent; text: "\uf240 BATTERY CHARGE LIMIT" }
            Row {
                spacing: 8
                Repeater {
                    model: [60, 80, 100]
                    ControlTile { required property int modelData; label: `${modelData}%`; glyph: "\uf240"; selected: RobotBench.data.chargeLimit === modelData; onActivated: root.action("charge", String(modelData)) }
                }
            }
            Text { width: parent.width; text: "60% desk use · 80% everyday · 100% travel"; font.family: Appearance.font.data; font.pixelSize: 12; color: Theme.widgetMuted }
            Row {
                spacing: 8
                ControlTile { label: "Auto fans"; glyph: "\udb80\ude10"; enabled: RobotBench.data.fanControlAvailable ?? false; selected: RobotBench.data.fanMode === 2; onActivated: root.action("fan", "auto") }
                ControlTile { label: "CPU boost"; glyph: "\udb80\ude10"; enabled: RobotBench.data.fanControlAvailable ?? false; selected: RobotBench.data.fanMode === 0; onActivated: root.action("fan", "boost") }
                ControlTile { label: "CPU mode"; glyph: "\uf135"; onActivated: root.action("profile") }
            }
            Text { width: parent.width; text: `CPU ${RobotBench.data.cpuTemperature ?? "--"}°C  ·  CPU/GPU fans ${(RobotBench.data.fans ?? []).join(" / ")} RPM`; font.family: Appearance.font.data; font.pixelSize: 13; color: (RobotBench.data.cpuTemperature ?? 0) >= 85 ? Theme.widgetAccent : Theme.widgetAccent }
            Grid {
                columns: 3; spacing: 8
                ControlTile { label: "Touchpad"; glyph: "\uf245"; selected: RobotBench.data.touchpadEnabled ?? true; onActivated: root.action("touchpad") }
                ControlTile { label: "Natural scroll"; glyph: "\uf07d"; selected: RobotBench.data.naturalScroll ?? true; onActivated: root.action("natural") }
                ControlTile { label: "Animations"; glyph: "\uf0d0"; selected: RobotBench.data.animationsEnabled ?? true; onActivated: root.action("animations") }
                ControlTile { label: "ScreenPad on/off"; glyph: "\uf26c"; selected: RobotBench.data.screenpadOn ?? true; onActivated: root.action("screenpad") }
                ControlTile { label: "Swap screens"; glyph: "\uf074"; onActivated: root.action("swap") }
                ControlTile { label: RobotBench.data.cameraEnabled ? "Camera on" : "Camera off"; glyph: "\uf030"; enabled: RobotBench.data.cameraControlAvailable ?? false; selected: RobotBench.data.cameraEnabled ?? false; onActivated: root.action("camera") }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.widgetBorder }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: `UX581GV · Intel UHD + RTX 2060\nStorage free: ${RobotBench.data.diskFreeGiB ?? "--"} GiB · ${RobotBench.data.diskUsedPercent ?? "--"}% used\nBuilt-in RGB / IR camera: ${RobotBench.data.cameraEnabled ? "ON" : "OFF"} · ScreenPad stays connected when switched off`; font.family: Appearance.font.data; font.pixelSize: 13; color: Theme.widgetMuted; lineHeight: 1.5 }
        }
        Column {id:systemPageEnter2Container;
            width: parent.width; spacing: 12; visible: ShellState.systemPage === 2
            
            ControlTile {label:"Docker robotics lab";glyph:"\uf308";detail:"Containers · CUDA · ARM · tmux";implicitWidth:parent.width;implicitHeight:52;onActivated:ShellState.dropdown="docker"}
            Row {
                spacing: 8
                ControlTile { label: "Training mode"; glyph: "\uf135"; selected: RobotBench.data.trainingMode ?? false; onActivated: root.action("training", (RobotBench.data.trainingMode ?? false) ? "off" : "on") }
                ControlTile { label: "NVIDIA terminal"; glyph: "\uf120"; onActivated: root.launch(["/home/fh1m/.local/bin/sim-console"]) }
                ControlTile { label: "GPU monitor"; glyph: "\uf201"; onActivated: root.launch(["sensei-terminal", "--title", "GPU-Monitor", "nvtop"]) }
            }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: "Training mode moves Chrome to Intel (saved tabs reopen), enables Performance + Keep Awake, and restores your previous choices when turned off. Other running GPU apps need relaunching."; font.family: Appearance.font.data; font.pixelSize: 12; color: Theme.widgetMuted }
            NrLabel { pixelSize: 13; color: (RobotBench.data.gpu.computeCount ?? 0) > 0 ? Theme.widgetAccent : Theme.widgetAccent; text: RobotBench.data.gpu.state === "sleep" ? "RTX 2060 · SLEEP · 0%" : (RobotBench.data.gpu.state === "active" ? `RTX ${Math.round(RobotBench.data.gpu.usage)}% · ${Math.round(RobotBench.data.gpu.temperature)}°C` : "RTX · DATA UNAVAILABLE") }
            Text { width: parent.width; text: RobotBench.data.gpu.state === "active" ? `VRAM ${Math.round(RobotBench.data.gpu.memoryUsedMiB ?? 0)} / ${Math.round(RobotBench.data.gpu.memoryTotalMiB ?? 0)} MiB` : "No GPU workload while sleeping"; font.family: Appearance.font.data; font.pixelSize: 13; color: Theme.widgetText }
            SegmentMeter { width: parent.width; segments: 40; segmentWidth: 11; segmentHeight: 8; value: (RobotBench.data.gpu.memory ?? 0) / 100; litColor: Theme.widgetAccent; hotThreshold: 0.85 }
            Column {
                width: parent.width; spacing: 6
                Repeater {
                    model: (RobotBench.data.gpu.processes ?? []).slice(0, 6)
                    Text { required property var modelData; width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText; text: `${modelData.type.includes("C") ? "COMPUTE" : "GRAPHICS"}  ${modelData.name}  · PID ${modelData.pid} · ${modelData.memoryMiB ?? "--"} MiB`; font.family: Appearance.font.data; font.pixelSize: 13; color: modelData.type.includes("C") ? Theme.widgetAccent : Theme.widgetAccent }
                }
                Text { visible: (RobotBench.data.gpu.processes ?? []).length === 0; text: RobotBench.data.gpu.processesKnown ? "No dedicated GPU processes" : "GPU process list unavailable"; font.family: Appearance.font.data; font.pixelSize: 12; color: Theme.widgetMuted }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.widgetBorder }
            Text { width: parent.width; wrapMode: Text.WordWrap; text: `USB serial devices: ${RobotBench.data.boardCount} · Simulators: ${RobotBench.data.simCount}\nCPU ${RobotBench.data.cpuTemperature ?? "--"}°C · Fans ${(RobotBench.data.fans ?? []).join("/")} RPM · Free disk ${RobotBench.data.diskFreeGiB ?? "--"} GiB`; font.family: Appearance.font.data; font.pixelSize: 13; color: Theme.widgetText; lineHeight: 1.5 }
            Repeater {
                model: (RobotBench.data.boards ?? []).slice(0, 3)
                Text { required property string modelData; width: parent.width; elide: Text.ElideMiddle; textFormat: Text.PlainText; text: "\uf287 " + modelData; font.family: Appearance.font.data; font.pixelSize: 12; color: Theme.widgetAccent }
            }
            Grid {
                columns: 3; spacing: 8
                ControlTile { label: "USB / serial"; glyph: "\uf287"; onActivated: root.launch(["sensei-terminal", "--title", "USB-Devices", "/home/fh1m/.local/bin/robot-bench-data", "--watch"]) }
                ControlTile { label: "Screenshot"; glyph: "\uf030"; onActivated: root.launch(["/home/fh1m/.local/bin/desktop-capture", "screenshot", "area"]) }
                ControlTile { label: RobotBench.data.recording ? "Stop recording" : "Record screen"; glyph: RobotBench.data.recording ? "\uf04d" : "\uf03d"; selected: RobotBench.data.recording ?? false; onActivated: root.launch(["/home/fh1m/.local/bin/desktop-capture", "record", "output"]) }
                ControlTile { label: "Screenshots"; glyph: "\uf07b"; onActivated: root.launch(["nautilus", "/home/fh1m/Pictures/Screenshots"]) }
                ControlTile { label: "Screencasts"; glyph: "\uf07b"; onActivated: root.launch(["nautilus", "/home/fh1m/Videos/Screencasts"]) }
                ControlTile { label: "Shortcuts"; detail:"Key bindings"; glyph: "\uf11c"; onActivated: root.launch(["/home/fh1m/.local/bin/desktop-shortcuts"]) }
            }
        }
    }
    Timer { id: refresh; interval: 500; onTriggered: RobotBench.refresh() }
}
