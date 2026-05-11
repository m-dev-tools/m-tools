---
created: 2026-04-27
last_modified: 2026-04-27
revisions: 1
doc_type: [REFERENCE, STATUS]
---

# M Development Toolchain — Implementation

**Document type:** Implementation status + as-built specifications
**Scope:** Shell tools, MUMPS routines, and integration patterns shipped under `~/projects/m-tools/`
**Audience:** Developers using or contributing to the toolchain
**Sibling document:** [gap-analysis-and-remediation-strategy.md](gap-analysis-and-remediation-strategy.md) — the strategy this implements

---

## Scope and portability

This document tracks the as-built state of the M development toolchain in this repository. The strategic context — what gaps the toolchain is trying to close, why each tool was prioritised — lives in [gap-analysis-and-remediation-strategy.md](gap-analysis-and-remediation-strategy.md).

The toolchain is conceptually portable across M (MUMPS) implementations (InterSystems IRIS, YottaDB, GT.M), since M itself is a standardised language. In practice this project uses **YottaDB as the foundation runtime**: it is the only fully open-source M runtime under active maintenance (AGPL-3.0), which makes the entire stack reproducible without licence negotiation, and its command-line surface (`mupip`, `gde`, `lke`, `dse`, `%XCMD`, the `ydb` runtime) gives a concrete substrate to integrate with. Source-only tools (formatters, linters, doc generators built on `tree-sitter-m`) are portable across implementations; runtime-bound tools (test runner, coverage, trace tail) are YottaDB-specific until a runtime-adapter layer is added. YottaDB-specific tooling is not wrapped or renamed — it is used directly.

The shell-level naming convention now in plan reflects this split:

- **`m <subcommand>`** for portable, source-level operations (`m fmt`, `m lint`, `m check`)
- **`ydb <subcommand>`** for YottaDB runtime-bound operations (`ydb test`, `ydb cover`, `ydb export`)
- **Vendor tools** (`mupip`, `gde`, `lke`, `dse`, `ydb` runtime itself, in-runtime debug commands) are used directly, not wrapped.

The **canonical command map (`m help`)** below is the discovery surface for the entire ecosystem. Existing `y*` shell scripts retain their current names; the planned `m`/`ydb` umbrella renaming is a future step and is documented for forward planning, not yet implemented.

---

## Table of Contents

