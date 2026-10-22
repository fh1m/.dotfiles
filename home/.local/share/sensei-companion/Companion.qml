import QtQuick
import "."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "ZondoLogic.js" as Logic
import "SpeechLayout.js" as Speech

// One existing cursor renderer. No network, window titles, keys or clipboard reads.
Item {
    id: root
    property string ownerOutput: ""
    GuestVisit {
        id:senseiGuests
        targetScreen:root.speechScreen
        permitted:root.eligible&&!root.denDnd&&root.preferences.guestsEnabled!==false
        busy:root.speaking
        reducedMotion:root.reduced
        obstacles:root.occupied
        preferences:root.preferences
        onBegan:{root.speaking=false;root.publish();}
        onEnded:root.publish()
    }

    property var journey: ({})
    onJourneyChanged:{if(journey.scene!==activity&&["courier","parcel","detective","wrench"].includes(journey.scene)){activity=journey.scene;frame=0;poseExpiry.restart();}const m=journey.memory;if(m&&Number(m.turn)>turn&&Array.isArray(m.recent)){turn=m.turn;recent=m.recent.slice(-40);remember();}}
    property real journeyClock: Date.now()/1000
    readonly property bool leased: journey.schema===1 && journey.expires>journeyClock
    readonly property bool managed: preferences.roaming===true || (presence.host==="homie" && !standalone)
    property var preferences: ({enabled:true,quiet:false,size:96})
    property var presence: ({})
    property bool fullscreen: false
    property bool landing: false
    property string message: ""
    property string noticeHeading: ""
    property real singEndAt:0
    property real lastLyricAt:0
    property string messageKind: "field note"
    property bool speaking: false
    property string activity: "read"
    property var lyricReceipt:({})
    property string lastSungLine:''
    FileView {path:Quickshell.env('HOME')+'/.local/state/sensei-den/zondo-music.json';watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.lyricReceipt=JSON.parse(text());}catch(e){root.lyricReceipt=({});}}}
    property real lastSingAt:0
    readonly property var currentLyric:leased&&journey.musicLine?.at>Number(lyricReceipt.at||0)?journey.musicLine:lyricReceipt
    onCurrentLyricChanged:{
        if(speaking&&messageKind==='singing along'){
            const fresh=Logic.singLine(currentLyric,Date.now(),'',0);
            if(fresh){message='♪ '+fresh;lastLyricAt=Date.now();}else message='♪';
        }else maybeSing();
    }
    function maybeSing():void {
        if(senseiGuests.active||!allowed||!speechWindow.bubblePlace.available||!denMusic||denDnd||speaking||preferences.chatter===false||Date.now()-lastSingAt<120000)return;
        const line=Logic.singLine(currentLyric,Date.now(),lastSungLine,0);
        if(line){lastSingAt=Date.now();lastLyricAt=Date.now();singEndAt=Date.now()+75000;lastSungLine=line;activity='sing';frame=0;say('♪ '+line,'singing along');speechExpiry.interval=75000;speechExpiry.restart();}
    }
    // Follows actual lyric transitions; a bounded fallback survives output changes.
    Timer {interval:15000;repeat:true;running:root.preferences.chatter!==false&&root.preferences.enabled!==false;onTriggered:root.maybeSing()}
    Timer {interval:250;repeat:true;running:root.speaking&&root.messageKind==='singing along';onTriggered:{const line=Logic.singLine(root.currentLyric,Date.now(),'',0);if(line){root.lastLyricAt=Date.now();root.message='♪ '+line;}else root.message='♪';if(!Logic.singingContinues(root.denMusic,root.denDnd,Date.now(),root.singEndAt,root.lastLyricAt))root.speaking=false;}}
    property bool musicPlaying:false
    readonly property bool denMusic:musicPlaying||(leased&&journey.musicPlaying===true)
    onDenMusicChanged:{if(denMusic){activity="dance";frame=0;poseExpiry.stop();}else vary();}
    property var telemetry:({})
    property string lastDeskWarning:""
    property var personal:[]
    property var memory:({recent:[],turn:0})
    property bool memoryLoaded:false
    property string lastMode:""
    property bool presenceLoaded:false
    property string welcomeText:""
    property bool welcoming:false
    property real lastWelcome:0
    property var wallpaperState:({})
    property var storyViews:({})
    property var storyWorld:({})
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/story-ready.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.storyViews=JSON.parse(text()).views||{};}catch(e){root.storyViews={};}}}
    FileView {path:Quickshell.env("HOME")+"/.local/share/sensei-den/story/world-v3.json";printErrors:false;onLoaded:{try{root.storyWorld=JSON.parse(text());}catch(e){}}}
    property int frame: 0
    property bool typingBurst: false
    property bool dragging:false
    property var dragStart:({x:0,y:0})
    property bool walkingRight: false
    property bool deliberateTravel: false
    property int variant: 0
    property var panelSpaces:[]
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/panel-spaces.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.panelSpaces=JSON.parse(text()).spaces||[];root.refresh();}catch(e){}}}
    property var occupied:[]
    property var placement: ({available:false,x:18,y:56})
    property var recent: []
    property int petTurns:0
    property int turn: 0
    property string lastContextLine:""
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
    IpcHandler {target:"companion";function guest(id:string):bool{return senseiGuests.start(id,true);}function guestNext():void{senseiGuests.next();}function guestPause():void{senseiGuests.paused=!senseiGuests.paused;}function guestClose():void{senseiGuests.finish();}function state():string{return JSON.stringify({name:"Zondo",musicPlaying:root.denMusic,guest:{active:senseiGuests.active,visible:senseiGuests.sceneVisible,id:senseiGuests.guest.id||"",page:senseiGuests.pageIndex,pages:senseiGuests.cards.length,kind:senseiGuests.card.kind||"",paused:senseiGuests.paused,revealed:senseiGuests.visibleCharacters,textLength:senseiGuests.textLength},allowed:root.allowed,speaking:root.speaking,speechVisible:speechWindow.visible,frame:root.frame,unread:root.pendingUnread,phonePending:root.phonePending,noticeAcks:root.noticeSeen.length,dnd:root.denDnd,output:root.target,fullscreen:root.fullscreen,pose:root.pose,size:root.preferences.size??96,reducedMotion:root.reduced,travel:root.deliberateTravel,placement:root.placement,obstacles:root.occupied,bubble:{x:speechWindow.margins.left,y:speechWindow.margins.top,width:speechWindow.width,height:speechWindow.height},activity:root.activity,extraPose:root.extraPose,welcome:root.welcoming,message:root.message,kind:root.messageKind,sprite:{status:character.status,sourceWidth:character.sourceSize.width,clip:character.sourceClipRect,viewport:{width:frameViewport.width,height:frameViewport.height,clipped:frameViewport.clip},scale:character.renderScale},panel:{x:pet.margins.left,y:pet.margins.top,width:pet.width,height:pet.height}});}}
    property string lastPublished:""
    function publish():void {
        const data=JSON.stringify({output:target,allowed:allowed,eligible:eligible,guestActive:senseiGuests.active,speaking:speaking||senseiGuests.active,speechVisible:speechWindow.visible||senseiGuests.active,message:message,kind:messageKind,name:"Zondo",reducedMotion:reduced,activity:activity,extraPose:extraPose,pose:pose,lastNote:lastNote,noteKind:noteKind});
        if(data!==lastPublished && renderFile){lastPublished=data;renderFile.setText(data);}
    }
    FileView {id:renderFile;path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-render.json";printErrors:false}
    Component.onCompleted:Qt.callLater(publish)
    onAllowedChanged:{updateSpeech();publish();}
    onSpeakingChanged:{updateSpeech();publish();if(!speaking&&["sing","phone"].includes(activity))vary();}
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
        for(const panel of panelSpaces)if(panel.output===target&&Number.isFinite(panel.x)&&Number.isFinite(panel.y)&&panel.w>0&&panel.h>0)windows.push({x:panel.x-12,y:panel.y-12,w:panel.w+24,h:panel.h+24});
        occupied=windows;
        const file=wallpaperState.displays?.[target]?.file||wallpaperState.lockedFile||"";
        const roof=!speaking&&variant%3===1?Logic.roofPlace(file,screen.width,screen.height,pet.width,pet.height,windows,variant):null;
        if(!animate&&placement.available&&placement.x>=12&&placement.y>=52&&placement.x+pet.width<=screen.width-12&&placement.y+pet.height<=screen.height-52&&!windows.some(w=>Logic.intersects({x:placement.x,y:placement.y,w:pet.width,h:pet.height},w)))return;
        placement=Logic.worldPlace(storyViews[target],storyWorld,screen.width,screen.height,pet.width,pet.height,windows,variant)||roof||Logic.place(screen.width,screen.height,pet.width,pet.height,windows,variant);
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
    function vary():void {activityTicks=0;activity=Logic.nextActivity(activity,denMusic,Math.random(),preferences.hiddenActivities||[],preferences.favoriteActivities||[]);if(placement.scene&&Math.random()<.4&&!denMusic){const moods={upper:"stargaze",main:"garden",lower:"calibrate",screenpad:"aquarium",homie:"robot"};activity=moods[placement.scene]||activity;}frame=0;poseExpiry.stop();}
    function welcome(text):void {if(Date.now()-lastWelcome<60000)return;if(preferences.welcome===false||preferences.quiet===true||preferences.enabled===false)return;lastWelcome=Date.now();welcomeText=text;welcoming=true;welcomeExpiry.restart();}
    function say(text,kind):void {if(senseiGuests.active)return;eventJob="";eventHost="";const words=String(text);const limit=kind==='singing along'?324:320;noticeHeading="";message=words.length>limit?words.slice(0,limit-4).replace(/\s+\S*$/,"")+"…":words;messageKind=kind||"field note";speaking=true;speechExpiry.interval=12000;speechExpiry.restart();updateSpeech();}
    function greet(manual):void {
        if(senseiGuests.active||!allowed||!speechWindow.bubblePlace.available||speaking||(!manual&&(preferences.chatter===false||denDnd))||!Logic.notes.length)return;
        if(notices.dnd&&notices.unread>0){say(notices.unread+" notifications waiting quietly. No rush; the bell has them when you want them.","quiet desk");return;}
        if(pendingUnread>0){announceNotice();if(speaking)return;}
        if(turn%3===0&&telemetry.suggestions?.length){
            const options=telemetry.suggestions.filter(x=>x!==lastContextLine);
            if(options.length){turn++;lastContextLine=options[Math.floor(Math.random()*options.length)];say(lastContextLine,"our workbench");remember();vary();return;}
        }
        if(turn%6===5&&personal.length){turn++;const text=personal[Math.floor(Math.random()*personal.length)];say("You kept this: "+text,"your words");remember();vary();return;}
        if(turn%5===4 && telemetry.summary){turn++;say(telemetry.summary,"live desk check");remember();return;}
        const note=Logic.nextNote(activeApp,recent,turn++,Math.random(),preferences.hiddenNotes||[],preferences.favoriteKinds||[]);
        if(!note)return;
        lastNote=note.id;noteKind=note.kind;recent=recent.concat([note.id]).slice(-40);remember();
        say(note.text,note.kind==="memory"?"from your project log":note.kind==="wit"?"Zondo, off duty":note.kind==="wonder"?"small wonder":"desk tip");
        vary();
    }
    function petHello():void {
        const lines=[
            "Hey, fh1m. Good to see you. Want a little company while the next idea takes shape?",
            "High five. I checked: your desk buddy is still smaller than the bugs we are going to catch.",
            "I brought exactly zero deadlines. We can just sit here for a moment.",
            "A whole Den of screens, and you found my tiny patch of roof. Excellent navigation.",
            "What are we curious about today? The answer is allowed to be something completely new.",
            "You handle the big ideas. I will supervise this extremely important mug.",
            "Tiny victory parade? I can provide the tiny part.",
            "If that diagram needs a second opinion, I have a very thoughtful head tilt ready.",
            "No productivity speech. Just a little wave from your corner of the digital universe.",
            "I like the bit where a confusing thing finally clicks. We can take our time getting there.",
            "A short stretch, a sip of water, then back to making things? Your call.",
            "Permission to be mildly ridiculous for thirty seconds? I have been rehearsing."
        ];
        activity=petTurns%3===2?"dance":"wave";frame=0;activityTicks=0;
        say(preferences.seeking?"Found me! My camouflage needs a peer review.":lines[petTurns++%lines.length],"your desk buddy");
        if(preferences.seeking)Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-den","companion","found"]);
    }
    function walk():void {
        if(!allowed||reduced)return;
        if(speaking)return;
        const old=placement, oldVariant=variant;
        variant=(variant+1)%35;locate(true);
        if(!Logic.canTravel(old,placement,pet.width,pet.height,occupied)){deliberateTravel=false;return;}
        walkingRight=placement.x>old.x;activity=placement.scene?"climb":placement.y!==old.y?"plane":"walk";frame=0;poseExpiry.restart();
    }
    onTargetChanged:{publish();deliberateTravel=false;placement={available:false,x:18,y:56};landing=false;refresh();arrivalHello.restart();}
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
    Timer {interval:Math.max(25000,Math.min(600000,(root.preferences.chatterSeconds??45)*1000));repeat:true;running:root.preferences.enabled!==false&&root.preferences.chatter!==false&&root.preferences.quiet!==true;onTriggered:root.greet()}
    Timer {id:dockHello;interval:1600;onTriggered:root.welcome("MORE ROOM TO BUILD")}
    Timer {id:arrivalHello;interval:5500;onTriggered:if(!root.speaking)root.greet()}
    FileView {path:Quickshell.env("HOME")+"/.local/state/sensei-den/companion-notifications.json";watchChanges:true;printErrors:false
        onFileChanged:reload();onLoaded:{try{const n=JSON.parse(text());if(root.noticeLoaded&&((n.event&&n.event!==root.notices.event)||n.unread>root.seenUnread)&&!n.dnd)noticeDelay.restart();if(root.noticeLoaded&&root.notices.dnd&&!n.dnd&&n.unread>0)noticeDelay.restart();root.seenUnread=n.unread||0;root.notices=n;root.noticeLoaded=true;}catch(e){}}
    }
    property var noticeSeen:[]
    property real lastNoticeAt:0
    property bool noticeMemoryLoaded:false
    readonly property var noticeSources:(leased?(journey.deskNotices||[]):[]).filter(n=>n.host!==notices.host).concat([notices])
    readonly property int pendingUnread:noticeSources.reduce((sum,n)=>sum+Number(n.unread||0),0)
    readonly property bool phonePending:noticeSources.some(n=>n.unread>0&&(n.entries||[]).some(e=>e.phone))
    readonly property bool denDnd:noticeSources.some(n=>n.dnd===true)
    onDenDndChanged:if(denDnd)speaking=false
    FileView {id:noticeMemory;onLoadFailed:root.noticeMemoryLoaded=true;path:Quickshell.env('HOME')+'/.local/state/sensei-den/zondo-notice-seen.json';printErrors:false;onLoaded:{try{root.noticeSeen=Array.from(new Set(root.noticeSeen.concat(JSON.parse(text()).ids||[]))).slice(-128);}catch(e){}root.noticeMemoryLoaded=true;}}
    function announceNotice():void {
        if(!noticeMemoryLoaded||senseiGuests.active||!allowed||!speechWindow.bubblePlace.available||denDnd||speaking||preferences.notificationChatter===false)return;
        const seen=noticeSeen.concat(journey.noticeAcks||[]);
        const e=Logic.nextNotice(noticeSources,seen,Date.now(),presence);
        if(e){noticeSeen=Array.from(new Set(seen.concat([e.id]))).slice(-128);
            if(noticeMemoryLoaded)noticeMemory.setText(JSON.stringify({ids:noticeSeen}));
            lastNoticeAt=Date.now();activity=e.phone?'phone':'wave';frame=0;say(Logic.noticeText(e),e.phone?'phone post':'den post');noticeHeading=Logic.noticeTitle(e);updateSpeech();
        }else if(pendingUnread>0&&Date.now()-lastNoticeAt>600000){lastNoticeAt=Date.now();say((phonePending?'Your phone still has stuff to say. ':'')+pendingUnread+' notifications are waiting in the bell. No rush.','pending post');}
    }
    Timer {id:noticeDelay;interval:1800;onTriggered:root.announceNotice()}
    Timer {interval:3500;repeat:true;running:root.preferences.enabled!==false&&root.preferences.notificationChatter!==false;onTriggered:root.announceNotice()}


    Timer {interval:Math.max(15000,Math.min(120000,(root.preferences.activitySeconds??27)*1000));repeat:true;running:root.eligible&&!root.reduced&&!root.speaking;onTriggered:root.vary()}
    Process {id:deskSample;command:[Quickshell.env("HOME")+"/.local/bin/sensei-zondo-context"];stdout:StdioCollector {onStreamFinished:{try{const x=JSON.parse(text);root.telemetry=x;const changed=root.musicPlaying!==x.playing;root.musicPlaying=x.playing;if(changed)root.vary();if(!x.warning)root.lastDeskWarning="";if(x.warning&&root.eligible&&!root.denDnd&&!root.speaking&&x.warning!==root.lastDeskWarning){root.lastDeskWarning=x.warning;root.say(x.warning,"measured, not guessed");}}catch(e){}}}}
    Timer {interval:20000;repeat:true;running:root.preferences.enabled!==false;triggeredOnStart:true;onTriggered:if(!deskSample.running)deskSample.running=true}
    Timer {interval:24000;repeat:true;running:root.allowed&&!root.reduced&&!root.speaking;onTriggered:root.walk()}
    Timer {interval:18000;repeat:true;running:root.allowed&&!root.reduced&&root.activity==="typing";onTriggered:{root.typingBurst=true;burstExpiry.restart();}}
    Timer {id:burstExpiry;interval:1320;onTriggered:{root.typingBurst=false;if(root.activity==="typing")root.frame=0;}}
    Timer {interval:root.activity==="sing"?240:root.activity==="dance"?180:root.activitySprite?.frames>4?130:180;repeat:true;running:root.allowed&&!root.reduced&&(root.typingBurst||root.activity==="walk"||root.activity==="climb"||root.activity==="dance"||root.activity==="sing"||(root.activitySprite&&(root.activitySprite.frames>4||root.activityTicks<12)));onTriggered:{root.frame=(root.frame+1)%(root.activitySprite?.frames||4);root.activityTicks++;}}
    Timer {id:poseExpiry;interval:2200;onTriggered:{root.vary();root.frame=0;root.deliberateTravel=false;}}
    Timer {id:speechExpiry;interval:12000;onTriggered:{root.speaking=false;}}
    Timer {id:landingExpiry;interval:700;onTriggered:root.landing=false}
    function updateSpeech():void {if(speechWindow)speechWindow.visible=!senseiGuests.active&&allowed&&speaking&&speechWindow.bubblePlace.available;}
    Timer {interval:250;repeat:true;running:root.allowed&&root.speaking;onTriggered:root.updateSpeech()}
    readonly property bool singingCard:speaking&&messageKind==='singing along'
    readonly property var speechScreen:Quickshell.screens.find(s=>s.name===root.target)??Quickshell.screens[0]
    PanelWindow {
        id:speechWindow;screen:root.speechScreen;visible:false
        readonly property var bubblePlace:Speech.place(root.speechScreen?.width??1920,root.speechScreen?.height??1080,speechWindow.implicitWidth,speechWindow.implicitHeight,root.placement,pet.width,pet.height,root.occupied)
        anchors {left:true;top:true}
        margins {left:bubblePlace.x;top:bubblePlace.y}
        readonly property int cardPadding:root.singingCard?20:16
        implicitWidth:Math.min((root.speechScreen?.width??1920)-32,root.singingCard?420:300)
        implicitHeight:Math.max(root.singingCard?100:76,Math.ceil(body.implicitHeight)+caption.implicitHeight+2*cardPadding+8)
        color:"transparent";exclusionMode:ExclusionMode.Ignore
        WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.namespace:"zondo-speech"
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.None;mask:Region {item:speechBubble}
        Rectangle {
            id:speechBubble
            TapHandler {onTapped:{if(root.eventJob)Quickshell.execDetached(["qs","-c","sensei","ipc","call","engineering-receipts","open",root.eventHost,root.eventJob]);else Quickshell.execDetached(["qs","-c","sensei","ipc","call","dropdown","open",["phone post","den post","pending post"].includes(root.messageKind)?"notifications":"engineering"]);}}
            anchors.fill:parent

            visible:true
            radius:9;color:root.messageKind==='phone post'?"#f211181b":"#f2171311";border.color:root.messageKind==='phone post'?"#788fbcc4":"#6244323a";border.width:1
            Text {id:caption;anchors {left:parent.left;top:parent.top;leftMargin:speechWindow.cardPadding;topMargin:speechWindow.cardPadding} text:root.noticeHeading?((root.messageKind==='phone post'?'▣ ':'')+root.noticeHeading):(root.singingCard?'♪ SING WITH ME':'ZONDO / '+root.messageKind.toUpperCase());textFormat:Text.PlainText;width:parent.width-2*speechWindow.cardPadding;elide:Text.ElideRight;font.family:"ZedMono Nerd Font";font.pixelSize:root.noticeHeading?13:11;font.weight:Font.DemiBold;font.letterSpacing:root.noticeHeading?0:.8;color:root.messageKind==='phone post'?"#8fbcc4":"#f23d70"}
            Text {id:body;anchors {left:parent.left;right:parent.right;top:caption.bottom;leftMargin:speechWindow.cardPadding;rightMargin:speechWindow.cardPadding;topMargin:8} text:root.message;textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:/[\u0980-\u09ff]/.test(text)?"Noto Sans Bengali":/[\u0900-\u097f]/.test(text)?"Noto Sans Devanagari":/[\u0600-\u06ff]/.test(text)?"Noto Sans Arabic":"Iosevka Nerd Font";font.pixelSize:root.singingCard?20:13;lineHeight:1.3;font.weight:root.singingCard?Font.Medium:Font.Normal;color:"#e8e2da"}
        }
    }
    PanelWindow {
        id:pet
        screen:Quickshell.screens.find(s=>s.name===root.target)??Quickshell.screens[0]
        visible:root.allowed&&!senseiGuests.active
        color:"transparent"
        readonly property real spriteSize:Math.max(64,Math.min(root.singingCard?200:180,root.singingCard?Math.max(160,(root.preferences.size??96)*1.65):(root.preferences.size??96)))
        implicitWidth:spriteSize
        implicitHeight:spriteSize
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
        Item {
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
            TapHandler {acceptedButtons:Qt.LeftButton;onTapped:root.petHello()}

            TapHandler {acceptedButtons:Qt.RightButton;onTapped:Quickshell.execDetached(["qs","-c","sensei","ipc","call","dropdown","open","engineering"])}
            id:character;clip:true;opacity:root.allowed?1:0;scale:root.landing?0.72:1
            Behavior on scale {enabled:!root.reduced;NumberAnimation {duration:650;easing.type:Easing.OutBack}}
            anchors {right:parent.right;bottom:parent.bottom}
            width:pet.spriteSize;height:width
            readonly property url atlasSource:Qt.resolvedUrl(root.activitySprite?root.activitySprite.file:root.activity==="climb"?"zondo-climb-v1.png":root.extraPose>=0?"zondo-life-v2.png":"fh1m-motion-v2.png")
            readonly property real cell:1254/4
            readonly property int tile:root.extraPose>=0?root.extraPose:root.pose
            readonly property rect frameRect:{if(root.activitySprite){const a=root.activitySprite,c=root.frame%(a.frames||4),r=a.row;if(a.rects){const q=a.rects[c];return Qt.rect(q[0],q[1],q[2],q[3]);}return Qt.rect(a.xs[c],a.ys[r],a.xs[c+1]-a.xs[c],a.ys[r+1]-a.ys[r]);}if(root.activity==="climb"){const xs=[0,543,1086,1629,2172],c=root.frame%4;return Qt.rect(xs[c],0,xs[c+1]-xs[c],724);}if(!(root.extraPose>=0))return Qt.rect((tile%4)*cell,Math.floor(tile/4)*cell,cell,cell);const xs=[0,313,627,945,1254],ys=[0,323,627,931,1254],c=tile%4,r=Math.floor(tile/4);return Qt.rect(xs[c],ys[r],xs[c+1]-xs[c],ys[r+1]-ys[r]);}
            readonly property int status:atlas.status
            readonly property size sourceSize:Qt.size(atlas.implicitWidth,atlas.implicitHeight)
            readonly property rect sourceClipRect:frameRect
            readonly property real renderScale:Math.min(width/frameRect.width,height/frameRect.height)
            // Clip the scaled frame itself, not the square pet surface: tall
            // frames otherwise expose the adjacent characters at either side.
            Item {id:frameViewport;anchors.centerIn:parent;width:character.frameRect.width*character.renderScale;height:character.frameRect.height*character.renderScale;clip:true
                Image {id:atlas;source:character.atlasSource;cache:true;asynchronous:true;retainWhileLoading:true;smooth:true
                    width:implicitWidth*character.renderScale;height:implicitHeight*character.renderScale
                    x:-character.frameRect.x*character.renderScale;y:-character.frameRect.y*character.renderScale
                }
            }
            SequentialAnimation on rotation {running:root.allowed&&!root.reduced&&root.activity==='dance';loops:Animation.Infinite;NumberAnimation {from:-3;to:3;duration:420;easing.type:Easing.InOutSine}NumberAnimation {from:3;to:-3;duration:420;easing.type:Easing.InOutSine}onStopped:character.rotation=0}

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
                Text {text:"FH1M / DIGITAL DEN";color:"#ff4297";font.family:"ZedMono Nerd Font";font.pixelSize:Math.max(14,Math.min(22,arrival.width*.014)); font.letterSpacing:3}
                Text {text:root.welcomeText; color:"#f4e9ee";font.family:"ZedMono Nerd Font";font.pixelSize:Math.max(24,Math.min(52,arrival.width*.032))}
                Text {text:"Zondo is at the desk.\nMake something that has to work.";color:"#c8b7bf";font.family:"ZedMono Nerd Font";font.pixelSize:Math.max(14,Math.min(21,arrival.width*.014));lineHeight:1.5}
            }
        }
    }

}
