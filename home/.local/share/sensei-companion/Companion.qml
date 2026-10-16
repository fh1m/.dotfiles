import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "CompanionLogic.js" as Logic

// One existing cursor renderer. No network, window titles, keys or clipboard reads.
Item {
    id: root
    property string ownerOutput: ""
    property var journey: ({})
    property real journeyClock: Date.now()/1000
    readonly property bool leased: journey.schema===1 && journey.expires>journeyClock
    readonly property bool managed: preferences.roaming===true || (presence.host==="homie" && !preferences.anchorManual && journey.managed===true && !standalone)
    property var preferences: ({enabled:true,quiet:false,size:96})
    property var presence: ({})
    property bool fullscreen: false
    property bool landing: false
    property string message: ""
    property string messageKind: "field note"
    property bool speaking: false
    property string activity: "typing"
    property int frame: 0
    property bool typingBurst: false
    property bool walkingRight: false
    property bool deliberateTravel: false
    property int variant: 0
    property var placement: ({available:false,x:18,y:56})
    property var recent: []
    property int turn: 0
    property string activeApp: ""
    property real seenPose: 0
    property real seenMessage: 0
    property real seenTip: 0
    property string seenBackup: ""
    property bool backupLoaded: false
    readonly property bool reduced: preferences.reducedMotion === true
    readonly property bool standalone: presence.mode?.effective === "homie" || presence.mode?.effective === "away"
    readonly property string preferred: Quickshell.screens.some(s=>s.name===preferences.output)?preferences.output:""
    readonly property string target: managed ? (leased ? journey.output : "") : ownerOutput ? (preferred || ownerOutput) : (standalone ? (preferred || Quickshell.screens[0]?.name || "") : "")
    readonly property bool eligible: preferences.enabled!==false && preferences.quiet!==true && preferences.suspended!==true && !fullscreen && target!==""
    readonly property bool allowed: eligible && placement.available
    readonly property int pose: activity==="walk" ? (walkingRight?8:4)+frame%4 : activity==="wave" ? 13 : activity==="celebrate" ? 14 : activity==="think" ? 12 : activity==="sleep" ? 15 : frame%4
    IpcHandler {target:"companion";function state():string{return JSON.stringify({allowed:root.allowed,output:root.target,fullscreen:root.fullscreen,pose:root.pose,size:root.preferences.size??96,reducedMotion:root.reduced,travel:root.deliberateTravel,placement:root.placement,activity:root.activity,message:root.message,kind:root.messageKind,sprite:{status:character.status,sourceWidth:character.sourceSize.width,clip:character.sourceClipRect},panel:{x:pet.margins.left,y:pet.margins.top,width:pet.width,height:pet.height}});}}
    function refresh():void {
        if(!eligible && target==="")return;
        query.restart();
    }
    function locate(animate):void {
        deliberateTravel=animate===true && !reduced;
        const screen=Quickshell.screens.find(s=>s.name===target);
        if(!screen){placement={available:false,x:18,y:56};return;}
        const mon=Hyprland.monitorFor(screen), data=mon?.lastIpcObject??{};
        fullscreen=mon?.activeWorkspace?.lastIpcObject?.hasfullscreen===true;
        const workspace=mon?.activeWorkspace?.id;
        const windows=[];
        for(const top of Hyprland.toplevels.values) {
            const c=top.lastIpcObject??{};
            if(top.activated)activeApp=c.class??c.initialClass??"";
            if(c.hidden || c.mapped===false || !c.at || !c.size || (top.workspace?.id!==workspace && !c.pinned))continue;
            windows.push({x:c.at[0]-(data.x??0)-12,y:c.at[1]-(data.y??0)-12,w:c.size[0]+24,h:c.size[1]+24});
        }
        placement=Logic.place(screen.width,screen.height,pet.width,pet.height,windows,variant);
    }
    function say(text,kind):void {message=String(text).slice(0,160);messageKind=kind||"field note";speaking=true;speechExpiry.restart();settle.restart();}
    function greet(manual):void {
        if(!allowed||(!manual&&preferences.chatter===false))return;
        const note=Logic.nextNote(activeApp,recent,turn++,Math.random());
        recent=recent.concat([note.id]).slice(-8);say(note.text,note.kind==="wit"?"off the clock":"desk tip");
        activity=note.kind==="wit"?"wave":"think";poseExpiry.restart();
    }
    function walk():void {
        if(!allowed||reduced)return;
        const old=placement, oldVariant=variant;
        variant=(variant+1)%2;locate(true);
        if(!Logic.canWalk(old,placement)){variant=oldVariant;deliberateTravel=false;placement=old;return;}
        walkingRight=placement.x>old.x;activity="walk";frame=0;poseExpiry.restart();
    }
    onTargetChanged:{deliberateTravel=false;placement={available:false,x:18,y:56};landing=!reduced;landingExpiry.restart();refresh();}
    onEligibleChanged:if(eligible)refresh()
    Timer {interval:1000;repeat:true;running:root.managed;onTriggered:root.journeyClock=Date.now()/1000}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-travel.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.journey=JSON.parse(text());root.journeyClock=Date.now()/1000;}catch(e){}}}
    FileView {path:Qt.resolvedUrl("notes.json");watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{Logic.notes=JSON.parse(text());}catch(e){}}}
    FileView {path:Quickshell.env("HOME")+"/.config/sensei-den/companion.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{
            root.preferences=JSON.parse(text());
            if(root.preferences.poseAt && root.preferences.poseAt!==root.seenPose && Date.now()/1000-root.preferences.poseAt<8){
                root.seenPose=root.preferences.poseAt;
                if(root.preferences.pose==="walk")root.walk();else {root.activity=root.preferences.pose;poseExpiry.restart();}
            }
            if(root.preferences.messageAt && root.preferences.messageAt!==root.seenMessage && Date.now()/1000-root.preferences.messageAt<8){root.seenMessage=root.preferences.messageAt;root.say(root.preferences.message,root.preferences.pose==="wave"&&root.preferences.poseAt===root.preferences.messageAt?"hello":"from you");}
            if(root.preferences.tipAt && root.preferences.tipAt!==root.seenTip && Date.now()/1000-root.preferences.tipAt<8){root.seenTip=root.preferences.tipAt;root.greet(true);}
        }catch(e){}}}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/presence.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{root.presence=JSON.parse(text());}catch(e){}}}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/backup-status.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{const x=JSON.parse(text());
            if(root.backupLoaded && x.finished && x.finished!==root.seenBackup && root.allowed && root.preferences.chatter!==false)
                root.say(x.ok?"Latest Den backup completed. Restore checks are a separate step.":"Backup needs attention. Your existing snapshots remain.","backup status");
            root.seenBackup=x.finished??"";root.backupLoaded=true;
        }catch(e){}}}
    Connections {target:Hyprland;function onRawEvent(event){
        if(["fullscreen","workspace","workspacev2","focusedmon","monitoradded","monitorremoved","activewindow","activewindowv2","openwindow","closewindow","movewindow","movewindowv2","changefloatingmode","windowtitle","configreloaded"].includes(event.name))root.refresh();
    }}
    Timer {id:query;interval:100;onTriggered:{Hyprland.refreshMonitors();Hyprland.refreshWorkspaces();Hyprland.refreshToplevels();settle.restart();}}
    Timer {id:settle;interval:180;onTriggered:root.locate()}
    Timer {interval:15000;repeat:true;running:root.eligible;onTriggered:root.refresh()}
    Timer {interval:360000;repeat:true;running:root.allowed&&root.preferences.chatter!==false;onTriggered:root.greet()}
    Timer {interval:90000;repeat:true;running:root.allowed&&!root.reduced;onTriggered:root.walk()}
    Timer {interval:18000;repeat:true;running:root.allowed&&!root.reduced;onTriggered:{root.typingBurst=true;burstExpiry.restart();}}
    Timer {id:burstExpiry;interval:1320;onTriggered:{root.typingBurst=false;root.frame=0;}}
    Timer {interval:220;repeat:true;running:root.allowed&&!root.reduced&&(root.typingBurst||root.activity==="walk");onTriggered:root.frame=(root.frame+1)%4}
    Timer {id:poseExpiry;interval:2200;onTriggered:{root.activity="typing";root.frame=0;root.deliberateTravel=false;}}
    Timer {id:speechExpiry;interval:9500;onTriggered:{root.speaking=false;settle.restart();}}
    Timer {id:landingExpiry;interval:700;onTriggered:root.landing=false}
    PanelWindow {
        id:pet
        screen:Quickshell.screens.find(s=>s.name===root.target)??Quickshell.screens[0]
        visible:root.allowed
        color:"transparent"
        readonly property real spriteSize:Math.max(64,Math.min(180,root.preferences.size??96))
        implicitWidth:root.speaking?256:spriteSize
        implicitHeight:spriteSize+(root.speaking?112:0)
        onWidthChanged:settle.restart()
        onHeightChanged:settle.restart()
        anchors {left:true;top:true}
        margins {left:root.placement.x;top:root.placement.y}
        exclusionMode:ExclusionMode.Ignore
        // Below application content even while geometry catches up. Never covers code.
        WlrLayershell.layer:WlrLayer.Bottom
        WlrLayershell.namespace:"sensei-fh1m-companion"
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
        mask:Region {}
        Behavior on margins.left {enabled:root.deliberateTravel&&!root.reduced;NumberAnimation {duration:2000;easing.type:Easing.InOutSine}}
        Behavior on margins.top {enabled:root.deliberateTravel&&!root.reduced;NumberAnimation {duration:2000;easing.type:Easing.InOutSine}}
        Rectangle {
            anchors {right:parent.right;bottom:character.top;bottomMargin:8}
            width:256;height:caption.implicitHeight+body.implicitHeight+30
            visible:root.speaking
            radius:9;color:"#f2171311";border.color:"#6244323a";border.width:1
            Text {id:caption;anchors {left:parent.left;top:parent.top;leftMargin:14;topMargin:10} text:root.messageKind.toUpperCase();font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.letterSpacing:1.1;color:"#f23d70"}
            Text {id:body;anchors {left:parent.left;right:parent.right;top:caption.bottom;leftMargin:14;rightMargin:14;topMargin:7} text:root.message;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;color:"#e8e2da"}
        }
        Image {
            id:character;opacity:root.allowed?1:0;scale:root.landing?0.72:1
            Behavior on scale {enabled:!root.reduced;NumberAnimation {duration:650;easing.type:Easing.OutBack}}
            anchors {right:parent.right;bottom:parent.bottom}
            width:pet.spriteSize;height:width
            source:Qt.resolvedUrl("fh1m-motion-v2.png")
            readonly property real cell:1254/4
            sourceClipRect:Qt.rect((root.pose%4)*cell,Math.floor(root.pose/4)*cell,cell,cell)
            fillMode:Image.PreserveAspectFit;smooth:true;asynchronous:true
        }
    }
}
