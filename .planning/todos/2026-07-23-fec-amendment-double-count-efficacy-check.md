# FEC amendment double-count — verify Phase 174 FEC-04 actually fires (efficacy follow-up)

**Created:** 2026-07-23 (out of Phase 174, workstream 2026-us-house-candidate-coverage)
**Priority:** medium — correctness of itemized FEC totals, not a reliability/outage issue
**Blocks:** nothing; Phase 174 shipped as-is

## Context

Phase 174 FEC-04 added `retireSupersededRows` in `backend/src/lib/adapters/fecAdapter.ts`:
a parameterized `DELETE FROM transparent_motivations.contributions WHERE data_source='fec'
AND source_transaction_id = ANY($1::text[])`, fed only by **non-null** `original_sub_id`
values collected from each incoming Schedule A batch. It is safe and inert.

**The catch:** across TWO independent live-sampling sessions (~1,500 rows in the RESEARCH
phase + ~140 rows during 174-04, targeting the deepest re-amended F3X committees), **every**
`amendment_indicator:"A"` row came back with `original_sub_id: null`. The field exists in
FEC's live OpenAPI ScheduleA schema and is documented as `orig_sub_id` in FEC's internal `sa`
warehouse wiki, but is not observed populated on the public API. The free bulk `indiv{YY}.zip`
(21 cols) does not carry it either. Operator authorized proceeding on schema-level evidence
(option 2, recorded in `174-FEC04-LIVE-CONFIRM.md`).

## The open question

If `original_sub_id` is reliably null on the public API, then `retireSupersededRows` never
fires — so FEC-04 does NOT actually resolve the amendment **double-count** it was written to
fix: an amended filing reloads its Schedule A lines with a NEW `sub_id` + fresh `load_date`,
the `ON CONFLICT (source_transaction_id)` dedup misses it (new key), and the superseded row
persists → itemized totals double-count.

## What to check

1. After Phase 174 deploys and a few daily cycles run, query prod (`kxsdzaojfaibhuzmclfq`) for
   evidence of double-counted amended rows — e.g. multiple `contributions` rows for the same
   FEC filing/transaction identity (`image_number` + line) under `data_source='fec'` that
   should represent a single amended transaction.
2. If double-counting is present, design a dedup key that does NOT depend on `original_sub_id`
   — candidate: dedup/supersede by (`image_number`, transaction line identity) or by the
   amendment chain (`prior_sub_id`/`amendment_indicator` + committee/report linkage), so the
   old version is retired when a newer `load_date` version of the same logical line arrives.
3. Separately, re-check whether FEC ever populates `original_sub_id` (schema drift) — if it
   starts appearing, the existing `retireSupersededRows` will begin working as designed and
   this may become moot.

## Pointers

- `backend/src/lib/adapters/fecAdapter.ts` — `retireSupersededRows`, `normalizeRecords`, `FEC_KEPT_FIELDS`
- `.planning/workstreams/2026-us-house-candidate-coverage/phases/174-*/174-FEC04-LIVE-CONFIRM.md` — full sampling evidence
- `.planning/workstreams/2026-us-house-candidate-coverage/phases/174-*/174-RESEARCH-amendments.md` — original amendment research

---

# ✅ RESOLVED IN CODE 2026-07-25 — the double-count is REAL and now prevented (FEC-04b)

## 1. The double-count was reproduced in prod

Committee **C00256925**, report **12P / 2020**. The same **$250 contribution dated 2020-05-07**
from Denise Chamblee is stored **twice**:

| stored `sub_id` | FEC `file_number` | `load_date` | `transaction_id` |
|---|---|---|---|
| `4052920201773727964` | **1409022** | 2020-05-30 | `VSHCSM0N319` |
| `4123020201986704254` | **1484476** | 2020-12-30 | `2208859` |

The original filing and its December amendment, both ingested. Thirteen donors on that one report
are duplicated the same way, including Bobby Vassar's $800 **and** $200 lines.

