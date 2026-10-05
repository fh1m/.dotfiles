import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 title:"\uf085 Sensei // operator deck";katakana:"ОПЕРАТОР";implicitWidth:596
 Column {width:parent.width;spacing:14
 NrLabel {text:"fh1m / R-01  ·  ZenBook Pro Duo UX581GV";pixelSize:15;color:Theme.widgetAccent}
 NrLabel {text:"Two panels. One RTX. Zero patience for mystery load.";pixelSize:11;color:Theme.widgetMuted}
 Rectangle {width:parent.width;height:1;color:Theme.rule}
 Row {width:parent.width;height:55;spacing:0
  Repeater {model:[
   {label:"CPU",value:Math.round(LiveMonitor.data.cpu??0)+"%"},
   {label:"RAM FREE",value:((LiveMonitor.data.memory?.available??0)/1073741824).toFixed(1)+" GiB"},
   {label:"CUDA JOBS",value:String(RobotBench.data.gpu.computeCount??0)},
   {label:"UPTIME",value:Math.floor((LiveMonitor.data.uptime??0)/3600)+"h "+Math.floor((LiveMonitor.data.uptime??0)/60%60)+"m"}
  ]
   Item {required property var modelData;required property int index;width:parent.width/4;height:55
    Rectangle {visible:index>0;x:0;y:5;width:1;height:45;color:Theme.rule}
    Column {x:12;y:4;spacing:4
     NrLabel {text:modelData.label;pixelSize:10;color:Theme.widgetMuted}
     NrLabel {text:modelData.value;pixelSize:17;color:Theme.widgetAccent}
    }
   }
  }
 }
 NrLabel {text:"USB "+(RobotBench.data.boardCount??0)+" boards  ·  "+(RobotBench.data.simCount??0)+" simulators  ·  "+ClipboardVault.count+" clips  ·  "+((RobotBench.data.gpu.computeCount??0)>0?"CUDA IN USE":"CUDA READY");pixelSize:11;color:Theme.widgetMuted}
 Grid {columns:3;spacing:8
 ControlTile {label:"System Monitor";glyph:"\uf080";onActivated:ShellState.dropdown="monitor"}
 ControlTile {label:"Clipboard Vault";glyph:"\uf0ea";onActivated:ShellState.dropdown="clipboard"}
 ControlTile {label:"Robotics controls";glyph:"\uf085";onActivated:{ShellState.systemPage=2;ShellState.dropdown="system"}}
 ControlTile {label:"NVIDIA terminal";glyph:"\uf120";onActivated:Quickshell.execDetached(["/home/fh1m/.local/bin/sim-console"])}
 ControlTile {label:"Project files";glyph:"\uf07c";onActivated:Quickshell.execDetached(["xdg-open","/home/fh1m"])}
 ControlTile {label:"Keyboard shortcuts";glyph:"\uf11c";onActivated:ShellState.openExclusive("shortcuts")}
 }
 ControlTile {label:"Display wallpapers";glyph:"\uf03e";onActivated:ShellState.openExclusive("picker")}
 NrLabel {text:"FIELD TAG  /  LEFT GITHUB  ·  MIDDLE DECK  ·  RIGHT XKCD";pixelSize:10;color:Theme.widgetMuted}
 }
}
