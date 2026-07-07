---
phase: 160-field-resolution-stance-gap-diagnostic
reviewed: 2026-07-03T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - backend/scripts/diag-160-incumbent-stance-gap.ts
  - backend/scripts/diag-160-external-id-collision.ts
  - backend/scripts/diag-160-race-preexistence-audit.ts
  - backend/scripts/diag-160-validate-field-table.py
  - backend/scripts/160-verify.sql
findings:
  critical: 1
  warning: 4
  info: 6
  total: 11
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-07-03
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the five Phase-160 read-only diagnostic/gate artifacts: three TypeScript prod-DB diagnostics, one Python CSV-shape gate, and one psql baseline gate. Read-only guarantees hold across all five (parameterized SELECTs only; the only writes are git-tracked phase-dir CSVs and `TEMP ... ON COMMIT DROP` tables). Credential handling is clean (`.env` via `dotenv/config` / `$DATABASE_URL`; no hardcoded secrets). The 178-row hard guard in the incumbent diagnostic and the fail-loud structure of `160-verify.sql` are well built.

One critical defect: the external_id collision audit scans the wrong negative-id band for all 6 at-large states (AK/DE/ND/SD/VT/WY) because it hardcodes `cd = 1..n` while every other Phase-160 artifact — including the canonical field table that the seeding phases consume — uses `cd = 0` for at-large districts. The band the seeders will actually compute was never audited, and project research indicates that exact band is already occupied by a historical state-exec scheme. Four warnings cover a stance-count/topic-set mismatch, a timezone-dependent DATE serialization footgun, and two silent-bypass gaps in the Python gate.

## Critical Issues

### CR-01: Collision audit scans the wrong external_id band for all 6 at-large states

**File:** `backend/scripts/diag-160-external-id-collision.ts:94-99` (also `:124`)
**Issue:** The audit loop iterates `for (let cd = 1; cd <= numDistricts; cd++)`, so for the 6 single-district states (AK, DE, ND, SD, VT, WY) it tests only the `cd=1` band `-(fips*10000 + 100 + seq)` and emits a synthetic `geo_id` of `"0201"`/`"5601"` etc. But the canonical Phase-160 convention for at-large districts is **cd=0** with geo_id `XX00`:

- `160-incumbent-map.csv` (produced by the sibling diagnostic via `parseInt(geo_id.slice(2))`): `AK,0,0200,...`, `WY,0,5600,...`
- `160-field-table.csv` / `staging/p165-AK.csv` (the artifact the seeding phases consume): `AK,0,0200,...`

So the band the seeders will actually compute for at-large challengers — `-(fips*10000 + 0*100 + seq)` = `-(fips*10000 + seq)` — was **never scanned**. That is precisely the band `160-RESEARCH.md:222` identifies as occupied by a historical `-(fips*10000+seq)` state-exec scheme ("WY/other state-exec ... (v2.18)"), so collisions there are not hypothetical: e.g., a WY at-large challenger at seq 1 would compute `-560001`, inside the band research already found polluted. Because the CSV only emits *colliding* districts, the absence of AK/DE/ND/SD/VT/WY rows reads as "band clean" — a false assurance for 6 of 178 districts. Additionally, the synthetic geo_ids (`0201`, `5601`) do not exist in `essentials.districts`, so any downstream join of this artifact on geo_id silently drops rows.

Downstream blast radius: Phase 165 seeds AK (14 candidates) and WY from this audit's `safe_start_seq` guidance; per RESEARCH.md's own pitfall note, an unaudited collision either aborts the seeding insert (unique violation) or, if upsert-by-external_id is used anywhere, silently overwrites an unrelated politician. The documented seeding-time live pre-write check reduces but does not eliminate the risk of the artifact actively misleading.

**Fix:** Derive districts (and `cd`) from the real DB geo_ids, exactly as the other two diagnostics do, instead of synthesizing `cd = 1..n`:
```ts
const { rows: dists } = await pool.query<{ geo_id: string }>(
  `SELECT geo_id FROM essentials.districts
   WHERE district_type = 'NATIONAL_LOWER' AND substr(geo_id, 1, 2) = ANY($1::text[])`,
  [Object.values(FIPS).map((f) => String(f).padStart(2, '0'))],
);
for (const { geo_id } of dists) {
  const fips = Number(geo_id.slice(0, 2));
  const cd = Number(geo_id.slice(2)); // 0 for at-large — matches 160-field-table.csv
  // ... existing seq 1-99 scan of -(fips*10000 + cd*100 + seq), keyed by the REAL geo_id
}
```
If the seeding phases instead intend `cd=1` for at-large external_ids, that convention must be written down and the field table's `cd=0` rows reconciled — either way the current audit + field table disagree and one of the two bands is unverified. Re-run the audit and regenerate `160-negative-id-audit.csv` after the fix.

## Warnings

