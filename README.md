# m-tools

Hub project for the M (MUMPS) development toolchain. Owns the legacy `y*`
shell scripts (kept for reference) and the M-side routines that run under
YottaDB. The canonical `m <subcommand>` CLI lives in
[`m-cli`](https://github.com/rafael5/m-cli) — this repo predates it and is
preserved as the historical reference + M-routine staging area.

## Layout

```
bin/         # legacy y* shell scripts (reference only — see m-cli for canonical CLI)
routines/    # M source — staged into the vista-meta YDB container by `make test`
fixtures/    # test fixtures
docs/        # gap analysis, implementation notes, command map
scripts/     # dev helpers
```

## Runtime

- Engine: shared **vista-meta** YottaDB container (no host YDB needed).
- Connection contract at `~/data/vista-meta/conn.env`.
- `make test` stages routines into the container over SSH, runs every
  suite remotely, then unseeds. There is no local database to initialise.

## Scope

- **Source-only tools** (formatters, linters, doc generators built on
  `tree-sitter-m`) — portable across M implementations (YDB / IRIS / GT.M).
- **Runtime-bound tools** (test runner, coverage, trace tail) — YottaDB-specific.
- YottaDB vendor commands (`mupip`, `gde`, `lke`, `dse`) are used directly,
  never wrapped or renamed. Their own `--help` is canonical.

## Companion projects

| Project | Relationship |
|---|---|
| [`m-cli`](https://github.com/rafael5/m-cli) | Successor — implements the canonical `m <subcommand>` surface. |
| [`m-standard`](https://github.com/rafael5/m-standard) | Spec layer — toolchain rules sourced from m-standard's reconciled grammar JSON. |
| [`tree-sitter-m`](https://github.com/rafael5/tree-sitter-m) | Grammar dependency for source-only tools. |
| [`tree-sitter-m-vscode`](https://github.com/rafael5/tree-sitter-m-vscode) | Downstream — VS Code extension exercising the grammar end-to-end. |
| [`m-stdlib`](https://github.com/rafael5/m-stdlib) | M-side library that `m-tools` routines should consume. |

## Key docs

- [`docs/gap-analysis-and-remediation-strategy.md`](docs/gap-analysis-and-remediation-strategy.md)
  — strategy, gap table, Tier 1–4 prioritisation.
- [`docs/implementation.md`](docs/implementation.md) — canonical command map
  (`m help`), as-built tool specs, per-tool deltas.

## See also

- [`CLAUDE.md`](CLAUDE.md) — project context for Claude (MUMPS basics, code style, test conventions).
- [`CHANGES.md`](CHANGES.md) — decision journal (the *why* behind changes).
- [`TODO.md`](TODO.md) — current backlog.
