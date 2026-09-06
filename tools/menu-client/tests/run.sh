#!/usr/bin/env bash
# End-to-end test for menu-client against the mock producers.
#
# Re-execs itself inside a private session bus (dbus-run-session) so it never
# touches the user's real session. Exits non-zero if any assertion fails.

set -uo pipefail

if [ "${MENU_CLIENT_TEST_BUS:-}" != "1" ]; then
    export MENU_CLIENT_TEST_BUS=1
    exec dbus-run-session -- "$0" "$@"
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
CLIENT="$ROOT/menu-client"
TMP="$(mktemp -d)"
PIDS=()
FAILURES=0

DBUSMENU_BUS="org.example.MockDBusMenu"
DBUSMENU_PATH="/MenuBar"
GTK_BUS="org.example.MockGtkMenu"
GTK_PATH="/org/gtk/mock/menus/menubar"

cleanup() {
    for pid in "${PIDS[@]:-}"; do kill "$pid" 2>/dev/null; done
    wait 2>/dev/null
    rm -rf "$TMP"
}
trap cleanup EXIT

ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

section() { printf '\n== %s\n' "$1"; }

# expect_exit WANTED DESCRIPTION cmd...   (stdout -> $TMP/out, stderr -> $TMP/err)
expect_exit() {
    local want="$1" desc="$2"
    shift 2
    "$@" >"$TMP/out" 2>"$TMP/err"
    local got=$?
    if [ "$got" -eq "$want" ]; then
        ok "$desc (exit $got)"
    else
        bad "$desc: expected exit $want, got $got"
        sed 's/^/        /' "$TMP/err"
    fi
}

wait_for_name() { # bus-name object-path
    for _ in $(seq 1 100); do
        gdbus call --session --dest "$1" --object-path "$2" \
            --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    return 1
}

wait_for_text() { # file text
    for _ in $(seq 1 100); do
        grep -q "$2" "$1" 2>/dev/null && return 0
        sleep 0.1
    done
    return 1
}

start_mock() { # script log-file extra-args...
    local script="$1" log="$2"
    shift 2
    python3 "$HERE/$script" "$@" >"$log" 2>&1 &
    PIDS+=("$!")
}

# ---------------------------------------------------------------------------
section "com.canonical.dbusmenu"
# ---------------------------------------------------------------------------
DBUSMENU_REC="$TMP/dbusmenu-events.jsonl"
: >"$DBUSMENU_REC"
start_mock mock-dbusmenu.py "$TMP/mock-dbusmenu.log" --record "$DBUSMENU_REC"

if wait_for_name "$DBUSMENU_BUS" "$DBUSMENU_PATH"; then
    ok "mock producer owns $DBUSMENU_BUS"
else
    bad "mock producer never appeared on the bus"
    cat "$TMP/mock-dbusmenu.log"
    exit 1
fi

if "$CLIENT" dump "$DBUSMENU_BUS" "$DBUSMENU_PATH" >"$TMP/dbusmenu.json" \
        2>"$TMP/dbusmenu.err"; then
    ok "dump exited 0"
else
    bad "dump failed"
    cat "$TMP/dbusmenu.err"
fi

python3 - "$TMP/dbusmenu.json" <<'PY'
import json, sys

CONTRACT = {"id", "label", "enabled", "visible", "checked", "separator",
            "shortcut", "children"}
fails = []
seen_ids = set()


def check(cond, msg):
    if not cond:
        fails.append(msg)


