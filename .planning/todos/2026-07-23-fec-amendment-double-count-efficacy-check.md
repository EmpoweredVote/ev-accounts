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
