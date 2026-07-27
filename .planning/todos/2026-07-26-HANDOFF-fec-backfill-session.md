# HANDOFF — FEC file_number backfill session (2026-07-26)

Operational handoff. **Substantive findings and cross-session coordination live in
`2026-07-26-fec-session-collision-notes.md` (rev 4)** — read that for the *why*. This file is
the *what to do next*.

---

## 1. Running right now — do not duplicate

> **SUPERSEDED 2026-07-26 (later same day).** PID 20320 **died** — it did not run to completion, and
> the "~20–24h ETA" below never applied. It had already burned all 40 wrapper attempts and exited 1
> before this file was written. Cause, fix and the relaunch are in §1a. Original text kept only
> because the rate-cap and no-concurrent-FEC-work rules still hold.

**Detached backfill, wrapper PID 20320** (survives session end; not a Claude Code background task).

| | |
|---|---|
| Progress | `backend/data/_backfill-run.log` |
| State | `backend/data/fec-file-number-backfill-state.json` |
| ~~Last measured~~ | ~~~2,493 / 6,549 targets, 64,539 rows filled, 145 unresolvable (0.2%)~~ — the 145 was a display artefact, see §1a |
| ~~ETA~~ | ~~~20–24h total, started ~18:50 UTC 07-26~~ — never applied; the run was already dead |
| Rate cap | `FEC_RATE_LIMIT_PER_MINUTE=12` (of ~16.7/min ceiling) — leaves headroom for the 06:00 UTC cron |

**Check it (PID is now 34608 — see §1a):**
```powershell
Get-Process -Id 34608 -ErrorAction SilentlyContinue      # alive?
Get-Content C:\EV-Accounts\backend\data\fec-file-number-backfill-state.json -Raw | ConvertFrom-Json
```

**If dead, resume (idempotent — re-running never double-writes):**
```powershell
cd C:\EV-Accounts\backend
$env:FEC_RATE_LIMIT_PER_MINUTE="12"
powershell -NoProfile -ExecutionPolicy Bypass -File .\_bf-wrapper.ps1   # retries on crash, 40 attempts
```
~~The wrapper exists because a transient DNS failure killed an earlier run.~~ Windows fetch **is**
flaky here, but **do not read the retry loop as proof that a failure was transient** — that framing
is exactly what hid the bug in §1a for a full run. Check *what* the attempts failed on before
assuming a resume is all that is needed: 40 identical errors is a wall, not flakiness.

**Do NOT run any other FEC API work while this is up** — shared api.data.gov key, and the local
rate limiter has no Redis to coordinate through.

---

## 1a. Why PID 20320 died, and what changed (commit `e1e87994`)

**It was a deterministic `statement_timeout`, not a transient fault.** All 40 attempts failed
identically at the cycle probe (`backfill-fec-file-numbers.ts:106`) with
`canceling statement due to statement timeout`. Progress froze at **2,809 / 6,549 targets (43%)**,
81,881 rows filled.

**Root cause.** The probe can only use an index on `politician_source_id`; committee-id (inside
JSONB), `contribution_date`, the `? 'file_number'` test and the cycle regex are all post-index
filters. So its cost scales with a politician's **entire** contribution history, not with the rows
the window needs. Measured on `C00736876|2022-11-11` (FEC `S0GA00559`, **Raphael Warnock**):

```
Bitmap Index Scan → 1,519,645 rows scanned   (everything that source has)
Rows Removed by Filter: ~1.5M                 to return 16,618
Heap Blocks: lossy=20,773                     bitmap outgrew work_mem → 41,060 extra rechecks
Buffers: shared read=122,124                  (~950 MB, not cached)
Execution Time: 36,793 ms                     vs. the role's 30s ceiling
```

Role `ev_api` carries a **role-level `statement_timeout=30s`** (`rolconfig`, set during the
2026-07-22 P1 finance incident — memory recording "8s" is wrong). A fast neighbour
(`C00699744|2026-04-11`, 14,921 rows) runs the *same plan shape* in **83 ms**. Nothing is wrong with
the window; the timeout is a line across a continuum and Warnock sits just past it.

