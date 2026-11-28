import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
import qs.utils

Column {
    id: root
    spacing: 10
    property string preferredInterface: ""
    property var snapshot: ({interfaces:[], neighbors:[], routes:[]})
    property var result: ({})
    property string details: ""
    property string expanded: ""
    property string error: ""
    readonly property var link: interfaces.model[interfaces.currentIndex] ?? {}
    readonly property string gateway: snapshot.routes.find(r => r.dst === "default" && r.dev === link.ifname)?.gateway ?? ""
    readonly property var neighbors: snapshot.neighbors.filter(n => n.dev === link.ifname)
    readonly property bool busy: inventory.running || probe.running
    function refresh() {
        if (!busy) { error=""; inventory.running=true; }
    }
    function diagnose(name) {
        if (busy) return;
        result={}; error="";
        probe.command=[Paths.home+"/.local/bin/sensei-network",name];
        if (["health","link"].includes(name)) probe.command=probe.command.concat(["--interface",link.ifname]);
        if (name==="resolve") probe.command=probe.command.concat(["--target",host.text.trim()||"example.com"]);
        probe.running=true;
    }
    function inspect() {
        expanded=expanded==="technical"?"":"technical";
        if(expanded && !details && !technical.running) technical.running=true;
    }
    Component.onCompleted: refresh()

    Row {
        width: parent.width; spacing: 8
        DeskComboBox {
            id: interfaces; width: parent.width-124; height:36
            model: root.snapshot.interfaces.filter(i=>i.ifname!=="lo")
            textRole: "ifname"; enabled: !root.busy
            onActivated: {root.result={};root.expanded="";}
        }
        ControlTile { implicitWidth:116; implicitHeight:36; label:"Refresh"; enabled:!root.busy; onActivated:root.refresh() }
    }
    Text {
        width:parent.width; textFormat:Text.PlainText; wrapMode:Text.Wrap
        text: root.link.ifname ? (root.link.flags?.includes("LOWER_UP") ? "Carrier detected" : "No carrier") + (root.gateway ? "  /  Gateway " + root.gateway : "  /  No IPv4 default route") : inventory.running ? "Reading interfaces…" : "No interfaces reported"
        font.family:Appearance.font.reading; font.pixelSize:Appearance.textSize.body; color:Theme.widgetText
    }
    ChamferPanel {
        width:parent.width; height:99; chamfer:7; scanlines:false; fillColor:Theme.widgetSurface; borderColor:Theme.widgetBorder
        Text {x:11;y:8;text:"Host traffic   ↓ "+Fmt.rateLong(SysInfo.netRxRate)+"   ↑ "+Fmt.rateLong(SysInfo.netTxRate);font.family:Appearance.font.telemetry;font.pixelSize:13;color:Theme.widgetText}
        Sparkline { x:10;y:31;width:parent.width-20;height:57;points:16;floorValue:1024;downValues:SysInfo.netRxHistory;upValues:SysInfo.netTxHistory;downColor:Theme.widgetAccent;upColor:Theme.widgetMuted;strokeWidth:1.5 }
        Text {anchors.centerIn:parent;anchors.verticalCenterOffset:8;visible:SysInfo.netRxHistory.length<2;text:"Collecting traffic samples…";font.family:Appearance.font.reading;color:Theme.widgetMuted}
    }
    Flow {
        width:parent.width;spacing:7
        ControlTile {label:"Test connection";enabled:!!root.link.ifname&&!root.busy;onActivated:root.diagnose("health")}
        ControlTile {label:"Link speed";enabled:!!root.link.ifname&&!root.busy;onActivated:root.diagnose("link")}
        ControlTile {label:"Profiles";onActivated:AppLaunch.run(["nm-connection-editor"])}
        ControlTile {label:"Gateway settings";enabled:/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(root.gateway);onActivated:AppLaunch.run(["xdg-open","http://"+root.gateway+"/"])}
    }
    Row {
        width:parent.width;spacing:8
        DeskTextField {id:host;width:parent.width-122;height:32;placeholderText:"DNS name (example.com)";maximumLength:253;onAccepted:root.diagnose("resolve")}
        ControlTile {implicitWidth:114;implicitHeight:32;label:"Resolve";enabled:!root.busy;onActivated:root.diagnose("resolve")}
    }
    Flow {
        width:parent.width;spacing:7
        Repeater {
            model:root.result.checks??[]
            ControlTile {
                required property var modelData
                label:modelData.name+": "+modelData.state
                selected:root.expanded===modelData.name
                onActivated:root.expanded=selected?"":modelData.name
            }
        }
    }
    Text {
        width:parent.width;visible:!!text;textFormat:Text.PlainText;wrapMode:Text.Wrap
        text:root.error||(probe.running?"Checking…":root.result.addresses?root.result.addresses.join(", ")+"  /  "+root.result.elapsedMs+" ms":root.result.result||root.result.note||"")
        font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:root.error?Theme.uiWarning:Theme.widgetText
    }
    Flow {
        width:parent.width;spacing:7
        ControlTile {label:"Neighbors ("+root.neighbors.length+")";selected:root.expanded==="neighbors";onActivated:root.expanded=selected?"":"neighbors"}
        ControlTile {label:"Technical details";selected:root.expanded==="technical";onActivated:root.inspect()}
        ControlTile {label:"Driver counters";visible:!!root.result.links;selected:root.expanded==="driver";onActivated:root.expanded=selected?"":"driver"}
    }
    Loader {
        width:parent.width
        active:root.expanded!==""
        asynchronous:true
        sourceComponent:ScrollView {
        height:Math.min(230,log.implicitHeight+12);contentWidth:availableWidth;clip:true
        TextArea {
            id:log;readOnly:true;textFormat:TextEdit.PlainText;wrapMode:TextEdit.Wrap
            text:{
                if(root.expanded==="neighbors")return root.neighbors.map(n=>n.dst+"  /  "+(n.state||[]).join(", ")).join("\n")||"No neighbors observed on this interface.";
                if(root.expanded==="technical")return root.details||"Reading details…";
                if(root.expanded==="driver")return root.result.physical||"No driver report available.";
                const check=root.result.checks?.find(c=>c.name===root.expanded)?.detail;
                return typeof check==="object"?(check.addresses||[]).join(", "):check||"";
            }
            font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.widgetText
            background:Rectangle {color:Theme.widgetSurface;border.color:Theme.widgetBorder}
        }
        }
    }
    Process {
        id:inventory;command:[Paths.home+"/.local/bin/sensei-network","summary"]
        stdout:StdioCollector {onStreamFinished:{
            try {
                const data=JSON.parse(text);if(data.error)throw new Error(data.error);
                const keep=root.link.ifname||root.preferredInterface||data.routes.find(r=>r.dst==="default")?.dev;
                root.snapshot=data;root.details="";
                interfaces.currentIndex=Math.max(0,interfaces.model.findIndex(i=>i.ifname===keep));
            }catch(e){root.error="Network interfaces unavailable.";}
        }}
    }
    Process {
        id:probe
        stdout:StdioCollector {onStreamFinished:{try{const d=JSON.parse(text);root.error=d.error||"";root.result=d.error?{}:d;root.expanded="";}catch(e){root.error="Could not read this check result.";}}}
    }
    Process {
        id:technical;command:[Paths.home+"/.local/bin/sensei-network","inventory"]
        stdout:StdioCollector {onStreamFinished:{try{
            const d=JSON.parse(text);if(d.error)throw new Error(d.error);
            root.details=[d.routes.map(r=>(r.dst||"default")+" via "+(r.gateway||"direct")+" / "+r.dev).join("\n"),d.dns,d.sockets].filter(Boolean).join("\n\n");
        }catch(e){root.details="Network details unavailable. Refresh links and retry.";}}}
    }
}
