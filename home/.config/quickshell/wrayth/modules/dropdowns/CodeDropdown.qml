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
    title: "fh1m / Code"
    katakana: CodeDesk.tab === 0 ? "GITHUB" : "AGENTS"
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
    function pushDate(value) {return value?new Date(value).toLocaleDateString(Qt.locale(),"d MMM yyyy"):"Unknown";}
    Column {
        width: parent.width
        spacing: 10
        Row {
            spacing: 8
            ControlTile {label:"Code";glyph:"\uf121";selected:CodeDesk.tab===0;implicitWidth:140;onActivated:CodeDesk.tab=0}
            ControlTile {label:"Agents";glyph:"\uf0e4";selected:CodeDesk.tab===1;implicitWidth:140;onActivated:CodeDesk.tab=1}
            ControlTile {label:"Refresh";glyph:"\uf021";implicitWidth:120;enabled:!CodeDesk.loading;onActivated:CodeDesk.refresh(true)}
            ControlTile {label:"Operator tools";glyph:"\uf085";implicitWidth:160;onActivated:ShellState.dropdown="ident"}
        }
        NrLabel {textFormat:Text.PlainText;tracked:false;font.capitalization:Font.MixedCase;width:parent.width;text:CodeDesk.tab===0?(CodeDesk.error || (CodeDesk.loading?"Refreshing GitHub…":root.ago(CodeDesk.data.fetchedAt)+(CodeDesk.data.stale?" · Cached":""))):(CodeDesk.provider===1?root.ago(CodeDesk.openCodeUsage.fetchedAt):(CodeDesk.usage.error||root.ago(CodeDesk.usage.fetchedAt)));color:CodeDesk.error?Theme.semanticAmber:Theme.paperMuted;pixelSize:12}
        Loader {
            width:parent.width
            sourceComponent:CodeDesk.tab===0?codePage:subscriptionPage
        }
    }
    Component {
        id:codePage
        Column {
            width:parent.width;spacing:12
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
                                MouseArea {id:dayHover;anchors.fill:parent;hoverEnabled:true}
                                ToolTip.visible:dayHover.containsMouse
                                ToolTip.text:modelData.date+" · "+modelData.contributionCount+" contributions"
                            }
                        }
                    }
                }
            }
            TextField {id:search;Component.onCompleted:root.searchInput=search;Component.onDestruction:root.searchInput=null;width:parent.width;placeholderText:"Find a project…";placeholderTextColor:Theme.paperMuted;text:CodeDesk.query;onTextEdited:CodeDesk.query=text;color:Theme.paper;font.family:Appearance.font.ui;font.pixelSize:12;background:Rectangle{color:Theme.surfaceOne;border.color:search.activeFocus?Theme.signalRed:Theme.rule;radius:3} Keys.onEscapePressed:{CodeDesk.query="";event.accepted=true;}}
            Row {
                width:parent.width;spacing:18
                Column {width:(parent.width-18)*.53;spacing:8
                    Row {spacing:6
                        ControlTile {implicitWidth:130;label:"Recent";glyph:"\uf017";selected:!CodeDesk.pinnedOnly;onActivated:CodeDesk.pinnedOnly=false}
                        ControlTile {implicitWidth:130;label:"Pinned";glyph:"\uf08d";selected:CodeDesk.pinnedOnly;onActivated:CodeDesk.pinnedOnly=true}
                    }
                    ScrollView {width:parent.width;height:365;clip:true;contentWidth:availableWidth
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
                    ScrollView {width:parent.width;height:365;clip:true;contentWidth:availableWidth
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
        }
    }

    Keys.onPressed:event=>{if(event.modifiers&Qt.ControlModifier){if(event.key===Qt.Key_K){CodeDesk.tab=0;Qt.callLater(()=>root.searchInput?.forceActiveFocus());event.accepted=true;}else if(event.key===Qt.Key_R){CodeDesk.refresh(true);event.accepted=true;}else if(event.key===Qt.Key_1){CodeDesk.tab=0;event.accepted=true;}else if(event.key===Qt.Key_2){CodeDesk.tab=1;event.accepted=true;}}}
}