## 2. `original_sub_id` is confirmed dead — and `transaction_id` is NOT a usable key either
- `original_sub_id`: null on **all 700+** live Schedule A rows sampled in this session (third
  independent confirmation). `retireSupersededRows` can never fire. Left in place, inert.
- `transaction_id`: **populated 100%, but NOT STABLE across amendments** — the same contribution
  above carries `VSHCSM0N319` in the original and `2208859` in the amendment (the filer changed
  filing software). Deduping on it would silently fail to merge. **This kills the dedup key the
  original todo proposed.**
- `amendment_indicator` on Schedule A means the **line action**, not "this row is an amendment":
  every row sampled reads `A` = `ADD` (`amendment_indicator_desc`). The FEC-04 design read this
  field as an amendment marker; that was a misreading.
- `image_number` is per-PAGE, and a filing's `beginning_image_number` does not match its Schedule A
  rows — so `?image_number=<beginning>` returns 0 rows. The `(image_number, line)` key the original
  todo suggested does not work either.

## 3. The fix: retire by (committee, report_year, report_type) + `file_number`
FEC amendments supersede a **whole report**, not individual lines. So the unit of supersession is
the report and the discriminator is `file_number` — highest wins.

`fecAdapter.retireSupersededFilings()`:
```sql
DELETE FROM transparent_motivations.contributions
 WHERE politician_source_id = $1          -- FIRST: rides idx_contrib_src_cycle
   AND data_source = 'fec'
   AND raw_record ? 'file_number'         -- never touches pre-fix rows
   AND raw_record->>'committee_id' = $2
   AND (raw_record->>'report_year')::int = $3
   AND raw_record->>'report_type' = $4
   AND (raw_record->>'file_number')::bigint < $5
```
- `file_number`, `report_year`, `report_type`, `load_date`, `transaction_id` added to
  `FEC_KEPT_FIELDS` (transaction_id for audit only — see above, it is not the key).
- Scoped by `politician_source_id` first **deliberately**: an unscoped JSONB predicate would
  seq-scan 26.9M rows, which is the exact shape of the 2026-07-22 P1 pool-saturation incident.
- `< maxFileNumber` means the rows just inserted (which ARE the max) can never be deleted.
- 4 new tests encode the real C00256925 case; full suite **889 passed**, tsc clean.

## 4. ⚠️ The fix is FORWARD-ONLY — there is an existing backlog
`raw_record ? 'file_number'` is a deliberate guard: rows ingested before this change carry no
`file_number`, so we cannot tell which version they are and deleting on a guess could destroy the
**current** version. Those need a separate, API-resolved cleanup.

**Backlog sized with `backend/scripts/detect-fec-amendment-dupes.mjs`** (read-only):

| scanned | rows | affected sources | dup groups | **excess rows** |
|---|---|---|---|---|
| 120 of 677 FEC sources | 5,026,930 | 29 | 6,905 | **9,941 (0.198%)** |

Extrapolated over ~26.9M FEC rows that is on the order of **~50k over-counted rows**. The average
is small but the distribution is skewed — two sampled sources had ~48% of their rows duplicated
(41 excess of 85; 172 of 358), which materially distorts those candidates' totals.

**Detector signature (needs no new fields):** `sub_id` embeds FEC's load date at chars 2-9
(`4|05292020|1773727971`), so one filing's lines share a prefix. A group identical on
(committee, donor, amount, contribution_date) spanning **>1 prefix** is a re-reported amendment.
Requiring >1 prefix is what excludes FEC's legitimate repeated identical lines (five $1.00
recurring donations on one day, consecutive sub_ids) — those must NOT be collapsed.

**Note `source_system` for FEC is `fec_house` (522) + `fec_senate` (150) + `fec` (5) = 677.**
Filtering on `'fec'` alone finds 5 sources and badly undercounts — the first run of the detector
made exactly that mistake.

## 5. Still to do
1. **Retire the backlog**: for each detected group, resolve (committee, report_year, report_type)
   against `/v1/filings/` and keep only the highest `file_number`. Snapshot before deleting, as with
   the stance retirements. Do NOT infer the survivor from the sub_id prefix alone.
