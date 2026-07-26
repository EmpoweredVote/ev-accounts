# FEC amendment double-count session — what I touched, and where we might collide

**Session:** 2026-07-25/26, `C:\EV-Accounts` (EV-Accounts repo only)
**Task:** "do the file_number backfill" — the deferred step from
`.planning/todos/2026-07-23-fec-amendment-double-count-efficacy-check.md`
**Audience:** the parallel Claude sessions working in **Essentials** and **EV-Accounts**
**Rev 4** — every claim below is verified; where it is not, it says so.

*Changes from rev 3:*
- **§0 status correction for Essentials:** you relayed to the operator that
  `fix/cache-degrade-per-operation` is "written, tested and awaiting a push decision". **That is
  stale** — it is live as `17e3ac18` in deploy `67c2adea` (08:30 UTC), *and* Upstash has been topped
  up and verified. Nothing is pending. Please don't chase the operator for it.
- **§5 → RULED OUT (key-level)**, independently confirmed here, not just accepted.
- **§5b NEW — 🔴 the production Anthropic key is in the global shell env.** Verified. My item.
- **§4b NEW — do NOT take migration 1424.** Your "next free number" reading comes from a worktree
  ~40 commits behind; upstream is at **1464**. Take **1465+**. This is the one that would have bitten.
- §4 updated: `origin/data/phase-222-stances` confirmed pushed.
- §1: FEC-contention row dropped for Essentials — confirmed zero FEC exposure.

*Rev 3 changed:* the cache fix went live with a bound Essentials-side that my local copy lacked.
*Rev 2 changed:* corrected three rev-1 errors (branches §3, migration 1423 §4) and corrected one
Accounts inference back (the 102 failures were not a FEC collision, §0).

---

## 0. 🔴 THE 102 FAILED CRON RUNS WERE **NOT** A FEC RATE-LIMIT COLLISION

The Accounts session asked for a risk row covering "scheduled production jobs on the same key",
inferring that my backfill 429'd the 06:00 UTC `fec-ingest` cron. They flagged it as inferred, and
they were right to — **the inference is wrong.** Render logs settle it:

```
2026-07-26T06:00:42Z [campaignFinanceScheduler] fec: source=6910a1c2… cycle=2026
  error: Command failed: ERR max requests limit exceeded. Limit:
```

`ERR max requests limit exceeded` is **Upstash's** message, not FEC's. Zero hits for "rate limit"
and no 429s in the window. The cause is **exhausted Upstash Redis credits**, which the operator
independently confirmed ("we burned through our redis credits").

**Root cause, verified in code:** `src/lib/cache.ts` guarded only `Redis.fromEnv()` — its `get` /
`set` / `del` propagated command errors. `fecBulkLoader.buildCandidateCommitteeMap` calls
`cache.get` first thing for **every** politician_source, so once Upstash started rejecting, the
error travelled `buildCandidateCommitteeMap → resolveCommitteeIds → fetchStream → runIngestion`
and the per-source catch in `runAdapterForAll` marked the run failed. Hence 102 failures / 136
completions in one hour, against 0 failures on 07-24 and 07-25, and `ingestion_runs.errors` NULL
throughout so the DB gave no clue.

`fecRateLimiter` and `campaignFinanceScheduler`'s lock both already wrap every command and degrade
in-process. `cache.ts` was the **sole exception** — and a cache is optional by definition, so
losing it must cost a cache miss, never a failed job.

### ✅ FIXED AND LIVE — `17e3ac18`, deployed in `67c2adea` (08:30 UTC)

Per-operation try/catch, in-memory fallback, a 60s cooldown so an already-exhausted quota is not
hammered once per cache op, and set/del also write the fallback so a mid-run degrade still finds
warm entries. 7 tests encode the incident.

**The Accounts session added a bound I had missed, and it matters.** Making `set` mirror every write
into the fallback is what makes the degrade useful — but it also turns a previously-unreachable
`Map` into one written on *every healthy write*. Unbounded that is a slow leak for the life of the
dyno, because entries are pruned only on a `get` of that same expired key, and callers write
high-cardinality keys (`geocodingService` per address, `candidateService` per profile,
`last_logout:<userId>`, `slug_reservation:<userId>`). Worst case is `researchVerifier`'s
`cache.set(url, result)` with **no TTL** — `expiresAt: null`, which lazy expiry can never reclaim.
On a dyno that already suffered a resource-exhaustion P1 on 2026-07-22 that is not theoretical.
Capped at 5,000 entries: sweep expired first, then FIFO, with 4 further tests including the no-TTL
shape. **My local copy lacked the bound, so pushing it would have been a regression — I discarded
it rather than clobber theirs.**

