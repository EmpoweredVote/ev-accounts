# Phase 162: IN + MD + MN + MO Candidate Seeding - Pattern Map

**Mapped:** 2026-07-04
**Files analyzed:** 12 (4 `.mts` generators, 1 flag-fix migration, 4 headshot scripts, 1 verify.sql, 1 coordinate-smoke.ts, 1 correspondence-audit.md; stance CSV/`_merge.ts`/`_push.ts`/`_push_uuid.ts` are reused as-is, not cloned)
**Analogs found:** 12 / 12 (this is a pure parameterization phase — every new file has an exact, already-executed Phase-161 analog on disk, except the IN-9 flag fix which has a partial/novel analog)

This phase is a direct clone of Phase 161's WA+AZ+TN+MA pipeline. Every `.mts` generator, headshot script, verify gate, and coordinate smoke test in 161 is production-proven and sitting on disk at `backend/scripts/`. The planner should treat each Pattern Assignment below as "copy this file, do a search-and-replace on the constants table, keep every comment block's structural shape."

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `backend/scripts/162-mo-generate.mts` | migration-generator (utility) | batch/transform (JSON→SQL) | `backend/scripts/161-tn-generate.mts` | exact (redistricted, severity-routed, 2-election) |
| `backend/scripts/162-mn-generate.mts` | migration-generator (utility) | batch/transform | `backend/scripts/161-az-generate.mts` | exact (vanilla new-election, 1-election) |
| `backend/scripts/162-in-generate.mts` | migration-generator (utility) | batch/transform | `backend/scripts/161-az-generate.mts` (+ IN-9 flag-fix prepended) | exact base pattern; flag-fix is a novel addition (see below) |
| `backend/scripts/162-md-generate.mts` | migration-generator (utility) | batch/transform | `backend/scripts/161-ma-generate.mts` | exact (races-only reuse onto `existing_race_id`) |
| `backend/migrations/{N}_fix_in9_incumbent_flags.sql` | migration (UPDATE, idempotent) | CRUD (single UPDATE) | *no direct 161 precedent* — closest structural analog: `backend/migrations/1204_...` (161's AZ roster-reconciliation `UPDATE ... candidate_status='withdrawn'` migration) | role-match only — see "Novel Pattern" section |
| `backend/scripts/seed-mo-house-headshots.py` | script (offline batch, image ingestion) | file-I/O + event-driven (per-candidate fetch) | `backend/scripts/seed-tn-house-headshots.py` | exact (2-election state, band-scoped-only `BANDS`, no election-name join) |
| `backend/scripts/seed-mn-house-headshots.py` | script (offline batch) | file-I/O | `backend/scripts/seed-ma-house-headshots.py` (or `seed-mi-house-headshots.py`) | exact (1-election state, election-scoped `BANDS`) |
| `backend/scripts/seed-in-house-headshots.py` | script (offline batch) | file-I/O | `backend/scripts/seed-ma-house-headshots.py` (or `seed-mi-house-headshots.py`) | exact (1-election state, election-scoped `BANDS`) |
| `backend/scripts/seed-md-house-headshots.py` | script (offline batch) | file-I/O | `backend/scripts/seed-ma-house-headshots.py` | exact (races-only reuse state, election-scoped `BANDS`, "incumbents already imaged" exclusion pattern) |
| `backend/scripts/162-verify.sql` | test/gate (SQL assertion script) | request-response (read-only SELECT/assert) | `backend/scripts/161-verify.sql` | exact structurally; needs 2 NEW assertion blocks (MO-SEVERE, IN9-FLAG) with no direct line-for-line precedent |
| `backend/scripts/162-coordinate-smoke.ts` | test (TS smoke script) | request-response (read-only, mirrors `electionService.ts`) | `backend/scripts/161-coordinate-smoke.ts` | exact (4-state positive samples + 1 severe-negative sample) |
| `162-mo-correspondence-audit.md` | doc/research artifact (no code) | transform (qualitative research → severity table) | `.planning/phases/161-.../161-tn-correspondence-audit.md` | exact (same rubric verbatim, same structure) |
| `backend/data/stance-research/{mo,mn,in,md}-2026-house/_merge.ts`, `_push.ts`, `_push_uuid.ts` | service (CSV validate/merge/push) | batch (CSV→DB) | `backend/data/stance-research/tn-2026-house/_push.ts` (existing-pid path) + `backend/data/stance-research/quick-candidates-2026/_push_uuid.ts` (NULL-external_id/new-pid path) | exact — **reuse verbatim, do not clone-and-edit**; only the CSV directory path changes |
| `backend/data/stance-research/{mo,mn,in,md}-2026-house/_TOPIC_SCALE_FULL.txt` | config (topic scale reference) | transform (live DB query → filtered file) | `backend/data/stance-research/tn-2026-house/_TOPIC_SCALE_FULL.txt` | exact structurally — content must be regenerated live, never copy-pasted (Pitfall 5) |

## Pattern Assignments

### `backend/scripts/162-mo-generate.mts` (migration-generator, batch/transform)

**Analog:** `backend/scripts/161-tn-generate.mts` (full file read; 338 lines)

This is the highest-value analog in the phase — TN and MO share the exact same shape: redistricted state, severity-routed withholding, 2 elections, 8/9 districts, one open seat (TN had 2 vacate-flagged incumbents; MO has 1 — Graves MO-6), one still-running incumbent facing a primary rematch (TN had none exactly like Bush/Bell but the `inc: true` + non-vacate pattern for `renominated` incumbents is identical).

**Header/comment-block pattern to copy (lines 1-24):**
```typescript
import { writeFileSync, mkdirSync } from 'fs';

// ---- TN field (validated against 160-field-table-p161.csv TN rows) ----
// Phase 161-06 Task 1: TN end-to-end seed, the heaviest slice (9 districts, 73 new records).
// ...
// SEVERE-DISTRICT WITHHOLDING (D-01b / 161-RESEARCH Pitfall 1): per the 161-01 correspondence audit
// (161-tn-correspondence-audit.md, "Severe geo_id list: 4704, 4705, 4706, 4708, 4709"), 5 of TN's 9
// districts shifted so severely under the May 2026 mid-cycle redistricting that showing the new-map
// candidate slate against the OLD-map polygon (essentials.districts/geofence_boundaries, unchanged
// until Phase 164.1) would actively mislead a voter. Severe races are wired to a dedicated, deliberately
// NON-GENERAL, past-dated "Polygon Pending" election row so electionService.ts's
// ELECTION_VISIBILITY_WINDOW evaluates FALSE for them (election_type != 'general' AND election_date >=
// CURRENT_DATE - 30 days) -- NEVER office_id NULL; office_id is ALWAYS the existing old-CD
// NATIONAL_LOWER office (D-01: races wire to the EXISTING old-numbered district rows regardless of
// severity). essentials.offices is NEVER touched (keeps the reps feed on the true old-map incumbent).
type Cand = { cd: number; name: string; party: string; inc?: boolean; vacate?: boolean };

const SEVERE_GEO_IDS = new Set([4704, 4705, 4706, 4708, 4709]);
const INC_EXT: Record<number, number> = {
  1: -47001, 2: -47002, 3: -47003, 4: -47004, 5: -47005, 6: -47006, 7: -47007, 8: -47008, 9: -47009,
};
```
**What must change for MO:** `SEVERE_GEO_IDS` from the yet-to-run `162-mo-correspondence-audit.md`'s "Severe geo_id list" (starting hypothesis: MO-5=2905, budget for MO-4/2904 and MO-6/2906 too — see Novel/Open section); `INC_EXT` = MO's FIPS-29 legacy incumbent scheme (`-29001`..`-29008`, confirmed in CONTEXT.md D-carried-forward); `FIELD` array = the 58 MO new records from `160-field-table-p162.csv`; geo prefix `29` not `47`; only **8** districts not 9 (MO has no CD-9).

**External-id assignment block to copy verbatim (lines 140-172, the `seqByCd`/`rows` loop):** identical formula shape `-(29 * 10000 + cd * 100 + seq)`; the `severe`/`election` branch (`severe ? WITHHELD_ELECTION : GENERAL_ELECTION`) carries over unchanged — this is the exact mechanism D-01b requires MO to replicate.

**Migration 1196-equivalent SQL template (lines 186-266):** copy verbatim, renaming `TN` → `MO`, `47` → `29`, and updating the 2 election names to `'MO 2026 Statewide General'` / `'MO 2026 Congressional Redistricting - Polygon Pending'`. The `WITHHELD_ELECTION` date must be MO's actual redistricting-signing/court-decision date (2026-03-24, the MO Supreme Court's 4-3 upholding date — analogous to TN's use of its bill-signing date 2026-05-07) rather than reusing TN's date. **office_id is NEVER null; essentials.offices is NEVER touched** — copy this invariant statement into the MO migration's header comment verbatim (it is the single most safety-critical line in the whole pipeline).

**Migration 1197-equivalent (lines 268-316):** the `race_candidates` join-by-`geo_id`-not-election-name pattern (line 281-296 in TN) is the critical detail to preserve — this is what lets one insert block wire both severe and non-severe MO races without branching logic.

**MO-1 Bush/Bell handling (novel wrinkle, no TN precedent):** TN's `vacate: true` flag models "incumbent retiring/withdrawing, no active row for them" — but MO-1 is different: Bell (incumbent) IS running (`inc: true`, no `vacate`), and Bush is a *separate* `FIELD` entry (not `inc`), requiring a live `SELECT id, external_id FROM essentials.politicians WHERE lower(full_name) LIKE '%bush%' AND lower(full_name) LIKE '%cori%'` check before deciding NEW vs REUSE for her row (per RESEARCH.md Pitfall 4 / Open Question 2). If she has a prior record, treat her like an `inc`-style REUSE entry pointing at her existing pid rather than a fresh external_id; if not, she is a normal `NEW` FIELD row.

---

### `backend/scripts/162-mn-generate.mts` and `backend/scripts/162-in-generate.mts` (migration-generators, vanilla new-election)

**Analog:** `backend/scripts/161-az-generate.mts` (full file read; 188 lines)

**Header pattern (lines 1-7):**
```typescript
import { writeFileSync, mkdirSync } from 'fs';

// ---- AZ field (validated against 160-field-table-p161.csv AZ rows, cross-checked
//      Wikipedia "2026 United States House of Representatives elections in Arizona") ----
// Phase 161-02 Task 1: AZ end-to-end seed (D-02 hard target: live before Jul-21 primary).
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-4001,2:-4002,3:-4003,4:-4004,5:-4005,6:-4006,7:-4007,8:-4008,9:-4009};
```
**What must change:** MN → FIPS 27, 8 districts, `INC_EXT` = `-27001`..`-27008`; IN → FIPS 18, 9 districts, `INC_EXT` = `-18001`..`-18009` — **but** IN's incumbents Baird/Carson/Messmer use *positive* SoS ids (`499386`/`499408`/`499413`) and Houchin uses `499417`, not the `-18nnn` legacy negative scheme for those 4 — confirm each incumbent's exact external_id per `160-incumbent-map.csv` row-by-row rather than assuming the uniform `-fips*1000+cd` pattern holds for every IN seat.

**Single-election migration template (lines 96-132) to copy verbatim** with name/state substitution:
```sql
-- 1187_seed_az_2026_house_elections_races.sql
...
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AZ 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'AZ'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AZ 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL, 1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-07-22'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '04'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AZ 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
```
Note: for **IN and MD**, `field_status=decided` — this phase's IN/MD elections are NOT `PROVISIONAL:`-prefixed (that marker is MN/MO-only per the Decided-vs-Late-Primary split in CONTEXT.md); the `description` string for IN's races migration should read something like `'Confirmed nominee + declared-so-far minor-party field (primary decided May-5)'` instead of AZ's `'PROVISIONAL: ...'` text — do not copy the PROVISIONAL wording onto IN.

**Candidate-insert migration template (lines 134-176)** — `sqlStr()` helper, `polInserts`/`rcInserts` loop shape, and the `NOT EXISTS` idempotency guards on both `politicians` and `race_candidates` — copy verbatim; only the FIELD array, FIPS constant, and election name change.

**IN-specific addition — flag-fix prepended (D-02):** `162-in-generate.mts` should either (a) also emit the flag-fix migration as its first `writeFileSync` call, or (b) leave the flag-fix as a wholly separate migration file authored by a preceding plan task. RESEARCH.md's recommendation (and CONTEXT.md's Claude's Discretion) is Task 1 of the IN seed plan — the planner should decide whether that means "inside `162-in-generate.mts`" or "a hand-written standalone SQL file run first." Either way, the general race's `race_candidates` INSERT for Houchin must pull her `politician_id` (`68568faf-1e0f-4ca2-89d9-bda625665712`) directly as a hardcoded REUSE entry (mirroring the `INC_EXT`/`inc: true` pattern), never derived from the (formerly-buggy) primary race's flags.

---

### `backend/scripts/162-md-generate.mts` (migration-generator, races-only reuse)

**Analog:** `backend/scripts/161-ma-generate.mts` (full file read; 192 lines)

**Header + `EXISTING_RACE_ID` map pattern (lines 1-21):**
```typescript
import { writeFileSync, mkdirSync } from 'fs';

// ---- MA field (validated against 160-field-table-p161.csv MA rows, cross-checked
//      MA SoS dem-state-primary-candidates2026.htm + declared-independent news coverage) ----
// Phase 161-08 Task 1: MA CANDIDATES-ONLY seed onto the 9 PRE-EXISTING MA races
//   (existing_race_id from 160-race-preexistence-audit.csv). NO elections/races INSERT here.
//   Clark (MA-5) and Pressley (MA-7) already have race_candidates rows (160-race-preexistence-audit.csv
//   rows 29/31) -- NEVER re-inserted. Moulton (MA-6, retired) gets NO incumbent row.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean };

const EXISTING_RACE_ID: Record<number, string> = {
  1: '3bfd0d89-cbb0-4bd4-952b-798214c29f84',
  ...
};
```
**What must change for MD:** `EXISTING_RACE_ID` = the 8 MD UUIDs already quoted in RESEARCH.md Must-Answer #4 (`2401→cb9a70c8-...`, `2402→01c39962-...`, ... `2408→52874d42-...`); `INC_PID`/`INC_NAME` = MD's 8 incumbents (Harris/Olszewski/Elfreth/Ivey/Hoyer[retired]/McClain Delaney/Mfume/Raskin) — **but unlike MA, MD has ZERO pre-wired `race_candidates` rows**, so MD needs no "ALREADY-WIRED-SKIP" branch at all (delete the Clark/Pressley-equivalent skip logic entirely) — every one of MD's 8 incumbents gets a fresh REUSE-ADD-ROW insert (lines 135-146 pattern), same as MA's non-Clark/Pressley 6 incumbents.

**PROVISIONAL-marking UPDATE (lines 164-168) — likely NOT needed for MD:** MA's migration marks its 9 existing races `description = 'PROVISIONAL: ...'` because MA is a late-primary reconciliation case; **MD is `field_status=decided`** — do not copy this UPDATE block for MD (or repurpose its wording to reflect the open independent/minor-party window per D-04a: `'Confirmed nominees + declared-so-far minor-party field; unaffiliated window open to 2026-08-03'`).

**Candidate + incumbent insert pattern (lines 110-146):** copy verbatim including the `NOT EXISTS (race_id, politician_id)` idempotency guard — this guard is "good practice, not a live protection" for MD per RESEARCH.md's Must-Answer #4 confirmation of 0 pre-existing rows, but keep it anyway (matches the milestone-standing idempotent-migration rule).

**Self-check console output block (lines 179-191)** — the `Clark/Pressley re-insert attempted: FAIL` sanity check has no MD-equivalent risk (0 pre-existing rows), so this specific check can be dropped from MD's script, or repurposed to assert "0 of MD's 8 incumbents already have a race_candidates row before this migration runs" as a pre-flight sanity print.

---

### `backend/migrations/{N}_fix_in9_incumbent_flags.sql` (novel — no direct 161 precedent)

**No 161 file matches this role+data-flow combination exactly** (161 had no incumbent-flag-bug fix). The closest structural analog on disk is **AZ's roster-reconciliation migration** (`backend/migrations/1204_...`, referenced in `161-verify.sql` lines 29-34/236-244) — a standalone idempotent UPDATE on existing `race_candidates` rows, gated with a `WHERE candidate_status <> 'withdrawn'`-style guard so re-runs are 0-row no-ops, verified by a subsequent gate assertion (`161-verify.sql` CRITERION 7). The IN-9 fix should follow the same "small standalone idempotent UPDATE migration + a dedicated gate CRITERION" shape.

**Exact SQL already specified in RESEARCH.md's Pattern 4 (Architecture Patterns section) — copy this verbatim as the migration body:**
```sql
-- Migration: fix_in9_incumbent_flags.sql
BEGIN;
UPDATE essentials.race_candidates
SET is_incumbent = true
WHERE id = '9d2de2ae-2fef-48b6-b3d4-2787166b78df'  -- Erin Houchin
  AND is_incumbent = false;

UPDATE essentials.race_candidates
SET is_incumbent = false
WHERE id IN (
  '037ad94f-d379-4f9c-baf1-a75742a46eac',  -- James H. (Jim) Graham
  '283b1fdd-3d89-4f82-a065-098324f2f967',  -- Keil L. Roark
  'a9233775-b8af-423e-aea6-734c2855e5ac',  -- Tim Peck
  '926943ad-ee64-4ddb-b9e7-6475a6a2d087'   -- Brad A. Meyer
) AND is_incumbent = true;
COMMIT;

-- Verification (must return exactly 1 row, is_incumbent=true, Houchin only):
SELECT rc.id, rc.full_name, rc.is_incumbent
FROM essentials.race_candidates rc
WHERE rc.race_id = '7d3f0042-eb15-462b-bf14-df15244c5d16'
ORDER BY rc.full_name;
```
**Before authoring:** re-verify both id sets (`candidate_pid` vs `race_candidates.id`) with a live SELECT per RESEARCH.md's Assumptions Log A2 — do not trust the `160-race-preexistence-audit.csv` positional column read alone. **Idempotency mechanism:** the `WHERE is_incumbent = {opposite value}` guards on each UPDATE make re-runs 0-row no-ops — this is the standard idempotent-UPDATE shape used throughout the AZ-reconciliation migration too (`SET candidate_status = 'withdrawn' WHERE candidate_status <> 'withdrawn'`-style guard).

**Ordering requirement (D-02, Pitfall 2):** this migration MUST run before any IN general-race/`race_candidates` migration is applied — sequence it as its own numbered migration file authored/run ahead of `162-in-generate.mts`'s output, or as literally the first statement block inside that same generator's migration output.

---

### Headshot scripts — `seed-mo-house-headshots.py` (band-scoped, 2-election variant)

**Analog:** `backend/scripts/seed-tn-house-headshots.py` (full file read; 324 lines)

**Critical departure to replicate (module docstring, lines 1-24, and the `BANDS` dict, lines 54-59):**
```python
"""
seed-tn-house-headshots.py — Phase 161-06 (v2.22 Wave 3). CLONE of seed-mi-house-headshots.py, all
guards intact incl. Phase-156 hardening (dropped american kw + pre-1940 historical-year reject).
Only change: TN band added.
...
NOTE (161-06 D-01b): TN's 5 severe (redistricting-withheld) districts' candidates are seeded on the
"TN 2026 Congressional Redistricting - Polygon Pending" election, NOT the general — but they still
get headshots here. The target query is scoped by external_id BAND ONLY (no election-name join),
because seeding is complete regardless of whether the district's race currently surfaces on
/elections. Incumbents (-47001..-47009) are excluded by construction (they fall outside the band).
"""
...
BANDS = {
    'TN': (-470910, -470101, 'Tennessee'),
}
```
**Target-selection query (lines 263-271) — band-only, NO election join:**
```sql
SELECT DISTINCT p.id, p.external_id, p.full_name
FROM essentials.politicians p
JOIN essentials.race_candidates rc ON rc.politician_id = p.id AND rc.candidate_status = 'active'
WHERE p.external_id BETWEEN %s AND %s
  AND p.is_active = true
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
ORDER BY p.external_id;
```
**For MO:** `BANDS = {'MO': (-290899, -290101, 'Missouri')}` (band bounds from the 58 new MO record external_ids); this exact 3-tuple shape (no 4th `election` element) is required, matching TN's variance from the vanilla single-election `BANDS` 4-tuple shape. Every other function (`wiki_get`, `resolve_portrait`, `crop_to_4_5`, the wrong-person guard regexes `_NON_PERSON_TITLE`/`_BAD_DISAMBIG`/`_HISTORICAL_YEAR`) is copied byte-for-byte unchanged — only the module docstring, `BANDS` dict, and `RESULTS_JSON` filename (`_mo-house-headshot-results.json`) change.

### Headshot scripts — `seed-mn-house-headshots.py`, `seed-in-house-headshots.py`, `seed-md-house-headshots.py` (election-scoped, 1-election variant)

**Analog:** `backend/scripts/seed-ma-house-headshots.py` (partial read, lines 1-60; structurally identical to `seed-mi-house-headshots.py`)

**`BANDS` dict shape (4-tuple, includes election name) and the election-join query (grep-confirmed in `seed-mi-house-headshots.py` lines 51/246-262):**
```python
BANDS = {
    'MA': (-250902, -250101, 'Massachusetts', '2026 Massachusetts General Election'),
}
...
lo, hi, sname, election = BANDS[state]
...
        JOIN essentials.elections el ON el.id = r.election_id
        WHERE el.name = %s
```
**For MN:** `BANDS = {'MN': (-270899, -270101, 'Minnesota', 'MN 2026 Statewide General')}`. **For IN:** `BANDS = {'IN': (-180999, -180101, 'Indiana', 'IN 2026 Statewide General')}` (verify IN's exact new-record band bounds against `162-in-generate.mts`'s emitted range once authored — RESEARCH.md's illustrative band was `-180901..-180999`, confirm final bounds live). **For MD:** `BANDS = {'MD': (-2440899, -2440101, 'Maryland', <whatever the MD races' pre-existing election name is>)}` — MD's races are pre-existing (`existing_race_id`), so the election name for the join must be looked up live (`SELECT DISTINCT el.name FROM essentials.elections el JOIN essentials.races r ON r.election_id=el.id WHERE r.id = ANY(ARRAY[<8 existing_race_id UUIDs>])`) rather than assumed — do not hardcode a guessed MD election name without that one-time lookup.

---

### `backend/scripts/162-verify.sql` (gate, request-response read-only assertion)

**Analog:** `backend/scripts/161-verify.sql` (full file read; 439 lines)

**Structural shape to clone (election-resolution block, lines 77-114):**
```sql
DO $$
DECLARE
  az_eid uuid; wa_eid uuid; tn_gen_eid uuid; tn_withheld_eid uuid; ma_eid uuid;
  ...