### WR-01: `stance_count` counts ALL topics, not the federal-24 set the tier bar assumes

**File:** `backend/scripts/diag-160-incumbent-stance-gap.ts:179-180` (Query A), `:201-202` (Query B)
**Issue:** The header and comments claim a "federal-24 compass stance count", and `topUpTier()` classifies `done` at `>= FEDERAL_TOPIC_BAR (24)`. But the subquery is `SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = p.id` with no topic filter. `politician_answers` PK is `(politician_id, topic_id)` (migration 026), so there is no double-counting — but the all-live topic set is larger than 24 (federal-24 = all-live minus city/judicial/data-centers). Any incumbent record carrying legacy answers on excluded topics (e.g., a record deduped from prior local/state coverage) gets an inflated count and can be misclassified `done` while missing federal topics — and per D-02 the tier drives whether a top-up happens at all. Likelihood is low for House incumbents but the failure mode is silent and this exact query is being copied wave-to-wave (identical in `diag-154`/`diag-148`).
**Fix:** Filter the count to the federal-24 keys:
```sql
(SELECT COUNT(*) FROM inform.politician_answers pa
  JOIN inform.compass_topics ct ON ct.id = pa.topic_id
 WHERE pa.politician_id = p.id
   AND ct.key = ANY($2::text[]))::int AS stance_count
```
passing the 24 federal keys (source of truth: `backend/data/stance-research/*/_TOPIC_SCALE_FULL.txt` set). Apply to both Query A and Query B so the console tier split and the CSV agree.

### WR-02: DATE serialization is timezone-dependent — shifts a day and breaks the Nov-3 filter on UTC+ machines

**File:** `backend/scripts/diag-160-race-preexistence-audit.ts:117, 189, 231`
**Issue:** `essentials.elections.election_date` is a Postgres `date` (migration 042). node-postgres parses `date` columns into a JS `Date` at **local midnight**; `.toISOString().slice(0, 10)` then re-renders it in UTC. On any UTC-positive timezone, local midnight 2026-11-03 is 2026-11-02T22:00Z (or similar), so the CSV `election_date` column emits `2026-11-02` and the reconciliation filter at line 231 (`r.election_date === '2026-11-03'`) matches nothing — the "29 pre-existing Nov-3 races" log silently reports 0 districts. It happens to work on this US-timezone machine, but the artifact is git-tracked and the script is re-runnable; a run from a UTC/UTC+ environment produces a corrupted artifact with no error. (The `timestamptz` columns — `created_at`/`updated_at`/`last_verified_at` — are fine; only the `date` column suffers.)
**Fix:** Render the date server-side and keep it a string end-to-end:
```sql
el.election_date::text AS election_date
```
then drop the `.toISOString().slice(0,10)` calls (lines 117, 189) and the type becomes `string` in `DetailRow`. `160-verify.sql` is unaffected (it compares `DATE '2026-11-03'` server-side).

### WR-03: AL district-split gate silently no-ops on unrecognized `cd` values

**File:** `backend/scripts/diag-160-validate-field-table.py:134-137`
**Issue:** The Alabama split assertion is `if cd in AL_DECIDED_CDS ... elif cd in AL_LATE_CDS ...` against raw string sets `{"3","4","5"}` / `{"1","2","6","7"}`. Any AL row whose `cd` is not an exact member of either set — zero-padded `"03"`, whitespace `" 3"`, or an outright wrong value like `"8"` — matches **neither** branch and the row passes the split check without any assertion firing. The per-state count check only guarantees AL has 7 rows, not which districts they are, so `AL,03,...` or a mistyped `AL,8,...` sails through the gate the docstring promises to enforce.
**Fix:** Normalize and close the set:
```python
if st == "AL":
    cdn = cd.strip().lstrip("0") or "0"
    if cdn in AL_DECIDED_CDS and fs != "decided":
        problems.append(...)
    elif cdn in AL_LATE_CDS and fs != "late-primary":
        problems.append(...)
    elif cdn not in AL_DECIDED_CDS | AL_LATE_CDS:
        problems.append("AL-%s: unexpected AL cd (must be 1-7)" % cd)
```

### WR-04: No per-district uniqueness check — duplicate+missing district pairs pass the gate

**File:** `backend/scripts/diag-160-validate-field-table.py:87-99` (row loop), `:139-142` (per-state counts)
**Issue:** The gate validates total row count (178) and exact per-state counts, but never asserts that the 178 rows cover 178 **distinct** districts. A field table containing `WA,1,5301` twice and no `WA,2,5302` row satisfies every current assertion ("WA: 10 rows") and PASSes. For a gate whose entire purpose is confirming per-district coverage before five seeding phases fan out, geo_id uniqueness is a core invariant, not a nice-to-have. There is also no check that `geo_id` is consistent with `state`+`cd` (e.g., a `WA,1,5302` typo passes).
**Fix:** Inside the loop collect `geo_ids.append(r["geo_id"].strip())`, then:
```python
dupes = [g for g, n in collections.Counter(geo_ids).items() if n > 1]
if dupes:
    problems.append("duplicate geo_id rows: %s" % ", ".join(sorted(dupes)))
```
and optionally assert `geo_id == FIPS[st] zero-padded + cd zero-padded` per row.

