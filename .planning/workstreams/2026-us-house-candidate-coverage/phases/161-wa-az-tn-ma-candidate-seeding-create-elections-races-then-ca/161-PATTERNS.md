# Phase 161: WA + AZ + TN + MA Candidate Seeding - Pattern Map

**Mapped:** 2026-07-03
**Files analyzed:** ~15 file/file-group targets (4 generators, up to 7 migrations, 4 headshot scripts, 4 stance-pipeline dir groups, 1 gate SQL, 1 coordinate smoke, 1 audit artifact)
**Analogs found:** 15 / 15 (every mechanical piece has a direct, previously-executed analog in this repo; only the TN election-visibility withholding trick and the TN correspondence audit are net-new)

This is a **pure-data phase** — no application/backend code changes, only migrations + one-off `.mts`/`.py`/`.ts` scripts that generate/push data. "Role" below is repurposed for this context (generator, migration, gate, etc.) since controller/component/service don't apply.

## File Classification

| New File (this phase) | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `backend/scripts/161-az-generate.mts` | generator (migration-SQL emitter) | transform/batch | `backend/scripts/159-mi-generate.mts` | exact |
| `backend/scripts/161-wa-generate.mts` | generator | transform/batch | `backend/scripts/159-mi-generate.mts` | exact |
| `backend/scripts/161-tn-generate.mts` | generator | transform/batch | `backend/scripts/159-mi-generate.mts` + `electionService.ts` (withholding logic, novel) | exact (create part) / novel (withhold part) |
| `backend/scripts/161-ma-generate.mts` | generator (candidates-only, reuse-race) | transform/batch | `backend/migrations/1148_seed_va_2026_house_candidates.sql` (VA 159-03 hand-authored; no `.mts` generator existed for VA, so treat 1148 itself as the shape-analog) | role-match |
| `backend/migrations/11XX_seed_az_2026_house_elections_races.sql` | migration | CRUD/batch | `backend/migrations/1146_seed_mi_2026_house_elections_races.sql` | exact |
| `backend/migrations/11XX_seed_wa_2026_house_elections_races.sql` | migration | CRUD/batch | `backend/migrations/1146_seed_mi_2026_house_elections_races.sql` | exact |
| `backend/migrations/11XX_seed_tn_2026_house_elections_races.sql` | migration | CRUD/batch | `1146_...` + novel withheld-election-row pattern (no direct prior-phase precedent) | exact (base) / novel (TN severe-race extension) |
| `backend/migrations/11XX_seed_az_2026_house_candidates.sql` | migration | CRUD/batch | `backend/migrations/1147_seed_mi_2026_house_candidates.sql` | exact |
| `backend/migrations/11XX_seed_wa_2026_house_candidates.sql` | migration | CRUD/batch | `backend/migrations/1147_seed_mi_2026_house_candidates.sql` | exact |
| `backend/migrations/11XX_seed_tn_2026_house_candidates.sql` | migration | CRUD/batch | `backend/migrations/1147_seed_mi_2026_house_candidates.sql` | exact |
| `backend/migrations/11XX_seed_ma_2026_house_candidates.sql` | migration | CRUD/batch | `backend/migrations/1148_seed_va_2026_house_candidates.sql` | exact |
| `backend/scripts/seed-az-house-headshots.py`, `seed-wa-...`, `seed-tn-...`, `seed-ma-...` | headshot ingestion script | file-I/O + CRUD | `backend/scripts/seed-mi-house-headshots.py` (also `seed-tx-ny-house-headshots.py` for the multi-state `--state` flag variant) | exact |
| `backend/data/stance-research/{az,wa,tn,ma}-2026-house/*.csv` (per-candidate stance CSVs) | data (CSV) | batch | `backend/data/stance-research/mi-2026-house/*.csv`, `va-2026-house/*.csv` | exact |
| `backend/data/stance-research/{az,wa,tn,ma}-2026-house/_merge.ts` | utility (CSV validate+merge) | transform/batch | `backend/data/stance-research/wa-house-a/_merge.ts` (an EXISTING WA-incumbent directory with the exact merge shape needed) | exact |
| `backend/data/stance-research/{state}-2026-house/_push.ts` (existing-pid) / `_push_uuid.ts` (new NULL-external_id pid) | push script | CRUD (transactional) | `backend/data/stance-research/mi-2026-house/_push.ts` / `backend/data/stance-research/quick-candidates-2026/_push_uuid.ts` | exact |
| `backend/scripts/161-verify.sql` | gate (read-only assertion) | request-response (SELECT-only) | `backend/scripts/156-verify.sql` (3-state pattern, skip-pin conventions) + `backend/scripts/158-verify.sql` (multi-state coordinate-adjacent gate) | exact (base) / novel (TN non-surfacing assertion block) |
| `backend/scripts/161-coordinate-smoke.ts` | test (smoke) | request-response (read-only) | `backend/scripts/158-coordinate-smoke.ts` | exact (base) / novel (negative-result sample for withheld TN district) |
| `backend/scripts/161-tn-correspondence-audit.ts` (or plain markdown artifact) | analysis/research artifact | batch (no DB writes) | No direct prior-phase script precedent — build from the skeleton in `161-RESEARCH.md` "Code Examples" section; treat as net-new | none (net-new; researcher already provided a skeleton) |

