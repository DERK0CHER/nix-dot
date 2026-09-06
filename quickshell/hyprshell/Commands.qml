pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The one command store. Everything that wants to know "what actions exist and
// what runs them" reads this singleton; nothing else parses `hyprctl binds -j`
// or writes its own little JSON on the side.
//
// Two inputs are merged into one model:
//
//   * live bindings from `hyprctl binds -j` - the source of truth for what keys
//     actually do right now, so the list can never drift from the config,
//   * ~/.config/hyprshell/commands.json - the user's own commands, plus name /
//     shortcut overrides for the discovered ones.
//
// The store is hot-reloaded: edit the JSON in any editor and the model updates
// without restarting the shell.  See README.md for the schema.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string storePath: home + "/.config/hyprshell/commands.json"
    // Pre-store persistence, migrated once into storePath and then renamed away.
    readonly property string legacyPath: home + "/.local/state/hyprshell/bind-labels.json"

    // ---- state ------------------------------------------------------------
    // store is id -> validated entry; storeOrder keeps the file's own order so
    // hand-written commands do not shuffle on every reload.
    property var store: ({})
    property var storeOrder: []
    property var binds: []            // raw `hyprctl binds -j`, submap binds dropped
    property bool storeReady: false   // first load attempt has finished
    property int dropped: 0           // invalid entries skipped on the last parse

    // ---- shortcut helpers -------------------------------------------------
    // modmask is a bitfield. Only the four this config uses are named; the order
    // here is the spelling order of a shortcut string ("Super+Shift+P").
    function modsToText(m: int): var {
        const parts = [];
        if (m & 64) parts.push("Super");
        if (m & 4)  parts.push("Ctrl");
        if (m & 8)  parts.push("Alt");
        if (m & 1)  parts.push("Shift");
        return parts;
    }

    function modsToMask(mods: var): int {
        let m = 0;
        for (let i = 0; i < mods.length; i++) {
            const s = String(mods[i]).toLowerCase();
            if (s === "super" || s === "mod4" || s === "meta") m |= 64;
            else if (s === "ctrl" || s === "control") m |= 4;
            else if (s === "alt" || s === "mod1") m |= 8;
            else if (s === "shift") m |= 1;
        }
        return m;
    }

    function keyOf(b: var): string {
        if (b.key && b.key !== "") return b.key;
        return b.keycode ? ("code:" + b.keycode) : "?";
    }

    // Identity of a discovered binding is its key combination, which is also how
    // the pre-store labels file was keyed - so migrating it is a pure rename and
    // cannot lose an entry.  Lower-cased so "P" and "p" are the same command.
    function idOf(b: var): string {
        return "hypr:" + b.modmask + "|" + keyOf(b).toLowerCase();
    }

    function shortcutOf(b: var): string {
        return modsToText(b.modmask).concat([keyOf(b)]).join("+");
    }

    // "Super+Shift+P" is what goes in the file; " + " is what a human reads.
    // The argument is deliberately untyped: an unbound command has shortcut
    // null, and a `: string` parameter would coerce that to the literal "null".
    function shortcutText(s: var): string {
        return (typeof s === "string" && s !== "") ? s.split("+").join(" + ") : "";
    }

    // The technical spelling of an action, used as the fallback name and as
    // search fodder. "exec  foo --bar" reads better than "exec foo --bar".
    function detailOf(exec: var): string {
        if (!exec) return "";
        if (exec.type === "hyprctl") {
            const a = (exec.arg || "").trim();
            return a === "" ? (exec.dispatcher || "") : (exec.dispatcher || "") + "  " + a;
        }
        if (exec.type === "shell") return exec.command || "";
        return exec.type || "";
    }

    function execOfBind(b: var): var {
        return { "type": "hyprctl", "dispatcher": b.dispatcher || "", "arg": (b.arg || "") };
    }

    // ---- the merged model -------------------------------------------------
    // Live bindings first, in config order, then store-only commands. A store
    // entry whose id matches a binding overrides that binding's name and
    // shortcut instead of adding a second row.
    readonly property var list: {
        const out = [];
        const seen = ({});    // id -> true, for "a row already claims this id"
        const nth = ({});     // combo -> how many rows have used it so far
        for (let i = 0; i < binds.length; i++) {
            const b = binds[i];
            // One combo can carry several dispatchers - this config binds
            // Alt+Tab to both cyclenext and bringactivetotop. They are separate
            // rows, so they need separate ids or run(id) would pick the wrong
            // one; the second and later occurrences get a "#2" suffix.
            const base = idOf(b);
            let id = base;
            if (nth[base] === undefined) nth[base] = 1;
            else { nth[base]++; id = base + "#" + nth[base]; }
            const o = store[id];
            const exec = (o && o.exec) ? o.exec : execOfBind(b);
            const detail = detailOf(exec);
            out.push({
                "id": id,
                "name": (o && o.name) ? o.name : detail,
                "exec": exec,
                "shortcut": (o && o.shortcut !== undefined) ? o.shortcut : shortcutOf(b),
                "source": "hyprland",
                "overridden": !!o,
                "description": b.description || "",
                "detail": detail,
                "bind": b
            });
            seen[id] = true;
        }
        for (let j = 0; j < storeOrder.length; j++) {
            const e = store[storeOrder[j]];
            // A "hyprland" entry is an override, never a command of its own: if
            // its binding is gone it lies dormant in the file rather than
            // showing up as a row that duplicates nothing.
            if (!e || e.source === "hyprland" || seen[e.id]) continue;
            out.push({
                "id": e.id,
                "name": e.name,
                "exec": e.exec,
                "shortcut": (e.shortcut === undefined) ? null : e.shortcut,
                "source": "user",
                "overridden": false,
                "description": e.description || "",
                "detail": detailOf(e.exec),
                "bind": null
            });
        }
        return out;
    }

    function byId(id: string): var {
        const l = list;
        for (let i = 0; i < l.length; i++) if (l[i].id === id) return l[i];
        return null;
    }

    // ---- search -----------------------------------------------------------
    // Every whitespace-separated term must match somewhere. No ranking: the
    // model's own order is the config's order, which is what users memorise.
    function search(query: string): var {
        const q = (query || "").trim().toLowerCase();
        const l = list;
        if (q === "") return l;
        const terms = q.split(/\s+/);
        const out = [];
        for (let i = 0; i < l.length; i++) {
            const c = l[i];
            const hay = (shortcutText(c.shortcut) + " " + c.name + " " + c.detail
                         + " " + c.description).toLowerCase();
            let ok = true;
            for (let t = 0; t < terms.length; t++)
                if (hay.indexOf(terms[t]) === -1) { ok = false; break; }
            if (ok) out.push(c);
        }
        return out;
    }

    // ---- running ----------------------------------------------------------
    function run(id: string): bool {
        const c = byId(id);
        if (!c) { console.warn("Commands.run: no such command:", id); return false; }
        const e = c.exec;
        if (!e) { console.warn("Commands.run: command has no exec:", id); return false; }
        if (e.type === "hyprctl") {
            Quickshell.execDetached(["hyprctl", "dispatch", e.dispatcher || "", (e.arg || "")]);
            return true;
        }
        if (e.type === "shell") {
            Quickshell.execDetached(["sh", "-c", e.command]);
            return true;
        }
        // dbus and menu are reserved in the schema but not wired up yet.
        console.warn("Commands.run: exec type '" + e.type + "' is not implemented yet:", id);
        return false;
    }

    // ---- validation -------------------------------------------------------
    // Returns a cleaned entry, or null after warning. A bad entry is dropped;
    // it never takes the rest of the file down with it.
    function validate(raw: var, where: string): var {
        function bad(why) { console.warn("Commands: dropping " + where + ": " + why); return null; }
        if (!raw || typeof raw !== "object" || Array.isArray(raw)) return bad("not an object");
        if (typeof raw.id !== "string" || raw.id.trim() === "") return bad("missing id");
        if (typeof raw.name !== "string" || raw.name.trim() === "") return bad("missing name (id " + raw.id + ")");

        let source = "user";
        if (raw.source !== undefined) {
            if (raw.source !== "user" && raw.source !== "hyprland")
                return bad("source must be \"user\" or \"hyprland\" (id " + raw.id + ")");
            source = raw.source;
        }

        const out = { "id": raw.id.trim(), "name": raw.name.trim(), "source": source };

        if (raw.exec !== undefined && raw.exec !== null) {
            const e = raw.exec;
            if (typeof e !== "object" || Array.isArray(e)) return bad("exec is not an object (id " + out.id + ")");
            if (e.type === "hyprctl") {
                if (typeof e.dispatcher !== "string" || e.dispatcher.trim() === "")
                    return bad("hyprctl exec needs a dispatcher (id " + out.id + ")");
                out.exec = { "type": "hyprctl", "dispatcher": e.dispatcher.trim(),
                             "arg": (typeof e.arg === "string" ? e.arg : "") };
            } else if (e.type === "shell") {
                if (typeof e.command !== "string" || e.command.trim() === "")
                    return bad("shell exec needs a command (id " + out.id + ")");
                out.exec = { "type": "shell", "command": e.command };
            } else if (e.type === "dbus" || e.type === "menu") {
                // Reserved: accepted and preserved so the file survives a
                // round-trip, but run() refuses them until they are implemented.
                out.exec = e;
            } else {
                return bad("unknown exec type '" + e.type + "' (id " + out.id + ")");
            }
        } else if (source === "user") {
            // Only an override may omit exec - it inherits the binding's.
            return bad("user command needs an exec (id " + out.id + ")");
        }

        // Absent shortcut means "inherit whatever Hyprland has"; an explicit
        // null means "unbound". The two are deliberately different.
        if (raw.shortcut !== undefined) {
            if (raw.shortcut === null) out.shortcut = null;
            else if (typeof raw.shortcut === "string" && raw.shortcut.trim() !== "") out.shortcut = raw.shortcut.trim();
            else return bad("shortcut must be a string or null (id " + out.id + ")");
        }
        if (typeof raw.description === "string") out.description = raw.description;
        return out;
    }

    // ---- store load -------------------------------------------------------
    function parseStore(text: string): void {
        let doc;
        try {
            doc = JSON.parse(text);
        } catch (e) {
            // Keep the last good store: a half-typed file in an open editor
            // should not blank the palette.
            console.warn("Commands: " + storePath + " is not valid JSON, keeping previous store:", e);
            return;
        }
        const raw = Array.isArray(doc) ? doc : (doc && Array.isArray(doc.commands) ? doc.commands : null);
        if (raw === null) {
            console.warn("Commands: " + storePath + ' has no "commands" array, keeping previous store');
            return;
        }
        const map = ({});
        const order = [];
        let bad = 0;
        for (let i = 0; i < raw.length; i++) {
            const c = validate(raw[i], "commands[" + i + "]");
            if (!c) { bad++; continue; }
            if (map[c.id]) { console.warn("Commands: duplicate id '" + c.id + "', keeping the first"); bad++; continue; }
            map[c.id] = c;
            order.push(c.id);
        }
        store = map;
        storeOrder = order;
        dropped = bad;
        console.log("Commands: loaded " + order.length + " command(s) from " + storePath
                    + (bad > 0 ? " (" + bad + " dropped)" : ""));
    }

    FileView {
        id: storeView
        path: root.storePath
        watchChanges: true
        printErrors: false
        // Verified against Quickshell 0.3.1: watchChanges + reload() survives a
        // truncating write, an atomic temp+mv, and a delete followed by a
        // recreate, which covers every way an editor saves a file.
        onFileChanged: storeView.reload()
        onLoaded: { root.parseStore(storeView.text()); root.afterStoreLoad(); }
        onLoadFailed: (err) => {
            // FileNotFound on a fresh install is normal, not an error.
            if (err !== FileViewError.FileNotFound)
                console.warn("Commands: cannot read " + root.storePath + ":", FileViewError.toString(err));
            root.afterStoreLoad();
        }
        onSaveFailed: (err) => console.warn("Commands: cannot write " + root.storePath + ":",
                                            FileViewError.toString(err))
    }

    function afterStoreLoad(): void {
        if (storeReady) return;
        storeReady = true;
        legacyView.reload();   // one-shot migration, see below
    }

    function save(): void {
        const cmds = [];
        for (let i = 0; i < storeOrder.length; i++) {
            const e = store[storeOrder[i]];
            if (e) cmds.push(e);
        }
        storeView.setText(JSON.stringify({ "version": 1, "commands": cmds }, null, 2) + "\n");
    }

    // ---- mutation ---------------------------------------------------------
    function upsert(cmd: var): bool {
        const c = validate(cmd, "upsert");
        if (!c) return false;
        const map = ({});
        for (const k in store) map[k] = store[k];
        const order = storeOrder.slice();
        if (!map[c.id]) order.push(c.id);
        map[c.id] = c;
        store = map;
        storeOrder = order;
        save();
        return true;
    }

    function remove(id: string): bool {
        if (!store[id]) return false;
        const map = ({});
        for (const k in store) if (k !== id) map[k] = store[k];
        const order = [];
        for (let i = 0; i < storeOrder.length; i++) if (storeOrder[i] !== id) order.push(storeOrder[i]);
        store = map;
        storeOrder = order;
        save();
        return true;
    }

    // Renaming a discovered binding creates a name-only override for it; an
    // empty name deletes that override and the binding goes back to its
    // technical spelling. This is exactly what the old labels file did.
    function setName(id: string, name: string): bool {
        const t = (name || "").trim();
        const existing = store[id];
        if (t === "") {
            if (existing && existing.source === "hyprland") return remove(id);
            if (existing) { console.warn("Commands.setName: a user command needs a name:", id); return false; }
            return true;
        }
        if (existing) {
            const copy = JSON.parse(JSON.stringify(existing));
            copy.name = t;
            return upsert(copy);
        }
        const live = byId(id);
        if (!live) { console.warn("Commands.setName: no such command:", id); return false; }
        return upsert({ "id": id, "name": t, "source": "hyprland" });
    }

    // ---- live bindings ----------------------------------------------------
    function refresh(): void { pBinds.running = true; }

    Process {
        id: pBinds
        running: true
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = JSON.parse(text);
                    // Submap binds would run in a mode the user is not in; hide them.
                    root.binds = raw.filter(b => !b.submap || b.submap === "");
                } catch (e) {
                    console.warn("Commands: cannot parse `hyprctl binds -j`:", e);
                    root.binds = [];
                }
            }
        }
    }

    // ---- rebinding --------------------------------------------------------
    Process { id: pRebind }

    // Rebinds go into hypr/custom/keybinds.conf, which hyprland.conf sources
    // last, inside a marked block so anything hand-written there survives.
    // Hyprland stays the source of truth for shortcuts: we write the config and
    // re-read `hyprctl binds -j` rather than caching the new combo in the store,
    // so the palette can never claim a shortcut the compositor does not have.
    function rebind(id: string, mods: var, key: string): bool {
        const c = byId(id);
        if (!c || !c.bind) {
            console.warn("Commands.rebind: only discovered bindings can be rebound yet:", id);
            return false;
        }
        const b = c.bind;
        const oldCombo = modsToText(b.modmask).join("+") + ", " + (b.key || "");
        const newCombo = mods.join("+") + ", " + key;
        const arg = (b.arg || "").trim();
        const line = "bind = " + newCombo + ", " + b.dispatcher + (arg ? ", " + arg : "");
        const unbind = "unbind = " + oldCombo;
        pRebind.command = ["sh", "-c",
            'f="$HOME/.config/hypr/custom/keybinds.conf"; mkdir -p "$(dirname "$f")"; touch "$f"; ' +
            'grep -q "BEGIN hyprshell rebinds" "$f" || printf "\n# BEGIN hyprshell rebinds - generated, edit above this line\n# END hyprshell rebinds\n" >> "$f"; ' +
            "awk -v u=\"" + unbind + "\" -v l=\"" + line + "\" '" +
            '/# END hyprshell rebinds/ { print u; print l } { print }' +
            "' \"$f\" > \"$f.tmp\" && mv \"$f.tmp\" \"$f\" && hyprctl reload >/dev/null 2>&1 && " +
            "notify-send -a hyprshell 'Shortcut changed' \"" + newCombo.replace(/"/g, "") + "\""];
        pRebind.running = true;

        // The id follows the combo, so carry a rename over to the new one -
        // otherwise rebinding silently threw the user's own label away.
        const override = store[id];
        if (override) {
            const newId = "hypr:" + modsToMask(mods) + "|" + String(key).toLowerCase();
            if (newId !== id) {
                const copy = JSON.parse(JSON.stringify(override));
                copy.id = newId;
                remove(id);
                upsert(copy);
            }
        }
        return true;
    }

    // ---- one-shot migration ----------------------------------------------
    // ~/.local/state/hyprshell/bind-labels.json was "modmask|key" -> label. The
    // new id for a binding is "hypr:" + that same key, so every rename carries
    // over as a name-only override without needing the binding to still exist.
    // The old file is renamed to .migrated afterwards: that is both the "done"
    // marker and a backup.
    FileView {
        id: legacyView
        path: root.legacyPath
        printErrors: false
        onLoaded: root.migrateLabels(legacyView.text())
        onLoadFailed: (err) => {
            if (err !== FileViewError.FileNotFound)
                console.warn("Commands: cannot read " + root.legacyPath + ":", FileViewError.toString(err));
        }
    }

    Process { id: pRetireLegacy }

    function migrateLabels(text: string): void {
        let labels;
        try {
            labels = JSON.parse(text);
        } catch (e) {
            console.warn("Commands: " + legacyPath + " is not valid JSON, not migrating:", e);
            return;
        }
        if (!labels || typeof labels !== "object") return;

        const map = ({});
        for (const k in store) map[k] = store[k];
        const order = storeOrder.slice();
        let added = 0, skipped = 0;
        for (const combo in labels) {
            const label = labels[combo];
            if (typeof label !== "string" || label.trim() === "") { skipped++; continue; }
            const sep = combo.indexOf("|");
            if (sep < 0) { skipped++; continue; }
            const id = "hypr:" + combo.slice(0, sep) + "|" + combo.slice(sep + 1).toLowerCase();
            if (map[id]) continue;                 // the new store already wins
            map[id] = { "id": id, "name": label.trim(), "source": "hyprland" };
            order.push(id);
            added++;
        }

        store = map;
        storeOrder = order;
        if (added > 0) save();
        console.log("Commands: migrated " + added + " label(s) from " + legacyPath
                    + (skipped > 0 ? " (" + skipped + " skipped)" : ""));

        // Rename rather than delete, so a failed migration is recoverable.
        pRetireLegacy.command = ["sh", "-c",
            'f="' + legacyPath + '"; [ -f "$f" ] && mv -f "$f" "$f.migrated"'];
        pRetireLegacy.running = true;
    }
}
