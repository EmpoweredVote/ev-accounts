---
phase: 160-field-resolution-stance-gap-diagnostic
verified: 2026-07-03T14:00:00Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/10 must-haves verified
  gaps_closed:
    - "USHC3-01 Part B: collision-free negative external_id bands verified per state before any insert"
  gaps_remaining: []
  regressions: []
---

# Phase 160: Field Resolution + Stance-Gap Diagnostic Verification Report

**Phase Goal:** Wave-3 US House field-resolution + stance-gap diagnostic — resolve the 2026 ballot field for the final 38 states / 178 districts into a master field table (with seeding_phase column 161-165), grounded in prod DB diagnostics (incumbent map, external-id collision audit, race-preexistence audit), so seeding phases 161-165 can execute without re-research.
**Verified:** 2026-07-03T14:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (commit b61f75df)

## Gap Closure Verification (this pass)

The single prior gap concerned `backend/scripts/diag-160-external-id-collision.ts` never testing the real `cd=0` at-large band for AK, DE, ND, SD, VT, WY (it looped `cd = 1..numDistricts`, which for all 6 single-district states means it only ever tested a synthetic, nonexistent `cd=1` band).

**Fix verified directly from the diff and the file on disk (commit `b61f75df`, `fix(160-01): scan at-large cd=0 bands in collision audit (CR-01 / verification gap)`):**

```diff
-    for (let cd = 1; cd <= numDistricts; cd++) {
+    // At-large states are keyed cd=0 / geo_id XX00 in essentials.districts and the
+    // incumbent map — their live band is -(fips*10000 + 0*100 + seq). A 1..1 loop
+    // would test a nonexistent CD1 band and report false assurance (CR-01).
+    const cds = numDistricts === 1 ? [0] : Array.from({ length: numDistricts }, (_, i) => i + 1);
+    for (const cd of cds) {
```

Read the live file (`backend/scripts/diag-160-external-id-collision.ts:95-99`) — the diff is present exactly as committed, not just claimed. Since `DELEG[AK]=DELEG[DE]=DELEG[ND]=DELEG[SD]=DELEG[VT]=DELEG[WY]=1`, all 6 at-large states now resolve `cds=[0]` and are scanned against the true `-(fips*10000+0*100+seq)` band. All other (multi-district) states are unaffected — `cds` still expands to `1..numDistricts` for them, so the 16 originally-audited collision districts are unchanged.

**Commit contents confirmed** (`git show --stat b61f75df`): touches exactly `backend/scripts/diag-160-external-id-collision.ts` (+8/-2) and `.planning/.../160-negative-id-audit.csv` (+3 rows) — a narrow, single-purpose fix, no unrelated changes.

**Regenerated CSV verified on disk** — `160-negative-id-audit.csv` now has **19 data rows** (confirmed by direct read + `wc -l` = 20 total lines incl. header):

| state | cd | geo_id | collision_count | safe_start_seq |
|---|---|---|---|---|
| AK | 0 | 0200 | 4 | 5 |
| DE | 0 | 1000 | 26 | 48 |
| VT | 0 | 5000 | 5 | 6 |

- AK-CD0: `colliding_seqs=1-4`, `max_seq=4`, `free_slots_remaining=95`, `safe_start_seq=5` — arithmetically correct (first free seq after the collision run).
- DE-CD0: `colliding_seqs` = 26 explicit odd-numbered values (1,2,3,4,5,7,9,...,47), `max_seq=47`, `safe_start_seq=48` — arithmetically correct, and DE-CD0 is the most-occupied at-large band found (26/99 slots).
- VT-CD0: `colliding_seqs=1-5`, `max_seq=5`, `safe_start_seq=6` — arithmetically correct.
- `geo_id` values (`0200`, `1000`, `5000`) match the `fips.padStart(2,'0') + cd.padStart(2,'0')` formula in the script AND match the at-large `geo_id` convention already used in `160-field-table.csv` (`AK,0,0200`; `DE,0,1000`; `VT,0,5000` — confirmed by direct grep of that file).
- ND-CD0, SD-CD0, WY-CD0 correctly produce **no rows** — they are now genuinely scanned (their `DELEG` entries are also `1`, so they follow the same `cds=[0]` code path as AK/DE/VT) and found clean, which is a real "tested and clean" result rather than the prior "never tested" silence.
- KY-CD1 and OK-CD1 retain `safe_start_seq=200` (the explicit alternate-sub-band districts) — unaffected by this fix, as expected, since the fix only touches at-large single-district states.
- Total audited districts is now 19 (16 original + 3 newly-discovered: AK/DE/VT), matching the commit message and the script's own updated console log text.

