# TODO

Known issues and deferred work for this repo. Add new entries at the top.

---

## ystate.m line 12 — RPARENMISSING parse error (caught 2026-04-25)

**Symptom:** `bin/ycheck ystate` prints a `%YDB-E-RPARENMISSING, Right
parenthesis expected` error on line 12 of `routines/ystate.m`, but reports
`OK` and exits 0 anyway.

**Affected line:**
```mumps
. for  set sub=$order(@("^"_gbl_"("""_sub_"""")"))  quit:sub=""  set count=count+1
```

**Likely fix:** the embedded-quote escaping is wrong. The intent is to
build `^GBL("KEY")` from variables `gbl` and `sub`. The clean form:
```mumps
. for  set sub=$order(@("^"_gbl_"("_$char(34)_sub_$char(34)_")"))  quit:sub=""  set count=count+1
```
or use a simpler walk via direct $ORDER on a stored reference.

**Impact:** `bin/ystate --globals` likely doesn't enumerate user globals
correctly (this label is what the `--globals` flag invokes). The Tier 2
`yglobsize` tool already covers the same job using `count^yutil`.

---

## bin/ycheck — exit code masks per-file failures (caught 2026-04-25)

**Symptom:** when `zcompile` errors on a file, ycheck prints the error
*and* `OK` for that file, then doesn't increment its `errors` counter.
Net effect: `make lint` and `yci` pass even with broken files, and the
whole reason ycheck exists (block bad commits via yhook) is undermined.

**Cause:** `if "$YDB" -run %xcmd "zcompile \"$file\"" 2>&1; then` — the
condition is the *exit code* of the pipeline, but `2>&1` merges stderr
into stdout for inspection without affecting the exit code. `zcompile`
appears to write the error to stderr and exit 0 anyway, so the `if`
branch always succeeds.

**Likely fix:** capture combined output to a variable and grep for
`%YDB-E-` (or `-FATAL` / `-WARNING`) before declaring success.