**It was never one window.** Sizing every remaining window by its largest source:
**27 of 3,687 pending windows exceed 30s** — 2 Warnock, then ~25 on `C00696526` (1,314,985 rows,
~32s each). **0 exceed 120s.** The old code died at the *first* wall and could never reach the other
26, so fixing one window would have bought ~2 more minutes.

**Four fixes, one per distinct defect:**

1. **`statement_timeout = 300s` for this script's pool only**, applied on the `connect` event so it
   survives a mid-run reconnect. A non-superuser may raise its **own** session value → **no grant and
   no privileged connection string needed** (unlike the D-11 case). Deliberately **not** in
   `src/lib/db.ts`: the 30s role default is the P1 guard for the API, and only this batch job should
   opt out. Worst remaining scan ~37s, so ~8× headroom.
2. **Per-window DB errors are caught.** Only *fetch* failures were, so one slow window ended a 24h
   run. Failed windows are counted and left un-done; the UPDATE's `NOT (raw_record ? 'file_number')`
   guard makes a redo idempotent.
3. **`done` is checkpointed every window**, not every 25 — the crash discarded in-memory marks, so
   each of the 40 retries re-walked up to 25 already-answered windows before reaching the wall.
4. **`state.unresolvable` accumulates** (`+=`) instead of being overwritten by the per-run counter.
   **That is why the 145 above reads 0** in the state file — every resume clobbered the total. It is
   the script's honesty metric for rows the API cannot resolve; treat pre-fix values as lost.

Also: the script now **exits non-zero while windows remain unfinished**, so the wrapper's retry loop
actually picks them up. Previously it only ever re-ran because the script *crashed* — with failures
now caught, a pass that skipped windows would exit 0 and strand them silently.

**Verified before and after relaunch:** the `connect` handler lands before the first query on a fresh
connection and on all 5 distinct backends; the poison window completes in 32–37s; and live —
`✓ C00736876|2022-11-11: 39258 API row(s), updated 16595, 23 row(s) the API no longer returns`.
State moved 2,809 → 2,863 windows, 81,881 → 98,476 rows, `unresolvable` 0 → 23, **0 failures,
0 timeouts**.

**Relaunched as wrapper PID 34608.**

⚠ **The ETA is probably optimistic and is dominated by API pages, not SQL.** The script header's
design premise is that duplicate groups are "extremely sparse in DATE" (~497 rows per period). This
window carried **16,618 → 39,258 API rows ≈ 393 pages ≈ 33 min at 12 req/min**, i.e. **33× the
assumption**, and it alone took ~25–30 min. Re-derive the ETA from observed throughput before
promising a finish time; do not reuse the 20–24h figure. Observed on the relaunched run: **~2.4
windows/min**, which put ~25h on the *remaining* 3,637 — so the whole job costs well over the
original estimate.

### 1b. 🔴 THE UNRESOLVABLE RATE IS ~2.6%, NOT 0.2% — re-plan §2 against this

`§1`'s "145 unresolvable (0.2%)" was produced by the overwrite bug and is **not a real
measurement**. First trustworthy figures, from the relaunched run (measured 2026-07-27 at 61% done):

| | |
|---|---|
| rows filled | 182,855 |
| **rows the API no longer returns** | **3,985 across 374 windows ≈ 2.6%** |
| windows done | 4,023 / 6,549 |
| failures | 2 (both transient, see below) · timeouts **0** |

Reconciled independently before trusting it: summing the per-window
`N row(s) the API no longer returns` lines in `_backfill-run.log` gives exactly the counter value
(3,947 = 3,947 at the time of the check), so the `+=` fix is not double-counting.

**This is not a defect and not a data-loss risk.** Those rows stay un-backfilled, and because the
per-line retirement guards on `raw_record ? 'file_number'`, it skips them rather than guessing. The
consequence is purely that **§2 will retire less than the 0.2% figure implied** — roughly an order of
magnitude more rows stay outside its reach. Do not "fix" this by loosening the guard; the whole
reason `file_number` gates retirement is that a row without one cannot be placed in a filing.

