# Phase 165: Small-Delegation States (17 states) — Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** ~9 categories of new files across 4 tracks (NV+ME reconciliation, UT re-key, AK RCV, 13 routine states) + verify/smoke gate + stance pipeline
**Analogs found:** 9/9 categories have a strong, directly-cloneable analog. Zero "no analog" files this phase — this is the 5th run of an already-proven pipeline.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `backend/scripts/165-nv-me-generate.mts` (Track 1: NV+ME candidates-only reconciliation) | migration-generator (service/utility) | CRUD (candidates-only onto pre-existing races) | `backend/scripts/164-or-generate.mts` | exact |
| `backend/scripts/165-ut-generate.mts` (Track 2: UT re-key) | migration-generator | CRUD (new election+races on existing offices + cross-district pid re-link) | `backend/scripts/163-la-generate.mts` (elections/races on existing offices) + `164-or-generate.mts` (pid reuse without recreation) — hybrid | role-match (novel shape, best 2-source composite) |
| `backend/scripts/165-ak-generate.mts` (Track 3: AK RCV/jungle) | migration-generator | CRUD (single at-large jungle race, `primary_party=NULL`) | `backend/scripts/163-la-generate.mts` | exact (jungle-primary mechanics identical; single-district not 6) |
| `backend/scripts/165-{nm,ne,wv,id,hi,nh,ri,mt,de,nd,sd,vt,wy}-generate.mts` (Track 4: 13 routine states) | migration-generator | CRUD (vanilla create-election-first) | `backend/scripts/162-mn-generate.mts` | exact |
| `backend/migrations/12NN_seed_{state}_2026_house_*.sql` (all tracks) | migration | CRUD | `backend/migrations/1235_seed_or_2026_house_candidates.sql`, `1228/1229_seed_la_2026_house_*.sql`, `1210/1211_seed_mn_2026_house_*.sql` | exact |
| `backend/scripts/seed-{state}-house-headshots.py` (all 17 states) | batch script (offline) | file-I/O (Wikipedia fetch → Storage upload → DB insert) | `backend/scripts/seed-ms-house-headshots.py` | exact |
| `backend/scripts/165-verify.sql` | test (SQL assertion gate) | request-response (read-only) | `backend/scripts/164-verify.sql` (+ NOTOUCH block from `backend/scripts/1641-verify.sql`) | exact |
| `backend/scripts/165-coordinate-smoke.ts` | test (integration smoke) | request-response (read-only) | `backend/scripts/164-coordinate-smoke.ts` | exact |
| `backend/data/stance-research/{state}-2026-house/_merge.ts`, `_push.ts`, `_push_uuid.ts`, `_AGENT_BRIEF.md` | batch script (offline) / provider | batch (CSV merge/validate) + CRUD (DB push) | `backend/data/stance-research/ks-2026-house/_merge.ts` + `_push.ts` + `_push_uuid.ts` + `_AGENT_BRIEF.md` | exact |

## Pattern Assignments

### Track 1 — `backend/scripts/165-nv-me-generate.mts` (migration-generator, CRUD candidates-only)