BEGIN
  SELECT id INTO az_eid FROM essentials.elections WHERE name = 'AZ 2026 Statewide General';
  ...
  IF az_eid IS NULL OR ... THEN
    RAISE EXCEPTION 'FAIL setup: one or more Phase-161 elections missing (...)';
  END IF;
```
For 162: resolve `in_eid`, `md_eid` (or the 8 MD `existing_race_id`s if no single election name applies cleanly — MD's races may span more than one election name if `160-race-preexistence-audit.csv`'s 8 rows aren't all under one election; verify live), `mn_eid`, `mo_gen_eid`, `mo_withheld_eid`.

**The combined working-set temp table pattern (lines 121-145)** — `_house` CTE-style temp table scoped by `election_id IN (...)` AND `district_type='NATIONAL_LOWER'` AND `substr(geo_id,1,2) IN ('18','24','27','29')` — copy verbatim structure.

**CRITERION 1 (race-count scope) — copy verbatim pattern, substitute counts:** IN 9, MD 8, MN 8, MO 8 = 33 total (vs. 161's AZ 9 + WA 10 + TN 9 + MA 9 = 37).

**CRITERION 6-equivalent — NEW MO-SEVERE block (no line-for-line 161 precedent to copy, but the exact TN-SEVERE block, lines 208-230, is the direct structural template):**
```sql
SELECT COUNT(DISTINCT geo_id) INTO v_leaked
FROM _house
WHERE st = 'TN'
  AND geo_id = ANY(ARRAY['4704', '4705', '4706', '4708', '4709'])
  AND race_election_id <> tn_withheld_eid;
