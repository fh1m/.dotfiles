import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
Rectangle {
 id:root
 implicitHeight:bannerContent.implicitHeight+20
 color:Theme.surfaceOne;radius:3;border.width:1;border.color:Theme.rule
 Column {id:bannerContent;anchors.fill:parent;anchors.margins:10;spacing:8
  Row {width:parent.width;spacing:20
   Text {text:'Operator tools';color:Theme.paper;font.family:Appearance.font.ui;font.pixelSize:12;font.weight:Font.DemiBold}
   Text {text:'CPU '+(LiveMonitor.data.memory?.available===undefined?'—':Math.round(LiveMonitor.data.cpu)+'%')+'  ·  RAM '+(LiveMonitor.data.memory?.available===undefined?'—':(LiveMonitor.data.memory.available/1073741824).toFixed(1)+' GiB free')+'  ·  CUDA '+(RobotBench.data.gpu.computeCount??0)+' jobs  ·  USB '+(RobotBench.data.boardCount??0)+' boards';color:Theme.paperMuted;font.family:Appearance.font.telemetry;font.pixelSize:11}
  }
  Flow {width:parent.width;spacing:7
   ControlTile {implicitWidth:140;label:'Monitor';glyph:'\uf080';onActivated:{ShellState.dropdownAnchorX=ShellState.anchorFor('monitor');ShellState.dropdown='monitor';}}
   ControlTile {implicitWidth:140;label:'Clipboard';glyph:'\uf0ea';onActivated:{ShellState.dropdownAnchorX=ShellState.anchorFor('clipboard');ShellState.dropdown='clipboard';}}
   ControlTile {implicitWidth:140;label:'Robotics';glyph:'\uf085';onActivated:{ShellState.systemPage=2;ShellState.dropdownAnchorX=ShellState.anchorFor('system');ShellState.dropdown='system';}}
   ControlTile {implicitWidth:140;label:'GPU terminal';glyph:'\uf120';onActivated:Quickshell.execDetached([Quickshell.env('HOME')+'/.local/bin/sim-console'])}
   ControlTile {implicitWidth:140;label:'Projects';glyph:'\uf07c';onActivated:Quickshell.execDetached(['xdg-open',Quickshell.env('HOME')])}
   ControlTile {implicitWidth:140;label:'Shortcuts';glyph:'\uf11c';onActivated:ShellState.openExclusive('shortcuts')}
   ControlTile {implicitWidth:140;label:'Wallpapers';glyph:'\uf03e';onActivated:ShellState.openExclusive('picker')}
  }
 }
}
