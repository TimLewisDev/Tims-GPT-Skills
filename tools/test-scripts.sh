#!/usr/bin/env bash
# test-scripts.sh: smoke tests for the tt-common status and continue-mode
# scripts, run against tools/fixtures/demo in a throwaway git repo. Needs bash,
# awk and git only. Prints one line per check and a count; exit 1 on failure.
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
S="$root/tt-common/scripts"
F="$root/tools/fixtures/demo"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0; fail=0

ok() { pass=$((pass + 1)); echo "ok    $1"; }
bad() { fail=$((fail + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; }
# expect <name> <exit code> <command...>: the command exits with the code
expect() { local n=$1 want=$2; shift 2; "$@" >"$T/out" 2>&1; local rc=$?; [ "$rc" = "$want" ] && ok "$n" || bad "$n" "exit $rc, wanted $want: $(head -c 300 "$T/out")"; }
# has <name> <file> <fixed string>: the file contains the string
has() { grep -qF -- "$3" "$2" && ok "$1" || bad "$1" "missing: $3"; }
hasnt() { grep -qF -- "$3" "$2" && bad "$1" "unexpected: $3" || ok "$1"; }

# A repo the fixture breakdown points at.
mkdir -p "$T/repo/src"
(cd "$T/repo" && git init -q -b feature/demo && git config core.autocrlf false && echo 'exit 0' >build.sh &&
	printf 'echo hi\n# DEBUG\n' >src/store.sh && echo 'echo hello' >src/greet.sh && git add . &&
	git -c user.email=t@t -c user.name=t commit -qm init)
for f in "$F"/*.md; do sed "s#REPO#$T/repo#g" "$f" >"$T/$(basename "$f")"; done
BD="$T/Demo - Task Breakdown.md"; ST="$T/Demo - Task Status.md"

echo "# status-set.sh"
expect "start a task" 0 bash "$S/status-set.sh" "$ST" T01 "In Progress"
has "task row set" "$ST" "| T01 | Add the settings store | Agent | WU1 | — | In Progress |"
has "unit follows the task" "$ST" "| WU1 | Save settings | T01, T02 | Agent | In Progress |"
has "header State" "$ST" "- State: In Progress"
has "Resume Here next action" "$ST" "4. Next action: T01 — Add the settings store (Agent)."
expect "block with a note" 0 bash "$S/status-set.sh" "$ST" T01 Blocked --note "D1: format"
has "Blocking Decisions" "$ST" "- Blocking Decisions: T01 (D1: format)"
has "unit Blocked" "$ST" "| WU1 | Save settings | T01, T02 | Agent | Blocked |"
expect "task Done only through its unit" 2 bash "$S/status-set.sh" "$ST" T01 Done
expect "unknown ID" 2 bash "$S/status-set.sh" "$ST" T99 Todo
expect "unknown status" 2 bash "$S/status-set.sh" "$ST" T01 Finished
hasnt "no report lines in the document" "$ST" " -> "

echo "# status-log.sh"
cat >"$T/T01.md" <<'EOF'
# Result: T01 — Add the settings store

- Task status: implemented

## Files Modified
- new `src/store.sh`: the store

## Summary
Wrote the store.

## To validate
1. Run `bash build.sh` → expect exit 0.

## Follow-up Concerns
none

## Risks
- The store format isn't versioned.

## Improvements
### Version it
- Description: Add a version field.
- Benefits: Safer upgrades.
- Risks/Tradeoffs: One more field.
- Why High Impact: Every unit reads it.

## Critical Decision
none
EOF
expect "apply a result" 0 bash "$S/status-log.sh" "$ST" "$T/T01.md"
has "Step Log entry" "$ST" "## T01 — Add the settings store"
has "validation deferred to the unit" "$ST" "- Validation: Deferred to WU1"
has "task Implemented" "$ST" "| T01 | Add the settings store | Agent | WU1 | — | Implemented |"
has "unit unblocked" "$ST" "| WU1 | Save settings | T01, T02 | Agent | In Progress |"
has "risk added" "$ST" "  - The store format isn't versioned. (T01, "
has "improvement added" "$ST" "## Improvement 1"
expect "apply the same result again" 0 bash "$S/status-log.sh" "$ST" "$T/T01.md"
[ "$(grep -c "The store format isn't versioned" "$ST")" = 1 ] && ok "risk not duplicated" || bad "risk not duplicated"
[ "$(grep -c '^## Improvement' "$ST")" = 1 ] && ok "improvement not duplicated" || bad "improvement not duplicated"
[ "$(grep -c '^## T01 —' "$ST")" = 1 ] && ok "entry replaced, not duplicated" || bad "entry replaced, not duplicated"
printf '# Result: T02 — x\n\n- Task status: blocked\n\n## Files Modified\nnone\n\n## Summary\nStopped.\n\n## Critical Decision\n### Issue\nName clash.\n' >"$T/T02.md"
expect "apply a blocked result" 0 bash "$S/status-log.sh" "$ST" "$T/T02.md"
has "critical decision reported" "$T/out" "critical decision: yes"
printf '# Result: T77 — x\n- Task status: implemented\n' >"$T/bad.md"
expect "result for an unknown task" 2 bash "$S/status-log.sh" "$ST" "$T/bad.md"

echo "# status-record.sh"
expect "decision" 0 bash "$S/status-record.sh" "$ST" decision --decision "Name | clash" --resolution "Rename" --affects T02
has "decision row, pipe escaped" "$ST" "| D1 | Name \| clash | Rename | T02 |"
expect "breakdown change" 0 bash "$S/status-record.sh" "$ST" change --affects T02 --change "Rename the file" --why "D1" --approved-by Engineer
expect "risk close" 0 bash "$S/status-record.sh" "$ST" risk --close "versioned" --how "added a version"
has "risk closed" "$ST" "**Closed "
expect "risk close with no match" 2 bash "$S/status-record.sh" "$ST" risk --close "nothing like this" --how x
expect "unblock T02" 0 bash "$S/status-set.sh" "$ST" T02 Implemented
expect "unit ready" 0 bash "$S/status-set.sh" "$ST" WU1 "Ready to Validate"

echo "# run-checks.sh"
expect "WU1 checks (one fails)" 1 bash "$S/run-checks.sh" "$BD" WU1 "$T/logs/WU1-1"
has "failing check" "$T/logs/WU1-1/attempt.md" "[Agent]: failed. \`git grep -n \"DEBUG\" -- src\`"
has "outcome Failed" "$T/logs/WU1-1/attempt.md" "- Outcome: Failed"
[ -s "$T/logs/WU1-1/check-2.log" ] && ok "check log written" || bad "check log written"
expect "record the attempt" 0 bash "$S/status-record.sh" "$ST" validation WU1 --file "$T/logs/WU1-1/attempt.md"
has "attempt heading" "$ST" "### Attempt 1"
sed -i '/DEBUG/d' "$T/repo/src/store.sh"
(cd "$T/repo" && git add -A && git -c user.email=t@t -c user.name=t commit -qm fix)
expect "WU1 checks after the fix" 0 bash "$S/run-checks.sh" "$BD" WU1 "$T/logs/WU1-2" --why "after fix"
expect "record attempt 2" 0 bash "$S/status-record.sh" "$ST" validation WU1 --file "$T/logs/WU1-2/attempt.md"
has "attempt 2" "$ST" "### Attempt 2"
expect "unit Done" 0 bash "$S/status-set.sh" "$ST" WU1 Done
has "tasks Done with the unit" "$ST" "| T02 | Add the settings loader | Agent | WU1 | T01 | Done |"
has "Step Log follows" "$ST" "- Status: Done"
expect "WU2 checks (engineer pending)" 0 bash "$S/run-checks.sh" "$BD" WU2 "$T/logs/WU2-1"
has "agent + engineer pending" "$T/logs/WU2-1/attempt.md" "[Agent + Engineer]: pending. agent part passed"
sed 's/```checks/```text/' "$BD" >"$T/nochecks.md"
expect "no checks block" 2 bash "$S/run-checks.sh" "$T/nochecks.md" WU1 "$T/logs/x"

echo "# status-record.sh check"
expect "record WU2 attempt" 0 bash "$S/status-record.sh" "$ST" validation WU2 --file "$T/logs/WU2-1/attempt.md"
expect "engineer answers check 2" 0 bash "$S/status-record.sh" "$ST" check WU2 2 passed --evidence "engineer: saw hello"
has "agent evidence kept" "$ST" "agent part passed:"
has "outcome still pending" "$T/out" "outcome: Pending (checks 3)"
expect "engineer answers check 3" 0 bash "$S/status-record.sh" "$ST" check WU2 3 passed
has "outcome Done" "$T/out" "outcome: Done"
expect "no such check" 2 bash "$S/status-record.sh" "$ST" check WU2 9 passed

echo "# validation-checklist.sh"
expect "no open engineer checks" 1 bash "$S/validation-checklist.sh" "$BD" "$ST" WU2
cp "$F/Demo - Task Status.md" "$T/fresh.md"
expect "checklist for a fresh unit" 0 bash "$S/validation-checklist.sh" "$BD" "$T/fresh.md" WU2
has "engineer check listed" "$T/out" "- 3. The greeting looks right in the tool (Engineer)"
has "engineer steps" "$T/out" "Open the tool and run Greet"

echo "# continue-preflight.sh"
expect "preflight (drift, findings)" 1 bash "$S/continue-preflight.sh" "$ST" "$BD"
has "plan drift" "$T/out" "plan: revision 1 -> 2 (drift)"
has "needs model" "$T/out" "needs_model: yes (plan drift"
sed -i 's/plan read: revision 1/plan read: revision 2/' "$BD"
printf '# Result: T03 — x\n- Task status: implemented\n## Files Modified\n- new `src/greet.sh`: g\n## Summary\nok\n' >"$T/T03.md"
bash "$S/status-log.sh" "$ST" "$T/T03.md" >/dev/null
expect "preflight after the plan is read again" 0 bash "$S/continue-preflight.sh" "$ST" "$BD"
has "no model needed" "$T/out" "needs_model: no"
sed -i 's/| T04 | Check the greeting in the tool | Engineer |/| T04 | Check the greeting in the tool | Agent |/' "$ST"
expect "preflight finds an executor mismatch" 1 bash "$S/continue-preflight.sh" "$ST" "$BD"
has "board finding" "$T/out" "board	T04	executor Agent	executor Engineer	fact"

echo "# donewhen.sh"
PL="$T/Demo - Comprehensive Tech Plan.md"
expect "list the plan's items" 0 bash "$S/donewhen.sh" "$PL"
has "flat item" "$T/out" "§1	1	It compiles. (R1)"
has "sub-bullet joined to its heading" "$T/out" "§1	2	After a restart: the settings are still there. (R1)"
hasnt "heading bullet not an item" "$T/out" "After a restart:	"
expect "one step" 0 bash "$S/donewhen.sh" "$PL" "§2"
[ "$(wc -l <"$T/out" | tr -d ' ')" = 1 ] && ok "one step's items only" || bad "one step's items only"

echo "# skeleton scripts"
D="$T/draft"; cp -r "$root/tools/fixtures/demo-draft" "$D"; sed -i "s#PLAN#$PL#" "$D/skeleton.md"
expect "skeleton tasks" 0 bash "$S/skeleton-tsv.sh" "$D/skeleton.md" tasks
expect "skeleton units" 0 bash "$S/skeleton-tsv.sh" "$D/skeleton.md" units
has "range expanded" "$T/out" "WU1	Save settings	T01,T02	Agent"
expect "clean skeleton" 0 bash "$S/skeleton-check.sh" "$D"
cp "$D/skeleton.md" "$T/skeleton.good"
sed -i '/^| §1 #3/d; s/| T03 | Add the greeting | Agent | new `src\/greet.sh` |/| T03 | Add the greeting | Agent | new `src\/greet.sh`; change `build.sh` |/' "$D/skeleton.md"
expect "skeleton with defects" 1 bash "$S/skeleton-check.sh" "$D"
has "missing Done-when item" "$T/out" "donewhen	§1 #3	plan item not in the Done-when map"
has "unchanged file" "$T/out" "files	T03	build.sh is marked unchanged"
cp "$T/skeleton.good" "$D/skeleton.md"
expect "render" 0 bash "$S/skeleton-render.sh" "$D"
has "manifest lists a card" "$D/manifest.txt" "parts/31-WU2-T04.md"
has "task map row" "$D/parts/20-task-map.md" "| T02 | Add the settings loader | Agent | T01 | WU1 | §1 | R2, §1 |"
expect "scaffold WU1" 0 bash "$S/card-scaffold.sh" "$D" WU1
expect "scaffold WU2" 0 bash "$S/card-scaffold.sh" "$D" WU2
has "verbatim Done-when item" "$D/parts/30-WU1.md" "- [ ] After a restart: the loader ran once. (R2) (plan §1) (Agent)"
has "unit check first" "$D/parts/30-WU1.md" "- [ ] No debug prints remain (Agent)"
has "plan link" "$D/parts/31-WU1-T02.md" "[[Demo - Comprehensive Tech Plan#§1. Settings store]]"
has "glossary excerpt" "$D/parts/31-WU1-T02.md" '`R2` "Settings load at start."'
has "confirm item" "$D/parts/31-WU1-T02.md" "**Confirm:** Where the loader logs"
expect "scaffold keeps existing parts" 0 bash "$S/card-scaffold.sh" "$D" WU1
has "skipped" "$T/out" "skipped (exists)"
expect "coverage with markers left" 1 bash "$S/coverage.sh" "$D"
has "fill markers reported" "$T/out" "fill	"
for f in "$D"/parts/3*.md; do sed -i 's/<!-- fill: [^>]*-->/Filled in./g' "$f"; echo '<!-- tt:end -->' >>"$f"; done
sed -i '/^Filled in\.$/d' "$D"/parts/30-*.md
expect "coverage once filled" 0 bash "$S/coverage.sh" "$D"
has "coverage part" "$D/parts/80-coverage.md" "| §1 | T01, T02 | WU1 |"
has "creator named" "$D/parts/80-coverage.md" "| \`src/greet.sh\` | T03 (creates) |"
sed -i '/After a restart: the loader ran once/d' "$D/parts/30-WU1.md"
expect "coverage finds a dropped item" 1 bash "$S/coverage.sh" "$D"
has "dropped item" "$T/out" "donewhen	§1 #3	not found verbatim"

echo "# status-init.sh"
expect "init from the breakdown" 0 bash "$S/status-init.sh" "$BD" "$T/init.md"
has "boards" "$T/init.md" "| T04 | Check the greeting in the tool | Engineer | WU2 | T03 | Todo | |"
has "derived header" "$T/init.md" "- Progress: 0 of 2 units Done · 0 of 4 tasks Implemented or Done"
has "branch from the header" "$T/init.md" "- Branch: \`feature/demo\` (base \`main\`)"
expect "init refuses a second document" 2 bash "$S/status-init.sh" "$BD" "$T/init.md"
expect "the new document is consistent" 0 bash "$S/status-counts.sh" "$T/init.md"

echo "# status-boards.sh"
awk '{ print } /^\| WU1 \| Save settings/ { print "| **Second batch** | | | | |" }' "$BD" >"$T/divider.md"
bash "$S/status-boards.sh" "$T/divider.md" >"$T/boards.md"
grep -q '^|  |' "$T/boards.md" && bad "divider row skipped" || ok "divider row skipped"
[ "$(grep -c '^| WU' "$T/boards.md")" = 2 ] && ok "both units kept" || bad "both units kept"

echo "# CRLF documents"
sed 's/$/\r/' "$F/Demo - Task Status.md" >"$T/crlf.md"
expect "set on a CRLF document" 0 bash "$S/status-set.sh" "$T/crlf.md" T01 "In Progress"
[ "$(grep -c $'\r$' "$T/crlf.md")" = "$(wc -l <"$T/crlf.md" | tr -d ' ')" ] && ok "CRLF kept on every line" || bad "CRLF kept on every line"
ls -a "$T" | grep -q '^\.status-' && bad "temp files left behind" || ok "no temp files left behind"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
