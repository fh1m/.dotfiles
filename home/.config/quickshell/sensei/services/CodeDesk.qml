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
    property bool claudeActivity: false
    function toggleClaudeActivity(): void {
        claudeActivity = !claudeActivity;
        refreshClaude(false);
    }
    function openClaudeProfile(): void {
        const directory = claudeUsage.directory;
        if (!directory) return;
        const profile = directory === Quickshell.env("HOME")+"/.claude"
            ? ["-u","CLAUDE_CONFIG_DIR"] : ["CLAUDE_CONFIG_DIR="+directory];
        AppLaunch.run(["alacritty","-e","env"].concat(profile).concat(["claude"]));
    }
    property var claudeUsage: ({})
    property string claudeDisplayContext: ""
    function claudeContext(account): string {
        return JSON.stringify([account, claudeDays, claudeActivity]);
    }
    function claudeFailure(message): void {
        claudeUsage = Object.assign({}, claudeUsage, {
            error: message,
            limits: Object.assign({}, claudeUsage.limits || {}, {stale: true})
        });
    }
    property int claudeGeneration: 0
    property var claudeRequests: []
    property bool claudeRefreshPending: false
    function selectClaudeAccount(id: string): void {
        if (claudeAccount === id) return;
        claudeAccount = id;
        refreshClaude(false);
    }
    function setClaudeDays(days: int): void {
        claudeDays = days;
        refreshClaude(false);
    }
    function cancelClaudeRequests(): void {
        claudeGeneration++;
        claudeRefreshPending = false;
        const requests = claudeRequests;
        claudeRequests = [];
        for (const request of requests) request.running = false;
    }
    function currentClaudeRequest(request): bool {
        return opened && tab === 1 && provider === 2
            && request.generation === claudeGeneration;
    }
    function startClaudeRequest(action, account, days, force): void {
        if (action === "claude" && claudeDisplayContext !== claudeContext(account)) {
            claudeUsage = {};
            claudeDisplayContext = claudeContext(account);
        }
        const command = [Quickshell.env("HOME") + "/.local/bin/sensei-code", action,
                         "--days", String(days)].concat(action === "claude" ? ["--account", account] : [])
                         .concat(force ? ["--refresh"] : [])
                         .concat(action === "claude" && claudeActivity ? ["--activity"] : []);
        const request = claudeRequestComponent.createObject(root, {
            generation: claudeGeneration, action: action, account: account,
            days: days, forceRefresh: force, command: command
        });
        if (!request) {
            claudeFailure("Unable to start Claude account request");
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
                claudeFailure(data.error);
                return;
            }
            if (request.action === "claude-accounts") {
                if (!Array.isArray(data.accounts)) throw new Error("Missing account list");
                // Keep the account delegates (and their keyboard focus) when
                // only the discovery timestamp changed.
                if (JSON.stringify(claudeAccounts.accounts) !== JSON.stringify(data.accounts))
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
            claudeFailure("Invalid Claude account response");
        }
    }
    function finishClaudeRequest(request): void {
        claudeRequests = claudeRequests.filter(item => item !== request);
        if (!request.answered && currentClaudeRequest(request))
            claudeFailure("Claude account request ended without a response");
        request.destroy();
        if (!claudeRequests.length && claudeRefreshPending) {
            claudeRefreshPending = false;
            const generation = claudeGeneration;
            Qt.callLater(() => {
                if (generation === root.claudeGeneration && root.opened
                        && root.tab === 1 && root.provider === 2)
                    root.refreshClaude(false);
            });
        }
    }
    function refreshClaude(force: bool): void {
        const context = claudeContext(claudeAccount);
        if (!force && claudeRequests.length && claudeDisplayContext === context) {
            claudeRefreshPending = true;
            return;
        }
        cancelClaudeRequests();
        if (claudeDisplayContext !== context) claudeUsage = {};
        claudeDisplayContext = context;
        if (opened && tab === 1 && provider === 2)
            startClaudeRequest("claude-accounts", "", 7, force);
    }
    property int feed: 0
    property bool pinnedOnly: false
    property int activityPage: 1
    property var data: ({})
    property var detail: ({})
    property string query: ""
    property string selectedRepo: ""
    property string error: ""
    readonly property bool loading: tab === 1
        ? provider === 2 ? claudeRequests.length > 0 : provider === 0 ? CodexAccounts.busy : openCode.running
        : tab === 2 || tab === 3 ? nerdLoading : overview.running
    Binding {target: CodexAccounts; property: "active"; value: root.opened && root.tab === 1 && root.provider === 0}
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
        if (tab === 1) { CodexAccounts.refresh(force); return; }
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
    function browse(url) {
        // User-activated source links may be on any public web host, never file/script schemes.
        if (typeof url === "string" && /^https?:\/\/[^\/\s?#]+(?:[\/?#]|$)/i.test(url))
            AppLaunch.run(["xdg-open",url]);
    }
    function project(repo) {
        const local = (data.localProjects ?? []).find(p => p.repo.toLowerCase() === repo.nameWithOwner.toLowerCase());
        if (local) AppLaunch.run([Quickshell.env("HOME")+"/.local/bin/sensei-dev","open",local.path]);
        else browse(repo.url);
    }
    onOpenedChanged: { if (opened) {quoteIndex=(quoteIndex+1)%Math.max(1,nerd.quotes?.length||3);refresh(false);} else {openCode.running=false; cancelClaudeRequests(); consoleLogin.running=false; overview.running=false; nerdFetch.running=false; curiosityFetch.running=false; details.running=false; more.running=false; activity.running=false;} }
    onProviderChanged: {openCode.running=false;cancelClaudeRequests();if(opened && tab===1)refresh(false);}
    onTabChanged: {error="";openCode.running=false;cancelClaudeRequests();if(opened) Qt.callLater(() => {if(root.opened)root.refresh(false);});}
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
    IpcHandler { target: "code"; function page(index:int):void {if(index<0||index>4)return;root.tab=index;ShellState.publishAnchor("code",12);ShellState.openDropdown("code");} function toggle():void {ShellState.publishAnchor("code",12);ShellState.toggleDropdown("code");} function state():string {return JSON.stringify({open:root.opened,tab:root.tab,loading:root.loading,repositories:root.repositories.length,codexBusy:CodexAccounts.busy,codexAccounts:CodexAccounts.accounts.length,error:root.error,curiosityLoading:curiosityFetch.running,showStories:root.curiosity.show?.length||0,askStories:root.curiosity.ask?.length||0,quote:root.quoteIndex});} function subscriptions():void {root.tab=1;} function agent(name:string):void {if(name!=="codex" && name!=="opencode" && name!=="claude")return;root.provider=name==="opencode"?1:name==="claude"?2:0;root.tab=1;} function account(id:string):void {root.selectClaudeAccount(id);} }
}
