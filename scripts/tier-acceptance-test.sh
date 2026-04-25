#!/usr/bin/env bash
# tier-acceptance-test.sh — Exercise every Tier 1/2/3 dev tool end-to-end.
#
# Each `step <name> <cmd...>` runs the command and verifies it succeeded.
# Each `expect <name> "<bash test>"` runs an assertion against captured state.
# Failures don't abort the run — every tool gets exercised so we see all
# regressions in one pass.
#
# Usage: scripts/tier-acceptance-test.sh [--verbose]

set -uo pipefail

PROJ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJ_DIR"

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

LOG="$(mktemp /tmp/tier-acceptance.XXXXXX.log)"
PASS=0; FAIL=0; STEP=0
declare -a FAILED_STEPS=()

color()  { printf '\e[%sm%s\e[0m' "$1" "$2"; }
green()  { color 32 "$1"; }
red()    { color 31 "$1"; }
yellow() { color 33 "$1"; }

step() {
    local name="$1"; shift
    STEP=$((STEP + 1))
    printf "[%2d] %-45s " "$STEP" "$name"
    {
        echo
        echo "=== STEP $STEP: $name ==="
        echo "+ $*"
    } >> "$LOG"
    if "$@" >> "$LOG" 2>&1; then
        echo "$(green PASS)"
        PASS=$((PASS + 1))
    else
        local rc=$?
        echo "$(red FAIL) (rc=$rc)"
        FAIL=$((FAIL + 1))
        FAILED_STEPS+=("$name")
    fi
}

expect() {
    local name="$1"; shift
    STEP=$((STEP + 1))
    printf "[%2d] %-45s " "$STEP" "$name"
    {
        echo
        echo "=== STEP $STEP (expect): $name ==="
        echo "+ $*"
    } >> "$LOG"
    if eval "$@" >> "$LOG" 2>&1; then
        echo "$(green PASS)"
        PASS=$((PASS + 1))
    else
        echo "$(red FAIL)"
        FAIL=$((FAIL + 1))
        FAILED_STEPS+=("$name")
    fi
}

run_silent() { "$@" >> "$LOG" 2>&1; }

echo "════════════════════════════════════════════════════════════════"
echo "  Tier 1/2/3 Acceptance Test"
echo "  Log: $LOG"
echo "════════════════════════════════════════════════════════════════"

# Pre-flight: clean slate, seed deterministic data
run_silent bin/yclean
run_silent bin/yeval 'do add^tasks("alpha")  do add^tasks("beta")  do add^tasks("gamma")  do done^tasks(2)  do log^trace("setup","seed complete")'

echo
echo "── Tier 1 ──────────────────────────────────────────────────────"

step "ytest (one suite)"            bin/ytest TASKSTST
step "ytest (one test)"             bin/ytest tasks tAddReturnsId
step "ytest (error path: bad suite)" bash -c '! bin/ytest doesnotexist 2>&1'
step "ytest (error path: bad label)" bash -c '! bin/ytest tasks tNoSuchLabel 2>&1'

step "yclean --list"                bin/yclean --list
step "yclean tasks"                 bin/yclean tasks
expect "yclean wiped ^tasks"        '[[ "$(bin/yeval "write \$\$count^tasks()")" == "0" ]]'
run_silent bin/yeval 'do add^tasks("seed-after-clean")'

step "ywhat tasks"                  bin/ywhat tasks
step "ywhat TASKSTST"               bin/ywhat TASKSTST
step "ywhat --all"                  bin/ywhat --all
step "ywhat (error: missing routine)" bash -c '! bin/ywhat doesnotexist 2>&1'

step "ylog backfill (timed)"        bash -c 'tmp=$(mktemp); timeout 1.0 bin/ylog --n 3 > "$tmp" 2>&1 || true; grep -q "streaming" "$tmp"; rc=$?; rm -f "$tmp"; exit $rc'

step "yhook install"                bin/yhook install
expect "yhook hook file exists"     '[[ -f .git/hooks/pre-commit ]]'
expect "yhook hook is yhook-managed" 'grep -q "yhook-managed" .git/hooks/pre-commit'
step "yhook status"                 bin/yhook status
step "yhook run"                    bin/yhook run
step "yhook uninstall"              bin/yhook uninstall
expect "yhook hook removed"         '[[ ! -f .git/hooks/pre-commit ]]'

step "yci (full)"                   bin/yci
step "yci --fast"                   bin/yci --fast
step "yci --report"                 bin/yci --report
expect "yci report file exists"     '[[ -s /tmp/yci-report.txt ]]'

echo
echo "── Tier 2 ──────────────────────────────────────────────────────"

# Re-seed: Tier 1 ran yhook + yci which run ytest, which clears ^tasks via
# TASKSTST's setup/teardown. Restore deterministic state for the I/O tools.
run_silent bin/yclean
run_silent bin/yeval 'do add^tasks("alpha")  do add^tasks("beta")  do add^tasks("gamma")  do done^tasks(2)  do log^trace("setup","tier2 seed")'

step "yexport (json)"               bash -c 'bin/yexport tasks taskSeq > /tmp/acc.json'
expect "yexport json valid"         'python3 -c "import json; d=json.load(open(\"/tmp/acc.json\")); assert len(d)>0"'

step "yexport (raw)"                bash -c 'bin/yexport --format raw tasks > /tmp/acc.raw'
expect "yexport raw has ^tasks"     'grep -q "^\^tasks" /tmp/acc.raw'

step "yexport (zwr)"                bash -c 'bin/yexport --format zwr tasks > /tmp/acc.zwr 2>&1'
expect "yexport zwr has ZWR header" 'grep -q ZWR /tmp/acc.zwr'