def walk(node, path):
    check(set(node) == CONTRACT,
          f"{path}: keys off contract: {sorted(set(node) ^ CONTRACT)}")
    check(isinstance(node.get("id"), str) and node["id"],
          f"{path}: id must be a non-empty string, got {node.get('id')!r}")
    check(node["id"] not in seen_ids, f"{path}: duplicate id {node['id']!r}")
    seen_ids.add(node.get("id"))
    check(isinstance(node.get("label"), str), f"{path}: label must be a string")
    check(isinstance(node.get("enabled"), bool), f"{path}: enabled must be bool")
    check(isinstance(node.get("visible"), bool), f"{path}: visible must be bool")
    check(node.get("checked") is None or isinstance(node["checked"], bool),
          f"{path}: checked must be bool or null")
    check(isinstance(node.get("separator"), bool),
          f"{path}: separator must be bool")
    check(node.get("shortcut") is None or isinstance(node["shortcut"], str),
          f"{path}: shortcut must be a string or null")
    check(isinstance(node.get("children"), list),
          f"{path}: children must be a list")
    check("_" not in node["label"] and "&" not in node["label"],
          f"{path}: mnemonic marker left in label {node['label']!r}")
    for i, child in enumerate(node.get("children") or []):
        walk(child, f"{path}/{node['label'] or node['id']}[{i}]")


tree = json.load(open(sys.argv[1]))
walk(tree, "root")

top = {c["label"]: c for c in tree["children"]}
check(sorted(top) == ["Edit", "File"], f"top level menus = {sorted(top)}")

fmenu = top.get("File", {"children": []})
labels = [c["label"] for c in fmenu["children"]]
check(labels == ["New", "Open", "", "Quit"], f"File children = {labels}")
check([c["separator"] for c in fmenu["children"]] == [False, False, True, False],
      "File: only the third child may be flagged as a separator")
check(fmenu["children"][0]["shortcut"] == "Control+N",
      f"New shortcut = {fmenu['children'][0]['shortcut']!r}")
check(fmenu["children"][3]["shortcut"] == "Control+Q",
      f"Quit shortcut = {fmenu['children'][3]['shortcut']!r}")

emenu = top.get("Edit", {"children": []})
edit = {c["label"]: c for c in emenu["children"]}
check(sorted(edit) == ["Copy", "Hidden", "Paste", "Word Wrap"],
      f"Edit children = {sorted(edit)}")
check(edit["Copy"]["enabled"] is False, "Copy must report enabled=false")
check(edit["Paste"]["enabled"] is True, "Paste must report enabled=true")
check(edit["Word Wrap"]["checked"] is True,
      "Word Wrap must report checked=true")
check(edit["Paste"]["checked"] is None,
      "a non-checkable item must report checked=null")
check(edit["Hidden"]["visible"] is False, "Hidden must report visible=false")
check(all(not c["children"] for c in emenu["children"]),
      "Edit entries are leaves")
check(len(tree["children"]) == 2 and len(fmenu["children"]) == 4
      and len(emenu["children"]) == 4, "nesting: 2 menus, 4 + 4 entries")

for msg in fails:
    print(f"  FAIL  {msg}")
sys.exit(1 if fails else 0)
PY
if [ $? -eq 0 ]; then
    ok "dbusmenu JSON matches the contract"
else
    bad "dbusmenu JSON assertions"
fi

QUIT_ID="$(python3 -c '
import json, sys
tree = json.load(open(sys.argv[1]))
f = [c for c in tree["children"] if c["label"] == "File"][0]
print([c for c in f["children"] if c["label"] == "Quit"][0]["id"])
' "$TMP/dbusmenu.json" 2>/dev/null)"

if [ -n "$QUIT_ID" ]; then
    ok "id for File > Quit read back from the dump: $QUIT_ID"
else
    bad "could not read the Quit id out of the dump"
fi

expect_exit 0 "activate File > Quit" \
    "$CLIENT" activate "$DBUSMENU_BUS" "$DBUSMENU_PATH" "$QUIT_ID"

if python3 -c '
import json, sys
want = sys.argv[2]
hits = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
sys.exit(0 if any(h["id"] == want and h["event"] == "clicked" for h in hits) else 1)
' "$DBUSMENU_REC" "$QUIT_ID"; then
    ok "mock recorded Event(id=$QUIT_ID, \"clicked\")"
else
    bad "mock did not record the activation; recorded: $(cat "$DBUSMENU_REC")"