**Both failure modes seen so far are transient, and both were previously fatal:**

- `Connection terminated unexpectedly` on a ~32s scan of a 1.3M-row source (`C00696526`) — 7 of that
  committee's 8 windows succeeded either side of it, so it is a socket drop, not a new wall.
- `The operation was aborted due to timeout` on an FEC fetch (`C00492785`).

2 failures in ~874 windows (0.2%). Each is counted, left un-done, and picked up by the wrapper on
the next pass via the new non-zero exit — the path that previously only worked because the script
crashed.

---

## 2. Next step, once the backfill finishes

Pure local SQL, no API, no rate-limit contention:

```bash
cd /c/EV-Accounts/backend
npx tsx scripts/retire-fec-superseded-local.ts --from data/fec-amendment-dupes-full.json          # DRY RUN first
npx tsx scripts/retire-fec-superseded-local.ts --from data/fec-amendment-dupes-full.json --apply
```

- `--from` targets only the 173 detector-flagged sources (same coverage, ~¼ the scanning).
- Snapshots every deletion to `data/fec-superseded-local-snapshot.json` before deleting.
- **Verify afterwards** with the invariant that was run today: every retired line must still have a
  surviving row in the same report at the survivor `file_number`. Zero last-copy deletions is the
  pass condition. (The ad-hoc script for this wasn't kept — re-derive from §6 of the collision notes.)
- ⚠ **Expect materially lower coverage than §1 implied — see §1b.** ~2.6% of rows in the scanned
  windows have no `file_number` and never will, so retirement cannot reach them. Budget for that in
  the efficacy check rather than reading it as the retirement under-performing.
- **Do not start this until the backfill is actually finished.** "Finished" means the wrapper exited
  **0**, not that the log went quiet — a non-zero exit now means windows remain (by design). Running
  retirement against partial `file_number` coverage computes the per-line window MAX over an
  incomplete set, which is exactly how FEC-04b destroyed rows the first time.

---

## 3. Time-gated check — 06:00 UTC 2026-07-27

> ## ✅ SETTLED 2026-07-27 22:15Z — BOTH questions closed. Read this instead of the block below.
>
> **(a) There is no wedged scheduler. The "~22-hour gap" was the normal cadence.** The block below
> reasons about missed "12:00, 18:00 and 00:00" ingests — **that schedule no longer exists.** Phase
> 174 (FEC-03) changed the FEC cron **6h → daily** and it has been `'0 6 * * *'` in
> `src/cron/campaignFinanceCron.ts:35` ever since. One burst per day is correct behaviour, so a ~22h
> gap between bursts is expected, not a defect. The daily burst spans several hours as it walks the
> sources — 07-25 was 06:00Z only, 07-26 ran 06:00→08:00Z, 07-27 ran 06:00→10:36Z.
>
> **Do not re-open this as a scheduler bug.** The §3 hypothesis ("the scheduler had been wedged
> since 07-26 08:08 and a deploy re-armed it") was an artefact of checking a daily job against a
> 6-hourly expectation. The standing lesson in the block below still holds and is still worth
> keeping: a silently-stalled scheduler yields *zero* failure rows, so always check `max(started_at)`
> alongside the status breakdown — just compare it against **24h**, not 6h.
>
> **(b) 🎉 THE CACHE FIX IS VERIFIED IN PRODUCTION — this was its first real exercise.** The 07-27
> burst ran **665 runs, 0 failures** (639 `completed` + 26 `completed_with_warning`). Compare the
> 07-26 outage burst: 102 failures at 06:00Z + 32 at 07:00Z = **134**. `17e3ac18` no longer counts as
> "never exercised in prod" — it is exercised and clean.
>
> | hour (UTC) | completed | warning | failed |
> |---|---|---|---|
> | 07-27 06:00 | 239 | 3 | **0** |
> | 07-27 07:00 | 112 | 3 | **0** |
> | 07-27 08:00 | 70 | 6 | **0** |
> | 07-27 09:00 | 144 | 17 | **0** |
> | 07-27 10:00 | 64 | 5 | **0** |
> | *07-26 06:00* | *136* | *4* | ***102*** |
> | *07-26 07:00* | *65* | *1* | ***32*** |
>
> The next thing worth watching is simply whether the **2026-07-28 06:00Z** burst is also clean.
>
> ---
>
> <details><summary>Superseded 2026-07-27 reasoning (kept for the audit trail — its premise was a
> schedule that no longer exists)</summary>
>
> **RUN 2026-07-27 — the answer was not the one this section anticipated, and it is NOT yet settled.**
>
> There were **no failures because there were no runs**. `max(started_at)` was
> **2026-07-26 08:08:55Z**, i.e. a **~22-hour gap** in which the 07-26 12:00, 07-26 18:00 and
> 07-27 00:00 ingests were all missed entirely. The cron then fired at **2026-07-27 06:05:48Z**,
> so the scheduler is alive again.
>
> Most likely cause: all scheduling is in-process `node-cron` on one Render dyno, the scheduler had
> been wedged since 07-26 08:08, and one of this session's deploys (`02:53`, `04:19`, `05:41`Z)
> re-armed it. **Untested hypothesis.**
>
> 🔴 **THE REAL TEST IS THE NEXT SCHEDULED RUN.** If 12:00Z fires on time, a restart fixed it. If the
> gap reappears, the scheduler has a genuine defect that a deploy only masks — and note that a
> silently-stalled scheduler produced *zero* failure rows, so **"0 failures" is indistinguishable
> from "not running" on this query**. Always check `max(started_at)` too, not just the status
> breakdown below.
>
> ```sql
> SELECT max(started_at) AS last_run, now() - max(started_at) AS since_last,
>        count(*) FILTER (WHERE started_at > now() - interval '24 hours') AS runs_24h
>   FROM transparent_motivations.ingestion_runs;
> ```
>
> </details>

**Confirm FEC ingest failures are back to 0.** — ✅ **DONE, they are 0.** See the settled block above.

```sql
SELECT date_trunc('hour', started_at) hr, status, count(*)
  FROM transparent_motivations.ingestion_runs
 WHERE started_at > '2026-07-26' GROUP BY 1,2 ORDER BY 1 DESC;
```
Baseline: 07-24 and 07-25 were 0 failures; 07-26 06:00 was **102 failures / 136 completions**.

**This was the first real exercise of the cache fix — and it PASSED.** ✅ The clean 08:00 hour on
07-26 was Upstash being fixed, not the fix working (the last ingest, 08:08, predated the deploy at
08:31). The 07-27 06:00Z burst is the genuine test: **665 runs, 0 failures.** `17e3ac18` is no
longer untested in production.

- **Good:** a single `[cache] Redis get failed — serving from in-memory fallback` in Render logs,
  with runs completing.
- **Bad:** `ERR max requests limit exceeded` from `campaignFinanceScheduler` again → Upstash is
  capped again (check the *database* plan, not account credits — see §4).

---

## 4. Gotchas that cost real time today

1. **`pool.query('SET statement_timeout=…')` is a no-op** on a pooled connection — it lands on
   whichever connection it gets. Use a dedicated `pool.connect()` client — **or, better for a long
   run, a `connect`-event handler** (what §1a actually shipped):
   ```ts
   pool.on('connect', (c) => { c.query("SET statement_timeout = '300s'").catch(…) });
   ```
   It re-applies on every reconnect, which a one-shot dedicated client does not, and keeps the
   pool's resilience over a 24h job. Verified: pg queues per-client, so the SET lands before the
   first query on a fresh connection, on every backend PID. **`ev_api` may raise its OWN session
   value — no grant and no privileged connection string needed.**
2. **Never self-join `contributions` on JSONB paths** — nested loop with the extraction in the join
   filter: **>10 min for one committee**, vs **2.7s** for a whole source via
   `max(fn) OVER (PARTITION BY …)`.
3. **Never derive an FEC two-year period from the contribution date.** FEC assigns some
   contributions to the *following* cycle — C00718866 on 2020-12-31 has 154 rows in cycle 2020 and
   **9,150 in cycle 2022**. Use the row's stored `election_cycle`.
4. **Upstash: account credits do NOT lift the per-database 500K cap** — the plan is per-database.
   The first top-up did nothing; moving db `stirred-pika-7510` off Free was the actual fix.
5. **A "killed" background-task notification is not proof the process died.** One outlived its
   notification and clobbered a state file that had already been reset.
6. **Claude Code background tasks do not survive turn boundaries.** Use a detached
   `Start-Process`, and make state files self-correcting (derive remaining work from the DB).
7. **Fetch and diff against `origin/master` before pushing a local fix** — three sessions push
   here; I nearly clobbered another session's improvement with my older subset.
8. **Render env-var changes queue a redeploy on autoDeploy services but only need a restart on
   others** — and the running process keeps the old value until that completes. This is what made
   the key rotation ordering matter.

---

## 5. Closed today

- **Per-line FEC supersession deployed** (`da8b4364`, `ea28e7b7`) — FEC-04b's whole-report rule was
  destructive; amendments are frequently DELTA filings (0 of 24 sampled were supersets).
- **Backlog retired:** 18,553 rows / **$20,176,240.79** of double-counted contributions, 62 sources
  / 90 reports, **zero last-copy deletions** (invariant verified over all rows). Undo:
  `data/fec-superseded-local-snapshot.json`.
- **Cache degrade + bounded fallback** (`17e3ac18`) — authored jointly with the Accounts session
  (my per-op degrade, their 5k bound). **Keep the bound** if you touch `cache.ts`.
- **Anthropic key rotation complete + verified:** `ev-accounts-api` → `…TwAA`,
  `civic-trivia-backend` → `…DgAA`, old shared `…tAAA` **disabled** (401 confirmed; disabled not
  deleted, so it's recoverable). Shell export removed from `~/.bashrc`. Deleted: `backend/.env.bak`
  (30 credential lines), a scratchpad `env.json`, `~/.bashrc.bak-2026-07-26`.
- Detection baseline: 677 sources / 26,750,014 rows / 173 affected / 72,362 groups /
  **80,296 excess rows (0.300%)** / 6,549 date windows.

---

## 6. Cross-session state

- **`origin/master` tip last seen: `a4ba83a7`.** It moved several times during this session —
  always `git fetch` before assuming anything.
- **Essentials / phase 222 migration numbering: start at 1468.** Highest used upstream is **1467**
  (was 1464 earlier the same day). **1468–1490 is reserved for phase 222; I claim no numbers** — my
  work created zero migration files. Re-check the max immediately before claiming:
  ```bash
  git fetch origin master && git ls-tree --name-only origin/master backend/migrations/ \
    | grep -oE '[0-9]{4}' | sort -n | tail -1
  ```
  Do **not** backfill the 1424–1440 gaps — they're leftover space from the WI/Racine renumber, and
  1462/1463 are schema changes (incl. `drop offices.politician_id`) that a lower number would
  falsely imply predating.
- **`perf/discovery-jurisdiction-backoff` still carries my commit `17575ada`** (redundant with
  `da8b4364` upstream). Not mine to delete.
- Local `master` diverged and is stale — rebase, don't merge.

---

## 7. Genuinely open

1. **`C:\Project Test\backend\.env`** — now on `…DgAA`. Confirm `Project Test` is actually
   civic-trivia's repo; if `civic-trivia-backend` deploys from elsewhere, that file is local-dev
   only.
2. **Whether anything outside Render used `…tAAA`** — CI, another machine, the Essentials checkout.
   Render's 21 services were swept (only 2 set the var). It's disabled not deleted, so a surprise
   is recoverable by re-enabling.
3. **~29 other credentials** that were sitting in the deleted `.env.bak` were never exposed the way
   the Anthropic key was (not shell-exported, never committed) — rotation judged unnecessary, but
   the Supabase service key and Render API key are the ones worth rotating if you want belt-and-braces.
4. **From the original todo, still unaddressed:** AWS Lambda/SQS duplicate-path decision, and an
   `ingestion_runs` retention policy.