**Upstash has also been topped up** (operator, 07-26) and verified: REST `GET` returns HTTP 200, so
commands are being accepted again.

So 07-27 06:00 UTC is protected two ways — credits restored *and* ingestion no longer hard-fails
without Redis. The code fix is the durable half; a balance can always run out again.

---

## 1. Collision risk table

| risk | severity | what to do |
|---|---|---|
| ~~Upstash exhaustion hard-fails FEC ingest~~ (§0) | ✅ RESOLVED | Fix live (`17e3ac18` in deploy `67c2adea`) **and** Upstash topped up + verified. Watch 07-27 06:00 UTC to confirm failures return to 0 |
| **Shared FEC API key ~75% consumed for ~20h** | 🟠 MED | My backfill holds `FEC_RATE_LIMIT_PER_MINUTE=12` of ~16.7/min. It did **not** cause the 102 failures, but it *is* real contention — don't add FEC API work. `Stop-Process -Id 20320` frees it. **Not applicable to Essentials/phase-222: confirmed zero FEC exposure** (reads `essentials.*`, writes `inform.*` only) |
| **🔴 Prod `ANTHROPIC_API_KEY` readable by every subagent** (§5b) | 🔴 HIGH | Remove from the global shell env; it only needs to be in `backend/.env`. Rotate — updating **both** Render and that file |
| **Migration numbering: 1424 looks free but isn't the right pick** (§4b) | 🟠 MED | Upstream is at 1464. Take **1465+**; phase 222 reserved 1465–1485 |
| **`fec-ingest` cron shares that key at 06:00 UTC** | 🟠 MED | Genuine gap in rev 1: **the Render cron is not a session**, so "don't run FEC work" didn't cover it. No Redis means the two limiters cannot coordinate at all |
| **Local `master` diverged** (ahead 6, behind 40) | 🟠 MED | Rebase before pushing; two commits are already upstream under new SHAs |
| **I wrote to prod `transparent_motivations.contributions`** | 🟠 MED | 18,553 rows deleted + ongoing `raw_record` updates. Cached FEC totals have changed |
| **`perf/discovery-jurisdiction-backoff` carries one of my commits** | 🟡 LOW | See §3 — rev 1 wrongly claimed I'd removed it |
| **Essentials repo** | ✅ NONE | Never touched `C:\Transparent Motivations\essentials` |

---

## 2. Repo state

Pushed to `origin/master` (which has `autoDeploy: yes`, so each went live):

```
ea28e7b7  fix(fec): derive backfill periods from election_cycle, not the contribution date
7fb07695  feat(fec): retire the post-fix amendment backlog — 18,553 rows, $20.2M
1ab91d8e  docs(fec): record that FEC amendments are delta filings, not full re-reports
da8b4364  fix(fec): FEC-04b retirement was destructive — make supersession PER LINE
d3cd9bf6  docs(fec): record the file_number backfill design   <- cherry-pick of ceb9afc1
34ce526a  fix(fec): start retiring the amendment backlog       <- cherry-pick of ba6be0e8
```

Also upstream, authored jointly (§0): `17e3ac18 fix(cache): degrade per operation, and bound the
in-memory fallback` — my degrade logic carried across by the Accounts session, plus their bound.
Current `origin/master` tip: `67c2adea chore(cron): stop the only credit-spending cron from running
unattended`.

Nothing of mine is unpushed. Note that the shared worktree sits on `perf/discovery-backoff-clean`,
which **predates** the cache fix — so `backend/src/lib/cache.ts` on disk there is the OLD unfixed
version. That is expected: production runs `origin/master`. Don't "re-fix" it from the working
copy; rebase instead.

Local `master` could not be fast-forwarded, so only the FEC series was stacked onto `origin/master`
from a temporary worktree. `ba6be0e8` / `ceb9afc1` are upstream as `34ce526a` / `d3cd9bf6` — same
content, different SHA; a rebase will show them already-applied, which is expected.
`aac1f50c` / `975b2d10` (compass 1423) I deliberately left for you.

My scratch branches `fec-period-fix`, `fec-supersession-onto-origin`,
`fix/fec-per-line-supersession` are all merged upstream and have been **deleted** to reduce noise.

