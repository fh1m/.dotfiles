import QtQuick
import "."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "GuestLogic.js" as Policy

// A local illustrated conversation. Real quotations and authored stage dialogue
// have different labels. No audio, online generation or application focus grab.
Item {
    id: root
    property var targetScreen:null
    property bool permitted:false
    property bool busy:false
    property bool reducedMotion:false
    property var obstacles:[]
    property var preferences:({})
    property var catalog:({guests:[],sources:{}})
    property var history:({quotes:[],guest:'',lastAt:0})
    property bool historyReady:false
    property bool active:false
    property bool paused:false
    property int guestIndex:0
    property int quoteIndex:0
    property int pageIndex:0
    property int frame:0
    property var cards:[]
    property var placement:({available:false,x:12,y:52})
    readonly property var guest:catalog.guests[guestIndex]||({})
    readonly property var card:cards[pageIndex]||({})
    readonly property var source:catalog.sources[card.source]||({})
    readonly property bool sceneVisible:scene.visible
    property int visibleCharacters:0
    readonly property int textLength:String(card.text||'').length
    onCardChanged:{visibleCharacters=(reducedMotion||paused)?String(card.text||'').length:0;Qt.callLater(checkSpace);}
    onReducedMotionChanged:if(reducedMotion)visibleCharacters=textLength
    Timer {interval:30;repeat:true;running:root.active&&!root.paused&&!root.reducedMotion&&root.visibleCharacters<root.textLength;onTriggered:root.visibleCharacters=Math.min(root.textLength,root.visibleCharacters+2)}
    readonly property bool listening:card.speaker!=='Zondo'
    readonly property bool sleepy:listening&&pageIndex>2&&cards.length>5&&quoteIndex%4===0
    property real seenRequest:0
    signal began()
    signal ended()
    FileView {path:Quickshell.env('HOME')+'/.local/share/sensei-companion/guests/catalog.json';printErrors:false
        onLoaded:{try{const d=JSON.parse(text());if(d.schema===1)root.catalog=d;}catch(e){}}
    }
    FileView {id:memory;path:Quickshell.env('HOME')+'/.local/state/sensei-den/zondo-guests.json';printErrors:false
        onLoadFailed:root.historyReady=true
        onLoaded:{try{const d=JSON.parse(text());root.history={guest:String(d.guest||''),quotes:Array.isArray(d.quotes)?d.quotes.slice(-60):[],lastAt:Number(d.lastAt)||0,requestAt:Number(d.requestAt)||0};root.seenRequest=root.history.requestAt;}catch(e){}root.historyReady=true;}
    }
    function start(id,manual):bool {
        if(!permitted||!targetScreen||!historyReady||!catalog.guests.length||(!manual&&busy))return false;
        const chosen=Policy.choose(catalog.guests,history,id||'',Math.random(),preferences.guestMode||'mixed');
        if(!chosen)return false;
        const pos=Policy.place(targetScreen.width,targetScreen.height,scene.implicitWidth,scene.implicitHeight,obstacles,chosen.guest);
        if(!pos.available)return false;
        guestIndex=chosen.guest;quoteIndex=chosen.quote;pageIndex=0;frame=0;paused=false;placement=pos;
        const selection=Policy.entries(guest)[quoteIndex];cards=Policy.pages(guest,selection);
        if(manual)seenRequest=Math.max(seenRequest,Number(preferences.guestRequest?.at||0));
        history={requestAt:seenRequest,guest:guest.id,quotes:(history.quotes||[]).concat([selection.id]).slice(-60),lastAt:Date.now()};
        memory.setText(JSON.stringify(history)+'\n');active=true;began();arrival.restart();pageClock.restart();return true;
    }
    function finish():void {if(!active)return;active=false;pageClock.stop();ended();}
    function next():void {if(pageIndex+1>=cards.length){finish();return;}pageIndex++;frame=0;if(!paused)pageClock.restart();}
    function previous():void {pageIndex=Math.max(0,pageIndex-1);if(!paused)pageClock.restart();}
    function checkSpace():void {
        if(!active)return;
        if(!permitted||!targetScreen){finish();return;}
        const p=Policy.place(targetScreen.width,targetScreen.height,scene.implicitWidth,scene.implicitHeight,obstacles,guestIndex);
        if(!p.available){finish();return;}placement=p;
    }
    onPermittedChanged:checkSpace()
    onTargetScreenChanged:if(active)finish()
    onObstaclesChanged:checkSpace()
    function tryRequest():void {
        const r=preferences.guestRequest;
        if(r&&Number(r.at)>seenRequest&&Date.now()/1000-r.at<300){
            if(start(String(r.id||''),true))seenRequest=Number(r.at);
        }
    }
    onPreferencesChanged:{if(preferences.guestsEnabled===false)finish();else tryRequest();}
    onPausedChanged:{if(paused){visibleCharacters=textLength;pageClock.stop();}else if(active)pageClock.restart();}
    Timer {interval:1500;repeat:true;running:root.permitted&&Number(root.preferences.guestRequest?.at||0)>root.seenRequest;onTriggered:{if(Date.now()/1000-Number(root.preferences.guestRequest?.at||0)>=300)stop();else root.tryRequest();}}
    Timer {interval:60000;repeat:true;running:root.permitted&&root.preferences.guestsEnabled!==false
        onTriggered:if(!root.active&&Date.now()-root.history.lastAt>=Math.max(15,root.preferences.guestMinutes||30)*60000)root.start('',false)
    }
    Timer {id:pageClock;interval:Policy.duration(root.card)+(root.reducedMotion?0:Math.ceil(root.textLength/2)*30);onTriggered:root.next()}
    Timer {interval:1100;repeat:true;running:root.active&&!root.reducedMotion;onTriggered:root.frame=(root.frame+1)%4}
    ParallelAnimation {id:arrival
        NumberAnimation {target:sceneContent;property:'opacity';from:0;to:1;duration:root.reducedMotion?0:500;easing.type:Easing.OutCubic}
        NumberAnimation {target:flight;property:'x';from:-18;to:0;duration:root.reducedMotion?0:650;easing.type:Easing.OutCubic}
    }
    PanelWindow {
        id:scene;screen:root.targetScreen;visible:root.active&&root.permitted&&root.placement.available
        implicitWidth:Math.min(480,(root.targetScreen?.width||1920)-24)
        implicitHeight:bubble.height+210
        anchors {left:true;top:true}
        margins {left:root.placement.x;top:root.placement.y}
        color:'transparent';exclusionMode:ExclusionMode.Ignore;exclusiveZone:0
        WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.namespace:'sensei-guest-visit';WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
        mask:Region {item:sceneContent}
        Item {id:sceneContent;anchors.fill:parent;transform:Translate {id:flight;x:0}
            Rectangle {
                id:bubble;anchors {left:parent.left;right:parent.right;top:parent.top} height:controls.y+33
                radius:10;color:'#f509090b';border.width:1;border.color:'#5e65434e'
                Rectangle {x:0;y:20;width:2;height:34;color:root.listening?'#d84370':'#8fbcc4'}
                Text {id:heading;x:18;y:14;width:parent.width-80;text:root.card.speaker||'';textFormat:Text.PlainText;font.family:'ZedMono Nerd Font';font.pixelSize:15;font.weight:Font.DemiBold;color:'#eee8e1';elide:Text.ElideRight}
                Text {x:18;y:38;width:parent.width-36;text:root.card.kind||'';textFormat:Text.PlainText;font.family:'Iosevka Nerd Font';font.pixelSize:11;color:'#a6909a';elide:Text.ElideRight}
                Text {id:fullBody;visible:false;width:parent.width-36;text:(root.card.kind==='quotation'?'“':'')+String(root.card.text||'')+(root.card.kind==='quotation'?'”':'');wrapMode:Text.WordWrap;font.family:'Iosevka Nerd Font';font.pixelSize:16;lineHeight:1.2}
                Text {x:18;y:62;width:parent.width-36;height:Math.max(48,fullBody.implicitHeight);text:(root.card.kind==='quotation'?'“':'')+String(root.card.text||'').slice(0,root.reducedMotion?root.textLength:root.visibleCharacters)+(root.card.kind==='quotation'?'”':'');textFormat:Text.PlainText;wrapMode:Text.WordWrap;font.family:'Iosevka Nerd Font';font.pixelSize:16;lineHeight:1.2;color:'#e8e2da'
                    TapHandler {onTapped:root.visibleCharacters=root.textLength}
                }
                Text {id:sourceCredit;x:18;y:72+Math.max(48,fullBody.implicitHeight);width:parent.width-36;text:root.source.title?('↗ '+root.source.title):'Illustrated visit · fictional staging';textFormat:Text.PlainText;font.family:'Iosevka Nerd Font';font.pixelSize:11;color:root.source.url?'#d990a7':'#887c84';elide:Text.ElideRight
                    TapHandler {enabled:Boolean(root.source.url)&&(String(root.source.url).startsWith('https://')||String(root.source.url).startsWith('http://number-none.com/'));onTapped:Qt.openUrlExternally(root.source.url)}
                }
                Row {id:controls;x:14;y:sourceCredit.y+22;spacing:5
                    Repeater {model:[{text:'‹',act:'back'},{text:root.paused?'▶':'Ⅱ',act:'pause'},{text:'Next ›',act:'next'},{text:'Another guest',act:'guest'},{text:'×',act:'close'}]
                        Rectangle {required property var modelData;width:modelData.act==='guest'?108:modelData.act==='next'?76:32;height:23;radius:4;color:buttonHover.hovered?'#32202a':'#171217';border.width:1;border.color:'#49313b'
                            Text {anchors.centerIn:parent;text:modelData.text;font.family:'ZedMono Nerd Font';font.pixelSize:11;color:'#d9c9cf'}
                            HoverHandler {id:buttonHover;cursorShape:Qt.PointingHandCursor}
                            TapHandler {onTapped:{const a=modelData.act;if(a==='back')root.previous();else if(a==='pause'){root.paused=!root.paused;}else if(a==='next')root.next();else if(a==='guest')root.start('',true);else root.finish();}}
                        }
                    }
                    Text {text:(root.pageIndex+1)+' / '+root.cards.length;leftPadding:5;topPadding:4;font.family:'Iosevka Nerd Font';font.pixelSize:11;color:'#a58d99'}
                }
                Rectangle {anchors {right:parent.right;top:parent.top;rightMargin:12;topMargin:12} width:22;height:22;radius:5;color:'#241820'
                    Text {anchors.centerIn:parent;text:'×';font.family:'ZedMono Nerd Font';color:'#d8c1cb'}
                    TapHandler {onTapped:root.finish()}
                }
            }
            GuestSprite {x:65;y:bubble.height+6;width:150;height:180;source:Qt.resolvedUrl('guests/'+(root.guest.atlas||''));frame:root.frame;reducedMotion:root.reducedMotion}
            GuestSprite {x:280;y:bubble.height+36;width:130;height:150;source:Qt.resolvedUrl(root.listening?'guests/zondo-listener-side-v1.png':'guests/zondo-listener-v1.png');frame:root.sleepy?3:root.listening?(root.frame%3):1;reducedMotion:root.reducedMotion}
            Text {x:230;y:bubble.height+190;width:240;text:root.sleepy?'Zondo is processing… with eyes closed.':root.listening?'Zondo · listening':'Zondo · wait, one question';horizontalAlignment:Text.AlignHCenter;font.family:'Iosevka Nerd Font';font.pixelSize:10;color:'#b3a5ac';elide:Text.ElideRight}
        }
    }
}