## Pattern Assignments

### `backend/scripts/161-{az,wa,tn}-generate.mts` (generator, transform/batch)

**Analog:** `backend/scripts/159-mi-generate.mts` (200 lines, read in full)

**Field-array + external_id assignment pattern** (lines 1–102):
```typescript
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-26001, 2:-26002, /* ... */};  // incumbents keep OLD external_id scheme
const FIELD: Cand[] = [
  { cd:1, name:'Jack Bergman', party:'R', role:'R', inc:true },
  { cd:1, name:'Callie Barr', party:'D', role:'D' },
  // ... one row per candidate, per district
];

const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '26' + String(c.cd).padStart(2, '0');   // <-- swap FIPS: WA='53', AZ='04', TN='47'
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(26 * 10000 + c.cd * 100 + seqByCd[c.cd]);   // <-- swap 26 for state FIPS per D-03/negative-id-audit
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}
```

**SQL-escape helper (mandatory, V5 input validation)** (line 86):
```typescript
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }
```

**Migration-1 (elections+races) emission** (lines 110–145) — write to a template string, then `writeFileSync`:
```typescript
const m1146 = `-- 1146_seed_mi_2026_house_elections_races.sql
BEGIN;
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MI 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MI 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL, 1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '26'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'MI 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
COMMIT;
`;
writeFileSync('migrations/1146_seed_mi_2026_house_elections_races.sql', m1146);
```
For AZ/WA (cull date differs per state — use each state's own primary+X window per the field table). TN's version additionally needs the withheld-election-row insert for severe districts (see novel pattern below) — the generator should branch per-district on the D-01a severity output.

**Migration-2 (politicians + race_candidates) emission** (lines 147–189):
```typescript
const newRows = rows.filter(r => r.decision === 'NEW');
const activeRows = rows.filter(r => r.decision === 'NEW' || r.decision === 'REUSE'); // excludes REUSE-NO-ROW (vacated seats)

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
WHERE el.name = 'MI 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}
```

**Self-check console output** (lines 191–200) — dup external_id, dup full_name, per-district active counts. Copy verbatim; this caught issues in prior phases before migrations ever ran.

---

### `backend/scripts/161-ma-generate.mts` (candidates-only, reuse-existing-race)

**Analog:** `backend/migrations/1148_seed_va_2026_house_candidates.sql` (Phase 159-03; hand-authored, no separate `.mts` existed for VA — this migration file IS the shape template)

**Reuse-race UPDATE + politicians + race_candidates onto existing_race_id** (lines 12–20, 20–159, 160–450 excerpted above at length):
```sql
-- Mark existing races PROVISIONAL (description-only; office_id/election_id untouched)
UPDATE essentials.races r
SET description = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
WHERE r.id IN ('65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, /* ...MA's 9 existing_race_id values from 160-race-preexistence-audit.csv... */)
  AND (r.description IS NULL OR r.description NOT LIKE 'PROVISIONAL:%');

-- New challenger politicians (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510101, 'Salaam Bhatti', 'Salaam', 'Bhatti', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510101);

-- race_candidates onto the EXISTING race_id (mandatory dedup guard on race_id+lower(full_name))
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Salaam Bhatti', 'Salaam', 'Bhatti', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510101
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Salaam Bhatti'));
```
**Critical MA-specific guard:** Clark (MA-5) and Pressley (MA-7) already have `race_candidates` rows on their `existing_race_id` per `160-race-preexistence-audit.csv` — the `NOT EXISTS` guard above must key on `(race_id, politician_id)` (or `race_id, lower(full_name)`) for every MA insert to avoid duplicating them; do not re-run the politicians INSERT for existing pids at all.

---

### TN severe-district withholding (novel pattern — NOT a copy, but the mechanism is fully specified)

**Source:** `backend/src/lib/electionService.ts` lines 24–26 (`ELECTION_VISIBILITY_WINDOW`, read directly) + `161-RESEARCH.md` Pitfall #1 (the concrete derivation).

**Visibility-window predicate that any race's parent election must satisfy to surface:**
```sql
(
  (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
  OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
)
```
**Mechanism:** create a second TN election row with `election_type='special'` and `election_date` far enough in the past (e.g. `'2026-05-07'`) that the first branch evaluates false; wire ONLY the severe races' `election_id` to this row (their `office_id` stays the normal shared old-CD office — never null). Non-severe TN races wire to the normal `'TN 2026 Statewide General'` row exactly like every other state's migration.
```sql
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'TN 2026 Congressional Redistricting — Polygon Pending', '2026-05-07'::date, 'special', 'state', 'TN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'TN 2026 Congressional Redistricting — Polygon Pending');
```
Race/candidate/stance INSERTs for severe TN districts are otherwise byte-identical to the standard pattern above — only `election_id` differs. **Never touch `essentials.offices` for TN** (Pitfall #2 — reps feed must stay on the true old-map incumbent, unrelated to this withholding).

---

### `backend/scripts/seed-{az,wa,tn,ma}-house-headshots.py`

**Analog:** `backend/scripts/seed-mi-house-headshots.py` (319 lines) / `backend/scripts/seed-tx-ny-house-headshots.py` (multi-state `--state` flag variant, same guard set)

**BANDS dict — the only per-state parameter** (line 51–53):
```python
BANDS = {
    'MI': (-261399, -260101, 'Michigan', 'MI 2026 Statewide General'),
}
# add AZ/WA/TN/MA entries: (min_ext, max_ext, 'State Full Name', 'STATE 2026 Statewide General')
```

**Wrong-person guard constants (copy verbatim, all hardening intact)** (lines 44–90):
```python
POLITICAL_KW = ['politic', 'governor', 'attorney general', 'secretary of state', 'treasurer',
    'comptroller', 'lieutenant', 'senator', 'representative', 'mayor', 'official',
    'commissioner', 'auditor', 'state of', 'chief financial',
    'congress', 'candidate', 'assembly', 'councilmember', 'council member']
# NOTE: 'american' removed (Phase 156): wrongly passed founding-father 'John Hancock' for OH-1 Libertarian.

_NON_PERSON_TITLE = re.compile(
    r'(election|congressional district|gubernatorial|ballot|primary|\bcity\b|, texas|, new york|...|'
    r'county|\b\d{4}\b|referendum|proposition|special election)', re.IGNORECASE)
_BAD_DISAMBIG = re.compile(r'\((racing|driver|musician|singer|actor|...)', re.IGNORECASE)
_HISTORICAL_YEAR = re.compile(r'(1[0-9]\d{2})')   # rejects pre-1940 historical homonyms
```
Pipeline: Wikipedia pageimages → license via `imageinfo extmetadata` (FREE only) → download → RGB → crop 4:5 → resize 600×750 LANCZOS q90 → upload `politician_photos/{uuid}-headshot.jpg` (upsert) → `INSERT politician_images WHERE NOT EXISTS`. **Do not re-derive any of this** — it took the Bouchard wrong-person incident + multiple hardening passes to reach this state.

---

### `backend/data/stance-research/{state}-2026-house/_merge.ts`

**Analog:** `backend/data/stance-research/wa-house-a/_merge.ts` (65 lines, read in full — this is an EXISTING WA-incumbent stance directory with the exact CSV-merge shape phase 161 needs)

**Full pattern (copy near-verbatim; swap `IN_SCOPE` set + `OUT` path + `FEDERAL` set to the live federal-24 keys)**:
```typescript
const IN_SCOPE = new Set([-53001,-53002,-53003,-53004,-53005]);  // <-- swap to this state's active external_id set (incumbents + new challengers)
const COLS = ['external_id','full_name','topic_key','value','reasoning','source_url_1','source_url_2','source_url_3','quote_text','quote_deidentified'];

function repair(raw: string): string {
  // Only collapse genuine quad+ quote artifacts. NEVER touch triple quotes (valid RFC-4180).
  return raw.replace(/"""""+/g, '"""').replace(/""""/g, '"""');
}
function esc(v: string): string {
  const s = (v ?? '').toString();
  return /[",\n\r]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
}

const files = readdirSync(DIR).filter((f) => f.endsWith('.csv') && !f.startsWith('_'));
for (const f of files.sort()) {
  const recs = parse(repair(readFileSync(DIR + '/' + f, 'utf8')), {
    columns: true, skip_empty_lines: true, relax_quotes: true, relax_column_count: true, trim: true,
  });
  for (const r of recs) {
    const ext = parseInt(r.external_id);
    if (!IN_SCOPE.has(ext)) problems.push(`bad external_id '${r.external_id}'`);
    if (!FEDERAL.has((r.topic_key || '').toLowerCase())) problems.push(`bad topic_key`);
    const val = parseInt(r.value);
    if (!(val >= 1 && val <= 5)) problems.push(`bad value`);
    if (!(r.reasoning || '').trim()) problems.push(`empty reasoning`);
    const srcs = [r.source_url_1, r.source_url_2, r.source_url_3].map((s) => (s || '').trim()).filter(Boolean);
    if (!srcs.some((s) => /^https?:\/\//i.test(s))) problems.push(`no http source`);
  }
}
```
**Note:** for NEW candidates with NULL `external_id`, the CSV/merge convention swaps `external_id` for a `politician_id` UUID column (matching `_push_uuid.ts`'s expectation) — see `backend/data/stance-research/quick-candidates-2026/` for that variant if any AZ/WA/TN/MA new-candidate CSVs need the UUID path before their politicians row exists at merge-time (though in practice, migrations run first, so external_id resolution via `_push.ts` against real politicians rows is preferred once the politician exists).

---

### `backend/data/stance-research/{state}-2026-house/_push.ts` (existing pid) and `_push_uuid.ts` (new NULL-external_id pid)

**Analog:** `backend/data/stance-research/mi-2026-house/_push.ts` (100 lines, read in full) / `backend/data/stance-research/quick-candidates-2026/_push_uuid.ts` (101 lines, read in full — byte-identical structure, keyed by `politician_id` UUID column instead of `external_id`)

**Core transactional push pattern (`_push.ts`, copy verbatim, only the CSV path argument changes at invocation)**:
```typescript
import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { pool } from '../../../src/lib/db.js';

const csvPath = process.argv[2];
const recs: any[] = parse(readFileSync(csvPath, 'utf8'), { columns: true, skip_empty_lines: true });

// Resolve external_id -> politician_id
const extIds = [...new Set(recs.map((r) => parseInt(r.external_id)))];
const { rows: pidRows } = await pool.query(
  'SELECT id, external_id, full_name FROM essentials.politicians WHERE external_id = ANY($1::int[])', [extIds]);
// ... build PID/NAME maps, resolve topic_key -> topic_id via inform.compass_topics WHERE is_live = true

await pool.query('BEGIN');
try {
  for (const r of recs) {
    // INSERT ... ON CONFLICT (politician_id, topic_id) DO UPDATE  -- politician_answers
    // INSERT ... ON CONFLICT (politician_id, topic_id) DO UPDATE  -- politician_context (reasoning + sources[])
    // quote dedup by (politician_id, lower(topic_key), quote_text); INSERT essentials.quotes if not dup
    // Read & Rank: surname-leak guard on quote_deidentified via word-boundary regex before readrank_selected=true
  }
  await pool.query('COMMIT');
} catch (e: any) { await pool.query('ROLLBACK'); process.exit(1); }
```
**Surname-leak guard (mandatory, exact regex)**:
```typescript
const surname = (NAME[ext] || '').replace(/,?\s*(Jr\.?|Sr\.?|III|II|IV)$/i, '').trim().split(/\s+/).pop()!;
const escaped = surname.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
if (surname && new RegExp('\\b' + escaped + '\\b', 'i').test(qdeid)) {
  leaks.push(NAME[ext] + '/' + tk + ': surname leak'); continue;
}
```
**Use `_push_uuid.ts` instead of `_push.ts`** for any candidate whose `politician_id` row doesn't yet carry a resolvable negative `external_id` at push time (rare in this phase since migrations always run before stance push, but the pattern exists if a plan needs it) — identical logic, keyed by `r.politician_id` (UUID) instead of `parseInt(r.external_id)`.

---

### `backend/scripts/161-verify.sql` (read-only phase gate)

**Analog:** `backend/scripts/156-verify.sql` (533 lines; targeted reads of lines 1–120 and 340–489) + `backend/scripts/158-verify.sql` (structurally, for the coordinate-adjacent multi-state pattern)

**Per-state scoping discipline (header comment, copy the discipline not just the text)** (lines 37–41):
```sql
-- PER-STATE SCOPING (the cross-state contamination trap):
--   AZ, WA, TN, MA are SEPARATE elections (MA reuses pre-existing races). Every assertion is
--   scoped by election id AND d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN ('04','53','47','25').
--   NEVER write a cross-state or election-wide count.
```

**Election-id resolution + working-set temp table pattern** (lines 98–120):
```sql
DO $$
DECLARE
  az_eid uuid; wa_eid uuid; tn_eid uuid; ma_eid uuid;  -- MA has no NEW election; resolve via existing_race_id set instead
  v_az_races int; v_wa_races int; v_tn_races int;
  v_nullpid int; v_dupname int; v_no_image int; v_unsourced int;
BEGIN
  SELECT id INTO az_eid FROM essentials.elections WHERE name = 'AZ 2026 Statewide General';
  -- ... IF eid IS NULL THEN RAISE EXCEPTION 'FAIL setup...'

  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE WHEN r.election_id = az_eid THEN 'AZ' WHEN r.election_id = wa_eid THEN 'WA'
              WHEN r.election_id = tn_eid THEN 'TN' ELSE 'MA' END AS st,
         r.id AS race_id, d.geo_id, rc.id AS rc_id, rc.politician_id, rc.full_name,
         rc.candidate_status, rc.is_incumbent
  FROM essentials.races r JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  WHERE d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN ('04','53','47','25');
END $$;
```

**Honest-skip pin tables (`_stance_skip`, `_img_skip`), ordered by key (the 143 lesson)** (lines 344–479):
```sql
CREATE TEMP TABLE _stance_skip (politician_id uuid, reason text) ON COMMIT DROP;
INSERT INTO _stance_skip (politician_id, reason) VALUES
  ('2e23b789-...', 'Maria Jukic OH-14 — campaign site under development; no fetchable positions'),
  -- one row per whole-record honest-skip WITH a written search trail, exact UUID pin
  ;

CREATE TEMP TABLE _img_skip (external_id bigint, reason text) ON COMMIT DROP;
INSERT INTO _img_skip (external_id, reason) VALUES
  (-391502, 'Brennan Barrington — no free-license portrait; obscure challenger/minor-line, no own bio image; wrong-person/historical fill refused'),
  -- ORDER BY external_id (143 lesson: an ordering mismatch false-fails the gate)
  ;
```

**Assertion pattern (headshot coverage example)** (lines 481–489):
```sql
SELECT COUNT(*), string_agg(p.full_name || ' (' || p.external_id || ')', ', ' ORDER BY p.external_id)
  INTO v_no_image, v_image_detail
FROM _new_cands nc
JOIN essentials.politicians p ON p.id = nc.politician_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id)
  AND p.external_id NOT IN (SELECT external_id FROM _img_skip);
```

**NEW assertion block needed (no prior precedent) — TN severe-race non-surfacing invariant:**
```sql
-- Assert every severe-TN race's election_id points at the withheld election, NOT the general
SELECT COUNT(*) INTO v_leaked
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.geo_id = ANY(ARRAY['4709', /* ...other severe TN geo_ids per the D-01a audit... */])
  AND e.name != 'TN 2026 Congressional Redistricting — Polygon Pending';
IF v_leaked > 0 THEN RAISE EXCEPTION 'FAIL: % severe TN race(s) wired to a surfacing election', v_leaked; END IF;
```

---

### `backend/scripts/161-coordinate-smoke.ts`

**Analog:** `backend/scripts/158-coordinate-smoke.ts` (168 lines, read in full)

**STATE_CONFIG + SAMPLES table pattern** (lines 40–58):
```typescript
const STATE_CONFIG: Record<string, { election: string; geoPrefix: string }> = {
  AZ: { election: 'AZ 2026 Statewide General', geoPrefix: '04' },
  WA: { election: 'WA 2026 Statewide General', geoPrefix: '53' },
  TN: { election: 'TN 2026 Statewide General', geoPrefix: '47' },
  MA: { election: 'MA 2026 Statewide General', geoPrefix: '25' },  // MA existing election name — verify exact string via 160-race-preexistence-audit.csv
};
const SAMPLES: Sample[] = [
  { state: 'AZ', geoId: '0401', minActive: 2 },
  { state: 'WA', geoId: '5301', minActive: 2 },
  { state: 'TN', geoId: '4701', minActive: 2 },   // pick a NON-severe TN district for the positive sample
  { state: 'MA', geoId: '2501', minActive: 2 },
];
```

**Coordinate-surfacing query (mirrors `electionService.ts` Part A exactly)** (lines 93–113):
```typescript
const surf = await pool.query(
  `SELECT r.id AS race_id,
          COUNT(*) FILTER (WHERE rc.candidate_status = 'active') AS active_cands,
          COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.is_incumbent = false) AS challengers,
          COUNT(*) FILTER (WHERE rc.candidate_status = 'active' AND rc.politician_id IS NULL) AS null_pid,
          array_agg(lower(rc.full_name)) FILTER (WHERE rc.candidate_status = 'active') AS active_names
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
**NEW negative-result sample needed (no prior precedent)** — add one severe-TN-district coordinate to `SAMPLES` with an inverted assertion (`expect zero rows returned`, not `>= minActive`), proving Pitfall #1's withholding actually works end-to-end. Structure it as a separate assertion block after the main loop, e.g.:
```typescript
// Negative sample: a severe TN district must surface ZERO House races
const negPt = /* centroid of a severe TN geo_id */;
const negSurf = await pool.query(/* same query shape, scoped to the WITHHELD election id or omit election filter entirely and assert 0 rows */);
if (negSurf.rows.length > 0) { failures.push('TN severe district leaked a surfacing race'); }
```

---

### `backend/scripts/161-tn-correspondence-audit.ts` (D-01a deliverable — net-new, no analog)

**Source:** `161-RESEARCH.md` "Code Examples" section (TN correspondence audit skeleton) — this is the one artifact with no prior-phase script to clone. Build per the researcher's skeleton:
```
For each TN geo_id (4701..4709):
  1. Pull OLD-map county composition (essentials.geofence_boundaries via ST_Intersects-against-county
     boundaries, OR pre-2026 TIGER/Census description).
  2. Pull NEW-map county composition (TN Comptroller's official redistricting map / HB 7003 district
     descriptions / Wikipedia "2026 Tennessee redistricting").
  3. Score severity: % of district population in counties that moved to a DIFFERENT CD.
     Known facts: Shelby County (Memphis) split 3 ways among new CD-5/8/9; Davidson County (Nashville)
     split 3 ways among new CD-4/6/7; TN-1/2/3 (East TN) reported unaffected; TN-9 (Cohen) dismantled.
  4. Districts scoring "severe" (>25% population moved, OR anchor city/county changed) get the
     Pitfall-#1 withholding treatment in the TN generator/migration.
```
This can ship as a plain markdown research artifact (no code) if the planner judges that sufficient — the researcher explicitly notes "no DB writes" and "pure geo/text analysis," so a `.ts` script is optional, not mandatory.

---

## Shared Patterns

### Idempotency (NOT EXISTS guards) — apply to EVERY migration INSERT
**Source:** `1146_seed_mi_2026_house_elections_races.sql`, `1147_seed_mi_2026_house_candidates.sql`, `1148_seed_va_2026_house_candidates.sql` (all three, universally)
```sql
INSERT INTO essentials.<table> (...)
SELECT ...
WHERE NOT EXISTS (SELECT 1 FROM essentials.<table> WHERE <natural-key-condition>);
```
Apply to: elections (by `name`), races (by `election_id, office_id`), politicians (by `external_id`), race_candidates (by `race_id, lower(full_name)` or `race_id, politician_id` for MA reuse).

### Antipartisan invariant — apply to ALL race/race_candidates authoring
**Source:** header comments in 1146/1147/1148 (repeated verbatim in every seeding migration to date)
```
ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
```

### `NOT EXISTS` dedup guard shape for `race_candidates` — apply to all 4 states
**Source:** `1147_seed_mi_2026_house_candidates.sql` line 171 / `1148_seed_va_2026_house_candidates.sql` (every INSERT)
```sql
AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(<name>));
```

### Election visibility window — apply to TN withholding + any future coordinate-smoke negative assertions
**Source:** `backend/src/lib/electionService.ts` lines 24–26
```sql
(e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
```

### Federal-24 topic filtering — apply to `_merge.ts`/stance-research agent prompts for all 4 states
**Source:** `.claude/skills/research-stances/SKILL.md` STEP 0 + `161-RESEARCH.md` "Code Examples" (live-query, never hardcode)
```typescript
const EXCLUDE = new Set(['transportation-priorities','economic-development','homelessness-response',
  'residential-zoning','city-sanitation','local-immigration','rent-regulation','growth-and-development',
  'local-environment','public-safety-approach','jail-capacity','data-centers']);
const fed24 = rows.filter(r => !EXCLUDE.has(r.topic_key) && !r.topic_key.startsWith('judicial-'));
// MUST equal 24 before dispatching any stance-research agent
```

### Live external_id collision re-check — apply before authoring each state's generator
**Source:** `161-RESEARCH.md` "Code Examples" (per the 160-01 lesson "never trust a computed negative external_id band as collision-free")
```typescript
const { rows } = await pool.query('SELECT external_id FROM essentials.politicians WHERE external_id = ANY($1::bigint[])', [candidates]);
console.log(rows.length === 0 ? 'CLEAR' : 'COLLISION: ' + JSON.stringify(rows));
```

### Wrong-person headshot guard — apply to all 4 states' headshot scripts
**Source:** `backend/scripts/seed-mi-house-headshots.py` lines 44–90 (see full excerpt above)

### `pool.query()` only, never PostgREST — applies to every DB-touching script this phase
**Source:** `backend/src/lib/db.js`, project-wide standing rule (CLAUDE.md / MEMORY.md); cwd resets between Bash calls — always `cd /c/EV-Accounts/backend &&` in the same compound command when invoking any of these scripts.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `backend/scripts/161-tn-correspondence-audit.ts` (or markdown equivalent) | analysis/research artifact | batch, no DB writes | No prior seeding phase needed a mid-cycle-redistricting correspondence audit; build from the `161-RESEARCH.md` skeleton, not a prior script |
| TN election-visibility withholding INSERT (within the TN elections_races migration) | migration (novel sub-pattern) | CRUD/batch | No prior phase needed to withhold a race from `/elections` while keeping it fully seeded; derived directly from reading `electionService.ts`'s SQL, not copied from a prior migration |
| Negative-result sample block in `161-coordinate-smoke.ts` | test (smoke) | request-response | `158-coordinate-smoke.ts` only asserts positive surfacing (>= minActive); no prior smoke script asserts a required ZERO-result — this phase is first to need it |

## Metadata

**Analog search scope:** `backend/scripts/` (159-mi-generate.mts, 159-va-generate.mts, 156-verify.sql, 158-verify.sql, 158-coordinate-smoke.ts, seed-mi-house-headshots.py, seed-tx-ny-house-headshots.py), `backend/migrations/` (1146–1149, tail of migration sequence through 1186 to determine next-available number), `backend/data/stance-research/` (mi-2026-house, va-2026-house, wa-house-a, tn-house-a, quick-candidates-2026 — including the pre-existing `az-house-a`/`wa-house-a`/`tn-house-a` incumbent-only directories, which are NOT this phase's target dirs but ARE valid `_merge.ts`/`_push.ts` analogs), `backend/src/lib/electionService.ts` (visibility-window + coordinate-surfacing SQL), `.claude/skills/research-stances/SKILL.md`.
**Files scanned:** ~20 read directly (full or targeted-range) + directory listings across `backend/migrations`, `backend/scripts`, `backend/data/stance-research`.
**Pattern extraction date:** 2026-07-03
**Migration-number note for planner:** as of this mapping, the highest migration file in the repo is `1186_schimmel_stances.sql` (likely claimed by the parallel Phase 177/178 OR session) — re-run `ls backend/migrations | sort | tail -5` immediately before authoring the first Phase-161 migration number, per `161-RESEARCH.md` Open Question 3.
**Existing near-collision directories flagged for planner:** `backend/data/stance-research/{az,wa,tn}-house-a` and `-house-b` already exist and cover a DIFFERENT (incumbent-only, prior-phase) candidate slice — Phase 161's new directories should use the `{state}-2026-house` naming convention (matching `mi-2026-house`, `va-2026-house`, `nj-2026-house`, `oh-2026-house`, `ga-2026-house`, `nc-2026-house`) to avoid any naming ambiguity with the pre-existing `-house-a`/`-house-b` incumbent dirs.
