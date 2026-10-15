import QtQuick
import Quickshell
import qs.config
import qs.services

WidgetSection {
    id: root
    title: "Digital Den"
    subtitle: Den.online ? ((Den.data.peer?.host ?? "Peer") + " · connected") : "Peer offline"
    glyph: "\uf233"
    Column {
        width: parent.width
        spacing: 8
        Row {
            width: parent.width
            spacing: 8
            ControlTile { implicitWidth: (parent.width-24)/4; implicitHeight: 44; label: Den.inputRunning ? "Sharing on" : "Paused"; detail: "Ctrl ×3"; glyph: "\uf11c"; selected: Den.inputRunning; enabled: !Den.working; onActivated: Den.inputToggle() }
            ControlTile { implicitWidth: (parent.width-24)/4; implicitHeight: 44; label: "Find cursor"; detail: "Ctrl ×2"; glyph: "\uf245"; enabled: !Den.working; onActivated: Den.locate() }
            ControlTile { implicitWidth: (parent.width-24)/4; implicitHeight: 44; label: "Bring home"; detail: "Pause + centre"; glyph: "\uf015"; enabled: !Den.working; onActivated: Den.home() }
            ControlTile { implicitWidth: (parent.width-24)/4; implicitHeight: 44; label: "Storage"; detail: Den.data.role === "receiver" ? "Homie drives" : "Encrypted link"; glyph: "\uf07b"; enabled: !Den.working; onActivated: Den.openStorage() }
        }
        Row {
            width: parent.width
            spacing: 8
            Text { textFormat: Text.PlainText; width: parent.width-96; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: Den.working ? "Working…" : ((Den.data.state ?? "Checking connection") + " · Clipboard " + (Den.data.clipboard === "active" ? "on" : "off") + " · Drives " + (Den.data.storageMounted ? "mounted" : "offline")); font.family: Appearance.font.ui; font.pixelSize: 11; color: Theme.widgetMuted }
            ControlTile { implicitWidth: 88; implicitHeight: 28; label: "Check"; glyph: "\uf021"; enabled: !Den.working; onActivated: Den.refresh() }
        }
        Row {
            width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:"Companion";glyph:"\uf1b0";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","companion","toggle"])}
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:"Bring here";glyph:"\uf124";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","companion","here"])}
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:"Sync files";glyph:"\uf021";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","sync","scan"])}
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:Den.data.mode==="away"?"Return home":"Away mode";glyph:"\uf0b1";enabled:Den.data.role!=="receiver";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","mode",Den.data.mode==="away"?"auto":"away"])}
        }
        Text { textFormat: Text.PlainText; width: parent.width; visible: Den.error !== ""; text: Den.error; wrapMode: Text.Wrap; font.family: Appearance.font.ui; font.pixelSize: 11; color: Theme.signalRed }
    }
}