IF v_leaked <> 0 THEN
  RAISE EXCEPTION 'FAIL TN-SEVERE-WITHHELD: ...', v_leaked;
END IF;
```
Substitute MO's own severe geo_id list (from `162-mo-correspondence-audit.md`, once run) and `mo_withheld_eid`/`mo_gen_eid`.

**NEW IN9-FLAG block (genuinely novel, no 161 precedent at all) — author fresh, following the RESEARCH.md-specified verification shape:**
```sql
SELECT rc.full_name, rc.is_incumbent INTO ... -- or a COUNT-based assertion
FROM essentials.race_candidates rc
WHERE rc.race_id = '7d3f0042-eb15-462b-bf14-df15244c5d16'
ORDER BY rc.full_name;
-- Expected: Houchin true; Graham/Roark/Peck/Meyer all false.
```
Wrap this as a `RAISE EXCEPTION` guard (count of `is_incumbent=true` rows on that race_id must equal exactly 1, and it must be Houchin's `race_candidates.id`), matching the style of every other CRITERION block in the file.

**MD reuse-dedup CRITERION (analog: lines 246-258, the MA-CLARK/MA-PRESSLEY check)** — MD needs an analogous "exactly 1 row per (race_id, politician_id)" check across all 8 incumbents + 13 new challengers rather than a name-specific 2-row check (MD has no pre-wired incumbents to specifically re-check like Clark/Pressley) — a `GROUP BY race_id, politician_id HAVING COUNT(*) > 1` style dedup assertion is the right generalization.

**Honest-skip pin tables (`_stance_skip`, `_img_skip`) — copy the exact structural shape (lines 274-381)** — `CREATE TEMP TABLE ... ON COMMIT DROP`, `INSERT ... VALUES (VALUES list) JOIN essentials.politicians p ON p.external_id = v.external_id ORDER BY p.id` (for stance skips, ordered by resolved politician_id per the "143 lesson") and `ORDER BY external_id` (for image skips) — these ordering disciplines are load-bearing (an ordering mismatch false-fails per the comment at line 36-38).

**USHC3-04/05 assertion blocks (lines 383-435)** — copy verbatim; only the pin-table contents and `_new_cands` band bounds change (IN/MD/MN/MO bands instead of AZ/WA/TN/MA bands).

---

### `backend/scripts/162-coordinate-smoke.ts` (test, request-response read-only)

**Analog:** `backend/scripts/161-coordinate-smoke.ts` (full file read; 209 lines)

**`STATE_CONFIG`/`SAMPLES` pattern (lines 44-60) — copy verbatim shape:**
```typescript
const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  AZ: { election: 'AZ 2026 Statewide General', geoPrefix: '04' },
  ...
  TN: { election: 'TN 2026 Statewide General', geoPrefix: '47' }, // surfacing election only (severe races live on the withheld election)
  ...
};
const SAMPLES: Sample[] = [
  { state: 'AZ', geoId: '0401', minActive: 2 },
  ...
];
const SEVERE_TN_GEO_ID = '4709';
```
For 162: `STATE_CONFIG` gets IN/MD/MN/MO entries (MO's entry uses the surfacing `'MO 2026 Statewide General'` election name, same "surfacing election only" comment pattern as TN); `SAMPLES` = one contested in-district coordinate per state (4 positive samples, `MIN_DISTRICTS = 4`); a NEW `SEVERE_MO_GEO_ID` constant + a copy of the negative-sample block (lines 155-194) proving a coordinate inside a severe MO district surfaces ZERO races on the MO surfacing election.

**Positive-sample query block (lines 79-153) and negative-sample block (lines 155-194) — copy verbatim**, both use `public.ST_Covers`/`public.ST_PointOnSurface`/`public.ST_SetSRID`/`public.ST_MakePoint` (note the `public.` PostGIS schema prefix per the project-wide standing rule) and the same `race_id` / `active_cands` / `challengers` / `null_pid` aggregation shape.

---

### `162-mo-correspondence-audit.md` (research artifact, no code)

**Analog:** `.planning/phases/161-.../161-tn-correspondence-audit.md` (full file read; 78 lines)

**Severity Rubric section — copy verbatim, word-for-word (this is a locked, cross-phase-reusable rubric per D-01a):**
```markdown
## Severity Rubric

