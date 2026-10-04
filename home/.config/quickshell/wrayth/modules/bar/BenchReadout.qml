import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.services

Row {
    id: root
    spacing: 10
    Text { renderType: Text.QtRendering; renderTypeQuality: 104;
        anchors.verticalCenter: parent.verticalCenter
        text: "\udb81\udea9"
        font.family: Appearance.font.icons
        font.pixelSize: 18
        color: Theme.signal
    }
    Text { renderType: Text.QtRendering; renderTypeQuality: 104;
        anchors.verticalCenter: parent.verticalCenter
        text: "СТЕНД"
        font.family: Appearance.font.accent
        font.pixelSize: 13
        color: Theme.signal
    }
    Divider { anchors.verticalCenter: parent.verticalCenter }
    NrLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: `\uf287 USB ${RobotBench.data.boardCount}`
        color: RobotBench.data.boardCount > 0 ? Theme.accent : Theme.dim
    }
    NrLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: `\uf1b2 SIM ${RobotBench.data.simCount > 0 ? RobotBench.data.simCount : "OFF"}`
        color: RobotBench.data.simCount > 0 ? Theme.signal : Theme.dim
    }
    NrLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: `\uf108 PAD ${RobotBench.data.brightness}%`
        color: RobotBench.data.brightness === 100 ? Theme.text : Theme.accent
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler {
        onTapped: Hyprland.dispatch('hl.dsp.exec_cmd("sensei-terminal --title Robot-Bench /home/fh1m/.local/bin/robot-bench-data --watch")')
    }
}
