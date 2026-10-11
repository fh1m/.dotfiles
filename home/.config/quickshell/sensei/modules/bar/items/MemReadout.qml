import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    implicitWidth: 190
    implicitHeight: 34
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        NrLabel { anchors.verticalCenter: parent.verticalCenter; text: "\uf538 RAM"; pixelSize: 12; font.letterSpacing: 0.5 }
        SegmentMeter { anchors.verticalCenter: parent.verticalCenter; segments: 4; segmentWidth: 4; segmentHeight: 16; value: SysInfo.memPercent / 100; litColor: Theme.signal }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: SysInfo.memUsedGib.toFixed(1) + "G USED"; font.family: Appearance.font.data; font.pixelSize: 13; font.weight: 600; color: Theme.signal }
            Text { renderType: Text.QtRendering; renderTypeQuality: 104; text: (SysInfo.memTotalGib - SysInfo.memUsedGib).toFixed(1) + "G FREE"; font.family: Appearance.font.data; font.pixelSize: 12; color: Theme.dim }
        }
    }
}
