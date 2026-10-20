import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

DropdownFrame {
    id: root
    property Item searchInput:null
    property string contributionInfo:""
    title: "fh1m / Code"
    katakana: CodeDesk.tab === 0 ? "GITHUB" : CodeDesk.tab===1 ? "AGENTS" : CodeDesk.tab===2 ? "NERD TALK" : CodeDesk.tab===4 ? "SENSEI GUESTS" : "RABBIT HOLES"
    implicitWidth: 1100
    function ago(stamp) {return stamp ? "Updated " + new Date(stamp*1000).toLocaleTimeString(Qt.locale(), "hh:mm") : "Waiting for account data";}
    function duration(minutes) {
        if(!minutes)return "Window duration unavailable";
        if(minutes>=1440 && minutes%1440===0)return (minutes/1440)+" days";
        if(minutes>=60 && minutes%60===0)return (minutes/60)+" hours";
        return minutes+" minutes";
    }
    function metric(value) {
        const text=String(value??"—"), number=Number(text.replace(/,/g,""));
        if(!Number.isFinite(number))return text;
        if(number>=1000000)return (number/1000000).toFixed(1)+"M";
        if(number>=1000)return (number/1000).toFixed(1)+"k";
        return text;
    }
    // A recorded window: what is left, the bar's fill, and when it resets. Missing means none recorded.
    function windowLeft(w) {return w&&w.used_percentage!=null?Math.max(0,100-w.used_percentage).toFixed(0)+"% remaining":"No window recorded";}
    function fillOf(w) {return w&&w.used_percentage!=null?Math.max(0,Math.min(1,(100-w.used_percentage)/100)):0;}
    function resetText(iso) {if(!iso)return "No reset recorded";const t=new Date(iso);return t<new Date()?"Reset passed · open Claude to record":"Resets "+t.toLocaleString(Qt.locale(),"ddd d MMM · hh:mm AP");}
    function peakDaily(days) {return (days??[]).reduce((m,d)=>Math.max(m,d.tokens),1);}
    function pushDate(value) {return value?new Date(value).toLocaleDateString(Qt.locale(),"d MMM yyyy"):"Unknown";}
    Column {
        width: parent.width
        spacing: 10
        Row {
            spacing: 8
            ControlTile {label:"Code";glyph:"\uf121";selected:CodeDesk.tab===0;implicitWidth:140;onActivated:CodeDesk.tab=0}
            ControlTile {label:"Agents";glyph:"\uf0e4";selected:CodeDesk.tab===1;implicitWidth:140;onActivated:CodeDesk.tab=1}
            ControlTile {label:"Nerd Talk";glyph:"\uf0eb";selected:CodeDesk.tab===2;implicitWidth:140;onActivated:CodeDesk.tab=2}
            ControlTile {label:"Sensei guests";glyph:"\uf4ad";selected:CodeDesk.tab===4;implicitWidth:160;onActivated:CodeDesk.tab=4}
            ControlTile {label:"Hacker News";glyph:"\uf074";selected:CodeDesk.tab===3;implicitWidth:140;onActivated:CodeDesk.tab=3}
            ControlTile {visible:CodeDesk.tab!==4;label:"Refresh";glyph:"\uf021";implicitWidth:120;enabled:!CodeDesk.loading;onActivated:CodeDesk.refresh(true)}
        }
        NrLabel {textFormat:Text.PlainText;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:CodeDesk.tab===0?(CodeDesk.error || (CodeDesk.loading?"Refreshing GitHub…":root.ago(CodeDesk.data.fetchedAt)+(CodeDesk.data.stale?" · Cached":""))):(CodeDesk.tab===4?"A visit, a source, a question · local and quiet-aware":CodeDesk.tab>=2?root.ago((CodeDesk.tab===3?CodeDesk.curiosity:CodeDesk.nerd).fetchedAt):CodeDesk.provider===1?root.ago(CodeDesk.openCodeUsage.fetchedAt):CodeDesk.provider===2?(CodeDesk.claudeUsage.error||root.ago(CodeDesk.claudeUsage.fetchedAt)):(CodeDesk.usage.error||root.ago(CodeDesk.usage.fetchedAt)));color:CodeDesk.error?Theme.semanticAmber:Theme.paperMuted;pixelSize:12}
        Loader {
            width:parent.width
            sourceComponent:CodeDesk.tab===0?codePage:CodeDesk.tab===1?subscriptionPage:CodeDesk.tab===2?nerdPage:CodeDesk.tab===4?guestPage:curiosityPage
        }
    }
    Component {id:guestPage;GuestLibrary {width:parent?parent.width:1000}}
    Component {
        id:nerdPage
        Column {width:parent.width;spacing:10
            Rectangle {
                width:parent.width;height:116;color:"#090807";radius:6;clip:true
                Image {anchors {right:parent.right;top:parent.top;bottom:parent.bottom} width:348;source:Quickshell.env("HOME")+"/.local/share/sensei-companion/night-shift.png";fillMode:Image.PreserveAspectFit;asynchronous:true}
                Column {x:16;y:20;width:parent.width-380;spacing:10
                    Text {text:"AFTER HOURS / FH1M'S DIGITAL DEN";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.caption;font.letterSpacing:1;color:Theme.signalRed}
                    Text {width:parent.width;text:"The lab has a night shift.";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.title;color:Theme.paper}
                    Text {width:parent.width;text:"Good questions. Small experiments. Occasional rubber ducks.";elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
                }
            }
            Rectangle {width:parent.width;height:72;color:Theme.surfaceOne;radius:3
                Column {x:12;y:10;width:parent.width-170;spacing:6
                    Text { textFormat: Text.PlainText;width:parent.width;elide:Text.ElideRight;text:CodeDesk.nerd.quotes?.[CodeDesk.quoteIndex]?.text?'“'+CodeDesk.nerd.quotes[CodeDesk.quoteIndex].text+'”':'One small experiment beats a large assumption.';color:Theme.signalRed;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.title}
                    Text { textFormat: Text.PlainText;width:parent.width;elide:Text.ElideRight;text:CodeDesk.nerd.quotes?.[CodeDesk.quoteIndex]?.text?(CodeDesk.nerd.quotes[CodeDesk.quoteIndex].context||'')+' · Andrej Karpathy':'Den field note · Original desk wisdom';color:Theme.paperMuted;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary}
                }
                ControlTile {anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;label:"Source";glyph:"\uf08e";implicitWidth:100;enabled:!!CodeDesk.nerd.quoteSource&&!!CodeDesk.nerd.quotes?.length;onActivated:CodeDesk.browse(CodeDesk.nerd.quoteSource)}
                MouseArea {x:12;width:parent.width-170;height:parent.height;onClicked:CodeDesk.quoteIndex=(CodeDesk.quoteIndex+1)%Math.max(1,CodeDesk.nerd.quotes?.length||0)}
            }
            Row {spacing:8
                Repeater {model:["New this week","Robotics / systems","GitHub changelog"]
                    ControlTile {required property string modelData;required property int index;label:modelData;glyph:["\uf005","\uf085","\uf1ea"][index];implicitWidth:190;selected:CodeDesk.nerdFeed===index;onActivated:CodeDesk.nerdFeed=index}
                }
            }
            Text { textFormat: Text.PlainText;width:parent.width;wrapMode:Text.Wrap;text:CodeDesk.nerdLoading?"Fetching public discovery…":(CodeDesk.nerd.errors||[]).join(' · ')||'Public search sorted by stars · not GitHub’s daily trending ranking · cached for one hour';font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
            ScrollView {width:parent.width;height:300;contentWidth:availableWidth;clip:true
                Column {width:parent.width;spacing:6
                    Repeater {model:CodeDesk.nerdFeed===2?(CodeDesk.nerd.news||[]):CodeDesk.nerdFeed===1?(CodeDesk.nerd.lab||[]):(CodeDesk.nerd.new||[])
                        Rectangle {required property var modelData;width:parent.width;height:86;color:Theme.surfaceOne;radius:3
                            Column {x:12;y:10;width:parent.width-28;spacing:6
                                Text {width:parent.width;text:modelData.full_name||modelData.title;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.signalRed}
                                Text {width:parent.width;text:modelData.description||modelData.summary||'No description';textFormat:Text.PlainText;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paper}
                                Text { textFormat: Text.PlainText;width:parent.width;text:modelData.full_name?root.metric(modelData.stargazers_count)+' stars · '+root.metric(modelData.forks_count)+' forks · '+(modelData.language||'Mixed')+' · '+root.metric(modelData.open_issues_count)+' open issues':modelData.date;elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.caption;color:Theme.paperMuted}
                            }
                            MouseArea {anchors.fill:parent;onClicked:CodeDesk.browse(modelData.html_url||modelData.url)}
                        }
                    }
                }
            }
        }
    }
    Component {
        id:curiosityPage
        Column {width:parent.width;spacing:12
            Text { textFormat: Text.PlainText;width:parent.width;text:"Things people made. Questions worth stealing.";color:Theme.signalRed;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.title}
            Row {spacing:8
                ControlTile {label:"Show HN";glyph:"\uf0ad";implicitWidth:130;selected:CodeDesk.curiosityFeed===0;onActivated:CodeDesk.curiosityFeed=0}
                ControlTile {label:"Ask HN";glyph:"\uf128";implicitWidth:130;selected:CodeDesk.curiosityFeed===1;onActivated:CodeDesk.curiosityFeed=1}
            }
            Text { textFormat: Text.PlainText;width:parent.width;wrapMode:Text.Wrap;text:CodeDesk.nerdLoading?"Opening a small rabbit hole…":(CodeDesk.curiosity.errors||[]).join(' · ')||"Public Hacker News stories · refreshes on demand · no tracking or notifications";color:Theme.paperMuted;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary}
            ScrollView {width:parent.width;height:410;clip:true;contentWidth:availableWidth
                Column {width:parent.width;spacing:8
                    Repeater {model:CodeDesk.curiosityFeed===0?(CodeDesk.curiosity.show||[]):(CodeDesk.curiosity.ask||[])
                        Rectangle {required property var modelData;width:parent.width;height:68;color:Theme.surfaceOne;radius:3
                            Column {x:12;y:10;width:parent.width-24;spacing:8
                                Text {width:parent.width;text:modelData.title;textFormat:Text.PlainText;elide:Text.ElideRight;color:Theme.paper;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body}
                                Text { textFormat: Text.PlainText;text:modelData.score+" points · "+modelData.comments+" comments · "+modelData.by;color:Theme.paperMuted;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary}
                            }
                            MouseArea {anchors.fill:parent;onClicked:CodeDesk.browse(modelData.url)}
                        }
                    }
                }
            }
        }
    }
    Component {
        id:codePage
        Column {
            width:parent.width;spacing:12
            OperatorBanner {width:parent.width}
            Row {spacing:20
                NrLabel {textFormat:Text.PlainText;tracked:false;font.capitalization:Font.MixedCase;text:"@"+(CodeDesk.data.login||"fh1m");pixelSize:16;color:Theme.signalRed}
                NrLabel {textFormat:Text.PlainText;tracked:false;font.capitalization:Font.MixedCase;text:(CodeDesk.data.repositoryCount?.totalCount??"—")+" repositories · "+(CodeDesk.data.followers?.totalCount??"—")+" followers · "+(CodeDesk.data.starredRepositories?.totalCount??"—")+" starred · "+(CodeDesk.data.contributionsCollection?.contributionCalendar?.totalContributions??"—")+" contributions / year";pixelSize:12}
            }
            NrLabel {tracked:false;font.capitalization:Font.MixedCase;pixelSize:11;color:Theme.paperMuted;text:(CodeDesk.data.prs?.total_count??0)+" open PRs   ·   "+(CodeDesk.data.reviews?.total_count??0)+" review requests   ·   "+(CodeDesk.data.issues?.total_count??0)+" issues   ·   "+(CodeDesk.data.following?.totalCount??0)+" following"}
            Row {
                spacing:3
                Repeater {
                    model:CodeDesk.data.contributionsCollection?.contributionCalendar?.weeks??[]
                    Column {required property var modelData;spacing:3
                        Repeater {model:modelData.contributionDays
                            Rectangle {required property var modelData;width:12;height:12;radius:2
                                color: {const n=modelData.contributionCount;return n===0?Theme.surfaceTwo:Theme.alpha(Theme.signalRed,n<3?.3:n<6?.5:n<10?.75:1);}
                                MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.contributionInfo=modelData.date+" · "+modelData.contributionCount+" contributions"}
                            }
                        }
                    }
                }
            }
            Text { textFormat: Text.PlainText;visible:root.contributionInfo!=="";text:root.contributionInfo;color:Theme.paperMuted;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary}
            TextField {id:search;Component.onCompleted:root.searchInput=search;Component.onDestruction:root.searchInput=null;width:parent.width;placeholderText:"Find a project…";placeholderTextColor:Theme.paperMuted;text:CodeDesk.query;onTextEdited:CodeDesk.query=text;color:Theme.paper;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;background:Rectangle{color:Theme.surfaceOne;border.color:search.activeFocus?Theme.signalRed:Theme.rule;radius:3} Keys.onEscapePressed:{CodeDesk.query="";event.accepted=true;}}
            Row {
                width:parent.width;spacing:18
                Column {width:(parent.width-18)*.53;spacing:8
                    Row {spacing:6
                        ControlTile {implicitWidth:130;label:"Recent";glyph:"\uf017";selected:!CodeDesk.pinnedOnly;onActivated:CodeDesk.pinnedOnly=false}
                        ControlTile {implicitWidth:130;label:"Pinned";glyph:"\uf08d";selected:CodeDesk.pinnedOnly;onActivated:CodeDesk.pinnedOnly=true}
                    }
                    ScrollView {width:parent.width;height:300;clip:true;contentWidth:availableWidth
                        Column {width:parent.width;spacing:6
                            Repeater {model:CodeDesk.repositories
                                Rectangle {required property var modelData;width:parent.width;height:81;radius:3;color:Theme.surfaceOne;border.color:CodeDesk.selectedRepo===modelData.nameWithOwner?Theme.signalRed:Theme.rule
                                    Column {x:12;y:9;width:parent.width-125;spacing:5
                                        NrLabel {textFormat:Text.PlainText;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:modelData.nameWithOwner;pixelSize:13;color:Theme.paper;elide:Text.ElideRight}
                                        NrLabel {textFormat:Text.PlainText;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:(modelData.isPrivate?"Private · ":"")+(modelData.description||"No description");pixelSize:11;color:Theme.paperMuted;elide:Text.ElideRight}
                                        NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:(modelData.stargazerCount??0)+" stars"+(modelData.pushedAt?" · Pushed "+root.pushDate(modelData.pushedAt):"");pixelSize:10;color:Theme.paperMuted;elide:Text.ElideRight}
                                    }
                                    Row {anchors.right:parent.right;anchors.rightMargin:8;anchors.verticalCenter:parent.verticalCenter;spacing:5
                                        ControlTile {implicitWidth:40;label:"";glyph:"\uf05a";Accessible.name:"Inspect repository";onActivated:CodeDesk.select(modelData.nameWithOwner)}
                                        ControlTile {implicitWidth:40;label:"";glyph:"\uf07c";Accessible.name:"Open project";onActivated:CodeDesk.project(modelData)}
                                    }
                                }
                            }
                        }
                    }
                }
                Column {width:(parent.width-18)*.47;spacing:8
                    Row {spacing:5
                        Repeater {model:["Activity","PRs","Issues","Commits"]
                            ControlTile {required property string modelData;required property int index;implicitWidth:103;label:modelData;glyph:["\uf0ae","\uf126","\uf188","\uf121"][index];selected:CodeDesk.feed===index;onActivated:CodeDesk.feed=index}
                        }
                    }
                    ScrollView {width:parent.width;height:300;clip:true;contentWidth:availableWidth
                        Column {width:parent.width;spacing:6
                            Repeater {model:CodeDesk.feed===0&&CodeDesk.selectedRepo?(CodeDesk.detail.runs?.workflow_runs??[]).slice(0,5):[]
                                ControlTile {required property var modelData;implicitWidth:parent.width;label:modelData.name;detail:"CI · "+(modelData.conclusion||modelData.status);glyph:"\uf0ae";onActivated:CodeDesk.browse(modelData.html_url)}
                            }
                            Repeater {model:CodeDesk.feed<=1?(CodeDesk.selectedRepo?(CodeDesk.detail.pulls??[]):(CodeDesk.data.reviews?.items??[]).concat(CodeDesk.data.prs?.items??[])).slice(0,CodeDesk.feed===0?3:1000):[]
                                ControlTile {required property var modelData;implicitWidth:parent.width;implicitHeight:49;label:modelData.title;detail:"Pull request #"+modelData.number;glyph:"\uf126";onActivated:CodeDesk.browse(modelData.html_url)}
                            }
                            Repeater {model:CodeDesk.feed===0||CodeDesk.feed===2?(CodeDesk.selectedRepo?(CodeDesk.detail.issues??[]).filter(x=>!x.pull_request):(CodeDesk.data.issues?.items??[])).slice(0,CodeDesk.feed===0?2:1000):[]
                                ControlTile {required property var modelData;implicitWidth:parent.width;implicitHeight:49;label:modelData.title;detail:"Issue #"+modelData.number;glyph:"\uf188";onActivated:CodeDesk.browse(modelData.html_url)}
                            }
                            Repeater {model:CodeDesk.feed===0||CodeDesk.feed===3?(CodeDesk.selectedRepo?(CodeDesk.detail.commits??[]):(CodeDesk.data.commits??[])):[]
                                ControlTile {required property var modelData;implicitWidth:parent.width;implicitHeight:49;label:modelData.messageHeadline;detail:modelData.repo+" · "+modelData.oid.slice(0,7);glyph:"\uf121";onActivated:CodeDesk.browse(modelData.url)}
                            }
                        }
                    }
                }
            }
            Row {spacing:8
                ControlTile {label:CodeDesk.data.repositories?.pageInfo?.hasNextPage?"Load more projects":"All repositories";glyph:"\uf09b";onActivated:{if(CodeDesk.data.repositories?.pageInfo?.hasNextPage)CodeDesk.loadMore();else CodeDesk.browse("https://github.com/"+(CodeDesk.data.login||"fh1m")+"?tab=repositories");}}
                ControlTile {visible:CodeDesk.selectedRepo===""&&CodeDesk.feed!==3&&((CodeDesk.data.prs?.total_count??0)>(CodeDesk.data.prs?.items?.length??0)||(CodeDesk.data.issues?.total_count??0)>(CodeDesk.data.issues?.items?.length??0)||(CodeDesk.data.reviews?.total_count??0)>(CodeDesk.data.reviews?.items?.length??0));label:"More activity";glyph:"\uf067";onActivated:CodeDesk.moreActivity()}
                ControlTile {visible:CodeDesk.selectedRepo!=="";label:"Back to overview";glyph:"\uf060";onActivated:CodeDesk.selectedRepo=""}
            }
        }
    }
    Component {
        id:subscriptionPage
        Column {
            width:parent.width;spacing:16
            Row {spacing:6
                ControlTile {label:"Codex";glyph:"\uf121";implicitWidth:136;selected:CodeDesk.provider===0;onActivated:CodeDesk.provider=0}
                ControlTile {label:"OpenCode";glyph:"\uf120";implicitWidth:146;selected:CodeDesk.provider===1;onActivated:CodeDesk.provider=1}
                ControlTile {label:"Claude Code";glyph:"\uf0e7";implicitWidth:168;selected:CodeDesk.provider===2;onActivated:CodeDesk.provider=2}
            }
            Column {
                width:parent.width;spacing:14;visible:CodeDesk.provider===0
                Row {spacing:18
                    NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"Codex / "+(CodeDesk.usage.account?.planType||CodeDesk.usage.rateLimits?.planType||"Awaiting account");pixelSize:16;color:Theme.paper}
                    NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:CodeDesk.usage.state?.label||"Connecting…";pixelSize:12;color:CodeDesk.usage.state?.kind==="exhausted"?Theme.signalRed:Theme.paperMuted}
                }
                Row {
                    width:parent.width;spacing:28
                    Repeater {model:[{name:"Current window",value:CodeDesk.usage.rateLimits?.primary},{name:"Longer window",value:CodeDesk.usage.rateLimits?.secondary}]
                        Column {required property var modelData;width:(parent.width-28)/2;spacing:8
                            Item {width:parent.width;height:20
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:modelData.name+(modelData.value?" · "+root.duration(modelData.value.windowDurationMins):"");pixelSize:11;color:Theme.paperMuted}
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;anchors.right:parent.right;text:modelData.value?Math.max(0,100-modelData.value.usedPercent)+"% remaining":"—";pixelSize:13;color:Theme.signalRed}
                            }
                            Rectangle {width:parent.width;height:3;radius:1;color:Theme.surfaceTwo
                                Rectangle {width:parent.width*Math.max(0,Math.min(1,(100-(modelData.value?.usedPercent??100))/100));height:3;radius:1;color:Theme.signalRed}
                            }
                            NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:modelData.value?"Resets "+new Date(modelData.value.resetsAt*1000).toLocaleString(Qt.locale(),"ddd, d MMM · hh:mm AP"):"No quota reported";pixelSize:11;color:Theme.paperMuted}
                        }
                    }
                }
                NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"Credits "+(CodeDesk.usage.rateLimits?.credits?.unlimited?"Unlimited":CodeDesk.usage.rateLimits?.credits?.balance??"Unavailable")+"    ·    Available resets "+(CodeDesk.usage.resetCredits??"Unavailable")+"    ·    Auth "+(CodeDesk.usage.account?.type||"Not signed in");pixelSize:11;color:Theme.paperMuted}
                NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:"Exhausted usage resets on the reported schedule. A Free plan offers an upgrade; billing expiry is not exposed by Codex.";wrapMode:Text.WordWrap;pixelSize:11;color:Theme.paperMuted}
                ControlTile {label:CodeDesk.usage.state?.kind==="free"?"Renew paid access":"Usage and billing";glyph:"\uf013";onActivated:Quickshell.execDetached(["xdg-open","https://chatgpt.com/codex/settings/usage"])}
            }
            Column {width:parent.width;spacing:14;visible:CodeDesk.provider===1
                NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"OpenCode / "+(CodeDesk.openCodeUsage.state||"Loading local statistics…");pixelSize:16}
                NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:CodeDesk.openCodeUsage.go?.label||"Checking Go subscription…";wrapMode:Text.WordWrap;pixelSize:12;color:Theme.signalRed}
                Row {width:parent.width;spacing:16
                    Repeater {model:Object.keys(CodeDesk.openCodeUsage.go?.windows??{})
                        Column {required property string modelData;width:(parent.width-32)/3;spacing:7
                            readonly property var window: CodeDesk.openCodeUsage.go.windows[modelData]
                            NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:({rolling:"5-hour window",weekly:"Weekly window",monthly:"Monthly window"})[modelData];pixelSize:11;color:Theme.paperMuted}
                            NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:Math.max(0,100-window.percent).toFixed(0)+"% remaining";pixelSize:13;color:Theme.signalRed}
                            Rectangle {width:parent.width;height:3;color:Theme.surfaceTwo;Rectangle {width:parent.width*Math.max(0,1-parent.parent.window.percent/100);height:3;color:Theme.signalRed}}
                            NrLabel {tracked:false;font.capitalization:Font.MixedCase;pixelSize:10;color:Theme.paperMuted;text:"Resets "+new Date(window.resetsAt).toLocaleString(Qt.locale(),"d MMM · hh:mm AP")}
                        }
                    }
                }
                Row {spacing:10
                    ControlTile {label:CodeDesk.connectingOpenCode?"Awaiting browser":"Connect account";glyph:"\uf084";enabled:!CodeDesk.connectingOpenCode;onActivated:CodeDesk.connectOpenCode()}
                    ControlTile {visible:CodeDesk.openCodeConnection.state==="connected";label:"Disconnect";glyph:"\uf127";onActivated:CodeDesk.disconnectOpenCode()}
                    ControlTile {label:"Refresh usage";glyph:"\uf021";onActivated:CodeDesk.refresh(true)}
                    ControlTile {label:"Billing / renewal";glyph:"\uf013";onActivated:Quickshell.execDetached(["xdg-open","https://opencode.ai/console/"])}
                }
                NrLabel {visible:!!CodeDesk.openCodeConnection.message;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:(CodeDesk.openCodeConnection.code?"Code "+CodeDesk.openCodeConnection.code+" · ":"")+(CodeDesk.openCodeConnection.message||"");wrapMode:Text.WordWrap;pixelSize:11;color:Theme.paperMuted}
                Row {spacing:8
                    Repeater {model:[7,30,0]
                        ControlTile {required property int modelData;label:modelData===0?"All time":modelData+" days";selected:CodeDesk.openCodeDays===modelData;onActivated:{CodeDesk.openCodeDays=modelData;CodeDesk.refresh(false);}}
                    }
                }
                Row {visible:!!CodeDesk.openCodeUsage.local;width:parent.width;spacing:32
                    Column {spacing:4;NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"Free-model responses";pixelSize:11;color:Theme.paperMuted} NrLabel {tracked:false;text:root.metric(CodeDesk.openCodeUsage.local?.freeResponses??0);pixelSize:16;color:Theme.signalRed}}
                    Column {spacing:4;NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"Free-model tokens";pixelSize:11;color:Theme.paperMuted} NrLabel {tracked:false;text:root.metric(CodeDesk.openCodeUsage.local?.freeTokens??0);pixelSize:16;color:Theme.signalRed}}
                    Column {spacing:4;NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"Go responses";pixelSize:11;color:Theme.paperMuted} NrLabel {tracked:false;text:root.metric(CodeDesk.openCodeUsage.local?.goResponses??0);pixelSize:16;color:Theme.signalRed}}
                }
                NrLabel {visible:!!CodeDesk.openCodeUsage.local;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:CodeDesk.openCodeUsage.local?.freeQuotaNote||"";wrapMode:Text.WordWrap;pixelSize:10;color:Theme.paperMuted}
                Column {width:parent.width;spacing:6;visible:!!CodeDesk.openCodeUsage.local
                    Repeater {model:(CodeDesk.openCodeUsage.local?.models??[]).slice(0,10)
                        Row {required property var modelData;spacing:14;width:parent.width
                            NrLabel {width:340;tracked:false;font.capitalization:Font.MixedCase;text:modelData.model+(modelData.free?" · Free":modelData.provider==="opencode-go"?" · Go":" · OpenCode");pixelSize:11;color:Theme.paper;elide:Text.ElideRight}
                            NrLabel {width:160;tracked:false;font.capitalization:Font.MixedCase;text:root.metric(modelData.responses)+" responses";pixelSize:11;color:Theme.signalRed}
                            NrLabel {tracked:false;text:root.metric(modelData.input+modelData.output)+" tokens";pixelSize:11;color:Theme.paperMuted}
                        }
                    }
                }
                Flow {width:parent.width;spacing:18
                    Repeater {model:Object.keys(CodeDesk.openCodeUsage.stats??{})
                        Column {required property string modelData;width:180;spacing:4
                            NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:modelData;pixelSize:11;color:Theme.paperMuted}
                            NrLabel {tracked:false;text:root.metric(CodeDesk.openCodeUsage.stats[modelData]);pixelSize:14;color:Theme.signalRed}
                        }
                    }
                }
                NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:CodeDesk.openCodeUsage.quotaNote||"Provider balance unavailable; no subscription status is inferred.";wrapMode:Text.WordWrap;pixelSize:11;color:Theme.paperMuted}
            }
            Column {
                width:parent.width;spacing:16;visible:CodeDesk.provider===2
                // One card per config dir. Click a card to make that account the one below.
                Flow {
                    width:parent.width;spacing:10
                    Repeater {
                        model:CodeDesk.claudeAccounts.accounts??[]
                        Rectangle {
                            required property var modelData
                            readonly property bool active:CodeDesk.claudeAccount===modelData.id
                            width:252;height:118;color:active?Theme.surfaceTwo:"transparent";border.width:Appearance.metrics.hairline;border.color:active?Theme.signalRed:Theme.rule
                            MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:CodeDesk.selectClaudeAccount(modelData.id)}
                            Column {
                                x:12;y:10;width:parent.width-24;spacing:6
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;elide:Text.ElideRight;text:modelData.name+(modelData.identity?.plan?" · "+modelData.identity.plan:"");pixelSize:13;color:Theme.paper}
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;elide:Text.ElideRight;text:modelData.identity?.signedIn?modelData.identity.email:"Not signed in";pixelSize:10;color:Theme.paperMuted}
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:"5-hour "+root.windowLeft(modelData.limits?.fiveHour);pixelSize:11;color:Theme.signalRed}
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:"7 days · "+root.metric(modelData.totals?.responses??0)+" responses · "+root.metric(modelData.totals?.output??0)+" out";pixelSize:10;color:Theme.paperMuted}
                            }
                        }
                    }
                }
                NrLabel {visible:(CodeDesk.claudeAccounts.accounts??[]).length===0;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:"No Claude Code config found. Sign in once with claude, or list config dirs in ~/.config/sensei/claude-accounts.json.";wrapMode:Text.WordWrap;pixelSize:11;color:Theme.paperMuted}
                NrLabel {visible:!!CodeDesk.claudeUsage.error;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;wrapMode:Text.WordWrap;text:CodeDesk.claudeUsage.error||"";pixelSize:11;color:Theme.signalRed}
                Column {
                    width:parent.width;spacing:14;visible:!!CodeDesk.claudeUsage.totals
                    NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;elide:Text.ElideRight;text:"Claude Code / "+(CodeDesk.claudeUsage.accountName||"")+" · "+(CodeDesk.claudeUsage.identity?.plan||"Plan unknown");pixelSize:16;color:Theme.paper}
                    NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:(CodeDesk.claudeUsage.identity?.email||"Not signed in")+(CodeDesk.claudeUsage.identity?.organization?" · "+CodeDesk.claudeUsage.identity.organization:"")+"   ·   "+(CodeDesk.claudeUsage.state||"");wrapMode:Text.WordWrap;pixelSize:11;color:Theme.paperMuted}
                    Row {
                        width:parent.width;spacing:28
                        Repeater {
                            model:[{name:"5-hour window",value:CodeDesk.claudeUsage.limits?.fiveHour},{name:"7-day window",value:CodeDesk.claudeUsage.limits?.sevenDay}]
                            Column {
                                required property var modelData
                                width:(parent.width-28)/2;spacing:8
                                Item {width:parent.width;height:20
                                    NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:modelData.name;pixelSize:11;color:Theme.paperMuted}
                                    NrLabel {tracked:false;font.capitalization:Font.MixedCase;anchors.right:parent.right;text:root.windowLeft(modelData.value);pixelSize:13;color:Theme.signalRed}
                                }
                                Rectangle {width:parent.width;height:3;radius:1;color:Theme.surfaceTwo
                                    Rectangle {width:parent.width*root.fillOf(modelData.value);height:3;radius:1;color:Theme.signalRed}
                                }
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:root.resetText(modelData.value?.resets_at);pixelSize:11;color:Theme.paperMuted}
                            }
                        }
                    }
                    Flow {
                        width:parent.width;spacing:18
                        Repeater {
                            model:[{label:"Sessions",value:CodeDesk.claudeUsage.totals?.sessions},{label:"Responses",value:CodeDesk.claudeUsage.totals?.responses},{label:"Input",value:CodeDesk.claudeUsage.totals?.input},{label:"Output",value:CodeDesk.claudeUsage.totals?.output},{label:"Cache read",value:CodeDesk.claudeUsage.totals?.cacheRead},{label:"Cache hit",value:CodeDesk.claudeUsage.totals?.cacheHitPercent==null?"—":CodeDesk.claudeUsage.totals.cacheHitPercent+"%"}]
                            Column {
                                required property var modelData
                                width:150;spacing:4
                                NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:modelData.label;pixelSize:11;color:Theme.paperMuted}
                                NrLabel {tracked:false;text:typeof modelData.value==="string"?modelData.value:root.metric(modelData.value??0);pixelSize:14;color:Theme.signalRed}
                            }
                        }
                    }
                    Column {
                        width:parent.width;spacing:6
                        NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"Output and input tokens per day · last 14 days";pixelSize:11;color:Theme.paperMuted}
                        Row {
                            width:parent.width;spacing:4;height:44
                            Repeater {
                                model:CodeDesk.claudeUsage.daily??[]
                                Item {
                                    required property var modelData
                                    width:(parent.width-4*13)/14;height:parent.height
                                    Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:Math.max(2,parent.height*modelData.tokens/root.peakDaily(CodeDesk.claudeUsage.daily));color:modelData.tokens>0?Theme.signalRed:Theme.surfaceTwo}
                                }
                            }
                        }
                        NrLabel {tracked:false;font.capitalization:Font.MixedCase;text:"Peak "+root.metric(root.peakDaily(CodeDesk.claudeUsage.daily))+" tokens in a day";pixelSize:10;color:Theme.paperMuted}
                    }
                    Column {
                        width:parent.width;spacing:6;visible:(CodeDesk.claudeUsage.models??[]).length>0
                        Repeater {
                            model:(CodeDesk.claudeUsage.models??[]).slice(0,6)
                            Row {
                                required property var modelData
                                spacing:14;width:parent.width
                                NrLabel {width:300;tracked:false;font.capitalization:Font.MixedCase;text:modelData.model;pixelSize:11;color:Theme.paper;elide:Text.ElideRight}
                                NrLabel {width:140;tracked:false;text:root.metric(modelData.responses)+" responses";pixelSize:11;color:Theme.signalRed}
                                NrLabel {tracked:false;text:root.metric(modelData.input+modelData.output)+" tokens";pixelSize:11;color:Theme.paperMuted}
                            }
                        }
                    }
                    NrLabel {visible:(CodeDesk.claudeUsage.projects??[]).length>0;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;wrapMode:Text.WordWrap;pixelSize:11;color:Theme.paperMuted;text:"Projects · "+(CodeDesk.claudeUsage.projects??[]).map(p=>p.name+" "+p.responses).join("   ·   ")}
                    Row {
                        spacing:8
                        Repeater {
                            model:[7,30,0]
                            ControlTile {required property int modelData;label:modelData===0?"All time":modelData+" days";selected:CodeDesk.claudeDays===modelData;onActivated:CodeDesk.setClaudeDays(modelData)}
                        }
                        ControlTile {visible:CodeDesk.tab!==4;label:"Refresh";glyph:"";onActivated:CodeDesk.refreshClaude(true)}
                        // The default account keeps its login in ~/.claude.json, so it runs without CLAUDE_CONFIG_DIR.
                        ControlTile {label:"Open Claude here";glyph:"";onActivated:Quickshell.execDetached(["alacritty","-e","bash","-c","if [ \"$1\" = \"$HOME/.claude\" ]; then exec claude; else CLAUDE_CONFIG_DIR=\"$1\" exec claude; fi","claude",CodeDesk.claudeUsage.directory||""])}
                    }
                    NrLabel {tracked:false;font.capitalization:Font.MixedCase;width:parent.width;wrapMode:Text.WordWrap;pixelSize:10;color:Theme.paperMuted;text:CodeDesk.claudeUsage.quotaNote||""}
                }
            }
        }
    }

    Keys.onPressed:event=>{if(event.modifiers&Qt.ControlModifier){if(event.key===Qt.Key_K){CodeDesk.tab=0;Qt.callLater(()=>root.searchInput?.forceActiveFocus());event.accepted=true;}else if(event.key===Qt.Key_R){CodeDesk.refresh(true);event.accepted=true;}else if(event.key===Qt.Key_1){CodeDesk.tab=0;event.accepted=true;}else if(event.key===Qt.Key_2){CodeDesk.tab=1;event.accepted=true;}}}
}