**Analog:** `backend/scripts/164-or-generate.mts` (full file read, 137 lines — OR's candidates-only reuse onto 6 pre-existing race UUIDs).

**Imports pattern** (lines 1):
```typescript
import { writeFileSync, mkdirSync } from 'fs';
```

**Core pattern — hardcoded `EXISTING_RACE_ID` map, NO election/race INSERT** (lines 13-25):
```typescript
const EXISTING_RACE_ID: Record<number, string> = {
  1: '8dfd6e35-f91d-4d14-bcec-ae983035da51',
  2: '504a156a-d4e6-4abe-9a85-a418c0135805',
  // ... one UUID per district, carried from the field table's existing_race_id column
};
const INC_EXT: Record<number, number> = {1:-4102001, /* ... */};
const INC_NAME: Record<number, string> = {1:'Suzanne Bonamici', /* ... */};
const SEQ_START: Record<number, number> = {1:14, /* D-04 sub-band starts, else 1 */};
```
For NV/ME, adapt this shape but note the RESEARCH's Track-1 caveats: (a) Lynn Chapman (NV) needs a **fix-not-recreate UPDATE** on an existing `race_candidates.politician_id` row (`id=08dfb911-9ddc-4c0d-85a2-fb14884a9160`) — this is NOT present in the OR analog and needs a bespoke `UPDATE essentials.race_candidates SET politician_id = ... WHERE id = '08dfb911-...'::uuid AND politician_id IS NULL;` block; (b) Ronald Russell / Matthew Dunlap (ME) need a live `SELECT * FROM essentials.politicians WHERE full_name ILIKE '%russell%' OR ILIKE '%dunlap%'` check before the polInserts block — reuse any hit's `id`, INSERT only if none found (Open Question 1 / Pitfall 3 discipline).

**Migration template — description UPDATE + politician INSERT + race_candidates INSERT, no elections/races INSERT** (lines 68-127, key excerpt 105-127):
```typescript
const migration = `-- 1235_seed_or_2026_house_candidates.sql
-- Phase 164-03: OR CANDIDATES-ONLY seed onto the 6 PRE-EXISTING OR U.S. House races
--   ('OR 2026 General'; races NOT created here -- reuse existing_race_id, D-03).
BEGIN;

-- Mark existing races with decided/open-window wording (description-only; idempotent)
UPDATE essentials.races
SET description = '...'
WHERE id IN (${raceIdList})
  AND (description IS NULL OR description NOT LIKE '%...%');

-- (a) new challenger records (idempotent on external_id)
${polInserts}
-- (b)+(c) challenger + incumbent race_candidates (NOT EXISTS on (race_id, politician_id))
${rcInserts}
COMMIT;
`;
```

**Error handling / idempotency:** every INSERT wrapped in `WHERE NOT EXISTS (...)`; the `race_candidates` guard checks the `(race_id, politician_id)` pair, not name — critical for NV/ME where the race already has other candidates.

**Verify command style** (lines 91-93 of `164-01-PLAN.md`'s Task 2 verify block — clone for NV/ME):
```bash
psql "$DATABASE_URL" -tAc "SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL) FROM essentials.races r JOIN essentials.elections e ON e.id=r.election_id WHERE e.name='NV 2026 Statewide General'"
```

---

### Track 2 — `backend/scripts/165-ut-generate.mts` (migration-generator, novel hybrid shape)

**No single existing analog does exactly this** (new election + races on EXISTING offices + cross-district incumbent pid re-link, i.e. candidacy on a *different* geo_id's race than the office currently reflects). Compose from two proven pieces:

**Piece A — new election + races wired to EXISTING offices** (clone from `backend/scripts/163-la-generate.mts` lines 143-183, the LA jungle-race-on-existing-office template — structurally identical to what UT needs, minus the primary_party=NULL part since UT is a normal partisan race):
```typescript
let raceInserts = '';
for (let cd = 1; cd <= 6; cd++) {
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(desc)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = ${sqlStr(election)}
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
```
For UT: `el.name = 'UT 2026 Statewide General'`, `d.geo_id` = the **NEW** geo_id (4902/4903/4904) for Moore/Maloy/Kennedy's race, `4901` for the open McAdams race — but the office join still resolves via `d.district_id` since geo_ids 4901-4904 persist per the wiring contract (no office/district INSERT needed at all, unlike LA which needed no office insert either — same shape).

**Piece B — reuse an EXISTING pid without recreating the politician record, INSERT only into `race_candidates`** (clone from `164-or-generate.mts` lines 93-103, the incumbent-reuse-by-external_id block) — but UT's incumbents have **no external_id** (per RESEARCH A2), so key by known UUID literal instead:
```typescript
// UT incumbents keyed by KNOWN EXISTING UUID (no external_id exists for them):
const INC_PID: Record<number, string> = { 4902: 'e365a1d4-...', 4903: 'a7983eb6-...', 4904: '9e3164d5-...' };
rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '${pid}'::uuid, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, true, 'active', ${sqlStr(source)}
FROM essentials.races r JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
WHERE d.geo_id = ${sqlStr(geo)} AND d.district_type='NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=r.id AND rc.politician_id='${pid}'::uuid);
`;
```
Same live-reuse discipline applies to McAdams/Crosby/Udell/Larsen (existing primary-scoped pids, per Pitfall 3) — query `essentials.politicians` by full_name before generating SQL, never re-derive a fresh external_id for them.

**New-challenger external_id formula (still apply the standard formula despite no-external_id incumbents):** `-(49*10000+cd*100+seq)` (RESEARCH A2) — same `seqByCd` pattern as `162-mn-generate.mts` lines 74-91.

**Binding constraint — do NOT emit any `UPDATE essentials.offices` / `essentials.districts` statement.** This is the single most important negative constraint for this file; the closest positive-control analog for verifying it is `164.1-ut-wiring-contract.md` itself (read in full above) — the plan/execute step should re-read this contract verbatim, not re-derive it.

**Verification NOTOUCH pattern** (clone from `backend/scripts/1641-verify.sql` lines 197-227, the D04-NOTOUCH per-row-md5 offices guard):
```sql
SELECT md5(coalesce(string_agg(
         o.id::text || ':' || coalesce(o.district_id::text, '') || ':' || coalesce(o.representing_state, ''),
         ',' ORDER BY o.id), ''))
  INTO v_md5
FROM essentials.districts d
JOIN essentials.offices o ON o.district_id = d.id
WHERE d.district_type = 'NATIONAL_LOWER' AND length(d.geo_id) = 4 AND substr(d.geo_id, 1, 2) = '49';
-- capture baseline BEFORE the UT migration runs; assert unchanged AFTER, inside 165-verify.sql's UT-REKEY block
```

---

### Track 3 — `backend/scripts/165-ak-generate.mts` (migration-generator, jungle/RCV)

**Analog:** `backend/scripts/163-la-generate.mts` (full file read, 251 lines) — same `primary_party=NULL` single-race-per-district shape, scaled down to AK's 1 at-large district (no severe-withholding block needed; no per-party primaries; no runoff).

**Core pattern — one race, `primary_party=NULL`, ALL candidates (all parties) wired to it** (lines 143-150):
```typescript
raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(desc)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = ${sqlStr(election)}
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
```
For AK: single iteration (geo `0200`), `election = 'AK 2026 Statewide General'` (new — AK has no pre-existing race, unlike LA which had a withheld/general split).

**Incumbent reuse (Begich, legacy 4-digit external_id `-2000`)** — treat like LA's `INC_EXT` reuse pattern (lines 26, 104-108) but Begich already has 9 existing stances (`partial`-tier per RESEARCH) so no stance re-derivation needed, only the `race_candidates` row.

**Description / PROVISIONAL wording** — clone LA's `RACE_DESC` constant pattern (line 133): `'PROVISIONAL: pre-primary qualified field (top-four-RCV), cull >= <AK primary date>'` (RESEARCH's exact template, Open Question 2 — verify exact date at plan/execute time via `elections.alaska.gov`).

**D-04 sub-band:** `safe_start_seq=5` (seqs 1-4 pre-occupied) — apply via the same `seqByCd`/`SEQ_START` mechanism used in `164-or-generate.mts` line 25 and `163-la-generate.mts` line 91.

---

### Track 4 — `backend/scripts/165-{13 states}-generate.mts` (migration-generator, vanilla)

**Analog:** `backend/scripts/162-mn-generate.mts` (full file read, 191 lines) — the canonical create-election-first, 1 election + N races on existing offices, N new politicians + active race_candidates template. This is the single most-reused analog in the milestone (161→162→163→164→165 wave-5 repetition).

**Imports** (line 1):
```typescript
import { writeFileSync, mkdirSync } from 'fs';
```

**Field array + incumbent map** (lines 8-63, structure only):
```typescript
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-27001, /* ... FIPS*1000+cd */};
const FIELD: Cand[] = [
  { cd:1, name:'Brad Finstad', party:'R', role:'R', inc:true },
  { cd:1, name:'Gregory A. Goetzman', party:'R', role:'R' },
  // ...
];
```
Open-seat handling: `vacate:true` on the incumbent's FIELD row → `decision:'REUSE-NO-ROW'` (no active `race_candidates` row for that pid) — this is the exact pattern for NE-2 (Bacon retired), MT-1 (Zinke retired), SD (Johnson ran for Gov), WY (Hageman retired), NH-1 (Pappas ran for Senate, zero-incumbent district).

**external_id assignment loop** (lines 74-91):
```typescript
const seqByCd: Record<number, number> = {};
for (const c of FIELD) {
  const geo = '27' + String(c.cd).padStart(2, '0');
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(27 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}
```
Apply the D-04 `safe_start_seq` floors from RESEARCH's collision table (NM-1/2/3, NE-3, NH-1, MT-2, DE, VT) by seeding `seqByCd[cd]` to `safe_start_seq - 1` before the loop starts for that district (same technique as `164-or-generate.mts`'s `SEQ_START` map, line 25).

**Migration 1 — election + races** (lines 99-135, full block already excerpted in Track 2 above — reuse verbatim, changing only FIPS/state name/election name/description/date-gating).

**Migration 2 — politicians + race_candidates** (lines 137-179):
```typescript
const newRows = rows.filter(r => r.decision === 'NEW');
const activeRows = rows.filter(r => r.decision === 'NEW' || r.decision === 'REUSE'); // excludes REUSE-NO-ROW

let polInserts = '';
for (const r of newRows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

let rcInserts = '';
for (const r of activeRows) {
  const { first, last } = nameParts(r.name);
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${r.is_incumbent}, 'active', ${sqlStr(r.source)}
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE el.name = ${sqlStr(ELECTION_NAME)} AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}
```

**Console diagnostics tail** (lines 181-190) — clone verbatim, it's the generator's own self-check (dup external_id, dup full_name, per-district active counts).

---

### Headshots — `backend/scripts/seed-{state}-house-headshots.py` (all 17 states)

**Analog:** `backend/scripts/seed-ms-house-headshots.py` (full file read, 330 lines) — itself a clone-of-a-clone (traces to `seed-ca-house-headshots.py`, the validated Phase-149 pipeline).

**The ONLY lines every state clone changes** (module docstring header, lines 1-27, and the `BANDS` dict, lines 60-65):
```python
BANDS = {
    'MS': (-280499, -280101, 'Mississippi'),
}
```
For Phase 165: one `BANDS` entry per state keyed by the state's new-challenger external_id range from the field table (e.g. `'NM': (-350399, -350101, 'New Mexico')`), plus the localized `, <state>` place-token inside `_NON_PERSON_TITLE` (line 93, the ONE regex token every clone localizes — all other guards are byte-for-byte frozen per the docstring's explicit warning).

**Wrong-person guards (DO NOT MODIFY — copy byte-for-byte):**
- `_NON_PERSON_TITLE` (lines 92-94) — election/city/county/year/referendum page rejection.
- `_BAD_DISAMBIG` (lines 96-100) — non-political-homonym Wikipedia disambiguator rejection (racing driver, musician, athlete, etc.).
- `_HISTORICAL_YEAR` / `_desc_is_historical` (lines 102-110) — pre-1940 historical-homonym rejection (the Hancock/Bouchard/Barringer incident guard).
- `_title_is_candidate_person` (lines 112-125) — requires BOTH first name and surname to appear in the resolved page title's base string.

**Query target (band-scoped, no election-name join)** (lines 269-277):
```python
cur.execute("""
    SELECT DISTINCT p.id, p.external_id, p.full_name
    FROM essentials.politicians p
    JOIN essentials.race_candidates rc ON rc.politician_id = p.id AND rc.candidate_status = 'active'
    WHERE p.external_id BETWEEN %s AND %s
      AND p.is_active = true
      AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
    ORDER BY p.external_id;
""", (lo, hi))
```
Note for UT: incumbents have NO external_id at all, so the band query naturally excludes them (correct — they're already imaged from prior phases); new UT challengers DO get the standard `-(49*10000+...)` band and are picked up normally.

**Invocation convention:** `py backend/scripts/seed-{state}-house-headshots.py --state {ABBR}` (never `python3`, per project convention already baked into every plan's task description).

---

### Verify gate — `backend/scripts/165-verify.sql`

**Analog:** `backend/scripts/164-verify.sql` (full file read, 307 lines) for the 5 standard blocks, PLUS `backend/scripts/1641-verify.sql` lines 194-227 for the NEW NOTOUCH block UT needs.

**Standard structure — resolve elections, build one combined temp table, then a numbered CRITERION sequence** (lines 38-127 pattern, reuse verbatim structure):
```sql
DO $$
DECLARE
  nv_eid uuid; me_eid uuid; ut_eid uuid; ak_eid uuid; /* ...13 more ... */
BEGIN
  SELECT id INTO nv_eid FROM essentials.elections WHERE name = 'NV 2026 Statewide General';
  -- ...
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE r.election_id WHEN nv_eid THEN 'NV' ... END AS st, r.id AS race_id, r.office_id, r.description,
         d.geo_id, rc.id AS rc_id, rc.politician_id, rc.full_name, rc.candidate_status, rc.is_incumbent, p.external_id
  FROM essentials.races r
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE r.election_id IN (nv_eid, me_eid, ut_eid, ak_eid, ...)
    AND d.district_type = 'NATIONAL_LOWER';
  -- CRITERION 1: race counts per state; CRITERION 2: 0 NULL office_id;
  -- CRITERION 3: 0 active NULL politician_id; CRITERION 4: 0 dup full_name within state;
  -- CRITERION 5: no party column on race_candidates (antipartisan structural invariant)
```

**NEW blocks this gate needs (per RESEARCH's Validation Architecture section) — clone these exact shapes:**
- **NV-RECONCILE / ME-RECONCILE** — clone CRITERION 7 (OR-REUSE) from `164-verify.sql` lines 146-166 (`v_or_reuse`/`v_or_wrong`/`v_or_dup` pattern: assert the state's races are exactly the pre-existing UUIDs, no new election authored, no duplicated `(race_id, politician_id)` pair). Add the Chapman-specific NULL-pid-fixed assertion as a 1-row scalar check.
- **UT-REKEY** — clone the D04-NOTOUCH block from `1641-verify.sql` lines 197-227 verbatim (see Track 2 excerpt above), scoped to FIPS `49`; ALSO assert Moore/Maloy/Kennedy's pids are `is_incumbent=true` on races for geo_ids 4902/4903/4904 respectively (not 4901-4903, the OLD mapping) and Owens (`cb87ddbb-...`) has 0 active `race_candidates` rows anywhere (clone CRITERION 6 OPEN-SEAT pattern, `164-verify.sql` lines 128-144).
- **AK-JUNGLE** — assert exactly 15 active `race_candidates` rows on AK's single race (simple `COUNT(*)` scalar check, no analog needed beyond the `_house` temp table).
- **PROVISIONAL** — clone CRITERION 8 verbatim (`164-verify.sql` lines 168-178), extend the `st IN (...)` lists to the 10 late-primary states/tracks (AK/HI/NH/RI/DE/VT/WY) vs. the 7 decided (NV/UT/NM/NE/WV/ID/MT/ND/SD; ME handled separately per its own reuse wording).
- **COLLISION-BAND** — clone CRITERION 9 verbatim (`164-verify.sql` lines 180-198), extend the `geo_id`/floor pairs to RESEARCH's 9-row table (NM-1/2/3, NE-3, NH-1, MT-2, AK, DE, VT).
- **HEADSHOT / UNSOURCED / COVERAGE pin-table blocks** — clone lines 220-304 verbatim (the `_new_cands` temp table + `_stance_skip`/`_img_skip` pin tables + the two final USHC3-04/05 assertion queries) — these are 100% mechanical, only the pinned external_id lists change per phase.

---

### Coordinate smoke — `backend/scripts/165-coordinate-smoke.ts`

**Analog:** `backend/scripts/164-coordinate-smoke.ts` (full file read, 143 lines).

**STATE_CONFIG + SAMPLES table structure** (lines 33-53) — clone verbatim shape, 17 entries (one contested/open-seat district per state, per RESEARCH's per-state notes — e.g. `WY: { election: 'WY 2026 Statewide General', geoPrefix: '56' }`, sample geoId `5600`, `minActive: 2` given the 18-candidate field). UT needs `election: 'UT 2026 Statewide General'`; NV/ME need their exact pre-existing election name strings (`'NV 2026 Statewide General'`, `'2026 Maine General Election'`).

**Core surfacing query — ST_Covers point-in-polygon, `public.ST_*` prefix mandatory** (lines 88-106):
```typescript
const surf = await pool.query(
  `SELECT r.id AS race_id,
          COUNT(*) FILTER (WHERE rc.candidate_status = 'active') AS active_cands,
          COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = false) AS challengers,
          COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.politician_id IS NULL) AS null_pid
   FROM essentials.races r
   JOIN essentials.offices o ON o.id = r.office_id
   JOIN essentials.districts d ON d.id = o.district_id
   JOIN essentials.geofence_boundaries gb
     ON gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
   LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE r.election_id = $1 AND d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = $4
     AND gb.geometry IS NOT NULL
     AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))
   GROUP BY r.id`,
  [eid, lng, lat, cfg.geoPrefix]
);
```
`MIN_DISTRICTS = 17` (one sample per state track — note ME's 2 races both RCV-general so pick either one).

---

### Stance pipeline — `backend/data/stance-research/{state}-2026-house/*`

**Analog:** `backend/data/stance-research/ks-2026-house/` (directory, files read: `_merge.ts`, `_push.ts`, `_push_uuid.ts`, `_AGENT_BRIEF.md`) — the current-convention directory shape (`{state}-2026-house`, not the older bare `{state}-house` naming from 154-159).

**`_merge.ts` pattern** (`ms-house/_merge.ts`, full file, 65 lines) — validates every per-candidate CSV against `IN_SCOPE` external_ids + the 24-key `FEDERAL` topic set + value range 1-5 + non-empty reasoning + ≥1 http source, then concatenates into one `_merged-{state}-2026-house.csv`. Change only the `IN_SCOPE` Set and `OUT` path per state.

**`_push.ts` pattern** (`ms-house/_push.ts`, full file, 100 lines) — resolves `external_id → politician_id` and `topic_key → topic_id`, then per-row: upsert `inform.politician_answers` (`ON CONFLICT (politician_id, topic_id) DO UPDATE`), upsert `inform.politician_context` (sources array), and conditionally insert `essentials.quotes` with surname-leak detection on the de-identified quote text before setting `readrank_selected`. Runs inside a single `BEGIN`/`COMMIT`/`ROLLBACK` transaction.

**`_push_uuid.ts` variant** (`ks-2026-house/_push_uuid.ts`, full file, 101 lines) — **use this for UT's re-linked incumbents and any NV/ME/UT record with a NULL external_id**: identical to `_push.ts` except the CSV carries a `politician_id` (UUID) column instead of `external_id`, and resolution is `SELECT id, full_name FROM essentials.politicians WHERE id = ANY($1::uuid[])` instead of the external_id lookup. This is the exact tool needed for UT's Moore/Maloy/Kennedy/McAdams/Crosby/Udell/Larsen (no external_id) stance rows, and for NV's/ME's incumbents if their pids also lack external_id.

**`_AGENT_BRIEF.md` pattern** (`ks-2026-house/_AGENT_BRIEF.md`, lines 1-49) — the standing dispatch brief every stance-research agent wave receives: real-fetched-sources-only, chairs-not-polarity, 0-unsourced, honest-skip-with-search-trail (`_SKIPS.md` line format: `- <external_id> <name>: <what you searched> — no usable stance evidence`), iSideWith-as-fallback-with-AI-inferred-row-exclusion, one-CSV-per-candidate output convention, and the mandatory re-fetch verification pass before finishing. Clone verbatim per state, changing only the phase/state header line and the topic-scale filename reference.

## Shared Patterns

### `sqlStr()` escaping (SQL-injection safety on free-text candidate names)
**Source:** every generator script (e.g. `162-mn-generate.mts` line 72, `163-la-generate.mts` line 79, `164-or-generate.mts` line 46)
**Apply to:** all 4 tracks' `.mts` generators, every free-text field before SQL interpolation
```typescript
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }
```

### Idempotent migrations (`NOT EXISTS` guards, never a bare INSERT)
**Source:** every migration template in every analog above
**Apply to:** all politicians/races/elections/race_candidates INSERTs across all tracks — re-running any migration must be a 0-row no-op.

### Antipartisan invariant (party never on the candidate card)
**Source:** `164-verify.sql` CRITERION 5 (lines 122-126); reinforced in every generator's migration header comment
**Apply to:** all `race_candidates` INSERTs — no `party`/`party_affiliation` column exists or should ever be added; party context lives only in the reconciliation CSV / `races.primary_party` (NULL for jungle states).
```sql
SELECT COUNT(*) INTO v_party_cols FROM information_schema.columns
WHERE table_schema='essentials' AND table_name='race_candidates' AND column_name IN ('party','party_affiliation');
```

### `pool.query()` only, never PostgREST (essentials/inform schema)
**Source:** project-wide rule (CLAUDE.md memory), enforced in every `_push.ts`/`_push_uuid.ts` (`import { pool } from '../../../src/lib/db.js'`)
**Apply to:** all stance pipeline TS scripts and any ad-hoc DB probes.

### PostGIS `public.ST_*` prefix (never `extensions.ST_*`)
**Source:** `164-coordinate-smoke.ts` lines 73-74, 103 — every ST_Covers/ST_PointOnSurface/ST_MakePoint/ST_SetSRID call
**Apply to:** `165-coordinate-smoke.ts` exclusively (the only new file this phase that touches PostGIS).

### Headshot wrong-person guard suite (frozen, never modified)
**Source:** `seed-ms-house-headshots.py` lines 92-125 (`_NON_PERSON_TITLE`, `_BAD_DISAMBIG`, `_HISTORICAL_YEAR`/`_desc_is_historical`, `_title_is_candidate_person`)
**Apply to:** all 17 `seed-{state}-house-headshots.py` clones — only the docstring, `BANDS` dict, `RESULTS_JSON` filename, and the localized place-token change.

### Honest-skip pin discipline (stance + headshot)
**Source:** `164-verify.sql` `_stance_skip` (lines 224-243) and `_img_skip` (lines 249-259) temp tables
**Apply to:** `165-verify.sql` — every whole-record stance skip needs a `reason` string citing the search trail; every headshot skip is pinned by bare external_id; both pin tables must be re-derived fresh from that phase's actual `_SKIPS.md`/results-JSON files, not copy-pasted from 164's pins.

## No Analog Found

None. All 9 file categories have a directly-cloneable or 2-source-composite analog from Phases 162-164 + 164.1's UT wiring contract. UT's re-key shape (Track 2) is the one genuinely novel composite in the milestone, but both of its component halves (new races on existing offices; incumbent-pid-reuse-without-recreation) are independently proven (163-la / 164-or respectively), and the binding contract (`164.1-ut-wiring-contract.md`) fully specifies the target end-state.

## Metadata

**Analog search scope:** `backend/scripts/` (all `16{1,2,3,4}-*-generate.mts`, `*-verify.sql`, `*-coordinate-smoke.ts`, `1641-*` polygon/verify scripts, `seed-*-house-headshots.py`), `backend/data/stance-research/` (`{state}-2026-house/` directories, `{state}-house/` legacy directories for provenance only), `.planning/phases/164-*/` (all 13 PLAN.md/SUMMARY.md + CONTEXT.md), `.planning/phases/163-*/163-RESEARCH.md`, `.planning/phases/164.1-*/164.1-ut-wiring-contract.md`.
**Files scanned:** ~40 (full reads: `164-or-generate.mts`, `162-mn-generate.mts`, `163-la-generate.mts`, `164-verify.sql`, `164-coordinate-smoke.ts`, `seed-ms-house-headshots.py`, `164.1-ut-wiring-contract.md`, `ms-house/_merge.ts`+`_push.ts`, `ks-2026-house/_push_uuid.ts`+`_AGENT_BRIEF.md`, `164-01-PLAN.md`; targeted reads: `1641-verify.sql` lines 190-230; directory listings: `backend/scripts/`, `backend/data/stance-research/`, `.planning/phases/164-*/`).
**Pattern extraction date:** 2026-07-07
