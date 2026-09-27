import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    implicitWidth: 224
    implicitHeight: 34
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        NrLabel { anchors.verticalCenter: parent.verticalCenter; text: "\uf108 GPU"; pixelSize: 12; font.letterSpacing: 0.5 }
        SegmentMeter { anchors.verticalCenter: parent.verticalCenter; segments: 4; segmentWidth: 4; segmentHeight: 16; value: (RobotBench.data.intelUsage ?? 0) / 100; litColor: Theme.signal }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: "INTEL " + (RobotBench.data.intelUsage === null || RobotBench.data.intelUsage === undefined ? "--" : Math.round(RobotBench.data.intelUsage) + "%"); font.family: Appearance.font.data; font.pixelSize: 13; font.weight: 600; color: Theme.signal }
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: RobotBench.data.gpu.state === "sleep" ? "RTX 0% · SLEEP" : (RobotBench.data.gpu.state === "active" ? "RTX " + Math.round(RobotBench.data.gpu.usage) + "% · " + Math.round(RobotBench.data.gpu.temperature) + "°C" : "RTX N/A"); font.family: Appearance.font.data; font.pixelSize: 12; color: Theme.dim }
        }
    }
}