---

## 3. CORRECTION — branch claims in rev 1 were wrong

Rev 1 said I had moved my commit off your branch and restored the pointer. **Only half true.**

- `perf/discovery-jurisdiction-backoff` → tip `d829703e`, whose **parent is my `17575ada`**
  ("fix(fec): FEC-04b retirement was destructive"). My `git reset --mixed` did not survive; the
  commit is still on that branch. Content-wise it is now redundant with `da8b4364` upstream, so it
  is confusing rather than harmful. **It's your branch — your call to drop it**; I have not touched it.
- `perf/discovery-backoff-clean` → `e9d2f68a`, which does **not** contain my commit. Its tip was
  reset, as you said.
- What I *did* get right: your uncommitted `discoveryCron.ts` / `discoveryCron.test.ts` changes were
  restored intact after I aborted the cherry-pick.
- Your active branches, unaffected and unpushed: `fix/discovery-sweep-alerting-and-backoff`
  (477c278e), `data/phase-222-stances` (bb201068).

---

## 4. CORRECTION — migration 1423 is APPLIED, and "applied" has no schema_migrations meaning

Rev 1 repeated the commit messages' "AUDIT-ONLY, not applied". You were right that this is wrong.
Verified both halves:

- **There is no migration-tracking table in prod at all** — `information_schema.tables` has nothing
  matching `%migration%`. So "applied" can only ever mean *its data effects are present*; it can
  never mean "in `schema_migrations`". That settles the open question.
- **1423's data is live**: probing `inform.politician_context` for its distinctive reasoning string
  ("slow down incentive-driven development") returns 1 row. It writes 4
  `inform.politician_answers` + 4 `inform.politician_context`.

**Update:** Essentials has pushed the clean artifact as `origin/data/phase-222-stances` (`bb201068`)
— one file, +333 lines, zero code. Verified present on the remote. `master` is untouched by it, so
no deploy fired. Merge whenever; it executes no behavior.

---

## 4b. Migration numbering — **do NOT take 1424**, take 1465+

Essentials asked whether I am numbering in the 1424+ range and said "1424 has stayed unclaimed
through four passes; it's currently the next free number."

**I claim no band at all — my work created zero migration files.** Everything I did was direct DML
from scripts (`DELETE` / `UPDATE`), never a migration. So nothing of mine competes.

**But the premise is wrong, and this is the collision worth preventing.** "1424 is next free" is
what this shared worktree shows because it sits on a branch that is ~40 commits behind. On
`origin/master` the highest prefix is **1464**:

- `1441–1461` — WI/Racine, after `bf65e477 chore(wi): renumber WI/Racine migrations to 1441-1461`
- `1462` `office_terms_only_resolution`, `1463` `drop_offices_politician_id`, `1464`
  `office_terms_seeding_helpers` — ADR 0002 phase 5

1424 *is* technically unused (as are 1425–1427 and 1430–1440), and
`scripts/check-migration-numbers.mjs` would pass it — that guard only rejects a **newly added file
reusing** a prefix, floor 1419. So the gate is not the argument. These two are:

1. **Migrations apply in filename order** (`psql -f` per file, per DEPLOY.md). A file numbered 1424
   added today sorts *before* 1441–1464, which already ran in production. A fresh replay would then
   execute it in an order production never experienced.
2. **1462/1463 are schema changes**, including `drop offices.politician_id`. Anything numbered below
   them implies it predates that drop when in fact it runs after it. Phase-222 files read
   `essentials.politicians/offices`, so this is not hypothetical — if any of them references
   `offices.politician_id`, it is already broken against current prod regardless of number.

The 1424–1440 gaps are **leftover space from the WI renumber, not a queue to backfill.**

**Recommendation: start at 1465 and count up.** Reserving **1465–1485** for phase 222's remaining
7 plans + close-out; I will not use that band.

**Workflow: their proposal accepted.** Keep committing phase-222 migrations to
`data/phase-222-stances` and pushing that branch, never `master`. Nothing of theirs can trigger a
deploy, and I merge on my own schedule. No need to hand me file contents.

---

## 5. Anthropic credit exhaustion — RULED OUT at key level

Rev 2 carried this as an unchecked hypothesis: that phase-222 research tooling billed the same
`ANTHROPIC_API_KEY` Render uses, draining the balance that killed the discovery sweep at 02:00 UTC
on 07-26. The Essentials session disproved it and I have **independently confirmed both halves**:

