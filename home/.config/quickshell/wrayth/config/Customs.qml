pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The user's own colour profiles, in ~/.config/wrayth/custom-profiles.json.
//
// Only the nine authored colours are stored. The rest of a palette is a set of
// fixed relationships between those nine -- see `Profiles.derive` -- so storing
// them would be storing a derivation, and a hand edit could then contradict
// itself. `Profiles` is what merges these with the six presets; nothing else in
// the shell has to know which kind of profile it is holding.
Singleton {
    id: root

    // [{ name, created, colors: { ground, panel, hair, text, bright, dim,
    //                             signal, accent, alert } }], creation order.
    property var list: []

    readonly property var names: root.list.map(entry => entry.name)

    // Entries the file holds that this shell will not load (a bad name or
    // colour, typically a hand edit), and profiles the user has deleted. Both
    // are written back to the file untouched, so a save never destroys them.
    property var rejectedEntries: []
    property var removed: []

    // The nine, in the order the editor lists them. The role text is the
    // editor's, so it lives with the key rather than in the view.
    readonly property var roles: [
        {
            key: "ground",
            role: "BASE BACKGROUND"
        },
        {
            key: "panel",
            role: "PANEL AND CARD FILL"
        },
        {
            key: "hair",
            role: "BORDERS"
        },
        {
            key: "text",
            role: "BODY TEXT"
        },
        {
            key: "bright",
            role: "TITLES, KEY VALUES"
        },
        {
            key: "dim",
            role: "LABELS"
        },
        {
            key: "signal",
            role: "DATA, GRAPHS, KATAKANA"
        },
        {
            key: "accent",
            role: "ACTIVE, HOT, SELECTED"
        },
        {
            key: "alert",
            role: "WARNINGS ONLY"
        }
    ]

    // The background colours, whose contrast is judged against TEXT rather
    // than against GROUND.
    readonly property var backgroundKeys: ["ground", "panel", "hair"]

    function find(name: string): var {
        for (const entry of list)
            if (entry.name.toLowerCase() === name.toLowerCase())
                return entry;
        return null;
    }

    function has(name: string): bool {
        return find(name) !== null;
    }

    // The one rule for a custom name, shared by every way in: the file, the
    // editor and the IPC. Letters, digits, spaces and hyphens, and never a
    // preset's name, which would otherwise replace that preset's palette.
    function validName(name: string): bool {
        return typeof name === "string" && /^[A-Za-z0-9 -]{1,40}$/.test(name) && !Profiles.presetNames.some(preset => preset.toLowerCase() === name.toLowerCase());
    }

    // Add a new profile or replace an existing one, keeping its place in the
    // creation order so the picker's cards do not shuffle when one is edited.
    function store(name: string, colors: var): bool {
        if (!validName(name))
            return false;
        const next = list.slice();
        const at = next.findIndex(entry => entry.name.toLowerCase() === name.toLowerCase());
        if (at >= 0)
            next[at] = Object.assign({}, next[at], {
                name,
                colors
            });
        else
            next.push({
                name,
                created: Date.now(),
                colors
            });
        list = next;
        write();
        return true;
    }

    // A delete is a move, not a loss: the entry goes under `removed` in the
    // file, stamped, the same way a deleted wallpaper goes to a recovery folder.
    function remove(name: string): void {
        const gone = list.filter(entry => entry.name.toLowerCase() === name.toLowerCase());
        if (!gone.length)
            return;
        removed = removed.concat(gone.map(entry => Object.assign({}, entry, {
            removedAt: new Date().toISOString()
        })));
        list = list.filter(entry => entry.name.toLowerCase() !== name.toLowerCase());
        write();
    }

    // See `Wallpapers.loaded`: a reload rebuilds this with an empty list and
    // the file loads asynchronously, so a write in that window would delete
    // every custom profile the user has.
    property bool loaded: false

    function write(): void {
        if (!root.loaded)
            return;
        const out = {
            profiles: root.list
        };
        if (root.rejectedEntries.length)
            out.rejected = root.rejectedEntries;
        if (root.removed.length)
            out.removed = root.removed;
        file.setText(`${JSON.stringify(out, null, 2)}\n`);
    }

    function adopt(contents: string): void {
        // An empty file is a valid "no custom profiles", and it counts as
        // read -- otherwise the first save would be refused for ever.
        if (!contents.trim()) {
            list = [];
            loaded = true;
            return;
        }
        try {
            const parsed = JSON.parse(contents);
            const profiles = parsed?.profiles;
            // Not readable as a profile list: say so, and do not mark the file
            // as loaded, so no save can write over what was not understood.
            if (!Array.isArray(profiles)) {
                console.warn("wrayth: custom-profiles.json has no profiles list; leaving it alone");
                return;
            }
            // A hand-edited file is not trusted to be complete **or safe**: an
            // entry without a name or without all nine colours would produce a
            // profile the shell could not paint with, and -- the security part
            // -- a profile name or a colour is not just displayed. The name is
            // written into `~/.cache/wrayth/status` (which the deck greeting
            // sources as shell) and used to build a wallpaper path; the colours
            // are interpolated into a `hyprctl eval` Lua string. So both are
            // validated to the same charset the editor enforces, and any entry
            // that fails is not loaded; it stays in the file under `rejected`,
            // so the user can fix it by hand. This is the single point
            // that keeps a crafted colour like `")); os.execute(...)` or a name
            // like `x=y;id` or `../../evil` out of every downstream sink.
            const hexOk = c => typeof c === "string" && /^#[0-9A-Fa-f]{6}$/.test(c);
            const valid = entry => entry && root.validName(entry.name) && entry.colors && root.roles.every(r => hexOk(entry.colors[r.key]));
            list = profiles.filter(valid);
            rejectedEntries = profiles.filter(entry => !valid(entry));
            removed = Array.isArray(parsed.removed) ? parsed.removed : [];
            loaded = true;
        } catch (e) {
            console.warn(`wrayth: custom-profiles.json is not readable JSON (${e})`);
        }
    }

    FileView {
        id: file

        path: Paths.customProfilesFile
        watchChanges: true
        printErrors: false

        onLoaded: root.adopt(text())
        onFileChanged: reload()
        // No file yet is the normal first run, and an empty list is exactly
        // right -- nothing is seeded, because there are no custom profiles
        // until the user makes one.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.list = [];
                root.loaded = true;
            }
        }
    }
}