2. **Backfill `file_number`** onto existing rows (re-fetch by committee+period) so the shipped fix
   can maintain them going forward.
3. Re-check whether FEC ever starts populating `original_sub_id` — if so, `retireSupersededRows`
   begins working and becomes a belt-and-braces second path.

---

# BACKLOG RETIREMENT STARTED 2026-07-25 — and the backlog is NOT what §4 assumed

## The detector's signature catches TWO phenomena, not one

Validated against the FEC API. Of 45 groups resolved:

| classification | count | disposition |
|---|---|---|
| **TRUE AMENDMENT** — versions share (report_type, report_year), differ in file_number | **27** | **RETIRED** (keep highest file_number) |
| **CROSS-REPORT** — versions sit in DIFFERENT reports (e.g. Q1/2020 *and* Q3/2020) | 4 | **KEPT** — not a supersession |
| **UNRESOLVABLE** — the live API no longer returns 2 matches | 14 | **KEPT** — cannot decide |

**So ~40% of the "backlog" must NOT be deleted.** Concrete examples of rows that a naive
prefix-based delete would have destroyed:
- `C00575209` SCOTT/YEE/HOFFMAN $2,800 2020-02-03 — appears in **Q1/2020 (file 1435580)** and
  **Q3/2020 (file 1452737)**. Different reports; neither supersedes the other.
- `C00742007` LEVY $6,600 2024-03-28 — **Q1/2024 (file 1775811)** and **Q2/2024 (file 1801674)**.

**This invalidates the earlier ~50k extrapolation as a deletion target.** 9,941 excess rows is the
size of the *signature*, not of the true duplicate set; the deletable subset is roughly 60% of it,
and only where the API can still confirm the report identity.

## The tool
`backend/scripts/retire-fec-amendment-dupes.mjs <detector.json> [--groups N] [--apply]`
- Classifies every group against the live API before touching anything; retires **only**
  same-report groups, keeping the row whose `sub_id` maps to the highest `file_number`.
- The survivor is a **resolved fact from the API**, never inferred from the sub_id prefix.
- Snapshots every deleted row to `data/fec-amendment-retired-snapshot.json` (reversible).
- Resumable: `data/fec-amendment-retire-state.json` records resolved group keys, so re-running
  continues rather than restarting. Fetch failures are NOT marked done — they retry.
- Self-throttled to 5 s/request because the FEC key is shared with the production daily ingest and
  the 15/min limiter is per-process.

## Progress + remaining cost
**45 of 6,905 detected groups resolved; 27 rows retired.** The 5 s throttle means the sampled
portion alone is ~9.5 hours of wall clock, and **557 of 677 FEC sources have not been scanned yet**
(`detect-fec-amendment-dupes.mjs --limit 677`). Run it in batches:

```bash
cd backend
node scripts/detect-fec-amendment-dupes.mjs --limit 677 --json data/fec-amendment-dupes.json
node scripts/retire-fec-amendment-dupes.mjs data/fec-amendment-dupes.json --groups 200 --apply
```
Prefer running it outside the 06:00 UTC ingest window.

## Worth fixing at the root instead
The UNRESOLVABLE bucket (31% of this batch) exists only because pre-fix rows lack `file_number`.
**Backfilling `file_number` onto existing rows would make the whole backlog resolvable locally**,
with no API calls and no ambiguity — likely cheaper than grinding through per-group classification.

---

# NEXT SESSION: build the `file_number` backfill (recommended over more API batches)

**Why this instead of grinding the per-group batches:** the UNRESOLVABLE bucket (31% of the resolved
batch) exists *only* because pre-fix rows lack `file_number`. Backfill it and the whole backlog
becomes resolvable with **plain SQL, no API calls, no rate-limit contention with the 06:00 UTC
ingest, and no unresolvable bucket** — and the already-shipped FEC-04b fix can then maintain those
rows going forward.

## The insight that makes it cheap
`sub_id` → `file_number` is a **many-to-one** mapping, and one FEC API page returns up to 100 rows
each carrying both. So you do **not** need one request per contribution — you need one pass per
`(committee_id, two_year_transaction_period)` to build a `sub_id → {file_number, report_year,
report_type}` map, then a bulk local UPDATE. The number of requests scales with committee-periods,
not with rows.