A district is scored **SEVERE** if either condition holds:
1. **>25% of the district's population moved to a different congressional district** between the old (2022, currently-live-in-`essentials.districts`) map and the new (2026) map, OR
2. **The district's core anchor city/county changed** — i.e., the metro area or county that defined the district's political and geographic identity under the old map is no longer the anchor under the new map (either lost entirely to another district, or a new metro anchor was added that wasn't previously present).

Otherwise a district is scored **NOT-SEVERE**.

**Evidence basis:** No shapefile/GIS diff was performed... Severity is derived from (a) explicit county-reassignment reporting in named sources, (b) a quantitative proxy — the shift in each district's notional 2024 presidential-election result recalculated under the new boundaries vs. the old boundaries (Wikipedia's redistricting partisan-breakdown table, sourced to Dave's Redistricting App), and (c) explicit "anchor changed" statements from named reporting.
```
**Per-District Severity Table structure (the markdown table shape, lines 32-44)** — 8 rows for MO's CDs (not 9), same columns: `geo_id | old_cd | incumbent | anchor_county_old | anchor_county_new | pct_population_moved (proxy) | severity | rationale`.

**"Notes for downstream consumers" section (lines 54-60)** — copy this closing-analysis pattern: state which districts confirmed the pre-audit hypothesis vs. which expanded/contracted the severe set, and explicitly flag the risk of under-scoping (per RESEARCH.md's Pitfall 1: TN's audit found 5/9 severe against a working assumption of "maybe just 1-2" — MO's audit must review **all 8** districts, not just the MO-4/5/6 hypothesis).

**Source-URL citation block (lines 64-75)** — same "all fetched directly during this audit" discipline; MO's audit needs its own named-source URLs (MO Supreme Court ruling coverage, Wikipedia "2026 Missouri redistricting" if it exists, MO SoS announcement, local news on the Cleaver/MO-5 remap) rather than reusing any TN URL.

---

### Stance pipeline reuse (NOT cloned — reused verbatim)

**`_merge.ts` / `_push.ts` (existing-pid path) / `_push_uuid.ts` (new NULL-external_id-pid path)** — these are NOT per-state files to author; they are already-generic scripts. `backend/data/stance-research/tn-2026-house/_push.ts` (full file read, 100 lines) resolves `external_id → politician_id` via a live `essentials.politicians` lookup and writes `inform.politician_answers` + `inform.politician_context` + `essentials.quotes` inside a single transaction, with the surname-leak guard on `readrank_selected` quotes (lines 81-91). `backend/data/stance-research/quick-candidates-2026/_push_uuid.ts` (full file read, 101 lines) is the UUID-keyed variant for candidates whose CSV carries a `politician_id` column directly instead of `external_id` — needed for **any MO-1 Bush scenario where she's treated as a genuinely new record with no external_id yet resolved**, or any candidate pushed before their politicians-row's external_id is confirmed.

**Practical guidance for the planner:** copy `backend/data/stance-research/tn-2026-house/_push.ts` byte-for-byte into `mo-2026-house/_push.ts`, `mn-2026-house/_push.ts`, `in-2026-house/_push.ts`, `md-2026-house/_push.ts` (only the relative import path `'../../../src/lib/db.js'` stays the same — zero other line changes needed, this is a copy-paste of a completely state-agnostic script). Same for `_merge.ts` (not read in full this session, but its role per RESEARCH.md is "per-candidate CSV → validate → merge" and it is referenced identically across every `{state}-2026-house/` directory).

**`_TOPIC_SCALE_FULL.txt` — do NOT copy content, only the directory convention.** Per Pitfall 5, this file must be rebuilt from a live `SELECT id, key, category FROM inform.compass_topics WHERE is_active = true ORDER BY category, key` query, filtered to the federal-24 subset, for each of the 4 new state directories — copying an old file's content risks staleness (the live topic count was 44 as of Phase 161 and "will be different by execution time" per that phase's own Pitfall 5 warning).

---

## Shared Patterns

### Antipartisan invariant (party never on race_candidates)
**Source:** every generator script's `races`/`race_candidates` INSERT (e.g., `161-tn-generate.mts` line 199, `161-az-generate.mts` implicit) + `161-verify.sql` CRITERION 5 (lines 194-206)
**Apply to:** all 4 new `.mts` generators and `162-verify.sql`
```sql
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, '...', NULL, 1, '...'
```
`primary_party` is always `NULL`; party is only ever readable from the FIELD array's data for reporting/CSV purposes, never persisted onto `race_candidates`.

### `sqlStr()` escaping helper (SQL injection prevention)
**Source:** every `.mts` generator (`161-tn-generate.mts` line 133-135, `161-az-generate.mts` line 69, `161-ma-generate.mts` line 78)
**Apply to:** all 4 new `162-{mo,mn,in,md}-generate.mts` files — every free-text field (candidate name, source string) MUST pass through this helper before string interpolation into generated SQL:
```typescript
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }
```

### External-id band assignment (`-(fips*10000 + cd*100 + seq)`)
**Source:** `161-tn-generate.mts` lines 140-172, `161-az-generate.mts` lines 71-88, `161-ma-generate.mts` lines 80-93
**Apply to:** all 4 new generators — the `seqByCd` per-CD counter + `-(FIPS*10000+cd*100+seq)` formula is identical across all three state-types (redistricted/vanilla/reuse-only); only the FIPS constant changes (IN=18, MD=24, MN=27, MO=29).

### Idempotent `NOT EXISTS` guards on every INSERT
**Source:** all 3 generator analogs, every `politicians`/`race_candidates`/`elections`/`races` INSERT statement
**Apply to:** all new migration SQL — `WHERE NOT EXISTS (SELECT 1 FROM ... WHERE external_id = ...)` for politicians, `WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(...))` (join-by-geo_id states) or `... AND rc.politician_id = p.id` (reuse states) for race_candidates.

### Election-visibility withholding mechanism (`ELECTION_VISIBILITY_WINDOW`)
**Source:** `161-tn-generate.mts` module comment (lines 9-18), `161-verify.sql` header comment (lines 18-27), `161-coordinate-smoke.ts` module comment (lines 17-24)
**Apply to:** `162-mo-generate.mts` only (MO is this phase's only redistricted/severity-routed state)
```sql
(e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
```
A dedicated, non-general, >30-days-past-dated "Polygon Pending" election row is the ONLY mechanism to suppress a subset of one state's races while `office_id` stays populated and `essentials.offices` stays untouched.

### Headshot pipeline core (Wikipedia pageimages → license filter → crop/resize → upload)
**Source:** `backend/scripts/seed-tn-house-headshots.py` lines 61-320 (the entire `wiki_get`/`resolve_portrait`/`crop_to_4_5`/`download`/`upload`/`main` chain), identical across all headshot scripts on disk
**Apply to:** all 4 new `seed-{mo,mn,in,md}-house-headshots.py` — copy the ENTIRE file except the module docstring and the `BANDS` dict; the wrong-person guard regexes (`_NON_PERSON_TITLE`, `_BAD_DISAMBIG`, `_HISTORICAL_YEAR`, `_desc_is_historical`, `_title_is_candidate_person`) are hardened, tested, and must not be modified.

### Read-only gate discipline (`SELECT`-only, `DO $$ ... $$`, `RAISE EXCEPTION` per criterion)
**Source:** `161-verify.sql` entire structure
**Apply to:** `162-verify.sql` — WRITE-FREE except `CREATE TEMP TABLE ... ON COMMIT DROP`; every criterion is a `SELECT COUNT(*) INTO v_x ... IF v_x <> 0/expected THEN RAISE EXCEPTION ... END IF; RAISE NOTICE 'PASS ...'` block.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `backend/migrations/{N}_fix_in9_incumbent_flags.sql` | migration (UPDATE) | CRUD (correction) | No prior seeding phase (149-161) had a pre-existing incumbent-flag bug to fix; the AZ roster-reconciliation migration (1204) is the closest structural cousin (idempotent UPDATE + gate criterion) but targets `candidate_status`, not `is_incumbent`, and corrects newly-seeded rows rather than a stale March SoS-excel import. Use RESEARCH.md's Pattern 4 SQL directly (already fully specified, no further research needed) rather than searching for a closer match. |
| MO's severity-list content inside `162-mo-generate.mts` | data (constant) | n/a | Cannot be sourced from any existing file — it is the direct output of the `162-mo-correspondence-audit.md` task, which has not yet run at pattern-mapping time. The audit's rubric and output *shape* are fully precedented (TN); its *content* (which MO geo_ids are severe) is necessarily novel per-phase data. |

## Metadata

**Analog search scope:** `backend/scripts/` (all `161-*.mts`, `161-verify.sql`, `161-coordinate-smoke.ts`, `seed-*-house-headshots.py`), `backend/data/stance-research/{tn,ma,az,wa}-2026-house/` (`_push.ts`, `_merge.ts` not fully re-read), `backend/data/stance-research/quick-candidates-2026/_push_uuid.ts`, `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-tn-correspondence-audit.md`
**Files scanned:** 12 read in full (161-tn-generate.mts, 161-az-generate.mts, 161-ma-generate.mts, 161-verify.sql, 161-coordinate-smoke.ts, 161-tn-correspondence-audit.md, seed-tn-house-headshots.py, tn-2026-house/_push.ts, quick-candidates-2026/_push_uuid.ts) + 2 partial (seed-ma-house-headshots.py header/BANDS, seed-mi-house-headshots.py grep for BANDS/election-join shape)
**Pattern extraction date:** 2026-07-04

---

*Phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca*
