pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// What the ScreenPad's workspace indicator shows. It tracks the main display,
// so focusing a ScreenPad app or the bottom bar cannot change its selection.
// The indicator is always seven regular slots wide: the numbered workspaces
// holding the active one, or -- while any special workspace is visible -- the
// special workspaces themselves.
//
// Kept out of the bar component so the indicator stays pure rendering, and out
// of `Deck` so it does not depend on the deck being constructed.
Singleton {
    id: root

    readonly property int perPage: 7
    readonly property var workspaceIds: [1, 2, 3, 7, 4, 5, 6]
    readonly property var workspaceNames: ["Terminal", "Web", "Code", "Sim", "Work", "Misc", "Study"]

    readonly property var workspaceGlyphs: ["\uf120", "\uf0ac", "\uf121", "\uf1b2", "\uf0b1", "\uf07b", "\uf518"]

    // Special workspaces carry a name; these are the ones worth a word rather
    // than the first four letters of whatever Hyprland calls them.
    readonly property var specialLabels: ({
        deck: "DECK",
        communication: "COMM",
        favourites: "FAVS",
        favorites: "FAVS"
    })

    readonly property var mainMonitor: Hyprland.monitors.values.find(m => m.name === "eDP-1") ?? null
    readonly property var monitorIpc: mainMonitor?.lastIpcObject ?? null

    readonly property int activeId: monitorIpc?.activeWorkspace?.id ?? mainMonitor?.activeWorkspace?.id ?? 1

    // "special:deck" while one is up, "" otherwise.
    readonly property string activeSpecial: monitorIpc?.specialWorkspace?.name ?? ""
    readonly property bool special: activeSpecial.startsWith("special:")

    // The bare names of every special workspace Hyprland currently knows about,
    // in a stable order so slots do not shuffle under the pointer.
    readonly property var specials: {
        const names = [];
        for (const ws of Hyprland.workspaces.values)
            if (ws.name?.startsWith("special:"))
                names.push(ws.name.slice(8));
        names.sort();
        return names;
    }

    function labelFor(name: string): string {
        return specialLabels[name] ?? name.slice(0, 4).toUpperCase();
    }

    // Regular slots use the configured order; a special page is padded
    // with empty slots, because the indicator's width is fixed and a short page
    // must not shrink it.
    readonly property var slots: {
        const out = [];
        if (special) {
            const current = activeSpecial.slice(8);
            const index = Math.max(0, specials.indexOf(current));
            const page = Math.floor(index / perPage);
            for (let i = 0; i < perPage; i++) {
                const name = specials[page * perPage + i];
                out.push({
                    label: name === undefined ? "" : labelFor(name),
                    target: name ?? "",
                    special: true,
                    empty: name === undefined,
                    active: name === current
                });
            }
            return out;
        }
        const page = 0;
        for (let i = 0; i < perPage; i++) {
            const id = workspaceIds[i];
            out.push({
                label: workspaceNames[id - 1] ?? `${id}`.padStart(2, "0"),
                glyph: workspaceGlyphs[id - 1] ?? "",
                target: `${id}`,
                special: false,
                empty: id > workspaceNames.length,
                active: id === activeId,
                occupied: Hyprland.toplevels.values.some(t=>t.workspace?.id===id),
                count: Hyprland.toplevels.values.filter(t=>t.workspace?.id===id).length
            });
        }
        return out;
    }

    // --- Pages, for the bar's page marker -----------------------------------
    // A page is in use if any of its workspaces exist or it is the active one.
    // Pages need not be contiguous -- workspaces 1 and 12 put pages 0 and 2 in
    // use and page 1 not -- so the pips follow the *used* pages in order, and
    // the lit one is the current page's place in that list rather than its
    // page number.
    readonly property var usedPages: {
        const pages = {};
        for (const ws of Hyprland.workspaces.values)
            if (ws.id >= 1)
                pages[Math.floor((ws.id - 1) / perPage)] = true;
        pages[Math.floor(Math.max(0, activeId - 1) / perPage)] = true;
        return Object.keys(pages).map(Number).sort((a, b) => a - b);
    }

    readonly property int currentPage: Math.floor(Math.max(0, activeId - 1) / perPage)

    // `SPC` while a special workspace is up, otherwise the page number.
    readonly property string pageLabel: special ? "SPC" : `P${currentPage + 1}`

    // One pip per used page, plus a final one for the special page.
    //
    // The marker rests at three pips -- two numbered pages and the special
    // one -- rather than following the used pages down to a single pip. A lone
    // pip reads as a decoration beside the slots; a standing row of three reads
    // as the pager it is, and the pips stop appearing and vanishing as
    // workspaces come and go. Extra pips light up as pages beyond the second
    // come into use.
    readonly property int minNumberedPips: 2
    readonly property int numberedPips: Math.max(minNumberedPips, usedPages.length)
    readonly property int pipCount: numberedPips + 1
    readonly property int litPip: special ? numberedPips : Math.max(0, usedPages.indexOf(currentPage))

    // Which slot the bar's accent line runs to, or -1 when none is lit.
    readonly property int activeIndex: special ? slots.findIndex(slot => slot.active)
                                                : workspaceIds.indexOf(activeId)

    function activate(slot: var): void {
        if (slot.empty)
            return;
        if (slot.special)
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${slot.target}")`);
        else
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${slot.target}" })`);
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;
            if (["activespecial", "workspace", "createworkspace", "destroyworkspace", "moveworkspace", "renameworkspace", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            }
        }
    }
}