## Sketch
1. **Enumerate targets**: `SELECT DISTINCT raw_record->>'committee_id', election_cycle FROM contributions
   WHERE data_source='fec' AND NOT (raw_record ? 'file_number')` — scope per `politician_source_id`
   so it rides `idx_contrib_src_cycle` (never an unscoped JSONB scan; that is the 2026-07-22 P1 shape).
2. **Fetch** `/v1/schedules/schedule_a/?committee_id=X&two_year_transaction_period=Y&per_page=100`,
   paginating with `last_index` + `last_contribution_receipt_date` (the ONLY valid sort keys are
   `contribution_receipt_date` and `contribution_receipt_amount` — `-load_date` returns 422).
   Reuse `acquireFecSlot()` from `src/lib/fecRateLimiter.ts` so it shares the 15/min budget with the
   cron instead of competing with it.
3. **UPDATE** matched rows by `source_transaction_id = sub_id`, setting
   `raw_record = raw_record || jsonb_build_object('file_number', …, 'report_year', …, 'report_type', …)`.
   Idempotent — re-running is a no-op on rows that already have it.
4. **Then** retire locally, no API: for each `(politician_source_id, committee, report_year,
   report_type)`, delete rows below `max(file_number)`. This is exactly the shipped
   `retireSupersededFilings` predicate, so reuse it rather than writing a second rule.
5. Snapshot before deleting, as with every other retirement this session.

## Caveats to carry over
- Rows whose `sub_id` the API no longer returns stay un-backfilled → leave them alone (same
  conservative stance as the `raw_record ? 'file_number'` guard). Report the count.
- **Do NOT** delete cross-report matches — the same contribution legitimately appears in different
  reports (`C00575209` $2,800 in Q1/2020 **and** Q3/2020). Step 4's predicate already excludes them
  because it keys on `(report_year, report_type)`; do not "improve" it into a looser key.
- Bulk `indiv{YY}.zip` (21 cols) does **not** carry `file_number` — the API is the only source.
- Run outside the 06:00 UTC ingest window.

## Repo state at handoff (2026-07-25)
- `b6f8b6f7` FEC-04b fix — **pushed, live in prod** (deploy `2fcda047`).
- `ba6be0e8` backlog tooling + 27 rows retired — **committed, NOT pushed**.
- `data/fec-amendment-retire-state.json` holds 45 resolved group keys; the retirement script resumes
  from it. `data/fec-amendment-retired-snapshot.json` holds the 27 deleted rows.
- **Reminder: `autoDeploy: yes` on master — any push deploys the backend immediately.**

---

# 2026-07-25 (later session) — THE BACKFILL PREMISE WAS WRONG, AND FEC-04b IS DESTRUCTIVE

Building the backfill surfaced a data-loss bug in the **shipped** FEC-04b fix. The backfill itself
is built and validated, but **it must not be applied until the adapter fix is deployed** — see
Ordering below.

## 1. FEC amendments are NOT full re-reports — they are often DELTA filings

The whole of FEC-04b (and step 4 of the plan above) rests on "an amendment supersedes a whole
REPORT", i.e. the surviving filing is a **superset** of the one it supersedes. That was never
tested — the FEC-04b unit tests assert the SQL fires, not that the survivor still contains the
retired filing's money.

Tested now, by amount-multiset containment on (contributor_name, amount, date) per report, over
live API data (`scripts/validate-fec-supersession-containment.ts`):

| superseded filings sampled | ARE a subset of their survivor | are NOT |
|---|---|---|
| 24 | **0** | **24** |

The starkest case — committee **C00574889**, report **Q1/2016**, contribution date **2016-03-11**:

| file_number | amendment_indicator | rows on that date |
|---|---|---|
| 1066886 | N (original) | **114** |
| 1081569 | A (amendment) | **2** |

