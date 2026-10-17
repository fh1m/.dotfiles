import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
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
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:"Zondo";glyph:"\uf1b0";selected:Den.data.companion!==false;onActivated:Den.companion("toggle","")}
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:"Bring here";enabled:Den.data.role!=="receiver"||!Den.online;glyph:"\uf124";onActivated:Den.companion("here","")}
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:"Sync files";glyph:"\uf021";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","sync","scan"])}
            ControlTile {implicitWidth:(parent.width-24)/4;implicitHeight:34;label:Den.data.mode==="away"?"Return home":"Away mode";glyph:"\uf0b1";enabled:Den.data.role!=="receiver";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","mode",Den.data.mode==="away"?"auto":"away"])}
        }
        Row {
            width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-8)/2;implicitHeight:34;label:"Say hello";glyph:"\uf075";onActivated:Den.companion("wave","")}
            ControlTile {implicitWidth:(parent.width-8)/2;implicitHeight:34;label:"Homie desk";detail:"Private · on demand";glyph:"\uf108";visible:Den.data.role!=="receiver";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","workbench","open"])}
        }
        Row {
            width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-16)/3;implicitHeight:34;label:"Desk tip";detail:"A useful nudge";glyph:"\uf0eb";onActivated:Den.companion("tip","")}
            ControlTile {implicitWidth:(parent.width-16)/3;implicitHeight:34;label:"Quiet";detail:Den.data.companionQuiet?"On":"Off";selected:Den.data.companionQuiet===true;glyph:"\uf186";onActivated:Den.companion("quiet","")}
            ControlTile {implicitWidth:(parent.width-16)/3;implicitHeight:34;label:"Motion";detail:Den.data.companionReducedMotion?"Reduced":"Gentle";selected:Den.data.companionReducedMotion!==true;glyph:"\uf554";onActivated:Den.companion("motion",Den.data.companionReducedMotion?"on":"off")}
        }
        Row {
            width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-8)/2;implicitHeight:34;label:"Tour displays";enabled:Den.data.role!=="receiver"||!Den.online;glyph:"\uf072";onActivated:Den.companion("tour","")}
            ControlTile {implicitWidth:(parent.width-8)/2;implicitHeight:34;label:"Follow my focus";enabled:Den.data.role!=="receiver"||!Den.online;glyph:"\uf124";onActivated:Den.companion("follow","")}
        }
        Row {width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-8)/2;label:"Focus corners only";onActivated:Den.companion("dim","off")}
            ControlTile {implicitWidth:(parent.width-8)/2;label:"Dim inactive screens";onActivated:Den.companion("dim","on")}
        }
        Row {width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-8)/2;label:"Den wallpaper story";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-wallpaper-story","enable"])}
            ControlTile {implicitWidth:(parent.width-8)/2;label:"Restore my wallpapers";onActivated:Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-wallpaper-story","disable"])}
        }
        DenMap {width:parent.width;visible:!MachineProfile.desktop}
        Text { textFormat: Text.PlainText; width: parent.width; visible: Den.error !== ""; text: Den.error; wrapMode: Text.Wrap; font.family: Appearance.font.ui; font.pixelSize: 11; color: Theme.signalRed }
        Row {width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-16)/3;implicitHeight:34;label:"Dance break";glyph:"\uf001";onActivated:Den.companion("dance","")}
            ControlTile {implicitWidth:(parent.width-16)/3;implicitHeight:34;label:"More like this";glyph:"\uf164";onActivated:Den.companion("more","")}
            ControlTile {implicitWidth:(parent.width-16)/3;implicitHeight:34;label:"Retire this line";glyph:"\uf04e";onActivated:Den.companion("less","")}
        }

        ControlTile {width:parent.width;label:"ScreenPad / Normal · Simulation · Coding · Hardware";glyph:"\uf108";visible:!MachineProfile.desktop;onActivated:ShellState.pinInstrument("context")}
        ControlTile {width:parent.width;label:"Engineering / projects & job queue";glyph:"\uf085";onActivated:ShellState.toggleDropdown("engineering")}
        DeskTextField {id:zondoThought;width:parent.width;placeholderText:"Tell Zondo a thought, or keep a personal memory";maximumLength:240;onAccepted:if(text.trim()){Den.companion("talk",text);text="";}}
        Text {width:parent.width;visible:Den.reply!=="";text:Den.reply;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.paper}
        Row {width:parent.width;spacing:8
            ControlTile {implicitWidth:(parent.width-8)/2;label:"Talk to Zondo";glyph:"\uf075";onActivated:if(zondoThought.text.trim()){Den.companion("talk",zondoThought.text);zondoThought.text="";}}
            ControlTile {implicitWidth:(parent.width-8)/2;label:"Remember locally";glyph:"\uf02d";onActivated:if(zondoThought.text.trim()){Den.companion("remember",zondoThought.text);zondoThought.text="";}}
        }
        Text {width:parent.width;text:"Local cue-based replies, no background AI. Remember stores your exact words privately on this machine.";wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.paperMuted}

    }
}