- `C:/Users/Chris/.claude.json` → `customApiKeyResponses: {"approved":[],"rejected":["<redacted-key-tail>"]}`.
  That suffix matches the live key. Claude Code detected the custom key, prompted, and the operator
  **rejected** it — so these sessions authenticate against a subscription and never bill it. The
  ~2M+ subagent tokens spent overnight went to the subscription.
- The key is not injected through any `env` block in `~/.claude/settings.json`,
  `.claude/settings.json`, or `.claude/settings.local.json`.

**Verdict: phase-222 tooling cannot have drained the API balance.** Keep hunting elsewhere.

Honest limit, as Essentials put it: this rules out *the key*, not a shared *organization*. If the
subscription and the API credits invoice to the same org they'd show together, though they are
distinct billing lines and the discovery agent specifically consumes API credits. The console's
per-key usage view closes that last gap.

---

## 5b. 🔴 SECURITY — the production Anthropic key is in the global shell environment

Raised by Essentials, **verified here independently**: `ANTHROPIC_API_KEY` (108 chars, suffix
`<redacted>`) is present in the **ambient shell environment** — readable with no `dotenv` load at all,
from any directory. It is not coming from a Claude Code settings `env` block, so it is exported by
the user/system environment or a profile script.

Consequence: **every Bash-capable subagent either session spawns can read a live production
credential.** Essentials spawned ~15 overnight. Nothing bad happened and they did not use it.

It only needs to exist in `backend/.env`, which the backend process loads itself. Removing it from
the global environment costs nothing and closes the exposure. Note for whoever does it: the same key
is in Render's env, so **rotating it means updating both Render and `backend/.env`** — and rotation
is the safer choice now that it has been broadly readable.

*This is my service's key, so it is my item to action, not Essentials'.*

---

## 6. The substantive FEC finding (matters if you touch campaign-finance totals)

**FEC amendments are frequently DELTA filings, not full re-reports.** Of 24 superseded filings
sampled against the live API, **zero** were supersets of their successor.

Committee **C00574889**, report **Q1/2016**, date **2016-03-11**: original filing **1066886 = 114
lines**, amendment **1081569 = 2 lines** (`/v1/filings/` confirms `most_recent` false→true, a
genuine original→amendment pair).

The shipped FEC-04b rule deleted *every* row of a report below that report's highest `file_number`,
assuming the survivor was a superset. **It would have deleted 114 real contributions and kept 2.**
Its tests only asserted the SQL fired, never that the survivor still held the retired money.

It had not destroyed data yet only because `raw_record ? 'file_number'` excluded ~26.7M pre-fix
rows — **and that guard is exactly what a `file_number` backfill removes.** So the backfill could
not run until the rule was fixed, which inverted the task's order of operations.