`/v1/filings/` confirms 1066886 is `most_recent=false` and 1081569 is `most_recent=true`, so this
IS a genuine original-to-amendment pair. The amendment simply re-reports 2 lines, not all 114.

**The shipped whole-report rule would delete 114 real contributions and keep 2.**

## 2. Why it has not already destroyed prod data — and why that is luck, not safety

Two things are holding it back:
- `raw_record ? 'file_number'` excludes all ~26.7M pre-fix rows.
- `filingMax` is computed per **100-row page**, so whether the rule fires at all depends on how a
  report's filings happen to interleave across pages. Checked C00574889 in prod: its only post-fix
  rows are reports with a single filing, so nothing was deleted. 95,782 post-fix rows exist across
  the 12 most recent sources and the 06:00 UTC cycle ran 2026-07-25, so this was close.

**The critical consequence: `raw_record ? 'file_number'` is the ONLY thing protecting the pre-fix
backlog. Backfilling `file_number` REMOVES that protection.** Running the backfill under the old
rule would have armed the bug across the entire backlog. This is the ordering requirement.

## 3. The corrected rule: per contribution LINE

A row is retired only when the **same line** (donor, amount, date) also exists in the **same**
(committee_id, report_year, report_type) under a **higher file_number**. That is precisely what the
double-count is, and it never touches a line only the earlier filing reports.

- C00256925 12P/2020 still resolves (Chamblee $250 is in both 1409022 and 1484476).
- C00574889 Q1/2016 now retires nothing.
- FEC legitimately repeats identical lines within one filing; they share that filing's file_number,
  so none is the "higher" version of another.
- Cross-report duplicates (C00575209 $2,800 in Q1/2020 **and** Q3/2020) stay — matching is scoped
  inside one (report_year, report_type). **Do not loosen this key.**

Implemented as a **window MAX, not a self-join**: the self-join plans as a nested loop with the
JSONB extraction in the join filter, so cost is quadratic in the source's row count — measured
**>10 min for a single committee of a single source**, vs **2.7 s** for the whole source with the
window form. Same rule now lives in `fecAdapter.retireSupersededFilings` and
`scripts/retire-fec-superseded-local.ts` — **change both together**.

### Validation
- On source `79798f42` the new rule returns **exactly the 13 rows / $18,700** that `b6f8b6f7`
  independently documented for report 12P/2020. Ground-truth match.
- The **27 rows already retired** by `retire-fec-amendment-dupes.mjs` were re-checked against the
  per-line rule (`scripts/_verify-retired-27.ts`): **27 of 27 hold up**. No restore needed — that
  script required 2+ API matches on the same (amount, date), which was per-line evidence by luck.

### Known conservatism (documented, not a bug)
If the earlier filing has 3 copies of a line and the amendment reports 1, all 3 earlier copies are
retired and 1 survives — the later filing is treated as authoritative for the lines it reports. For
a delta amendment that corrected only one of several identical lines this can under-count by one.
Strictly better than double-counting, and vastly better than the whole-report rule.

## 4. The backfill: (committee, period, DATE) windows, not committee-periods

The plan of record said requests scale with committee-periods. True, but the periods are huge:
**C00742007/2024 is 102,312 rows = 1,024 pages, about 68 min** at the shared 15/min budget; 268
implicated periods runs to days. The duplicate groups are extremely sparse in **date** (that
committee has ONE group on ONE date), so `min_date=max_date=<date>` cuts it to **497 rows / 5
pages — about 200x** — and still returns every filing's version of the lines on that date, which is
all the per-line rule needs.

Full detection now completes (the detector previously aborted the whole sweep on one source's
`statement_timeout`; it now raises the timeout on its own connection and reports unscanned sources):

| sources | rows | affected | groups | excess rows | date windows | committee-periods |
|---|---|---|---|---|---|---|
| 677 | 26,750,014 | 173 | 72,362 | **80,296 (0.300%)** | **6,549** | 268 |

Dry run: **373 fillable rows over 12 windows, 1 unresolvable** — against the **31% UNRESOLVABLE**
of the per-group API approach this replaces. Estimated cost for all 6,549 windows: ~13k requests,
**about 14 h** at the shared 15/min. Windows are cached to `data/fec-period-cache/` so the API is
paid once across the validator, backfill and any re-run.