fi

expect_exit 4 "activate with a malformed id" \
    "$CLIENT" activate "$DBUSMENU_BUS" "$DBUSMENU_PATH" "not-an-id"

# ---------------------------------------------------------------------------
section "watch"
# ---------------------------------------------------------------------------
"$CLIENT" watch "$DBUSMENU_BUS" "$DBUSMENU_PATH" >"$TMP/watch.log" 2>&1 &
WATCH_PID=$!
PIDS+=("$WATCH_PID")

if wait_for_text "$TMP/watch.log" '"watching"'; then
    gdbus call --session --dest "$DBUSMENU_BUS" --object-path "$DBUSMENU_PATH" \
        --method org.example.MockControl.Touch >/dev/null 2>&1
    if wait_for_text "$TMP/watch.log" 'layout-updated'; then
        ok "watch printed a line when the menu changed"
    else
        bad "watch missed the LayoutUpdated signal; log: $(cat "$TMP/watch.log")"
    fi
else
    bad "watch never started; log: $(cat "$TMP/watch.log")"
fi
kill "$WATCH_PID" 2>/dev/null

# ---------------------------------------------------------------------------
section "error paths"
# ---------------------------------------------------------------------------
expect_exit 2 "dump against a bus name nobody owns" \
    "$CLIENT" dump org.example.NotRunning /MenuBar
expect_exit 3 "dump against an object speaking neither protocol" \
    "$CLIENT" dump "$DBUSMENU_BUS" /

# ---------------------------------------------------------------------------
section "org.gtk.Menus + org.gtk.Actions"
# ---------------------------------------------------------------------------
GTK_REC="$TMP/gtk-events.jsonl"
: >"$GTK_REC"
start_mock mock-gtkmenu.py "$TMP/mock-gtkmenu.log" --record "$GTK_REC"

if wait_for_name "$GTK_BUS" "$GTK_PATH"; then
    ok "mock producer owns $GTK_BUS"
else
    bad "gtk mock producer never appeared on the bus"
    cat "$TMP/mock-gtkmenu.log"
fi

if "$CLIENT" dump "$GTK_BUS" "$GTK_PATH" >"$TMP/gtk.json" 2>"$TMP/gtk.err"; then
    ok "dump exited 0"
else
    bad "dump failed"
    cat "$TMP/gtk.err"
fi

python3 - "$TMP/gtk.json" <<'PY'
import json, sys

CONTRACT = {"id", "label", "enabled", "visible", "checked", "separator",
            "shortcut", "children"}
fails = []
seen_ids = set()


def check(cond, msg):
    if not cond:
        fails.append(msg)


def walk(node, path):
    check(set(node) == CONTRACT,
          f"{path}: keys off contract: {sorted(set(node) ^ CONTRACT)}")
    check(isinstance(node.get("id"), str) and node["id"],
          f"{path}: id must be a non-empty string")
    check(node["id"] not in seen_ids, f"{path}: duplicate id {node['id']!r}")
    seen_ids.add(node.get("id"))
    check(isinstance(node.get("enabled"), bool), f"{path}: enabled must be bool")
    check(isinstance(node.get("visible"), bool), f"{path}: visible must be bool")
    check(node.get("checked") is None or isinstance(node["checked"], bool),
          f"{path}: checked must be bool or null")
    check(isinstance(node.get("separator"), bool),
          f"{path}: separator must be bool")
    check(node.get("shortcut") is None or isinstance(node["shortcut"], str),
          f"{path}: shortcut must be a string or null")
    check("_" not in node["label"] and "&" not in node["label"],
          f"{path}: mnemonic marker left in label {node['label']!r}")
    for i, child in enumerate(node.get("children") or []):
        walk(child, f"{path}/{node['label'] or node['id']}[{i}]")


tree = json.load(open(sys.argv[1]))
walk(tree, "root")

top = {c["label"]: c for c in tree["children"]}
check(sorted(top) == ["Edit", "File"], f"top level menus = {sorted(top)}")

