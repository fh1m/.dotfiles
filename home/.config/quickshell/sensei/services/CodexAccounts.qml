pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool active: false
    property var accounts: []
    property string selected: ""
    property var usage: ({})
    property string error: ""
    property string discoveryWarning: ""
    property var requests: []
    property int generation: 0
    property bool refreshPending: false
    property var usageQueue: []
    readonly property bool busy: requests.length > 0
    property double observedAt: Date.now()

    function resetEpoch(window): double {
        const value = window?.resetsAt;
        if (typeof value === "number") return value * (value > 1e12 ? 1 : 1000);
        return Date.parse(value || "");
    }
    function measurementState(snapshot, now): string {
        const captured = snapshot?.measurementAt;
        if (!Number.isFinite(captured) || captured <= 0 || captured * 1000 > now + 30000)
            return "unknown";
        // A reset affects its own window, not another meter on the same account.
        if (snapshot.error || snapshot.state === "unknown" || now - captured * 1000 > 90000
            || (snapshot.stale && snapshot.state !== "expired"))
            return "historical";
        return "current";
    }
    function quotaWindow(snapshot, key, now): var {
        const window = snapshot?.rateLimits?.[key];
        const reset = resetEpoch(window);
        const ageState = measurementState(snapshot, now);
        if (!window || ageState === "unknown") return {state: "unknown"};
        if (Number.isFinite(reset) && reset <= now) return {state: "expired"};
        const left = Number.isFinite(window.remainingPercent) ? window.remainingPercent
            : Number.isFinite(window.usedPercent) ? 100 - window.usedPercent : NaN;
        if (!Number.isFinite(left) || left < 0 || left > 100) return {state: "unknown"};
        return {state: ageState, left: left};
    }

    function cancel(): void {
        generation++;
        const pending = requests;
        requests = [];
        refreshPending = false;
        usageQueue = [];
        for (const request of pending) request.running = false;
    }
    function start(action, account, force, extra): void {
        if (!active) return;
        const command = [Quickshell.env("HOME") + "/.local/bin/sensei-codex-accounts", action]
            .concat(account ? ["--account", account] : [])
            .concat(force ? ["--refresh"] : []).concat(extra || []);
        const request = requestComponent.createObject(root, {
            generation: generation, action: action, account: account,
            forceRefresh: force, command: command
        });
        if (!request) { error = "Unable to start account request"; return; }
        requests = requests.concat([request]);
        request.running = true;
    }
    function refresh(force: bool): void {
        if (!active) return;
        if (busy) { refreshPending = refreshPending || force; return; }
        error = "";
        start("list", "", force, []);
    }
    function queueUsage(force: bool): void {
        const ids = accounts.filter(account => account.monitored).map(account => account.id);
        const ordered = selected ? [selected].concat(ids.filter(id => id !== selected)) : ids;
        usageQueue = ordered.map(id => ({account: id, force: force}));
        nextQueued();
    }
    function nextQueued(): void {
        if (!active || busy || !usageQueue.length) return;
        const next = usageQueue[0];
        usageQueue = usageQueue.slice(1);
        start("usage", next.account, next.force, []);
    }
    function selectAccount(id: string): void {
        if (!accounts.some(account => account.id === id && account.monitored)) return;
        if (selected === id && (busy || usage.accountId === id)) return;
        cancel();
        selected = id;
        usage = accounts.find(account => account.id === id)?.snapshot || {};
        error = "";
        queueUsage(false);
    }
    function monitor(id: string, enabled: bool): void {
        if (!accounts.some(account => account.id === id)) return;
        cancel();
        error = "";
        if (!enabled && selected === id) { selected = ""; usage = {}; }
        if (enabled) { selected = id; usage = {}; }
        start(enabled ? "add" : "remove", id, false, []);
    }
    function addProfile(directory: string, name: string): void {
        if (!directory.trim()) return;
        cancel();
        error = "";
        start("add", "", false, ["--profile", directory.trim(), "--name", name.trim() || "Codex profile"]);
    }
    function accept(request, line): void {
        if (request.answered) return;
        request.answered = true;
        if (!active || request.generation !== generation) return;
        try {
            const data = JSON.parse(line);
            if (data.error && !data.accountId) {
                if (request.action !== "usage") { error = data.error; return; }
                // A failed identity/reconnect check does not certify a prior limit.
                data.accountId = request.account;
                data.state = "unknown";
            }
            if (request.action === "list") {
                if (!Array.isArray(data.accounts)) throw new Error("Missing account list");
                accounts = data.accounts;
                discoveryWarning = (data.warnings || []).map(item => item.error).join(" · ");
                if (!accounts.some(account => account.id === selected && account.monitored)) {
                    selected = accounts.find(account => account.monitored)?.id || "";
                    usage = {};
                }
                if (selected) {
                    const listed = accounts.find(account => account.id === selected);
                    if (listed?.unavailable) usage = {accountId: selected, state: "unknown",
                        error: "Sign-in changed or is unavailable on this host"};
                    else if (listed?.snapshot || usage.accountId !== selected)
                        usage = listed?.snapshot || {};
                }
                queueUsage(request.forceRefresh);
            } else if (request.action === "usage") {
                if (data.accountId !== request.account) throw new Error("Account identity did not match the request");
                if (request.account === selected) usage = data;
                accounts = accounts.map(account => account.id === data.accountId
                    ? Object.assign({}, account, {snapshot: data}) : account);
            } else {
                if (!data.ok) throw new Error("Account change was not acknowledged");
                if (request.action === "add") selected = data.accountId;
                start("list", "", false, []);
            }
        } catch (failure) { error = "Invalid Codex account response"; }
    }
    function finish(request): void {
        requests = requests.filter(item => item !== request);
        if (active && request.generation === generation && !request.answered)
            error = "Codex account request ended without a response";
        request.destroy();
        nextQueued();
        if (!busy && refreshPending && active) { refreshPending = false; refresh(true); }
    }
    onActiveChanged: { if (active) { observedAt = Date.now(); refresh(false); } else cancel(); }
    Timer { interval: 10000; repeat: true; running: root.active; onTriggered: root.observedAt = Date.now() }
    Timer { interval: 60000; repeat: true; running: root.active; onTriggered: root.refresh(false) }
    Component {
        id: requestComponent
        Process {
            id: request
            property int generation
            property string action
            property string account
            property bool forceRefresh
            property bool answered: false
            stdout: SplitParser { onRead: line => root.accept(request, line) }
            onExited: root.finish(request)
        }
    }
}