**Conclusion: the gap is genuinely closed.** The fix is minimal, correctly scoped, arithmetically verified, and consistent with every other Phase-160 artifact's at-large `cd=0` convention.

## Regression Check — Other 9 Must-Haves Untouched

Confirmed via `git log` that the fix commit did not touch any other phase artifact:

- `160-field-table.csv` — only commit touching this file is `ba8ddd99` (`docs(160-07): merge 5 seeding-group partials into master 160-field-table.csv`), predating the fix. Unchanged.
- `160-incumbent-map.csv` — only commit touching this file is `bd6ab8ae` (`feat(160-01): add diag-160-incumbent-stance-gap.ts + 178-row incumbent map`), predating the fix. Unchanged.
- `160-race-preexistence-audit.csv`, `160-field-table-p161..p165.csv`, `160-FIELD-TABLE.md`, `diag-160-validate-field-table.py`, `160-verify.sql` — not touched by `b61f75df` (confirmed via `git show --stat`, which lists only the collision script + its own CSV).

No regressions. All previously-VERIFIED truths (1, 3, 4, 5, 6, 7, 8, 9, 10 from the prior report) stand as-is.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | 178-row incumbent map exists keyed by (NATIONAL_LOWER, geo_id), tier split 13 zero / 154 partial / 11 done | ✓ VERIFIED | Unchanged from prior verification — `160-incumbent-map.csv` = 178 rows; tier split matches; file untouched by the fix commit (`git log` confirms only `bd6ab8ae`). |
| 2 | Per-district negative external_id collision audit exists, collision-free bands verified per state before any insert | ✓ VERIFIED | **Gap closed.** `diag-160-external-id-collision.ts` now derives `cds = numDistricts === 1 ? [0] : [1..n]`, correctly testing the real at-large `cd=0` band for AK/DE/ND/SD/VT/WY. Re-run (commit `b61f75df`) regenerated `160-negative-id-audit.csv` to 19 rows: the original 16 (KY/OR/OK/KS/NV/NM/NE/ME/NH/MT) plus 3 newly-surfaced at-large collisions (AK-CD0: 4, DE-CD0: 26, VT-CD0: 5), each with an arithmetically-correct `safe_start_seq`. ND/SD/WY at-large bands are now genuinely scanned and confirmed clean (not merely absent from an incomplete loop). |
| 3 | Pre-existing race/candidate audit sweeps ANY election_date, surfaces ME/MD/MA/NV/OR baseline + IN-9/NV-2 anomalies | ✓ VERIFIED | Unchanged from prior verification — file untouched by fix commit. |
| 4 | All three Plan-01 diagnostic scripts are SELECT-only against prod | ✓ VERIFIED | Re-confirmed: the fix only adds a loop-derivation line and a comment; no new query statements introduced. Still zero INSERT/UPDATE/DELETE across all three scripts. |
| 5 | Master `160-field-table.csv` = 178 rows, seeding_phase distribution {161:37,162:33,163:36,164:38,165:34}, 88 decided / 90 late-primary, every row has non-empty source_url | ✓ VERIFIED | Unchanged from prior verification — file untouched by fix commit (only commit is `ba8ddd99`, predates `b61f75df`). |
| 6 | Only AK+ME carry rcv=true; AL is district-split 3 decided/4 late; LA is 6 open-primary-nov3 rows; 29 rows carry existing_race_id exactly for MA9/MD8/OR6/NV4/ME2 | ✓ VERIFIED | Unchanged from prior verification — file untouched by fix commit. |
| 7 | `diag-160-validate-field-table.py` (CSV shape gate) passes against the master CSV | ✓ VERIFIED | File untouched by fix commit (`git log` shows only `53638580`); master CSV also untouched, so the previously-confirmed PASS/EXIT=0 result stands. |
| 8 | `160-verify.sql` is a write-free gate asserting the discovered 29-race baseline (not a blanket zero) + 178 counts + empty vacancy set | ✓ VERIFIED (read, not re-run per instructions) | Unchanged from prior verification — file untouched by fix commit. |
| 9 | `160-FIELD-TABLE.md` documents the 88/90 split, AL district-split, LA jungle-primary, AK/ME RCV over-indulgence, per-state new-record counts, and a Phase-167 primary-date cluster table | ✓ VERIFIED | Unchanged from prior verification — file untouched by fix commit; confirmed it does not reference the collision-audit count, so nothing there is stale. |
| 10 | Mid-cycle redistricting flags (TN/MO/AL/LA/UT) and NOTE-* markers (IN-9, CT-1, KY/OK collision, NV-2 NULL-pid, UT re-key) are carried forward for downstream phases | ✓ VERIFIED | Unchanged from prior verification — `160-field-table.csv` untouched by the fix; `NOTE-EXTERNAL-ID-COLLISION` markers for KY-1/OK-1 confirmed still present and correct (the fix does not require adding new NOTE markers to the field table for AK/DE/VT — that is a seeding-time concern for phases 161/163/165, using the audited `safe_start_seq` values directly from `160-negative-id-audit.csv`). |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/scripts/diag-160-incumbent-stance-gap.ts` | Read-only 178-row incumbent map + tier query | VERIFIED | Unchanged, untouched by fix |
| `backend/scripts/diag-160-external-id-collision.ts` | Per-district collision audit, 0 UNRESOLVED, all 38 states genuinely scanned | ✓ VERIFIED | Loop now correctly derives `cd=0` for all 6 at-large single-district states; fix confirmed by direct read of the file and the commit diff |
| `backend/scripts/diag-160-race-preexistence-audit.ts` | ANY-election_date sweep + anomaly flags | VERIFIED | Unchanged, untouched by fix |
| `.planning/.../160-incumbent-map.csv` | 178 rows | VERIFIED | Unchanged, untouched by fix |
| `.planning/.../160-negative-id-audit.csv` | 19 rows, per-district safe_start_seq, including at-large cd=0 bands | ✓ VERIFIED | 19 data rows confirmed on disk incl. AK-CD0/DE-CD0/VT-CD0 with arithmetically-correct safe_start_seq; ND/SD/WY genuinely scanned clean |
| `.planning/.../160-race-preexistence-audit.csv` | Full-column dump, IN-9/NV-2 anomalies | VERIFIED | Unchanged, untouched by fix |
| `.planning/.../160-field-table-p161.csv` .. `p165.csv` | 5 seeding-group partials, 37/33/36/38/34 rows | VERIFIED | Unchanged, untouched by fix |
| `.planning/.../160-field-table.csv` | Master 178-row table | VERIFIED | Unchanged, untouched by fix |
| `.planning/.../160-FIELD-TABLE.md` | Human view, all special cases + Phase-167 clusters | VERIFIED | Unchanged, untouched by fix |
| `backend/scripts/diag-160-validate-field-table.py` | CSV shape gate, exits 0 | VERIFIED | Unchanged, untouched by fix |
| `backend/scripts/160-verify.sql` | Write-free DB gate, discovered 29-race baseline | VERIFIED (read-only inspection) | Unchanged, untouched by fix |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `diag-160-incumbent-stance-gap.ts` | `essentials.districts`→`offices`→`politicians` | `(district_type='NATIONAL_LOWER', geo_id)` join | WIRED | Unchanged from prior verification |
| `diag-160-incumbent-stance-gap.ts` | `inform.politician_answers` | `COUNT(*)` per politician_id | WIRED (see WR-01, unresolved but non-blocking) | Unchanged from prior verification — latent risk, did not manifest |
| `diag-160-external-id-collision.ts` | `essentials.politicians WHERE external_id < 0` | live per-computed-value check, now including `cd=0` at-large bands | ✓ WIRED | Fixed — all 38 states / 6 at-large + 32 multi-district states are genuinely queried against the loaded negative-id set |
| `160-field-table.csv` | `160-field-table-p161.csv`..`p165.csv` | concatenation | VERIFIED | Unchanged from prior verification |
| `160-verify.sql` | `essentials.races`/`elections`/`districts` | discovered 29-race assertion | VERIFIED (structural) | Unchanged from prior verification |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| USHC3-01 | 160-01 through 160-07 (all 7 plans declare it) | Field resolution for 178 districts/38 states, incumbent map, collision-free external_id bands, race-preexistence baseline | ✓ SATISFIED | Field resolution, incumbent map, and race-preexistence baseline previously verified. The clause "collision-free negative external_id bands verified per state before any insert" is now satisfied for all 38 states, including the 6 at-large states previously untested. |

No orphaned requirements — REQUIREMENTS.md maps USHC3-01 to Phase 160 only, and all 7 plans declare `requirements: [USHC3-01]`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `backend/scripts/diag-160-external-id-collision.ts` | 94-99 (was 94) | ~~Hardcoded `cd = 1..numDistricts` never reaches the real at-large `cd=0` convention~~ — **RESOLVED** by commit `b61f75df` | ✓ Resolved | Was 🛑 Blocker (CR-01) in prior verification; now closed. |
| `backend/scripts/diag-160-incumbent-stance-gap.ts` | 179, 201 | `stance_count` subquery counts ALL `inform.politician_answers` topics, not filtered to the federal-24 key set | ⚠️ Warning (unchanged, non-blocking) | Latent misclassification risk (160-REVIEW.md WR-01); did not manifest this session — tier split matches the researched 13/154/11 baseline exactly |
| `backend/scripts/diag-160-race-preexistence-audit.ts` | 117, 189, 231 | `election_date::text` conversion via `.toISOString().slice(0,10)` is timezone-dependent | ⚠️ Warning (unchanged, non-blocking) | Did not manifest on this US-timezone machine; portability risk only (160-REVIEW.md WR-02) |
| `backend/scripts/diag-160-validate-field-table.py` | 134-137 | AL split assertion no-ops on a malformed `cd` value | ⚠️ Warning (unchanged, non-blocking) | No malformed rows found in current master CSV (160-REVIEW.md WR-03) |
| `backend/scripts/diag-160-validate-field-table.py` | 87-99 | No per-district `geo_id` uniqueness check | ⚠️ Warning (unchanged, non-blocking) | 178/178 unique geo_ids confirmed in current master CSV (160-REVIEW.md WR-04) |

No TBD/FIXME/XXX debt markers found in any Phase-160-created file. Prior research/plan docs (`160-RESEARCH.md`, `160-01-PLAN.md`, `160-PATTERNS.md`, `160-01-SUMMARY.md`) still reference the original "16/178 districts collide" finding — these are historical session records of the research/build-time state and are not stale in a misleading way (they predate the CR-01 fix and are not consulted by seeding phases 161-165, which will read `160-negative-id-audit.csv` directly).

### Human Verification Required

None. This is a read-only data/diagnostic phase; all must-haves are mechanically checkable against the CSVs, scripts, and git history.

### Downstream Note for Phases 161/163/165 (Seeding)

- **DE-CD0** is the most-occupied at-large band discovered: 26/99 sequence slots already used by pre-existing negative external_ids. Any new Delaware at-large House candidate records inserted during seeding MUST start at `safe_start_seq=48` (per `160-negative-id-audit.csv`), not `seq=1`.
- **AK-CD0**: start at `safe_start_seq=5`. **VT-CD0**: start at `safe_start_seq=6`.
- **ND-CD0, SD-CD0, WY-CD0**: genuinely clean (0 collisions) — safe to use `seq=1` onward for these three at-large bands.
- **KY-CD1 and OK-CD1** remain flagged for the alternate sub-band: `safe_start_seq=200` (unaffected by this fix). The `NOTE-EXTERNAL-ID-COLLISION` markers on those rows in `160-field-table.csv` stand as previously verified.
- Seeding phases must read `safe_start_seq` per-district from `160-negative-id-audit.csv` (not assume `seq=1` for any of the 19 flagged districts) before computing new negative `external_id` values.

### Gaps Summary

None. The single gap from the prior verification pass — the collision-audit script's failure to scan the real `cd=0` at-large band for AK/DE/ND/SD/VT/WY — is closed by commit `b61f75df`. The fix is narrow (touches only the collision script and its own output CSV), arithmetically correct (verified safe_start_seq math for all 3 newly-surfaced collision districts), and does not disturb any of the other 9 previously-verified must-haves (confirmed via git log that the field table and incumbent map files have no commits after their original creation). Phase 160 goal is fully achieved: the master field table, incumbent map, and now-complete external-id collision audit together let seeding phases 161-165 execute without re-research.

---

_Verified: 2026-07-03T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