**Note `pool.query('SET statement_timeout=...')` does NOT work** — it lands on whichever pooled
connection it is handed, so the next query can get a different one. Take a dedicated
`pool.connect()` client. This is how the first retirement run silently failed.

## 5. Ordering — MANDATORY

1. **Deploy the per-line adapter fix first.** Branch `fix/fec-per-line-supersession`, off `master`.
   Full suite **906 passed**, tsc clean. **NOT pushed** — `autoDeploy: yes` on master means any
   push deploys immediately, and this is the operator's call.
2. Then backfill: `tsx scripts/backfill-fec-file-numbers.ts data/fec-amendment-dupes-full.json --windows N --apply`
3. Then retire locally, no API: `tsx scripts/retire-fec-superseded-local.ts --sources 677 --apply`
   (snapshots every deleted row to `data/fec-superseded-local-snapshot.json`).

A dry-run retirement sweep over already-post-fix rows found **10,031 superseded rows across the
first 30 sources** before it was stopped — so there is material over-counting recoverable even
before any backfill. Run outside the 06:00 UTC ingest window.

## 6. Repo/branch note
The parallel session had checked out `perf/discovery-jurisdiction-backoff` in `C:/EV-Accounts` with
uncommitted `discoveryCron` work. This work was moved off that branch onto
`fix/fec-per-line-supersession` via a temporary worktree; their branch and working tree were
restored untouched. The new scripts also sit untracked in the main worktree so the tooling stays
runnable where `.env` and `data/` live.

---

# ✅ 2026-07-26 — PER-LINE FIX DEPLOYED, POST-FIX BACKLOG RETIRED

## Deployed
`origin/master` `1ab91d8e`, Render deploy `dep-d9iokquk1jcs73f520qg` **live 04:18 UTC**. The
destructive whole-report rule is out of production. 890 tests / tsc clean against the real upstream
tree before pushing.

**Local `master` had DIVERGED from origin** (origin was 10+ commits ahead), so it could not be
pushed. The coherent FEC series — `ba6be0e8` (backlog tooling, never pushed), `ceb9afc1` (design
doc), the per-line fix, this doc — was stacked onto `origin/master` and pushed from there. The
unrelated compass-data commits (`aac1f50c`, `975b2d10`) remain unpushed on local master.

## Retired (post-fix rows only — NO backfill needed for these)

| scanned | affected sources | rows deleted | money | errors |
|---|---|---|---|---|
| 173 flagged sources | 62 | **18,540** (+13 ground-truth = 18,553) | **$20,176,240.79** | 0 |

Swept the 173 detector-flagged sources rather than all 677 (`--from data/fec-amendment-dupes-full.json`):
same coverage — a source with no duplicate signature has nothing for this rule to find — for about a
quarter of the work, since there is no index for `raw_record ? 'file_number'` and scanning a source
means a full pass over its rows either way.

### Verification
- Ground-truth case first: report 12P/2020 went from two filings to file **1484476 alone, 17 rows /
  $21,000**, exactly the FEC API's authoritative amendment. One duplicate line remains in that
  report and SHOULD — it is FEC's legitimate repeated identical line inside a single filing.
- **Invariant checked over all 18,553 retired rows**: every retired line still has a surviving row
  in the same report carrying the survivor `file_number`. **Zero last-copy deletions.**
- Full snapshot at `data/fec-superseded-local-snapshot.json` — every deletion is reversible.

## Still open: the pre-fix backlog
The detector's signature covers **80,296 excess rows**; the ~18.5k above are the ones that already
carried `file_number`. The remainder sits on pre-fix rows and needs
`backfill-fec-file-numbers.ts` first — **6,549 date windows, ~13k requests, ~14 h** at the shared
15/min budget. Tooling is built, dry-run clean (373 fillable / 12 windows / 1 unresolvable), and now
safe to apply because the per-line rule is deployed. Not yet run.