## Info

### IN-01: Dead code in safe_start_seq computation

**File:** `backend/scripts/diag-160-external-id-collision.ts:113-119`
**Issue:** `candidateSeq` starts at `maxSeq + 1`, which by definition of `maxSeq = Math.max(...collisions)` can never be in `collidingSet`, so the `while` loop at line 118 never iterates. Similarly, `freeSlotsRemaining < 2` at line 114 implies `collisions.length > 97`, already covered by `collisions.length >= 90`.
**Fix:** Simplify to `safeStartSeq = maxSeq + 1 <= MAX_SEQ ? maxSeq + 1 : ALTERNATE_SUB_BAND_START;` (plus the explicit KY-1/OK-1 override), or delete the redundant clauses.

### IN-02: `unresolvedCount` assertion can never fire

**File:** `backend/scripts/diag-160-external-id-collision.ts:195-196`
**Issue:** `safe_start_seq` is always `>= 2` or `200` by construction, so `!a.safe_start_seq || a.safe_start_seq < 1` is always false and the "(expected 0)" line is vestigial comfort output, not a real check.
**Fix:** Remove it, or make it check something falsifiable (e.g., `safe_start_seq <= MAX_SEQ || safe_start_seq === ALTERNATE_SUB_BAND_START`).

### IN-03: Magic number 23 duplicates FEDERAL_TOPIC_BAR

**File:** `backend/scripts/diag-160-incumbent-stance-gap.ts:213-214`
**Issue:** Query B hardcodes `BETWEEN 1 AND 23` and `>= 24` while the tier logic derives from `FEDERAL_TOPIC_BAR = 24`; if the bar ever changes, console tiers and SQL buckets silently diverge.
**Fix:** Interpolate the constant: `BETWEEN 1 AND ${FEDERAL_TOPIC_BAR - 1}` / `>= ${FEDERAL_TOPIC_BAR}` (constant-only interpolation, no injection surface).

### IN-04: Per-state tally omits states with zero districts

**File:** `backend/scripts/diag-160-incumbent-stance-gap.ts:293-301`
**Issue:** The tally loop iterates only over rows the query returned; a Wave-3 state with 0 `NATIONAL_LOWER` districts would be silently absent from the per-state list (no `MISMATCH` line), visible only via the TOTAL shortfall — and the tally is console-only. The 178-row CSV guard and `160-verify.sql` A1 do catch this downstream, so severity is informational.
**Fix:** Iterate over `EXPECTED_PER_STATE` keys and look up the actual count (defaulting 0), mirroring the LEFT JOIN pattern used in `160-verify.sql` A1.

### IN-05: Python gate robustness — short rows crash with a traceback; BOM/whitespace edge cases

**File:** `backend/scripts/diag-160-validate-field-table.py:76, 97, 102`
**Issue:** (a) A data row with fewer fields than the header makes `DictReader` yield `None` for trailing keys, so `r["source_url"].strip()` raises `AttributeError` — still a non-zero exit (gate-safe) but an ugly traceback instead of a clean `FAIL: <row>`. (b) A UTF-8 BOM (Excel round-trip) makes the first fieldname `\ufeffstate` (U+FEFF prefix) and fails the header check with a confusing message — `encoding="utf-8-sig"` is free insurance. (c) Line 102 compares `r["nominee_status"]` unstripped against `PID_EXEMPT` while line 98 strips; a trailing-space `"vacancy "` over-fails (safe direction, but inconsistent).
**Fix:** Open with `encoding="utf-8-sig"`; normalize each row up front (`r = {k: (v or "").strip() for k, v in r.items() if k is not None}`).

### IN-06: Expected-count tables quadruplicated across four files

**Files:** `backend/scripts/diag-160-incumbent-stance-gap.ts:78-118`, `diag-160-external-id-collision.ts:31-42`, `diag-160-validate-field-table.py:39-45`, `160-verify.sql:62-70`
**Issue:** The 38-state FIPS/delegation table is hand-maintained in four syntaxes. This exact table has already been wrong once this phase (commit 377974b5 "fix MT district count"), and a partial fix — correcting three copies but not the fourth — would make the diagnostics and the gate disagree silently. Acceptable for one-shot multi-language tooling, but worth a shared source (e.g., a checked-in JSON the TS/Python read, with the SQL copy cross-checked by the gate itself) if a Wave-4 reuses these.
**Fix:** At minimum, add a comment in each file pointing at the other three copies so future count fixes touch all four.

---

_Reviewed: 2026-07-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
