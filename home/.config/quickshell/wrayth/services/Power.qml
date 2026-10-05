pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services

// Battery state from UPower; power policy through sensei-power/system76-power.
// The CPU profile never implies a full-speed PWM fan override.
Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool onBattery: UPower.onBattery
    readonly property real charge: (battery?.percentage ?? 0) * 100
    readonly property bool present: battery?.isPresent ?? false

    property string profileName: "balanced"
    property string error: ""
    readonly property int profile: profileName === "performance" ? PowerProfile.Performance : profileName === "power-saver" ? PowerProfile.PowerSaver : PowerProfile.Balanced
    readonly property bool hasPerformance: true

    // Tile order in the dropdown, with the names powerprofilesctl expects.
    readonly property var profiles: [
        {
            id: PowerProfile.PowerSaver,
            cli: "power-saver",
            label: "SAVER",
            katakana: "ЭКОНОМ"
        },
        {
            id: PowerProfile.Balanced,
            cli: "balanced",
            label: "BALANCED",
            katakana: "БАЛАНС"
        },
        {
            id: PowerProfile.Performance,
            cli: "performance",
            label: "PERFORMANCE",
            katakana: "ТУРБО"
        }
    ]

    property string queuedProfile: ""
    function setProfile(cli: string): void {
        if (setProc.running) {queuedProfile=cli; return;}
        setProc.command = ["/home/fh1m/.local/bin/sensei-power", "set", cli];
        setProc.running = true;
    }

    // The charge state, as the dropdown header words it.
    function stateLabel(): string {
        switch (battery?.state ?? UPowerDeviceState.Unknown) {
        case UPowerDeviceState.Charging:
            return "CHARGING";
        case UPowerDeviceState.Discharging:
            return "DISCHARGING";
        case UPowerDeviceState.Empty:
            return "EMPTY";
        case UPowerDeviceState.FullyCharged:
            return "CHARGED";
        case UPowerDeviceState.PendingCharge:
            return "PENDING CHARGE";
        case UPowerDeviceState.PendingDischarge:
            return "PENDING DISCHARGE";
        default:
            return "UNKNOWN";
        }
    }

    Process {id:setProc;onExited:{if(root.queuedProfile){let next=root.queuedProfile;root.queuedProfile="";root.setProfile(next);}}command:["/home/fh1m/.local/bin/sensei-power","get"];stdout:StdioCollector{onStreamFinished:{try{let d=JSON.parse(text);if(d.error)root.error=d.error;else{root.profileName=d.name;root.error="";}}catch(e){root.error=String(e);}}}}
    FileView {path:"/home/fh1m/.config/hypr/power-state.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{let d=JSON.parse(text());root.profileName=d.name;}catch(e){}}}
    onOnBatteryChanged:if(!RobotBench.data.trainingMode)root.setProfile("balanced")
    Timer {interval:60000;repeat:true;running:ShellState.dropdown==="system";onTriggered:if(!setProc.running){setProc.command=["/home/fh1m/.local/bin/sensei-power","get"];setProc.running=true;}}
    // Read the existing profile at startup. Reloading the shell must not
    // silently promote AC to Performance or cancel a deliberate user choice.
    Component.onCompleted: { setProc.command=["/home/fh1m/.local/bin/sensei-power","get"];setProc.running=true; }
}
