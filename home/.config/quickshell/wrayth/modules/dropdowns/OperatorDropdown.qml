import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 title:"\uf085 Sensei // operator deck";katakana:"ОПЕРАТОР";implicitWidth:596
 Column {width:parent.width;spacing:14
 NrLabel {text:Machine.hostname+" · ZenBook Pro Duo UX581GV";pixelSize:15;color:Theme.widgetAccent}
 NrLabel {text:"Hyprland · Intel display engine / RTX compute\nUptime "+Math.floor(LiveMonitor.data.uptime/3600)+"h "+Math.floor(LiveMonitor.data.uptime/60%60)+"m · "+LiveMonitor.data.ips.join(" / ");pixelSize:12}
 NrLabel {text:"USB boards "+(RobotBench.data.boardCount??0)+" · Simulators "+(RobotBench.data.simCount??0)+"\nCUDA processes "+(RobotBench.data.gpu.computeCount??0)+" · Clipboard items "+ClipboardVault.count;pixelSize:13}
 Grid {columns:3;spacing:8
 ControlTile {label:"System Monitor";glyph:"\uf080";onActivated:ShellState.dropdown="monitor"}
 ControlTile {label:"Clipboard Vault";glyph:"\uf0ea";onActivated:ShellState.dropdown="clipboard"}
 ControlTile {label:"Robotics controls";glyph:"\uf085";onActivated:{ShellState.systemPage=2;ShellState.dropdown="system"}}
 ControlTile {label:"NVIDIA terminal";glyph:"\uf120";onActivated:Quickshell.execDetached(["/home/fh1m/.local/bin/sim-console"])}
 ControlTile {label:"Project files";glyph:"\uf07c";onActivated:Quickshell.execDetached(["xdg-open","/home/fh1m"])}
 ControlTile {label:"Keyboard shortcuts";glyph:"\uf11c";onActivated:ShellState.openExclusive("shortcuts")}
 }
 ControlTile {label:"Display wallpapers";glyph:"\uf03e";onActivated:ShellState.openExclusive("picker")}
 NrLabel {text:"LOCAL WORKSTATION // commands are copied, never executed by clipboard";pixelSize:10;color:Theme.widgetMuted}
 }
}
