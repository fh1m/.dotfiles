pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services

// Battery state from UPower, power profiles from power-profiles-daemon.
// Quickshell exposes PowerProfiles.profile read-only, so setting one goes
// through powerprofilesctl; the D-Bus property then updates on its own.
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
        setProc.command = ["@HOME@/.local/bin/sensei-power", "set", cli];
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

    Process {id:setProc;onExited:{if(root.queuedProfile){let next=root.queuedProfile;root.queuedProfile="";root.setProfile(next);}}command:["@HOME@/.local/bin/sensei-power","get"];stdout:StdioCollector{onStreamFinished:{try{let d=JSON.parse(text);if(d.error)root.error=d.error;else{root.profileName=d.name;root.error="";}}catch(e){root.error=String(e);}}}}
    FileView {path:"@HOME@/.config/hypr/power-state.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{let d=JSON.parse(text());root.profileName=d.name;}catch(e){}}}
    onOnBatteryChanged:if(!RobotBench.data.trainingMode)root.setProfile(onBattery?"balanced":"performance")
    Timer {interval:60000;repeat:true;running:ShellState.dropdown==="system";onTriggered:if(!setProc.running){setProc.command=["@HOME@/.local/bin/sensei-power","get"];setProc.running=true;}}
    Component.onCompleted:root.setProfile(onBattery?"balanced":"performance")
}
