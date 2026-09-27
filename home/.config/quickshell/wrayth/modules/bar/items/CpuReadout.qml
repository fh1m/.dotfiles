import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    implicitWidth: 144
    implicitHeight: 34
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        NrLabel { anchors.verticalCenter: parent.verticalCenter; text: "\uf2db CPU"; pixelSize: 12; font.letterSpacing: 0.5 }
        SegmentMeter { anchors.verticalCenter: parent.verticalCenter; segments: 4; segmentWidth: 4; segmentHeight: 16; value: SysInfo.cpuPercent / 100; litColor: Theme.signal }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: Math.round(SysInfo.cpuPercent) + "%"; font.family: Appearance.font.data; font.pixelSize: 13; font.weight: 600; color: Theme.signal }
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: (RobotBench.data.cpuTemperature ?? "--") + "°C CPU"; font.family: Appearance.font.data; font.pixelSize: 12; color: (RobotBench.data.cpuTemperature ?? 0) >= 85 ? Theme.accent : Theme.dim }
        }
    }
}
