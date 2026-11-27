pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
    id: root
    property var nerd:({})
    property var curiosity:({})
    property int curiosityFeed:0
    property int nerdFeed:0
    property int quoteIndex:Math.floor(Date.now()/86400000)%3
    readonly property bool nerdLoading:tab===3?curiosityFetch.running:nerdFetch.running
    property int tab: 0
    property int provider: 0
    property int openCodeDays:30
    property var openCodeUsage: ({})
    property var openCodeConnection: ({})
    readonly property bool connectingOpenCode: consoleLogin.running
    function disconnectOpenCode():void {consoleLogin.running=false;consoleLogout.running=true;}
    function connectOpenCode():void {if(!consoleLogin.running){openCodeConnection={state:"starting",message:"Starting browser authorization…"};consoleLogin.running=true;}}
    property var claudeAccounts: ({})
    property string claudeAccount: ""
    property int claudeDays: 30
    property var claudeUsage: ({})
    property int claudeGeneration: 0
    property var claudeRequests: []
    function selectClaudeAccount(id: string): void {
        claudeAccount = id;
        refreshClaude(false);
    }
    function setClaudeDays(days: int): void {
        claudeDays = days;
        refreshClaude(false);
    }
    function cancelClaudeRequests(): void {
        claudeGeneration++;
        const requests = claudeRequests;
        claudeRequests = [];
        for (const request of requests) request.running = false;
    }
    function currentClaudeRequest(request): bool {
        return opened && tab === 1 && provider === 2
            && request.generation === claudeGeneration;
    }
    function startClaudeRequest(action, account, days, force): void {
        const command = [Quickshell.env("HOME") + "/.local/bin/sensei-code", action,
                         "--days", String(days)].concat(action === "claude" ? ["--account", account] : [])
                         .concat(force ? ["--refresh"] : []);
        const request = claudeRequestComponent.createObject(root, {
            generation: claudeGeneration, action: action, account: account,
            days: days, forceRefresh: force, command: command
        });
        if (!request) {
            claudeUsage = {error: "Unable to start Claude account request"};
            return;
        }
        claudeRequests = claudeRequests.concat([request]);
        request.running = true;
    }
    function acceptClaudeResponse(request, line): void {
        if (request.answered) return;
        request.answered = true;
        if (!currentClaudeRequest(request)) return;
        try {
            const data = JSON.parse(line);
            if (data.error) {
                claudeUsage = {error: data.error};
                return;
            }
            if (request.action === "claude-accounts") {
                if (!Array.isArray(data.accounts)) throw new Error("Missing account list");
                claudeAccounts = data;
                if (!data.accounts.some(account => account.id === claudeAccount))
                    claudeAccount = data.accounts[0]?.id ?? "";
                if (claudeAccount)
                    startClaudeRequest("claude", claudeAccount, claudeDays, request.forceRefresh);
                else
                    claudeUsage = {error: "No configured Claude account"};
            } else if (request.account === claudeAccount && request.days === claudeDays) {
                claudeUsage = data.account === request.account
                    ? data : {error: "Claude returned data for a different account"};
            }
        } catch (error) {
            claudeUsage = {error: "Invalid Claude account response"};
        }
    }
    function finishClaudeRequest(request): void {
        claudeRequests = claudeRequests.filter(item => item !== request);
        if (!request.answered && currentClaudeRequest(request))
            claudeUsage = {error: "Claude account request ended without a response"};
        request.destroy();
    }
    function refreshClaude(force: bool): void {
        cancelClaudeRequests();
        claudeUsage = {};
        if (opened && tab === 1 && provider === 2)
            startClaudeRequest("claude-accounts", "", 7, force);
    }
    property int feed: 0
    property bool pinnedOnly: false
    property int activityPage: 1
    property var data: ({})
    property var usage: ({})
    property var detail: ({})
    property string query: ""
    property string selectedRepo: ""
    property string error: ""
    property bool loading: overview.running
    readonly property bool opened: ShellState.dropdown === "code"
    readonly property var repositories: (pinnedOnly ? (data.pinnedItems?.nodes ?? []) : (data.repositories?.nodes ?? [])).filter(r => !query || score(r.nameWithOwner + " " + (r.description ?? ""), query))
    function score(text, needle) {
        const value = text.toLowerCase(), search = needle.toLowerCase().trim();
        let at = 0;
        for (let c of search) { at = value.indexOf(c, at); if (at < 0) return false; at++; }
        return true;
    }
    function refresh(force) {
        if(tab===4)return;
        if(tab===2 || tab===3){
            const process=tab===3?curiosityFetch:nerdFetch;
            if(!process.running){error="";process.command=[Quickshell.env("HOME")+"/.local/bin/sensei-nerd"].concat(tab===3?["--curiosity"]:[]).concat(force?["--refresh"]:[]);process.running=true;}
            return;
        }
        if (tab === 1 && provider === 1) { if(!openCode.running){openCode.command=[Quickshell.env("HOME")+"/.local/bin/sensei-code","opencode","--days",String(openCodeDays)].concat(force?["--refresh"]:[]);openCode.running=true;} return; }
        if (tab === 1 && provider === 2) { refreshClaude(force); return; }
        if (tab === 1) { if (quota.running) quota.running = false; Qt.callLater(() => {if(root.opened && root.tab===1 && root.provider===0) quota.running=true;}); return; }
        if (overview.running) return;
        error = "";
        overview.command = [Quickshell.env("HOME") + "/.local/bin/sensei-code", "overview"].concat(force ? ["--refresh"] : []);
        overview.running = true;
    }
    function moreActivity() {
        if(activity.running)return;
        activity.command=[Quickshell.env("HOME")+"/.local/bin/sensei-code","activity",String(activityPage+1)];activity.running=true;
    }
    function loadMore() {
        if(more.running||!data.repositories?.pageInfo?.hasNextPage)return;
        more.command=[Quickshell.env("HOME")+"/.local/bin/sensei-code","repositories",data.repositories.pageInfo.endCursor];more.running=true;
    }
    function select(repo) {
        feed=0;
        selectedRepo = repo;
        detail = {};
        if (details.running) details.running = false;
        Qt.callLater(() => {details.command=[Quickshell.env("HOME")+"/.local/bin/sensei-code","details",root.selectedRepo]; details.running=true;});
    }
    function browse(url) { if (/^https:\/\/(github\.com|github\.blog|karpathy\.github\.io|news\.ycombinator\.com)\//.test(url)) Quickshell.execDetached(["xdg-open", url]); }
    function project(repo) {
        const local = (data.localProjects ?? []).find(p => p.repo.toLowerCase() === repo.nameWithOwner.toLowerCase());
        if (local) Quickshell.execDetached([Quickshell.env("HOME")+"/.local/bin/sensei-dev", "open", local.path]);
        else browse(repo.url);
    }
    onOpenedChanged: { if (opened) {quoteIndex=(quoteIndex+1)%Math.max(1,nerd.quotes?.length||3);refresh(false);} else {quota.running=false; openCode.running=false; cancelClaudeRequests(); consoleLogin.running=false; overview.running=false; nerdFetch.running=false; curiosityFetch.running=false; details.running=false; more.running=false; activity.running=false;} }
    onProviderChanged: {quota.running=false;openCode.running=false;cancelClaudeRequests();if(opened && tab===1)refresh(false);}
    onTabChanged: {error="";quota.running=false;openCode.running=false;cancelClaudeRequests();if(opened) Qt.callLater(() => {if(root.opened)root.refresh(false);});}
    // Separate collectors keep late responses attached to their own feed.
    // SplitParser ignores an empty stream when a closed window cancels a request.
    Process {id:nerdFetch;stdout:SplitParser {onRead:line=>{try{root.nerd=JSON.parse(line);}catch(e){if(root.tab===2)root.error="GitHub discovery response unavailable";}}}}
    Process {id:curiosityFetch;stdout:SplitParser {onRead:line=>{try{root.curiosity=JSON.parse(line);}catch(e){if(root.tab===3)root.error="Hacker News response unavailable";}}}}
    Process {
        id: overview
        stdout: SplitParser {onRead: line => {try {const d=JSON.parse(line); if(d.error) root.error=d.error; else {root.data=d;root.activityPage=1;}} catch(e){root.error="Invalid GitHub response";}}}
    }
    Process {
        id: details
        stdout: SplitParser {onRead: line => {try {const d=JSON.parse(line); if(d.error) root.error=d.error; else if(d.repo===root.selectedRepo)root.detail=d;}catch(e){}}}
    }
    Process {
        id: more
        stdout: SplitParser {onRead: line => {try {const d=JSON.parse(line);if(d.error){root.error=d.error;return;}let v=Object.assign({},root.data);v.repositories={nodes:(v.repositories?.nodes??[]).concat(d.nodes??[]),pageInfo:d.pageInfo};root.data=v;}catch(e){root.error="Invalid repository page";}}}
    }
    Process {
        id: activity
        stdout: SplitParser {onRead: line => {try {const d=JSON.parse(line);if(d.error){root.error=d.error;return;}let v=Object.assign({},root.data);for(let key of ['prs','reviews','issues'])v[key]={total_count:d[key]?.total_count??0,items:(v[key]?.items??[]).concat(d[key]?.items??[])};root.activityPage=d.page;root.data=v;}catch(e){root.error="Invalid activity page";}}}
    }
    Process {
        id: quota
        command: [Quickshell.env("HOME") + "/.local/bin/sensei-code", "codex-watch"]
        stdout: SplitParser {onRead: line => {try {root.usage=JSON.parse(line);}catch(e){root.usage={error:"Invalid usage response"};}}}
    }
    Process {
        id: openCode
        command: [Quickshell.env("HOME")+"/.local/bin/sensei-code", "opencode"]
        stdout: SplitParser {onRead: line => {try {const d=JSON.parse(line);if(!d.go && root.openCodeUsage.go)d.go=root.openCodeUsage.go;root.openCodeUsage=d;}catch(e){root.openCodeUsage={state:"Local statistics unavailable"};}}}
    }
    Component {
        id: claudeRequestComponent
        Process {
            id: request
            property int generation
            property string action
            property string account
            property int days
            property bool forceRefresh
            property bool answered: false
            stdout: SplitParser {onRead: line => root.acceptClaudeResponse(request, line)}
            onExited: root.finishClaudeRequest(request)
        }
    }
    Process {id:consoleLogout;command:[Quickshell.env("HOME")+"/.local/bin/sensei-opencode-connect","disconnect"]
        stdout:SplitParser {onRead:line=>{try{root.openCodeConnection=JSON.parse(line);}catch(e){}}}
        onExited:root.refresh(true)
    }
    Process {id:consoleLogin;command:[Quickshell.env("HOME")+"/.local/bin/sensei-opencode-connect"]
        stdout:SplitParser {onRead:line=>{try{root.openCodeConnection=JSON.parse(line);}catch(e){root.openCodeConnection={state:"error",message:"Invalid authorization response"};}}}
        onExited:if(root.openCodeConnection.state==="connected")root.refresh(true)
    }
    Timer {interval:60000;repeat:true;running:root.opened && root.tab===1 && root.provider>0;onTriggered:root.refresh(false)}
    IpcHandler { target: "code"; function page(index:int):void {if(index<0||index>4)return;root.tab=index;ShellState.publishAnchor("code",12);ShellState.openDropdown("code");} function toggle():void {ShellState.publishAnchor("code",12);ShellState.toggleDropdown("code");} function state():string {return JSON.stringify({open:root.opened,tab:root.tab,loading:root.loading,repositories:root.repositories.length,quotaRunning:quota.running,error:root.error,curiosityLoading:curiosityFetch.running,showStories:root.curiosity.show?.length||0,askStories:root.curiosity.ask?.length||0,quote:root.quoteIndex});} function subscriptions():void {root.tab=1;} function agent(name:string):void {if(name!=="codex" && name!=="opencode" && name!=="claude")return;root.provider=name==="opencode"?1:name==="claude"?2:0;root.tab=1;} function account(id:string):void {root.selectClaudeAccount(id);} }
}