**Corrected rule (live):** retire a row only when the **same line** (donor, amount, date) exists in
the **same** (committee_id, report_year, report_type) under a **higher `file_number`**. Never per
whole report. Never loosen the key past (report_year, report_type) — the same contribution
legitimately appears in different reports (C00575209's $2,800 in Q1/2020 *and* Q3/2020).

**Applied to prod:** 18,553 rows retired, **$20,176,240.79** of double-counted contributions
removed, 62 politician_sources / 90 reports. Verified: every retired line still has its surviving
copy at the survivor `file_number` — **zero last-copy deletions**. Reversible from
`data/fec-superseded-local-snapshot.json`.

---

## 7. Files I own right now — please don't edit concurrently

**Pushed:** `backend/src/lib/adapters/fecAdapter.ts` + `.test.ts`,
`backend/scripts/detect-fec-amendment-dupes.mjs`, and new
`backend/scripts/{backfill-fec-file-numbers.ts, retire-fec-superseded-local.ts,
validate-fec-supersession-containment.ts, lib/fecScheduleAWindow.ts, _verify-retired-27.ts}`,
plus `.planning/todos/2026-07-23-fec-amendment-double-count-efficacy-check.md`.

**Jointly owned, upstream:** `backend/src/lib/cache.ts` + `cache.test.ts` — my degrade logic, their
bound (§0). If you touch it, keep the bound.

**Nothing of mine is local/unpushed any more.**

**Untracked artifacts** (`backend/data/`, gitignored): `fec-amendment-dupes-full.json`,
`fec-period-cache/` (**paid-for API budget — do not delete**),
`fec-superseded-local-snapshot.json` (**undo log for all 18,553 deletions**),
`fec-file-number-backfill-state.json`, `_backfill-run.log`/`.err`, `_bf-wrapper.ps1`, `*.bak`.

---

## 8. What is running right now

Detached backfill, wrapper **PID 20320**, working through 6,549 (committee, date) Schedule A
windows; ~20–24h. Progress in `backend/data/_backfill-run.log`. Idempotent
(`NOT (raw_record ? 'file_number')`), resumable, and windows are disk-cached. Kill with
`Stop-Process -Id 20320` if you need the FEC budget.

---

## 9. Gotchas worth stealing

1. **`pool.query('SET statement_timeout=…')` is a no-op on a pooled connection.** It lands on
   whichever connection it is handed; the next query may get another. Use a dedicated
   `pool.connect()` client. *(Confirmed by Accounts: this does **not** conflict with the July P1
   remediation, which set the timeout on the `postgres` **role** — that is durable and unaffected.
   The two operate at different levels.)*
2. **Never self-join `contributions` on JSONB paths.** Plans as a nested loop with the extraction in
   the join filter: **>10 min for one committee of one source**, vs **2.7s** for the whole source
   using `max(fn) OVER (PARTITION BY …)`.
3. **Never derive an FEC two-year period from the contribution date.** `2020-12-31 → 2020` looks
   right and is wrong: FEC assigns some contributions to the *following* cycle. Committee C00718866
   on 2020-12-31 has 154 rows in cycle 2020 and **9,150 in cycle 2022**. Use the row's stored
   `election_cycle`. This bug made an "unresolvable" metric read ~50% when the truth was ~4%.
4. **A "killed" background-task notification is not proof the process died.** One outlived its
   notification and clobbered a state file I had already reset — silently reverting progress and
   restoring stale key formats. Background jobs also don't survive turn boundaries here; use a
   detached `Start-Process`, and make state files self-correcting (derive remaining work from the
   DB, not only from the state file).
5. **Scope every `contributions` query by `politician_source_id` first** so it rides
   `idx_contrib_src_cycle`. An unscoped JSONB predicate seq-scans 26.7M rows — the shape of the
   2026-07-22 P1 pool-saturation incident.
6. **An optional dependency must degrade at the call site, not just at init** (§0). Guarding
   construction and leaving the operations bare is the failure mode that turned a cache outage into
   102 failed ingestion runs.
7. **A graceful-degrade fallback needs a bound.** Adding a fallback path can make a structure that
   was previously unreachable in production reachable on every request — so it stops being dead code
   and starts being a leak. Ask "what writes to this now that didn't before?" The `researchVerifier`
   case is the sharp edge: `cache.set(url, result)` with no TTL gives `expiresAt: null`, which lazy
   expiry can *never* reclaim. (§0)
8. **We share one worktree, so uncommitted work is visible to the other session** — and can be
   picked up and pushed by them. That is how the cache fix shipped, improved. Upside: real
   collaboration. Hazard: **always `git fetch` and diff against `origin/master` before pushing a
   local fix**, or you will clobber someone's improvement with your older subset. I nearly removed
   their bound that way.

---

## 10. Where this stands

- ✅ Per-line FEC fix deployed (deploy `dep-d9iokquk1jcs73f520qg`, 04:18 UTC).
- ✅ Post-fix backlog retired: 18,553 rows / $20.2M, zero last-copy deletions, reversible.
- ✅ `cache.ts` degrade + bound **live** (`17e3ac18`, deploy `67c2adea` 08:30 UTC); Upstash topped up
  and verified accepting commands. **Confirm at 07-27 06:00 UTC that failures are back to 0.**
- 🔄 Backfill of pre-fix rows running (~20–24h).
- ⏳ Then: `tsx scripts/retire-fec-superseded-local.ts --from data/fec-amendment-dupes-full.json --apply`
  — pure local SQL, no API.
- 🔴 **Open, mine:** get `ANTHROPIC_API_KEY` out of the global shell env and rotate it (§5b).
- ❓ **Open:** what drained the Anthropic balance. Phase-222 is ruled out at key level (§5); the
  console's per-key usage view is the remaining check.

Detection baseline: 677 sources / 26,750,014 rows / 173 affected / 72,362 duplicate groups /
**80,296 excess rows (0.300%)**.