- [1. Canonical Command Map (`m help`)](#1-canonical-command-map-m-help)
- [2. Current Custom Toolchain](#2-current-custom-toolchain)
- [3. As-Built Tool Specifications](#3-as-built-tool-specifications)
- [4. Implementation Status](#4-implementation-status)
- [5. Per-Tool Implementation Detail](#5-per-tool-implementation-detail)
  - [5.1 Per-tool delta vs. original spec](#51-per-tool-delta-vs-original-spec)
  - [5.2 New helper module: `routines/yutil.m`](#52-new-helper-module-routinesyutilm)
  - [5.3 Acceptance test catalog](#53-acceptance-test-catalog)
  - [5.4 Outstanding follow-ups](#54-outstanding-follow-ups)
  - [5.5 Parser-project split](#55-parser-project-split)

---

## 1. Canonical Command Map (`m help`)

This is the single discovery surface for the toolchain. Three groups of commands operate side-by-side:

1. **Project commands** (the `y*` shell scripts in `bin/`) — what's shipped today.
2. **YottaDB vendor tools** (`mupip`, `gde`, `lke`, `dse`, the `ydb` runtime) — used directly, not wrapped. Their own `--help` is canonical; this map just notes their existence so you know they're part of the toolchain.
3. **In-runtime debug commands** — accessed inside a `ydb` direct-mode session.

A future renaming (see [gap-analysis-and-remediation-strategy.md → Tier 4](gap-analysis-and-remediation-strategy.md#34-tier-4--long-term--aspirational)) will introduce two umbrella dispatchers: `m <subcommand>` for source-only / portable operations, and `ydb <subcommand>` for YottaDB-runtime-bound operations. The existing `y*` names remain in place for now.

### 1.1 Project commands — source-only

Operate on `.m` text without invoking the runtime. Portable in principle to any conformant M implementation.

| Command (today) | Future name | Description |
|-----------------|-------------|-------------|
| `ywhat` | `m symbols` | List labels and signatures in a `.m` file |
| `yhook` | `m hook` | Install / manage git pre-commit hook |
| `yci` | `m ci` | Orchestrate full CI pipeline (delegates to runtime tools) |
| `ynew` | `m new` | Scaffold module + test |
| `ydoc` | `m doc` | Generate Markdown docs from `.m` source |
| `ysnapshot` | `m snapshot` | Snapshot-test fixtures (text-file diff) |
| `ytest-watch-smart` | `m watch` | File watcher → triggers `ydb test` |

### 1.2 Project commands — runtime-bound

Invoke `$YDB`, `mupip`, or YDB intrinsics (`%XCMD`, `ZBREAK`, `$ZHOROLOG`).

| Command (today) | Future name | Description |
|-----------------|-------------|-------------|
| `yeval` | `ydb eval` | Run any MUMPS expression via `%XCMD` |
| `ycheck` | `ydb check` | Syntax-check via `zcompile` |
| `ystate` | `ydb state` | Snapshot of globals + routines + recent trace |
| `ytest` | `ydb test` | Run one suite or one test |
| `yclean` | `ydb clean` | Reset named global groups |
| `ylog` | `ydb log` | Live tail of `^trace` |
| `yexport` | `ydb export` | Export globals (json / zwr / raw) |
| `yseed` | `ydb seed` | Load fixture data into globals |
| `ydiff` | `ydb diff` | Database state diff |
| `yglobsize` | `ydb gsize` | Report nodes + storage per global |
| `yrundown` | `ydb rundown` | Crash / lockup cleanup |
| `yperf` | `ydb bench` | Benchmark via `$ZHOROLOG` |
| `ycover` | `ydb cover` | Coverage approximation (label-entry, ZBREAK-based) |
| `ytap` | `ydb test --format=tap` | TAP-13 output (will fold into `ydb test`) |

### 1.3 App-specific (not toolchain)

| Command | Description |
|---------|-------------|
| `yserve` | Start the HTTP/JSON server (project app code, not part of the toolchain) |
| `gtree` | Visualize any global as a tree (shipped helper utility) |
| `tasks` | Task-manager CLI (project app) |

### 1.4 YottaDB vendor tools — use directly

Documented in detail in [gap-analysis-and-remediation-strategy.md → Appendix C](gap-analysis-and-remediation-strategy.md#appendix-c-what-ships-with-yottadb-foundation-runtime).

| Tool | Purpose |
|------|---------|
| `ydb` (runtime) | Direct mode (`ydb` interactive); `-run` mode (`ydb -run ^routine`); the foundation runtime |
| `mupip` | Database management (`mupip extract` / `load` / `size` / `rundown` / `integ` / …) |
| `gde` | Global directory editor — configure which globals live in which database files |
| `lke` | Lock examination — inspect and clear stuck `LOCK` entries |
| `dse` | Database structure editor — block-level recovery (dangerous; recovery scenarios only) |

### 1.5 In-runtime debug commands

When inside a `ydb` direct-mode session:

| Command | Effect |
|---------|--------|
| `ZBREAK label` / `ZBREAK label:"cond"` | Set (conditional) breakpoint |
| `ZSTEP INTO` / `ZSTEP OVER` / `ZSTEP OUTOF` | Step execution |
| `ZSHOW "V"` / `"G"` / `"L"` / `"S"` / `"A"` | Inspect locals / globals / locks / stack / all |
| `ZWRITE var` | Print a variable in MUMPS `SET` syntax |
| `ZPRINT label^routine` | Print source of a label or routine |
| `ZCONTINUE` | Resume after a breakpoint |
| `$ZPOSITION` | Current routine + label + offset |

### 1.6 Optional aliases for tab-completion consistency

If you want vendor tools to appear under a unified `m-` prefix for tab completion, source `m-aliases.sh`:

```bash
alias m-mupip='mupip'   alias m-gde='gde'   alias m-lke='lke'
alias m-dse='dse'       alias m-ydb='ydb'
```

Vendor tools remain unwrapped — these are pure shell aliases for muscle-memory consistency.

---

## 2. Current Custom Toolchain

| Tool | Type | Description |
|------|------|-------------|
| `yeval` | Shell | Run any MUMPS expression from the shell via `%XCMD`; one-shot evaluation |
| `ycheck` | Shell | Syntax-check one or all `.m` files via `zcompile`; exit code 1 on failure |
| `ystate` | Shell | Snapshot: active globals (via `mupip size`), `.m` file list + sizes, recent `^trace` |
| `gtree` | Shell | Visualize any global as a tree (`├──`/`└──` connectors); wraps `show^gtree` |
| `tasks` | Shell | CLI for the task manager: `add`, `list`, `done`, `undone`, `del`, `show`, `clear-done` |
| `yserve` | Shell | Start the HTTP/JSON server on a given port; wraps `start^server` |
| `make test` | Make | Run all 11 test suites in sequence; prints pass/fail summary |
| `make lint` | Make | Run `ycheck --all` across all routines |
| `make watch` | Make | Use `entr` to rerun `make test` on any `.m` file change |
| `make check-env` | Make | Verify `YDB_DIST` set and database initialized |
| `make install` | Make | Install YottaDB and initialize the database |
| `make install-munit` | Make | Install M-Unit testing framework |

**Pre-Tier-1 totals:** 6 shell tools, 6 Makefile targets — the project's original baseline before the gap-analysis-driven Tier 1–3 work shipped (see [§4 Implementation Status](#4-implementation-status)).

---

## 3. As-Built Tool Specifications

For each Tier 1 and Tier 2 tool, a brief specification reflecting the shipped state. (These were originally written as forward-looking specs in the gap analysis; they are kept here as as-built reference. For deltas between original spec and shipped reality, see [§5.1](#51-per-tool-delta-vs-original-spec).)

---

### `ytest` — Run one suite or one test

```
Usage:
  ytest                        # run all suites (same as make test)
  ytest TASKSTST               # run one suite
  ytest TASKSTST tByDone       # run one labeled test within a suite

How it works:
  - With no args: delegates to make test
  - With suite name: runs $YDB -run ^SUITENAME; filters output
  - With suite + label: injects a modified entry point that calls only
    the named label, then calls report^TESTRUN

Implementation notes:
  - Suite name is uppercased automatically (tasks → TASKSTST by convention)
  - Needs a small MUMPS helper or can use XECUTE to call a single label
  - Exit code 1 if any failures
```

---

### `yclean` — Reset test globals

```
Usage:
  yclean                       # kill all known test globals
  yclean tasks                 # kill only tasks-related globals
  yclean trace                 # kill only trace globals
  yclean --all                 # kill all globals (dangerous — confirms first)

Globals cleaned by default:
  ^tasks, ^taskSeq, ^tasksByDone, ^tasksByFirst
  ^trace, ^traceSeq
  ^lastError
  ^txnTest, ^txnAcct
  ^idxTest
  (configurable via a list in the script)

How it works:
  - Single yeval call with kill commands
  - --all uses mupip extract to list globals, then kills each
```

---

### `ylog` — Live trace tail

```
Usage:
  ylog                         # stream new ^trace entries as they appear
  ylog --n 50                  # show last 50 first, then stream
  ylog --clear                 # clear log then stream
  ylog --filter "server"       # only show entries where ctx matches pattern

How it works:
  - Reads current $traceSeq
  - Loop: sleep 0.2s; read new entries since last seq; print them
  - Ctrl-C to stop
  - Uses yeval 'write $$count^trace()' to poll for new entries
```

---

### `ywhat` — List labels and signatures in a .m file

```
Usage:
  ywhat tasks                  # list all labels in routines/tasks.m
  ywhat TASKSTST               # list all labels in routines/tests/TASKSTST.m
  ywhat --all                  # list all labels in all .m files

Output format:
  tasks.m:
    add(title)                 — line 15
    done(id)                   — line 27
    undone(id)                 — line 33
    ...

How it works:
  - grep/awk for column-1 lines (labels) in .m files
  - Extract label name + parameters from the line
  - Show line number
  - Optionally extract the first ; comment line after the label as description
```

---

### `yhook` — Install git pre-commit hook

```
Usage:
  yhook install                # install pre-commit hook
  yhook uninstall              # remove pre-commit hook
  yhook run                    # run the hook manually

Hook behavior (runs before every git commit):
  1. ycheck --all              (syntax check all routines)
  2. make test                 (run full test suite)
  If either fails: abort commit, print what failed

How it works:
  - Writes to .git/hooks/pre-commit
  - Sets executable bit
  - Sources ydb-env.sh to ensure environment is set
```

---

### `yci` — Full CI pipeline

```
Usage:
  yci                          # run full pipeline
  yci --fast                   # skip tests, lint only
  yci --report                 # generate summary report file

Pipeline steps (in order, stop on first failure):
  1. make check-env            — environment verification
  2. ycheck --all              — syntax check
  3. make test                 — all test suites
  4. yglobsize                 — (informational) print global sizes
  5. print summary

Exit code: 0 if all pass, 1 if anything fails
Suitable for use in GitHub Actions or any CI runner.
```

---

### `ydiff` — Database state diff

```
Usage:
  ydiff before                 # take a snapshot (saves to /tmp/ydiff-before.zwr)
  ydiff after                  # take a snapshot (saves to /tmp/ydiff-after.zwr)
  ydiff                        # take before, run last command, show diff
  ydiff -- yeval 'do something^mymod()'  # snapshot before+after this command

Output format (like git diff):
  + ^tasks(5) = "New task"
  + ^tasks(5,"done") = "0"
  + ^tasks(5,"created") = "66123,45678"
  ~ ^taskSeq = "4" → "5"
  - ^txnTest("x") = "42"       (deleted)

How it works:
  - Uses mupip extract to dump all globals to ZWR format
  - Diff the two ZWR files
  - Parse and format the diff for readability
  - Accepts a --globals flag to restrict which globals to watch
```

---

### `yexport` — Export globals to JSON

```
Usage:
  yexport tasks                # export ^tasks to stdout as JSON
  yexport tasks > fixture.json # save to file
  yexport tasks trace          # export multiple globals
  yexport --format zwr tasks   # export in ZWR format (mupip native)

JSON output format:
  {
    "tasks": {
      "1": { "_value": "Learn MUMPS", "done": "0", "created": "66123,0" },
      "2": { "_value": "Write tests", "done": "1", "created": "66123,1" }
    }
  }

How it works:
  - MUMPS routine walks global with $ORDER/$QUERY
  - Emits JSON using json.m
  - Shell wrapper calls the routine and captures output
```

---

### `yseed` — Load fixture data

```
Usage:
  yseed fixture.json           # load globals from JSON fixture
  yseed --clean fixture.json   # yclean first, then load
  yseed fixtures/tasks.json    # load from fixtures directory

How it works:
  - Parse JSON in shell (jq required)
  - For each global node: drive yeval 'set ^global(sub)=value'
  - Or: generate a temporary .m file with SET statements and run it
  - Reports count of nodes loaded

Convention: fixtures/ directory in project root
```

---

### `yglobsize` — Global size report

```
Usage:
  yglobsize                    # report all globals
  yglobsize tasks              # report ^tasks only
  yglobsize --watch            # re-report every 2s

Output:
  Global              Nodes    Est. Size
  ──────────────────────────────────────
  ^tasks                  5      < 1 KB
  ^tasksByDone            4      < 1 KB
  ^tasksByFirst           4      < 1 KB
  ^trace                 12      < 1 KB
  ──────────────────────────────────────
  Total                  25      < 1 KB

How it works:
  - mupip size for storage estimates
  - $ORDER walk for node counts (or mupip size -select)
  - Formatted output
```

---

## 4. Implementation Status

Last update: 2026-04-27.

| Tier | Tools | Status |
|------|-------|--------|
| **Tier 1** | ytest, yclean, ywhat, ylog, yhook, yci | ✅ **6/6 done** — committed, all green |
| **Tier 2** | yexport, yseed, ydiff, yglobsize, yrundown, ytest-watch-smart | ✅ **6/6 done** — committed, all green |
| **Tier 3** | ynew, ydoc, ytap, yperf, ysnapshot, ycover | ✅ **6/6 done** — committed, all green |
| **Tier 4** | yfmt, ylint-deep, ydebug, yrepl, yparallel | 🟢 **Unblocked** — parser foundation now shipped (see below). Tools themselves not yet built; ready to start as downstream consumers of [`tree-sitter-m`](https://github.com/rafael5/tree-sitter-m). |

### 4.1 Parser-foundation status (the unlock for Tier 4)

| Project | Purpose | Status |
|---------|---------|--------|
| **[`m-standard`](https://github.com/rafael5/m-standard)** (`~/projects/m-standard/`) | Integrated, citable, machine-readable reference for the M language. Reconciles AnnoStd (ISO 11756), YottaDB docs, IRIS docs, and VA SAC/XINDEX into a unified grammar-surface JSON. | ✅ **v1.0 tagged** for AnnoStd + YottaDB scope; end-to-end pipeline green; all 9 validation gates passing on every CI run. v0.2 in progress for IRIS + SAC additions. |
| **[`tree-sitter-m`](https://github.com/rafael5/tree-sitter-m)** (`~/projects/tree-sitter-m/`) | Production tree-sitter grammar for M, generated from `m-standard`'s grammar-surface (949 keyword forms, schema-pinned). Bindings scaffolded for Node / Rust / Python / Go. | ✅ **v1.0 grammar work complete.** 99.06% clean on the full 39,330-routine VistA corpus (162 MB, 4.7 MB/s); 100% of clinical packages. 10k-line synthesised routine parses in 78.6 ms (under the 100 ms spec budget). 110 corpus tests + 19 lib tests + 347/347 keyword-coverage triples all green. **Remaining for v1.0 release:** publish bindings to npm/crates.io/PyPI/Go, AD-03 stamping integration, perf budget in CI. |
| **[`tree-sitter-m-vscode`](https://github.com/rafael5/tree-sitter-m-vscode)** (`~/projects/tree-sitter-m-vscode/`) | VS Code extension for M. Two-layer highlighting: TextMate grammar for cold-load + `DocumentSemanticTokensProvider` powered by `tree-sitter-m` compiled to WASM. | ✅ **v0.1 working.** `vsce package` produces a 1.27 MB `.vsix` bundling the parser WASM + web-tree-sitter runtime. Marketplace `vsce publish` gated only on a Personal Access Token from dev.azure.com. Editor demonstration criterion #8 in `tree-sitter-m`'s spec is implementation-complete. |

**Acceptance test:** [`scripts/tier-acceptance-test.sh`](../scripts/tier-acceptance-test.sh) — 70 steps cover every Tier 1/2/3 tool. Last run 2026-04-25: 70/70 PASS. Catalog at [§5.3](#53-acceptance-test-catalog).

---

## 5. Per-Tool Implementation Detail

### 5.1 Per-tool delta vs. original spec

For each shipped tool, what changed from the [§3 As-Built Specifications](#3-as-built-tool-specifications) above (originally written as forward-looking specs) and why.

| Tool | Spec said | Built | Delta / Reason |
|------|-----------|-------|----------------|
| **ytest** | suite + label routing | suite + label + `make test` delegation | `ytest` with no args delegates to `make test`. Name resolution is verbatim → uppercase → +`TST` (so both `tasks` and `TASKSTST` work). `report^TESTRUN`'s `halt` returns 0 even on failure — exit code is detected by grepping for `N test(s) FAILED` in captured output. |
| **yclean** | hard-coded list + `--all` via mupip extract | named groups + `--list` | Replaced single-list with 7 named groups (`tasks`, `trace`, `safe`, `txn`, `idx`, `fixtures`, `demo`) so partial cleans are safe. `--all` mupip path was not needed; `yclean` with no args wipes every group. |
| **ylog** | poll + filter | poll + backfill (`--n N`) + filter + clear | Added `--n N` backfill and `--clear`. Poll uses `$$count^trace()` then a sequential `for s=N+1:1:M` (denser than `$ORDER` since `^traceSeq` is `$INCREMENT`-driven). |
| **ywhat** | grep/awk for column-1 lines | awk only | Single awk script handles label parsing + comment extraction + `;@TEST` decoration stripping. No `--all` performance issues at current scale. |
| **yhook** | install/uninstall/run | + `status`; refuses to overwrite hand-written hooks | Added marker line check (`# yhook-managed`) — `uninstall` refuses to remove anything yhook didn't install. |
| **yci** | `--fast`, `--report` | `--fast`, `--report`, `--help` | Skipped the `yglobsize` step from the original spec (informational only); pipeline is now `check-env → ycheck → ytest`. Per-step timing emitted. |
| **ydiff** | mupip extract before/after + ZWR diff | flat `dump^yutil` + `diff -u` + awk to merge `-`/`+` into `~` | Skipped ZWR parsing entirely. Sorted flat dumps are simpler to diff and the `-`/`+` → `~` collapse in awk produces git-style output. |
| **yexport** | JSON via `$ORDER` walk | JSON + ZWR + raw | Three formats. Default JSON, `--format zwr` delegates to `mupip extract`, `--format raw` is the format `ydiff` consumes. mupip's "won't overwrite" behavior required `mktemp -u`. |
| **yseed** | parse JSON + drive `set` | auto-detect JSON / ZWR / raw + `--clean` | Format auto-detected from first non-blank byte (`[`, `^`, or `YottaDB MUPIP EXTRACT`). JSON path uses python3 to emit `set @"<ref>"="<val>"` commands and pipes through `$YDB -direct`. |
| **yglobsize** | wrap `mupip size` + node counts | exact node count + storage blocks | Node count via `count^yutil` (since argless `for` fails through `%XCMD`). `mupip size` writes to stderr — `2>&1` redirect was needed. Skips empty globals silently. |
| **yrundown** | wrap `mupip rundown` + `lke clear` | + safety guard (refuses if other YDB procs alive) + `--dry`/`--locks`/`--db` | Original spec didn't include the alive-process check, but it's load-bearing — running `mupip rundown` while another process holds the region corrupts state. |
| **ytest-watch-smart** | map filename to suite | filename mapping + polling-based file watcher | No `entr`/`inotifywait`/`fswatch` dep — pure `stat -c %Y` polling at configurable interval. Initial pass records mtimes; subsequent ticks detect and dispatch. |
| **ynew** | template + Makefile injection | template + python3 Makefile injection + `--dry`/`--no-make` | Makefile injection uses python3 (clean string replacement against the `All suites passed.` marker) rather than awk/sed which would have struggled with multi-line targets. |
| **ydoc** | awk on `.m` files → Markdown | awk on `.m` files → Markdown | As specified. Skips `tXxx` test labels and `;@TEST` decorations automatically. |
| **ytap** | wrap TESTRUN.m for TAP | wrap `ytest` output for TAP-13 | Wraps `ytest` rather than modifying `TESTRUN.m`. Per-suite `# suite: NAME` comments emitted. |
| **yperf** | $ZHOROLOG loop + stats | `bench^yutil` + awk stats | MUMPS does the timing loop; awk does stats (mean, median, p95, min, max, stddev, outliers). 3 warmup iterations not counted. |
| **ysnapshot** | capture + diff + update | `create`/`check`/`update`/`list`/`show`/`rm` | Snapshots in `fixtures/snapshots/<name>.txt`. `check` returns 1 on diff; printed as `diff -u` output. |
| **ycover** | ZBREAK or `$STACK` instrumentation | ZBREAK at every label, single-process run | Single YDB `-direct` session sets ZBREAK on every discovered label, runs all suites, then dumps `^ycov`. Per-routine table + JSON + uncovered-only modes. **Caveat:** label-entry coverage only — not line/branch. |

### 5.2 New helper module: `routines/yutil.m`

Not in the original plan. Created during Tier 2 because `%XCMD`'s wrapper (line 22 of `_XCMD.m`) prepends `new $ETRAP,$zcmdline set $ETRAP=etrap ` to the user's code with only one space separator, which breaks argless `FOR` loops with `%YDB-E-EQUAL, Equal sign expected but not found`. Non-trivial walks now live in `yutil.m` and are invoked as `$YDB -run <label>^yutil <arg>`.

| Label | $ZCMDLINE | Used by |
|-------|-----------|---------|
| `count` | `<gname>` | `yglobsize`, acceptance test |
| `dump` | `<gname>` | `ydiff`, `yexport --format raw` |
| `exportJson` | `<gname>` | `yexport` (default) |
| `bench` | `<iters>\|<code>` | `yperf` |
| `listGlobals` | (ignored) | (reserved for future use) |

### 5.3 Acceptance test catalog

[`scripts/tier-acceptance-test.sh`](../scripts/tier-acceptance-test.sh) — 70 steps across the three tiers. Last run 2026-04-25: **70/70 PASS**.

Coverage per tool:

| Tool | Steps |
|------|-------|
| ytest | 4 (one suite, one test, bad suite, bad label) |
| yclean | 3 (`--list`, `tasks`, post-clean assertion) |
| ywhat | 4 (one routine, test routine, `--all`, missing routine) |
| ylog | 1 (timed backfill mode) |
| yhook | 7 (install/status/run/uninstall + 3 file-state assertions) |
| yci | 4 (full / `--fast` / `--report` + report-file assertion) |
| yexport | 6 (json/raw/zwr × output + content assertions) |
| yseed | 6 (json/raw/`--clean` × roundtrip + restored-data assertions) |
| ydiff | 4 (`--reset` / `before` / `after` no-change / inline mode) |
| yglobsize | 3 (default / specific globals / contains-^tasks) |
| yrundown | 2 (`--dry` mode + format check) |
| ytest-watch-smart | 1 (touch detection via background process) |
| ynew | 6 (`--dry` / live / module-exists / test-exists / Makefile-injected / test-passes / cleanup-verified) |
| ydoc | 4 (one routine / H2-heading / `--all --out` / file-non-empty) |
| ytap | 3 (one suite / version-line / plan-line) |
| yperf | 2 (small N / mean-stat-emitted) |
| ysnapshot | 6 (full lifecycle: create/check/list/detect-change/update/rm) |
| ycover | 3 (table / `--uncovered` / `--json` parseable) |

The script is self-contained: re-seeds deterministic data between Tier 1 and Tier 2 (since `yhook run` and `yci` both invoke `ytest`, which clears `^tasks` via `TASKSTST`'s setup/teardown), and cleans up all temp fixtures + snapshot files at the end.

### 5.4 Outstanding follow-ups

Tracked in [`TODO.md`](../TODO.md):

1. **`ystate.m:12` parse error** — quote-escaping bug in the `$order` indirection. Fix is one-line; deferred because `yglobsize` already covers the same job correctly.
2. **`bin/ycheck` exit-code masks zcompile errors** — `if cmd 2>&1; then` silently passes broken files. This is what *hid* issue #1 from the existing `make lint`. Fix: capture combined output and grep for `%YDB-E-` before declaring success.

### 5.5 Parser-project split

This project (`m-tools`) is a hub that integrates outputs from sibling projects rather than absorbing them. Two reasons the parser work lives in separate repos:

1. **Different audiences.** `m-tools` is a personal MUMPS toolchain workspace. The parser projects are infrastructure that other tools (and other people) should be able to depend on. Mixing them confuses both.
2. **Different lifecycles.** Shell tools change weekly; a grammar should be stable for years. A version-pinned dependency boundary makes that explicit.

**Realised layout (2026-04-27):**

```
~/projects/m-standard/         # spec layer — reconciled grammar-surface JSON
                               # (AnnoStd + YDB + IRIS + SAC), conformance
                               # corpora, ADRs. v1.0 tagged for AnnoStd+YDB.

~/projects/tree-sitter-m/      # implementation layer — production tree-sitter
                               # grammar generated from m-standard's
                               # grammar-surface. 99.06% on VistA. Bindings
                               # for Node/Rust/Python/Go.

~/projects/tree-sitter-m-vscode/ # VS Code extension. Two-layer highlighting:
                               # TextMate grammar + tree-sitter-m WASM
                               # semantic-tokens. Demonstrates the editor-
                               # integration success criterion end-to-end.

~/projects/m-tools/            # this repo — the hub. Shell tools + MUMPS
                               # routines. Could later add `ydb-pkg` once
                               # m-standard finalises the dependency-manifest
                               # format.
```

**Delta from the original plan.** The original plan called for a single `m-grammar` repo housing both a Lark implementation (Phase 1, for grammar iteration) and a Tree-sitter implementation (Phase 2, for IDE integration). In practice, `m-standard`'s schema-pinned grammar-surface JSON gave enough structure to drop straight into Tree-sitter — `tree-sitter-m/tools/build-grammar.js` reads the grammar-surface and emits keyword tables, so grammar changes are spec-driven. The Lark phase was skipped, and `m-grammar` collapsed into `tree-sitter-m`.

`tree-sitter-m` declares `m-standard` as an upstream pin (`schema_version="1"`). The Tier 4 tools (`yfmt`, `ylint-style`, `ylint-logic`, `ycov-line`, etc.) live as their own small projects depending on `tree-sitter-m`'s Python (or Node / Rust / Go) binding, or — if the user wants — as additional binaries inside `~/projects/m-tools/bin/` that import from it.

---

*End of implementation document.*
