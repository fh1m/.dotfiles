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
    onJourneyChanged:{if(["courier","parcel","detective","wrench"].includes(journey.scene)){activity=journey.scene;frame=0;poseExpiry.restart();}const m=journey.memory;if(m&&Number(m.turn)>turn&&Array.isArray(m.recent)){turn=m.turn;recent=m.recent.slice(-40);remember();}}
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
    onDenMusicChanged:{if(denMusic){activity="dance";frame=0;poseExpiry.stop();}else vary();}
    property var telemetry:({})
    property var personal:[]
    property var memory:({recent:[],turn:0})
    property bool memoryLoaded:false
    property string lastMode:""
    property bool presenceLoaded:false
    property string welcomeText:""
    property bool welcoming:false
    property real lastWelcome:0
    property var wallpaperState:({})
    property int frame: 0
    property bool typingBurst: false
    property bool dragging:false
    property var dragStart:({x:0,y:0})
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
    readonly property var activitySprite:Logic.activitySprite(activity)
    property int activityTicks:0
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
    onActivityChanged:{activityTicks=0;Qt.callLater(publish);}
    onReducedChanged:Qt.callLater(publish)
    function refresh():void {
        if(!eligible && target==="")return;
        query.restart();
    }
    function locate(animate):void {
        deliberateTravel=animate===true && !reduced;
        const screen=Quickshell.screens.find(s=>s.name===target);
        if(dragging)return;
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
        const file=wallpaperState.displays?.[target]?.file||wallpaperState.lockedFile||"";
        const roof=!speaking&&variant%3===1?Logic.roofPlace(file,screen.width,screen.height,pet.width,pet.height,windows,variant):null;
        placement=roof||Logic.place(screen.width,screen.height,pet.width,pet.height,windows,variant);
    }
    property string eventJob:""
    property string eventHost:""
    property var localEngineeringEvents:[]
    readonly property var engineeringEvents:localEngineeringEvents.concat(journey.engineeringEvents||[])
    property var engineeringSeen:[]
    property bool engineeringMemoryLoaded:false
    property double engineeringLastShown:0
    FileView {id:engineeringMemory;path:Quickshell.env("HOME")+"/.local/state/sensei-den/zondo-engineering-seen.json";printErrors:false
        onLoaded:{try{root.engineeringSeen=Array.from(new Set(root.engineeringSeen.concat(JSON.parse(text()).ids||[],root.journey.engineeringAcks||[]))).slice(-128);}catch(e){}root.engineeringMemoryLoaded=true;}
        onLoadFailed:root.engineeringMemoryLoaded=true
    }
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-engineering/receipts.json";watchChanges:true;printErrors:false;onFileChanged:reload()
        onLoaded:{try{root.localEngineeringEvents=(JSON.parse(text()).events||[]).slice(-32);}catch(e){}}
    }
    Timer {interval:2000;repeat:true;running:root.eligible&&root.engineeringEvents.length>0
        onTriggered:{
            if(!root.engineeringMemoryLoaded||root.notices.dnd||root.preferences.quiet||root.speaking||Date.now()-root.engineeringLastShown<60000)return;
            const now=Date.now()/1000;
            const event=root.engineeringEvents.filter(e=>now-e.at<120&&now-e.at>=0&&!root.engineeringSeen.includes(e.id)&&["project.launch","job.submitted","job.completed","experiment.completed","hardware.disconnected","hardware.returned","hardware.ambiguous"].includes(e.kind)).sort((a,b)=>(b.data?.repeatFailures||0)-(a.data?.repeatFailures||0)||b.at-a.at)[0];
            if(!event)return;
            root.engineeringSeen=root.engineeringSeen.concat([event.id]).concat(root.engineeringEvents.filter(e=>event.data?.failureKey&&e.host===event.host&&e.data?.failureKey===event.data.failureKey&&e.at<=event.at).map(e=>e.id)).slice(-128);engineeringMemory.setText(JSON.stringify({ids:root.engineeringSeen}));
            root.engineeringLastShown=Date.now();
            const d=event.data||{};
            if(event.kind==="project.launch"){root.activity="robot";root.say("Project opened. One small baseline before the magnificent machine?","project receipt");}
            else if(event.kind==="job.submitted"){root.activity="courier";root.say("A reviewed job is queued. Packing the tiny laptop; the real receipt will tell us what happened.","job receipt");}
            else if(event.kind==="hardware.disconnected"){root.activity="wrench";root.say((d.label||"Known device")+" disconnected. Its hardware passport keeps the stable identity.","hardware receipt");}
            else if(event.kind==="hardware.ambiguous"){root.activity="inspect";root.say("More than one node matches this hardware passport. Check identity before choosing a port.","hardware receipt");}
            else if(event.kind==="hardware.returned"){root.activity="wave";root.say((d.label||"Known device")+" is back. The node may change; the identity should not.","hardware receipt");}
            else {const good=["passed","succeeded"].includes(d.outcome);root.activity=good?"parcel":"detective";root.say(d.repeatFailures>=3?"This command has failed repeatedly. Its receipt keeps a failure excerpt; inspect the log before another retry.":good?"Run complete. The receipt is saved; a successful process is still only the start of checking the claim.":"Run failed, and the evidence is kept. The job receipt has the exit code and artifacts.","verified run receipt");root.eventJob=d.job||"";root.eventHost=event.host||"";}
        }
    }
    FileView {path:Qt.resolvedUrl("activity-atlases.json");onLoaded:{try{Logic.activityAtlases=JSON.parse(text());root.vary();}catch(e){}}}
    function remember():void {if(memoryLoaded)memoryFile.setText(JSON.stringify({schema:1,recent:recent.slice(-40),turn:turn}));}
    function vary():void {activityTicks=0;activity=Logic.nextActivity(activity,denMusic,Math.random(),preferences.hiddenActivities||[],preferences.favoriteActivities||[]);frame=0;poseExpiry.stop();}
    function welcome(text):void {if(Date.now()-lastWelcome<60000)return;if(preferences.welcome===false||preferences.quiet===true||preferences.enabled===false)return;lastWelcome=Date.now();welcomeText=text;welcoming=true;welcomeExpiry.restart();}
    function say(text,kind):void {eventJob="";eventHost="";const words=String(text);message=words.length>160?words.slice(0,156).replace(/\s+\S*$/,"")+"…":words;messageKind=kind||"field note";speaking=true;speechExpiry.restart();settle.restart();}
    function greet(manual):void {
        if(!eligible||(!manual&&(preferences.chatter===false||notices.dnd))||!Logic.notes.length)return;
        if(notices.dnd&&notices.unread>0){say(notices.unread+" notifications waiting quietly. No rush; the bell has them when you want them.","quiet desk");return;}
        if(notices.unread>0&&notices.event&&nudgedEvent!==notices.event){nudgedEvent=notices.event;say(notices.unread+' notifications waiting. The bell has the details whenever you are ready.','desk post');return;}
        if(turn%6===5&&personal.length){turn++;const text=personal[Math.floor(Math.random()*personal.length)];say("You kept this: "+text,"your words");remember();vary();return;}
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
        walkingRight=placement.x>old.x;activity=placement.scene?"climb":placement.y!==old.y?"plane":"walk";frame=0;poseExpiry.restart();
    }
    onTargetChanged:{publish();deliberateTravel=false;placement={available:false,x:18,y:56};landing=!reduced;landingExpiry.restart();refresh();arrivalHello.restart();}
    onEligibleChanged:{publish();if(eligible)refresh()}
    Timer {interval:1000;repeat:true;running:root.managed;onTriggered:root.journeyClock=Date.now()/1000}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-travel.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.journey=JSON.parse(text());root.engineeringSeen=Array.from(new Set(root.engineeringSeen.concat(root.journey.engineeringAcks||[]))).slice(-128);root.journeyClock=Date.now()/1000;}catch(e){}}}
    FileView {path:Quickshell.env("HOME")+"/.config/sensei-den/zondo-personal.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.personal=JSON.parse(text()).notes||[];}catch(e){}}}
    FileView {id:memoryFile;path:Quickshell.env("HOME")+"/.local/state/sensei-den/zondo-memory.json";printErrors:false
        onLoaded:{try{const m=JSON.parse(text());if(Number(m.turn)>=root.turn){root.recent=Array.isArray(m.recent)?m.recent.slice(-40):[];root.turn=Number(m.turn)||0;}}catch(e){}root.memoryLoaded=true;}}
    Timer {interval:1500;running:true;onTriggered:root.memoryLoaded=true}
    FileView {path:Quickshell.env("HOME")+"/.config/sensei/wallpapers.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.wallpaperState=JSON.parse(text());}catch(e){}}}
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
    Timer {interval:Math.max(45000,Math.min(600000,(root.preferences.chatterSeconds??90)*1000));repeat:true;running:root.preferences.enabled!==false&&root.preferences.chatter!==false&&root.preferences.quiet!==true;onTriggered:root.greet()}
    Timer {id:dockHello;interval:1600;onTriggered:root.welcome("MORE ROOM TO BUILD")}
    Timer {id:arrivalHello;interval:5500;onTriggered:if(!root.speaking)root.greet()}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-notifications.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{const n=JSON.parse(text());if(root.noticeLoaded&&((n.event&&n.event!==root.notices.event)||n.unread>root.seenUnread)&&!n.dnd)noticeDelay.restart();if(root.noticeLoaded&&root.notices.dnd&&!n.dnd&&n.unread>0)noticeDelay.restart();root.seenUnread=n.unread||0;root.notices=n;root.noticeLoaded=true;}catch(e){}}
    }
    Timer {id:noticeDelay;interval:1800;onTriggered:if(root.eligible&&!root.notices.dnd&&root.notices.unread>0){root.nudgedEvent=root.notices.event;root.say(root.notices.unread+' unread notification'+(root.notices.unread===1?'':'s')+(root.notices.app?' · '+root.notices.app:'')+'. The bell has the details.','desk post');}}

    Timer {interval:Math.max(15000,Math.min(120000,(root.preferences.activitySeconds??27)*1000));repeat:true;running:root.eligible&&!root.reduced;onTriggered:root.vary()}
    Process {id:deskSample;command:[Quickshell.env("HOME")+"/.local/bin/sensei-zondo-context"];stdout:StdioCollector {onStreamFinished:{try{const x=JSON.parse(text);root.telemetry=x;const changed=root.musicPlaying!==x.playing;root.musicPlaying=x.playing;if(changed)root.vary();if(x.warning&&root.eligible&&!root.notices.dnd)root.say(x.warning,"measured, not guessed");}catch(e){}}}}
    Timer {interval:20000;repeat:true;running:root.preferences.enabled!==false;triggeredOnStart:true;onTriggered:if(!deskSample.running)deskSample.running=true}
    Timer {interval:35000;repeat:true;running:root.allowed&&!root.reduced;onTriggered:root.walk()}
    Timer {interval:18000;repeat:true;running:root.allowed&&!root.reduced;onTriggered:{root.typingBurst=true;burstExpiry.restart();}}
    Timer {id:burstExpiry;interval:1320;onTriggered:{root.typingBurst=false;root.frame=0;}}
    Timer {interval:220;repeat:true;running:root.allowed&&!root.reduced&&(root.typingBurst||root.activity==="walk"||root.activity==="climb"||root.activity==="dance"||(root.activitySprite&&root.activityTicks<12));onTriggered:{root.frame=(root.frame+1)%4;root.activityTicks++;}}
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
        mask:Region {item:petContents}
        Behavior on margins.left {enabled:root.deliberateTravel&&!root.reduced&&!root.dragging;NumberAnimation {duration:1100;easing.type:Easing.InOutSine}}
        Behavior on margins.top {enabled:root.deliberateTravel&&!root.reduced&&!root.dragging;NumberAnimation {duration:1100;easing.type:Easing.InOutSine}}
        Item {id:petContents;anchors.fill:parent
        Rectangle {
            id:speechBubble
            TapHandler {onTapped:{if(root.eventJob)Quickshell.execDetached(["qs","-c","sensei","ipc","call","engineering-receipts","open",root.eventHost,root.eventJob]);else Quickshell.execDetached(["qs","-c","sensei","ipc","call","dropdown","open","engineering"]);}}
            anchors {right:parent.right;bottom:character.top;bottomMargin:8}
            width:256;height:caption.implicitHeight+body.implicitHeight+30
            visible:root.speaking
            radius:9;color:"#f2171311";border.color:"#6244323a";border.width:1
            Text {id:caption;anchors {left:parent.left;top:parent.top;leftMargin:14;topMargin:10} text:"ZONDO / "+root.messageKind.toUpperCase();width:parent.width-28;elide:Text.ElideRight;font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.letterSpacing:1.1;color:"#f23d70"}
            Text {id:body;anchors {left:parent.left;right:parent.right;top:caption.bottom;leftMargin:14;rightMargin:14;topMargin:7} text:root.message;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;color:"#e8e2da"}
        }
        Image {
            DragHandler {
                target:null
                onActiveChanged:{
                    if(active){root.dragStart={x:root.placement.x,y:root.placement.y};root.dragging=true;root.deliberateTravel=false;}
                    else if(root.dragging){
                        root.dragging=false;
                        const screen=Quickshell.screens.find(s=>s.name===root.target);
                        if(!screen)return;
                        const x=Math.max(8,Math.min(screen.width-pet.width-8,root.placement.x+centroid.velocity.x*.12));
                        const y=Math.max(52,Math.min(screen.height-pet.height-52,root.placement.y+centroid.velocity.y*.12));
                        const candidate={x:x,y:y,w:pet.width,h:pet.height};
                        root.deliberateTravel=!root.reduced;root.activity="plane";
                        root.placement=root.occupied.some(w=>Logic.intersects(candidate,w))?Logic.place(screen.width,screen.height,pet.width,pet.height,root.occupied,++root.variant):{available:true,x:x,y:y};
                        poseExpiry.restart();
                    }
                }
                onTranslationChanged:{if(root.dragging){const s=Quickshell.screens.find(s=>s.name===root.target);if(s)root.placement={available:true,x:Math.max(8,Math.min(s.width-pet.width-8,root.dragStart.x+translation.x)),y:Math.max(52,Math.min(s.height-pet.height-52,root.dragStart.y+translation.y))};}}
            }
            TapHandler {acceptedButtons:Qt.LeftButton;onTapped:{root.activity="highfive";root.activityTicks=0;root.say(root.preferences.seeking?"You found me! Excellent fieldwork. I was conducting a very small expedition.":"High five, engineer. What is taking shape today?","off duty");if(root.preferences.seeking)Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","companion","found"]);}}
            TapHandler {acceptedButtons:Qt.RightButton;onTapped:Quickshell.execDetached(["qs","-c","sensei","ipc","call","dropdown","open","engineering"])}
            id:character;cache:!root.activitySprite;opacity:root.allowed?1:0;scale:root.landing?0.72:1
            Behavior on scale {enabled:!root.reduced;NumberAnimation {duration:650;easing.type:Easing.OutBack}}
            anchors {right:parent.right;bottom:parent.bottom}
            width:pet.spriteSize;height:width
            source:Qt.resolvedUrl(root.activitySprite?root.activitySprite.file:root.activity==="climb"?"zondo-climb-v1.png":root.extraPose>=0?"zondo-life-v2.png":"fh1m-motion-v2.png")
            readonly property real cell:1254/4
            readonly property int tile:root.extraPose>=0?root.extraPose:root.pose
            sourceClipRect:{if(root.activitySprite){const a=root.activitySprite,c=root.frame%4,r=a.row;return Qt.rect(a.xs[c],a.ys[r],a.xs[c+1]-a.xs[c],a.ys[r+1]-a.ys[r]);}if(root.activity==="climb"){const xs=[0,543,1086,1629,2172],c=root.frame%4;return Qt.rect(xs[c],0,xs[c+1]-xs[c],724);}if(!(root.extraPose>=0))return Qt.rect((tile%4)*cell,Math.floor(tile/4)*cell,cell,cell);const xs=[0,313,627,945,1254],ys=[0,323,627,931,1254],c=tile%4,r=Math.floor(tile/4);return Qt.rect(xs[c],ys[r],xs[c+1]-xs[c],ys[r+1]-ys[r]);}
            fillMode:Image.PreserveAspectFit;smooth:true;asynchronous:true
        }
    }
    }
    NumberAnimation {id:welcomeFadeOut;target:welcomeCard;property:"opacity";to:0;duration:root.reduced?0:280;onFinished:root.welcoming=false}
    NumberAnimation {id:welcomeFadeIn;target:welcomeCard;property:"opacity";from:0;to:1;duration:root.reduced?0:400}
    onWelcomingChanged:if(welcoming){welcomeFadeOut.stop();welcomeFadeIn.restart()}
    Timer {id:welcomeExpiry;interval:4200;onTriggered:welcomeFadeOut.restart()}
    PanelWindow {
        id:arrival
        screen:Quickshell.screens.find(s=>s.name===(root.presence.host==="homie"?root.preferences.output:"eDP-1"))??Quickshell.screens[0]
        visible:root.welcoming
        anchors {left:true;right:true;top:true;bottom:true}
        color:"transparent"
        exclusionMode:ExclusionMode.Ignore
        WlrLayershell.layer:WlrLayer.Overlay
        WlrLayershell.namespace:"sensei-zondo-arrival"
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
        mask:Region {}
        property real progress:0
        NumberAnimation on progress {from:0;to:1;duration:4200;running:root.welcoming&&!root.reduced}
        Rectangle {id:welcomeCard;anchors.fill:parent;radius:16;color:"#151116";clip:true
            Image {anchors.fill:parent;source:Qt.resolvedUrl("den-welcome-v2.png");fillMode:Image.PreserveAspectCrop;opacity:.65}
            Rectangle {anchors.fill:parent;gradient:Gradient {orientation:Gradient.Horizontal;GradientStop {position:0;color:"#ee100e12"} GradientStop {position:1;color:"#00100e12"}}}
            Rectangle {anchors {left:parent.left;right:parent.right;bottom:parent.bottom;leftMargin:36;rightMargin:36;bottomMargin:28}height:2;color:"#30ffffff";Rectangle {height:2;width:parent.width*arrival.progress;color:"#ff4297"}}
            Column {anchors {left:parent.left;verticalCenter:parent.verticalCenter;leftMargin:Math.max(36,parent.width*.085)} spacing:22
                Text {text:"FH1M / DIGITAL DEN";color:"#ff4297";font.family:"JetBrainsMono Nerd Font";font.pixelSize:Math.max(14,Math.min(22,arrival.width*.014)); font.letterSpacing:3}
                Text {text:root.welcomeText; color:"#f4e9ee";font.family:"JetBrainsMono Nerd Font";font.pixelSize:Math.max(24,Math.min(52,arrival.width*.032))}
                Text {text:"Zondo is at the desk.\nMake something that has to work.";color:"#c8b7bf";font.family:"JetBrainsMono Nerd Font";font.pixelSize:Math.max(14,Math.min(21,arrival.width*.014));lineHeight:1.5}
            }
        }
    }

}