step "yseed (json roundtrip)"       bash -c 'bin/yclean tasks && bin/yseed /tmp/acc.json'
expect "yseed restored ^tasks"      '[[ "$(bin/yeval "write \$\$exists^tasks(1)")" == "1" ]]'

step "yseed (raw roundtrip)"        bash -c 'bin/yclean tasks && bin/yseed --format raw /tmp/acc.raw'
expect "yseed --raw restored data"  '[[ "$(bin/yeval "write \$\$count^tasks()")" -gt "0" ]]'

step "yseed --clean (json)"         bash -c 'bin/yseed --clean /tmp/acc.json'
expect "yseed --clean preserved data" '[[ "$(bin/yeval "write \$\$count^tasks()")" -gt "0" ]]'

step "ydiff --reset"                bin/ydiff --reset
step "ydiff before"                 bin/ydiff before
step "ydiff after (no changes)"     bash -c 'out=$(bin/ydiff after); [[ "$out" == "(no changes)" ]]'
step "ydiff inline mode"            bash -c 'out=$(bin/ydiff -- bin/yeval "do add^tasks(\"diff-test\")"); echo "$out" | grep -q "^+"'

step "yglobsize (default)"          bin/yglobsize
step "yglobsize tasks"              bin/yglobsize tasks
expect "yglobsize shows ^tasks"     'bin/yglobsize tasks 2>&1 | grep -q "\^tasks"'

step "yrundown --dry"               bin/yrundown --dry
expect "yrundown --dry refuses live" 'bin/yrundown --dry 2>&1 | grep -q "DRY:"'

step "ytest-watch-smart (touch detect)" bash -c '
    tmp=$(mktemp); bin/ytest-watch-smart --interval 0.3 > "$tmp" 2>&1 &
    pid=$!
    sleep 0.6
    touch routines/hello.m
    sleep 1.5
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
    grep -q "ytest HELLOTST" "$tmp"
    rc=$?
    rm -f "$tmp"
    exit $rc
'

echo
echo "── Tier 3 ──────────────────────────────────────────────────────"

step "ynew --dry"                   bin/ynew --dry probe
step "ynew (live)"                  bin/ynew probe
expect "ynew created module"        '[[ -f routines/probe.m ]]'
expect "ynew created test"          '[[ -f routines/tests/PROBETST.m ]]'
expect "ynew injected Makefile"     'grep -q "^PROBETST" Makefile || grep -q "PROBETST" Makefile'
step "ynew test passes"             bin/ytest probe
# Cleanup ynew artifacts
run_silent bash -c 'rm -f routines/probe.m routines/tests/PROBETST.m routines/probe.o routines/tests/PROBETST.o'
run_silent python3 -c "
import pathlib
mk = pathlib.Path('Makefile')
txt = mk.read_text()
inject = '\t@echo \"==> Running PROBETST...\"\n\t@\$(YDB) -run ^PROBETST\n'
mk.write_text(txt.replace(inject, ''))
"
expect "Makefile cleaned of PROBE"  '! grep -q "PROBETST" Makefile'

step "ydoc tasks"                   bash -c 'bin/ydoc tasks > /tmp/acc-doc.md'
expect "ydoc emits H2 heading"      'grep -q "^## .tasks." /tmp/acc-doc.md'
step "ydoc --all --out"             bin/ydoc --all --out /tmp/acc-doc-all.md
expect "ydoc --all wrote a file"    '[[ -s /tmp/acc-doc-all.md ]]'

step "ytap (one suite)"             bash -c 'bin/ytap HELLOTST > /tmp/acc.tap'
expect "ytap has TAP version line"  'head -1 /tmp/acc.tap | grep -q "^TAP version 13"'
expect "ytap has plan line"         'tail -1 /tmp/acc.tap | grep -qE "^1\.\."'

step "yperf (small N)"              bin/yperf -n 20 'set x=1+2+3'
expect "yperf reports stats"        'bin/yperf -n 10 "set x=1+2" 2>&1 | grep -q "mean="'

step "ysnapshot create"             bin/ysnapshot create acc-snap 'do list^tasks()'
step "ysnapshot check (match)"      bin/ysnapshot check acc-snap 'do list^tasks()'
step "ysnapshot list shows entry"   bash -c 'bin/ysnapshot list | grep -q acc-snap'
step "ysnapshot detects change"     bash -c '! bin/ysnapshot check acc-snap "write \"different\",!"'
step "ysnapshot update"             bin/ysnapshot update acc-snap 'do list^tasks()'
step "ysnapshot rm"                 bin/ysnapshot rm acc-snap

step "ycover (table)"               bin/ycover
step "ycover --uncovered"           bin/ycover --uncovered
step "ycover --json (parseable)"    bash -c 'bin/ycover --json | python3 -c "import json,sys; d=json.load(sys.stdin); assert d[\"total\"] > 0"'

# Final cleanup of acceptance fixtures
run_silent rm -f /tmp/acc.json /tmp/acc.raw /tmp/acc.zwr /tmp/acc-doc.md /tmp/acc-doc-all.md /tmp/acc.tap /tmp/yci-report.txt
run_silent bin/yclean
run_silent bin/ydiff --reset

echo
echo "════════════════════════════════════════════════════════════════"
TOTAL=$((PASS + FAIL))
if [[ "$FAIL" -eq 0 ]]; then
    echo "  $(green ALL PASS): $PASS / $TOTAL steps"
else
    echo "  $(red FAILED): $FAIL of $TOTAL steps"
    echo "  Failed steps:"
    for s in "${FAILED_STEPS[@]}"; do
        echo "    - $s"
    done
fi
echo "  Log: $LOG"
echo "════════════════════════════════════════════════════════════════"

if (( VERBOSE )); then
    echo
    cat "$LOG"
fi

[[ "$FAIL" -eq 0 ]]
