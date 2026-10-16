import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "ZondoLogic.js" as Logic

// One existing cursor renderer. No network, window titles, keys or clipboard reads.
Item {
    id: root
    property string ownerOutput: ""
    property var journey: ({})
    onJourneyChanged:{const m=journey.memory;if(m&&Number(m.turn)>turn&&Array.isArray(m.recent)){turn=m.turn;recent=m.recent.slice(-40);remember();}}
    property real journeyClock: Date.now()/1000
    readonly property bool leased: journey.schema===1 && journey.expires>journeyClock
    readonly property bool managed: preferences.roaming===true || (presence.host==="homie" && !standalone)
    property var preferences: ({enabled:true,quiet:false,size:96})
    property var presence: ({})
    property bool fullscreen: false
    property bool landing: false
    property string message: ""
    property string messageKind: "field note"
    property bool speaking: false
    property string activity: "read"
    property bool musicPlaying:false
    readonly property bool denMusic:musicPlaying||(leased&&journey.musicPlaying===true)
    onDenMusicChanged:vary()
    property var telemetry:({})
    property var memory:({recent:[],turn:0})
    property bool memoryLoaded:false
    property string lastMode:""
    property bool presenceLoaded:false
    property string welcomeText:""
    property bool welcoming:false
    property int frame: 0
    property bool typingBurst: false
    property bool walkingRight: false
    property bool deliberateTravel: false
    property int variant: 0
    property var occupied:[]
    property var placement: ({available:false,x:18,y:56})
    property var recent: []
    property int turn: 0
    property int lastNote:-1
    property string noteKind:""
    property var notices:({unread:0,dnd:false})
    property int seenUnread:0
    property bool noticeLoaded:false
    property double nudgedEvent:0
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
    readonly property int extraPose:Logic.extendedPose(activity,frame)
    readonly property int pose: activity==="walk" ? (walkingRight?8:4)+frame%4 : activity==="wave" ? 13 : activity==="celebrate" ? 14 : activity==="think" ? 12 : activity==="sleep" ? 15 : frame%4
    IpcHandler {target:"companion";function state():string{return JSON.stringify({name:"Zondo",musicPlaying:root.denMusic,allowed:root.allowed,speaking:root.speaking,unread:root.notices.unread||0,dnd:root.notices.dnd||false,output:root.target,fullscreen:root.fullscreen,pose:root.pose,size:root.preferences.size??96,reducedMotion:root.reduced,travel:root.deliberateTravel,placement:root.placement,activity:root.activity,extraPose:root.extraPose,welcome:root.welcoming,message:root.message,kind:root.messageKind,sprite:{status:character.status,sourceWidth:character.sourceSize.width,clip:character.sourceClipRect},panel:{x:pet.margins.left,y:pet.margins.top,width:pet.width,height:pet.height}});}}
    property string lastPublished:""
    function publish():void {
        const data=JSON.stringify({output:target,allowed:allowed,eligible:eligible,speaking:speaking,message:message,kind:messageKind,name:"Zondo",reducedMotion:reduced,activity:activity,extraPose:extraPose,pose:pose,lastNote:lastNote,noteKind:noteKind});
        if(data!==lastPublished && renderFile){lastPublished=data;renderFile.setText(data);}
    }
    FileView {id:renderFile;path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-render.json";printErrors:false}
    Component.onCompleted:Qt.callLater(publish)
    onAllowedChanged:publish()
    onSpeakingChanged:publish()
    onMessageChanged:publish()
    onActivityChanged:Qt.callLater(publish)
    onReducedChanged:Qt.callLater(publish)
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
        occupied=windows;
        placement=Logic.place(screen.width,screen.height,pet.width,pet.height,windows,variant);
    }
    function remember():void {if(memoryLoaded)memoryFile.setText(JSON.stringify({schema:1,recent:recent.slice(-40),turn:turn}));}
    function vary():void {activity=Logic.nextActivity(activity,denMusic,Math.random());frame=0;poseExpiry.stop();}
    function welcome(text):void {if(preferences.welcome===false||preferences.quiet===true||preferences.enabled===false)return;welcomeText=text;welcoming=true;welcomeExpiry.restart();}
    function say(text,kind):void {const words=String(text);message=words.length>160?words.slice(0,156).replace(/\s+\S*$/,"")+"…":words;messageKind=kind||"field note";speaking=true;speechExpiry.restart();settle.restart();}
    function greet(manual):void {
        if(!eligible||(!manual&&preferences.chatter===false)||!Logic.notes.length)return;
        if(notices.dnd&&notices.unread>0){say(notices.unread+" notifications waiting quietly. No rush; the bell has them when you want them.","quiet desk");return;}
        if(notices.unread>0&&notices.event&&nudgedEvent!==notices.event){nudgedEvent=notices.event;say(notices.unread+' notifications waiting. The bell has the details whenever you are ready.','desk post');return;}
        if(turn%5===4 && telemetry.summary){turn++;say(telemetry.summary,"live desk check");remember();return;}
        const note=Logic.nextNote(activeApp,recent,turn++,Math.random(),preferences.hiddenNotes||[],preferences.favoriteKinds||[]);
        if(!note)return;
        lastNote=note.id;noteKind=note.kind;recent=recent.concat([note.id]).slice(-40);remember();
        say(note.text,note.kind==="memory"?"from your project log":note.kind==="wit"?"Zondo, off duty":note.kind==="wonder"?"small wonder":"desk tip");
        vary();
    }
    function walk():void {
        if(!allowed||reduced)return;
        const old=placement, oldVariant=variant;
        variant=(variant+1)%35;locate(true);
        if(!Logic.canTravel(old,placement,pet.width,pet.height,occupied)){deliberateTravel=false;return;}
        walkingRight=placement.x>old.x;activity=placement.y!==old.y?"plane":"walk";frame=0;poseExpiry.restart();
    }
    onTargetChanged:{publish();deliberateTravel=false;placement={available:false,x:18,y:56};landing=!reduced;landingExpiry.restart();refresh();arrivalHello.restart();}
    onEligibleChanged:{publish();if(eligible)refresh()}
    Timer {interval:1000;repeat:true;running:root.managed;onTriggered:root.journeyClock=Date.now()/1000}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-travel.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.journey=JSON.parse(text());root.journeyClock=Date.now()/1000;}catch(e){}}}
    FileView {id:memoryFile;path:Quickshell.env("HOME")+"/.local/state/sensei-den/zondo-memory.json";printErrors:false
        onLoaded:{try{const m=JSON.parse(text());if(Number(m.turn)>=root.turn){root.recent=Array.isArray(m.recent)?m.recent.slice(-40):[];root.turn=Number(m.turn)||0;}}catch(e){}root.memoryLoaded=true;}}
    Timer {interval:1500;running:true;onTriggered:root.memoryLoaded=true}
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
        onFileChanged:reload();onLoaded:{try{const p=JSON.parse(text()),mode=p.mode?.effective||"";
            if(root.presenceLoaded && mode!==root.lastMode)root.welcome(mode==="together"?"THE DEN IS TOGETHER":p.host==="homie"?"HOMIE HOLDS THE FORT":"ARETE, ON THE MOVE");
            if(!root.presenceLoaded)root.welcome("WELCOME HOME, FH1M");
            root.presenceLoaded=true;root.lastMode=mode;root.presence=p;}catch(e){}}}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/backup-status.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{const x=JSON.parse(text());
            if(root.backupLoaded && x.finished && x.finished!==root.seenBackup && root.allowed && root.preferences.chatter!==false)
                root.say(x.ok?"Latest Den backup completed. Restore checks are a separate step.":"Backup needs attention. Your existing snapshots remain.","backup status");
            root.seenBackup=x.finished??"";root.backupLoaded=true;
        }catch(e){}}}
    Connections {target:Hyprland;function onRawEvent(event){
        if(event.name==="monitoradded")dockHello.restart();
        if(["fullscreen","workspace","workspacev2","focusedmon","monitoradded","monitorremoved","activewindow","activewindowv2","openwindow","closewindow","movewindow","movewindowv2","changefloatingmode","windowtitle","configreloaded"].includes(event.name))root.refresh();
    }}
    Timer {id:query;interval:100;onTriggered:{Hyprland.refreshMonitors();Hyprland.refreshWorkspaces();Hyprland.refreshToplevels();settle.restart();}}
    Timer {id:settle;interval:180;onTriggered:root.locate()}
    Timer {interval:15000;repeat:true;running:root.eligible;onTriggered:root.refresh()}
    // Keep the clock independent of 45–90 s travel leases and available wallpaper.
    Timer {interval:Math.max(45000,Math.min(600000,(root.preferences.chatterSeconds??110)*1000));repeat:true;running:root.preferences.enabled!==false&&root.preferences.chatter!==false&&root.preferences.quiet!==true;onTriggered:root.greet()}
    Timer {id:dockHello;interval:1600;onTriggered:root.welcome("MORE ROOM TO BUILD")}
    Timer {id:arrivalHello;interval:5500;onTriggered:if(!root.speaking)root.greet()}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-notifications.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{const n=JSON.parse(text());if(root.noticeLoaded&&((n.event&&n.event!==root.notices.event)||n.unread>root.seenUnread)&&!n.dnd)noticeDelay.restart();if(root.noticeLoaded&&root.notices.dnd&&!n.dnd&&n.unread>0)noticeDelay.restart();root.seenUnread=n.unread||0;root.notices=n;root.noticeLoaded=true;}catch(e){}}
    }
    Timer {id:noticeDelay;interval:1800;onTriggered:if(root.eligible&&!root.notices.dnd&&root.notices.unread>0){root.nudgedEvent=root.notices.event;root.say(root.notices.unread+' unread notification'+(root.notices.unread===1?'':'s')+(root.notices.app?' · '+root.notices.app:'')+'. The bell has the details.','desk post');}}

    Timer {interval:Math.max(15000,Math.min(120000,(root.preferences.activitySeconds??33)*1000));repeat:true;running:root.eligible&&!root.reduced;onTriggered:root.vary()}
    Process {id:deskSample;command:[Quickshell.env("HOME")+"/.local/bin/sensei-zondo-context"];stdout:StdioCollector {onStreamFinished:{try{const x=JSON.parse(text);root.telemetry=x;const changed=root.musicPlaying!==x.playing;root.musicPlaying=x.playing;if(changed)root.vary();if(x.warning&&root.eligible&&!root.notices.dnd)root.say(x.warning,"measured, not guessed");}catch(e){}}}}
    Timer {interval:20000;repeat:true;running:root.preferences.enabled!==false;triggeredOnStart:true;onTriggered:if(!deskSample.running)deskSample.running=true}
    Timer {interval:90000;repeat:true;running:root.allowed&&!root.reduced;onTriggered:root.walk()}
    Timer {interval:18000;repeat:true;running:root.allowed&&!root.reduced;onTriggered:{root.typingBurst=true;burstExpiry.restart();}}
    Timer {id:burstExpiry;interval:1320;onTriggered:{root.typingBurst=false;root.frame=0;}}
    Timer {interval:220;repeat:true;running:root.allowed&&!root.reduced&&(root.typingBurst||root.activity==="walk"||root.activity==="dance");onTriggered:root.frame=(root.frame+1)%4}
    Timer {id:poseExpiry;interval:2200;onTriggered:{root.vary();root.frame=0;root.deliberateTravel=false;}}
    Timer {id:speechExpiry;interval:9500;onTriggered:{root.speaking=false;settle.restart();}}
    Timer {id:landingExpiry;interval:700;onTriggered:root.landing=false}
    PanelWindow {
        id:pet
        screen:Quickshell.screens.find(s=>s.name===root.target)??Quickshell.screens[0]
        visible:root.allowed
        color:"transparent"
        readonly property real spriteSize:Math.max(64,Math.min(180,root.preferences.size??96))
        implicitWidth:root.speaking?256:spriteSize
        implicitHeight:spriteSize+(root.speaking?speechBubble.height+8:0)
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
            id:speechBubble
            anchors {right:parent.right;bottom:character.top;bottomMargin:8}
            width:256;height:caption.implicitHeight+body.implicitHeight+30
            visible:root.speaking
            radius:9;color:"#f2171311";border.color:"#6244323a";border.width:1
            Text {id:caption;anchors {left:parent.left;top:parent.top;leftMargin:14;topMargin:10} text:"ZONDO / "+root.messageKind.toUpperCase();width:parent.width-28;elide:Text.ElideRight;font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.letterSpacing:1.1;color:"#f23d70"}
            Text {id:body;anchors {left:parent.left;right:parent.right;top:caption.bottom;leftMargin:14;rightMargin:14;topMargin:7} text:root.message;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;color:"#e8e2da"}
        }
        Image {
            id:character;opacity:root.allowed?1:0;scale:root.landing?0.72:1
            Behavior on scale {enabled:!root.reduced;NumberAnimation {duration:650;easing.type:Easing.OutBack}}
            anchors {right:parent.right;bottom:parent.bottom}
            width:pet.spriteSize;height:width
            source:Qt.resolvedUrl(root.extraPose>=0?"zondo-life-v2.png":"fh1m-motion-v2.png")
            readonly property real cell:1254/4
            readonly property int tile:root.extraPose>=0?root.extraPose:root.pose
            sourceClipRect:{if(!(root.extraPose>=0))return Qt.rect((tile%4)*cell,Math.floor(tile/4)*cell,cell,cell);const xs=[0,313,627,945,1254],ys=[0,323,627,931,1254],c=tile%4,r=Math.floor(tile/4);return Qt.rect(xs[c],ys[r],xs[c+1]-xs[c],ys[r+1]-ys[r]);}
            fillMode:Image.PreserveAspectFit;smooth:true;asynchronous:true
        }
    }
    NumberAnimation {id:welcomeFadeOut;target:welcomeCard;property:"opacity";to:0;duration:root.reduced?0:280;onFinished:root.welcoming=false}
    NumberAnimation {id:welcomeFadeIn;target:welcomeCard;property:"opacity";from:0;to:1;duration:root.reduced?0:400}
    onWelcomingChanged:if(welcoming){welcomeFadeOut.stop();welcomeFadeIn.restart()}
    Timer {id:welcomeExpiry;interval:5200;onTriggered:welcomeFadeOut.restart()}
    PanelWindow {
        id:arrival
        screen:Quickshell.screens.find(s=>s.name===(root.presence.host==="homie"?root.preferences.output:"eDP-1"))??Quickshell.screens[0]
        visible:root.welcoming
        implicitWidth:Math.min(540,(screen?.width??600)-48);implicitHeight:240
        color:"transparent"
        exclusionMode:ExclusionMode.Ignore
        WlrLayershell.layer:WlrLayer.Overlay
        WlrLayershell.namespace:"sensei-zondo-arrival"
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
        mask:Region {}
        Rectangle {id:welcomeCard;anchors.fill:parent;radius:16;color:"#151116";clip:true
            Image {anchors.fill:parent;source:Qt.resolvedUrl("den-welcome-v1.png");fillMode:Image.PreserveAspectCrop;opacity:.65}
            Rectangle {anchors.fill:parent;gradient:Gradient {orientation:Gradient.Horizontal;GradientStop {position:0;color:"#ee100e12"} GradientStop {position:1;color:"#00100e12"}}}
            Column {anchors {left:parent.left;verticalCenter:parent.verticalCenter;leftMargin:26} spacing:14
                Text {text:"FH1M / DIGITAL DEN";color:"#ff4297";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11; font.letterSpacing:2}
                Text {text:root.welcomeText; color:"#f4e9ee";font.family:"JetBrainsMono Nerd Font";font.pixelSize:16}
                Text {text:"Zondo is at the desk.\nMake something that has to work.";color:"#c8b7bf";font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;lineHeight:1.5}
            }
        }
    }

}