fmenu = top.get("File", {"children": []})
labels = [c["label"] for c in fmenu["children"]]
# Two GMenu sections must be flattened with a separator between them.
check(labels == ["New", "Open", "", "Quit"], f"File children = {labels}")
check([c["separator"] for c in fmenu["children"]] == [False, False, True, False],
      "File: a separator must be synthesised between the two sections")
check(fmenu["children"][0]["shortcut"] == "<Control>n",
      f"New accel = {fmenu['children'][0]['shortcut']!r}")

emenu = top.get("Edit", {"children": []})
edit = {c["label"]: c for c in emenu["children"]}
check(sorted(edit) == ["Copy", "Grid view", "List view", "Paste", "Word Wrap"],
      f"Edit children = {sorted(edit)}")
# The Edit menu lives in subscription group 1: reaching it proves the client
# followed the reference and called Start() again.
check(edit["Copy"]["enabled"] is False,
      "Copy is disabled in DescribeAll, so enabled must be false")
check(edit["Paste"]["enabled"] is True, "Paste must report enabled=true")
check(edit["Word Wrap"]["checked"] is True,
      "boolean action state must map to checked=true")
check(edit["List view"]["checked"] is True,
      "radio action whose state equals its target must be checked")
check(edit["Grid view"]["checked"] is False,
      "radio action whose state differs from its target must be unchecked")
check(edit["Paste"]["checked"] is None,
      "a stateless action must report checked=null")
check(all(n["visible"] is True for n in emenu["children"]),
      "org.gtk.Menus has no visibility flag; everything present is visible")
check(edit["Grid view"]["id"].startswith("gtk:win.view?"),
      f"targeted id must carry the target: {edit['Grid view']['id']!r}")

for msg in fails:
    print(f"  FAIL  {msg}")
sys.exit(1 if fails else 0)
PY
if [ $? -eq 0 ]; then
    ok "gtk JSON matches the contract"
else
    bad "gtk JSON assertions"
fi

GTK_QUIT_ID="$(python3 -c '
import json, sys
tree = json.load(open(sys.argv[1]))
f = [c for c in tree["children"] if c["label"] == "File"][0]
print([c for c in f["children"] if c["label"] == "Quit"][0]["id"])
' "$TMP/gtk.json" 2>/dev/null)"
GTK_GRID_ID="$(python3 -c '
import json, sys
tree = json.load(open(sys.argv[1]))
e = [c for c in tree["children"] if c["label"] == "Edit"][0]
print([c for c in e["children"] if c["label"] == "Grid view"][0]["id"])
' "$TMP/gtk.json" 2>/dev/null)"

expect_exit 0 "activate File > Quit" \
    "$CLIENT" activate "$GTK_BUS" "$GTK_PATH" "$GTK_QUIT_ID"
expect_exit 0 "activate Edit > Grid view (action with a target)" \
    "$CLIENT" activate "$GTK_BUS" "$GTK_PATH" "$GTK_GRID_ID"

if python3 -c '
import json, sys
hits = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
ok = (any(h["action"] == "quit" and h["params"] == [] for h in hits)
      and any(h["action"] == "view" and h["params"] == ["grid"] for h in hits))
sys.exit(0 if ok else 1)
' "$GTK_REC"; then
    ok "mock recorded Activate(\"quit\") and Activate(\"view\", [\"grid\"])"
else
    bad "mock did not record the activations; recorded: $(cat "$GTK_REC")"
fi

expect_exit 4 "activate a structural (non-actionable) gtk id" \
    "$CLIENT" activate "$GTK_BUS" "$GTK_PATH" "gtknode:0/0/0"

# ---------------------------------------------------------------------------
printf '\n'
if [ "$FAILURES" -eq 0 ]; then
    printf 'PASS\n'
    exit 0
fi
printf 'FAIL (%d assertion(s))\n' "$FAILURES"
exit 1
