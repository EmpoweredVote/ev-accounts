# Knight Program — Florida Waves FL-1 and FL-2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Load Florida's TIGER 2024 legislative and place polygons, then seat all 160 members of the Florida Legislature, so that any Florida address returns its state representative and state senator.

**Architecture:** Four stages, each independently verifiable. TIGER 2024 `sldl`/`sldu`/`place` polygons load straight to the DB through the existing generalized loader (a script, not a migration). A roster builder reconciles the 160 sitting members across three independent sources and writes a JSON file, reading nothing from the DB. A generator turns that JSON into two migrations — structure (chambers + offices) and occupancy (politicians + terms) — split so a re-seat never re-runs office creation. Acceptance is the address-reachability gate, because every cheaper check passes vacuously when a term row is missing.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, TIGER shapefiles via `shapefile` + `adm-zip`.

**Spec:** `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`

## Global Constraints

- **Migration namespace is `CC_`** (Chris Cantrell). Next free slots are `CC_0006` and `CC_0007`, measured 2026-08-28. **Take the numbers LAST**: write the files as `CC_wip_*.sql`, and rename + apply + commit in one go. Re-verify with `git fetch origin` and `npm run check:migrations --prefix backend` first.
- **Branch is `docs/knight-cities-program`**, branched off `origin/master` at `c46795f9`. `git fetch origin` before reading any migration max.
- **Every migration is idempotent** (`NOT EXISTS` guards or `ON CONFLICT DO NOTHING`) and ends with a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.
- **Dry-run against prod first** by wrapping the body `BEGIN; … ROLLBACK;` through `psql "$DATABASE_URL"`, and confirm the rollback actually reverted.
- **`ev_api` cannot create objects in `essentials`.** These migrations are DML only, so `psql` works. Do **not** reach for the Supabase MCP for the apply — it wraps each call in its own transaction, which destroys `BEGIN; … ROLLBACK;` semantics.
- **Always pair `geo_id` with `mtfcc` / `district_type` in a join.** Florida's `sldl` and `sldu` GEOIDs both start at `12001` — measured 2026-08-28. The collision is total for districts 1–40. A bare `d.geo_id = g.geo_id` join silently reports the wrong chamber and nothing errors.
- **No party affiliation** is recorded on a person or an office. Party lives on `races.primary_party`.
- **No `term_end` is written.** A future `term_end` makes a seat silently self-vacate.
- **`essentials.politicians.alternate_names` is `NOT NULL DEFAULT '{}'`.** Emit an empty array, never NULL.
- **`office_current_holder` LEFT JOINs from `offices`**, so a vacancy is a NULL `politician_id`, not an absent row. Seated counts must use `count(och.politician_id)`, never `count(*)`.
- **`term_start` is the start of continuous occupancy by that person**, not the start of the current term. Re-election does not end an occupancy.
- **Do not invent a date.** `start_precision` is one of `day` / `month` / `year` / `unknown`, per source, per person.
- **`cwd` resets between Bash calls.** Prefix every command with `cd /c/EV-Accounts/backend &&` in the same compound command.
- **A WAF or catch-all rejection can be HTTP 200.** `myfloridahouse.gov` returns HTTP 200 with a 74,830-byte roster page for paths that do not exist — a `.pdf` path that cannot exist returned exactly the same bytes as the roster (measured 2026-08-28). Never judge a Florida source by its status code; judge it by its content.

---

## Facts measured 2026-08-28 — do not re-derive these

These were measured while planning. They are the reason this plan can assert counts instead of discovering them.

**Raw TIGER 2024 FIPS 12, read straight from the `.dbf` inside each zip:**

| Layer | Records | Detail |
| --- | --- | --- |
| `sldl` | **120** | 0 `ZZZ` pseudo-districts. `LSY = 2024`. GEOID `12001` … `12120`. |
| `sldu` | **40** | 0 `ZZZ` pseudo-districts. `LSY = 2024`. GEOID `12001` … `12040`. |
| `place` | 956 total | **411 `G4110`** incorporated municipalities + 545 `G4210` CDPs. |

Florida is **single-member in both chambers**, so polygon count equals seat count — unlike AZ/WA/ND/SD where one `sldl` polygon carries two seats.

**Target-city place GEOIDs, for later Florida waves:**

| Place | GEOID | Interior point (lon, lat) |
| --- | --- | --- |
| Bradenton city | `1207950` | -82.5768045, 27.4897985 |
| Tallahassee city | `1270600` | -84.2522719, 30.4535287 |
| Miami city | `1245000` | -80.2086152, 25.7751630 |
| West Palm Beach city | `1276600` | -80.1270377, 26.7451143 |

**Database facts:**

- `State of Florida` government already exists: `623ac987-c7bc-4da1-8112-68adaec10cb2`.
- Florida already holds 67 `COUNTY`, 28 `NATIONAL_LOWER`, 1 `NATIONAL_UPPER` and 4 `STATE_EXEC` districts. It holds **zero** `STATE_LOWER` and **zero** `STATE_UPPER`. Greenfield.
- 🔴🔴 **The obvious `external_id` band is TAKEN.** `-(1210000 + n)` — the scheme NC and CO used — collides with **166 existing rows** in `-1212802 … -1210101`. Those are the 2026 US House candidates from `seed-fl-2026-house/`, keyed `-12<district><candidate>`. Seating a senator there would overwrite a real person's row.
  **Use `-(1220000 + n)` for the House and `-(1230000 + n)` for the Senate.** Both ranges measured completely empty on 2026-08-28.
- `essentials.seat_officeholder(p_office_id, p_politician_id, p_term_start, p_source, p_how_started default 'elected', p_start_precision default 'day', p_how_ended_prev default 'term_expired')`.
- The reachability gate is **baseline-driven**, not a list of address probes: `backend/data/address-reachability-baseline.json` is keyed `check -> "state|district_type" -> count`, and the gate fires on growth in a bucket **or on any new bucket**. Florida's only existing entry is `DEAD_GEOGRAPHY: fl|NATIONAL_LOWER: 1` — pre-existing, unrelated, do not touch it. A correct FL-1 + FL-2 introduces **no new bucket**. That is the acceptance test.

**Source facts:**

| Source | Measured 2026-08-28 |
| --- | --- |
| `https://www.flhouse.gov/Representatives` | 266,835 bytes. Member links are `/Sections/Representatives/contactmember.aspx?MemberId=<id>`. **127 unique `MemberId` values for 120 seats** — the same over-long-list shape NC had (125 for 120). |
| `https://www.flsenate.gov/Senators/` | 84,387 bytes. Member links are `/Senators/2024-2026/S<district>`. **Exactly 40, districts 1–40 complete.** |

🔴 **The Senate path is SESSION-SCOPED (`2024-2026`).** A session roster is not a statement about current occupancy — this is the OLIS lesson. A senator who resigned mid-session can still be listed under their session. Every seat gets the change-since-source check in Task 2 Step 6.

🔴 **`flsenate.gov` has no CSV export.** `?format=csv` and `/Senators/Senators.csv` both return the same 84 KB of HTML with HTTP 200.

---

### Task 1: Florida TIGER layers — allowlist, pre-flight assertion, load, verify

Delivers 160 rows in `essentials.districts` plus 160 polygons in `essentials.geofence_boundaries`, and separately 411 `place` polygons.

**Files:**
- Modify: `backend/scripts/load-state-tiger-boundaries.ts` — `STATE_LAYER_ALLOWLIST` (~line 35), `STATE_CITY_ASSERTIONS` (~line 148), and a new pre-flight block beside the existing `EXPECTED_*_MTFCC` blocks (after the NC block, ~line 1432)
- Create: `backend/scripts/verify-fl-tiger-import.sql`

**Interfaces:**
- Consumes: nothing.
- Produces: `essentials.districts` rows with `district_type IN ('STATE_LOWER','STATE_UPPER')`, `state = 'fl'`, `geo_id` = TIGER `GEOID` (5 chars, e.g. `12116` for HD-116), `label` of the form `State House District 116` / `State Senate District 40`. Tasks 3 and 4 join on `geo_id` **paired with** `district_type`.

- [ ] **Step 1: Add Florida to the allowlist and the city-assertion gate**

In `backend/scripts/load-state-tiger-boundaries.ts`, add this entry to `STATE_LAYER_ALLOWLIST`, immediately after the `NC` entry:

```typescript
  // FL. sldu/sldl: Florida's operative legislative maps are the 2022 apportionment
  // (adopted after the 2020 census; Florida redistricts decennially, so the next
  // legislative remap is 2032). Only the CONGRESSIONAL map was litigated after 2022 —
  // the House and Senate plans were not disturbed. TIGER 2024 carries LSY=2024 on
  // both layers, i.e. the maps used for the 2024 elections, which are still current.
  // Counts MEASURED against raw TIGER 2024 FIPS 12 on 2026-08-28 by reading the .dbf
  // directly: sldl 120, sldu 40, ZERO 'ZZZ' pseudo-districts in either file, so
  // skipDistrictCodes removes nothing here.
  // Florida is SINGLE-MEMBER in both chambers, so polygon count EQUALS seat count —
  // unlike AZ/WA (and ND/SD in later Knight waves) where one sldl polygon covers two
  // seats. Asserted in the FL pre-flight block below.
  // 🔴 sldl and sldu GEOIDs BOTH start at 12001 — the geo_id collision is TOTAL for
  // districts 1-40. Every downstream join must pair geo_id with mtfcc/district_type.
  // county is EXCLUDED: all 67 FL counties already exist with geo_id and carry offices
  // in later Knight waves — do not disturb them.
  // place: 956 raw records = 411 G4110 incorporated municipalities + 545 G4210 CDPs.
  // The G4110 filter below (same as OR/MD/VA/NV/AZ/WA/CO/NC) excludes the CDPs.
  FL: new Set(['sldu', 'sldl', 'place']),
```

Then add this entry to `STATE_CITY_ASSERTIONS`, after the `CO` entry:

```typescript
  // The four Knight Foundation Florida jurisdictions' municipalities, plus Palm Beach
  // County's seat. Every string verified present in raw TIGER 2024 FIPS 12 place (all
  // G4110) by direct .dbf probe 2026-08-28 before wiring this gate — Bradenton city
  // resolves to GEOID 1207950, Tallahassee city 1270600, Miami city 1245000, West Palm
  // Beach city 1276600, Palm Beach town 1254025.
  FL: ['Bradenton city', 'Tallahassee city', 'Miami city', 'West Palm Beach city',
       'Palm Beach town'],
```

- [ ] **Step 2: Add the Florida pre-flight assertion block**

Insert immediately **after** the closing brace of the NC block (`if (fipsArg === '37') { … }`) and **before** the `// ── Dry-run stops here` comment:

```typescript
  // ── FL MTFCC pre-flight assertion (Knight program, wave FL-1) ───────────────
  // Counts MEASURED against raw TIGER 2024 FIPS 12 on 2026-08-28 by parsing the
  // .dbf inside each zip directly, not inferred from statute:
  //   sldl  120 records, 0 'ZZZ', LSY=2024, GEOID 12001..12120
  //   sldu   40 records, 0 'ZZZ', LSY=2024, GEOID 12001..12040
  //   place 956 records = 411 G4110 + 545 G4210 CDPs
  // Florida is single-member in BOTH chambers, so these polygon counts ARE the seat
  // counts (120 Representatives + 40 Senators). If either SLD count drifts, a
  // legislative remap has happened and Task 2's roster assertions are also wrong —
  // stop, do not raise the number to get a green run.
  if (fipsArg === '12') {
    const EXPECTED_FL_MTFCC: Record<string, number> = {
      sldl:  120,
      sldu:   40,
      place: 411, // 411 FL G4110 incorporated municipalities; the file's other 545
                  // records are G4210 CDPs, filtered out above.
    };
    if (layer in EXPECTED_FL_MTFCC) {
      const expected = EXPECTED_FL_MTFCC[layer];
      let actualCount = 0;
      await streamShapefile(shpPath, dbfPath, async (_geom, props) => {
        if (layerDef.filterByStatefp) {
          const statefpKey = resolveColumn(props, ['STATEFP', 'STATEFP20', 'STATEFP10']);
          if (String(props[statefpKey] ?? '') !== fipsArg) return;
        }
        if (layer === 'place') {
          const mtfccRaw = (props['MTFCC'] ?? props['mtfcc'] ?? '') as string;
          if (mtfccRaw && mtfccRaw !== 'G4110') return;
        }
        if (layerDef.districtNumField) {
          const fpKey = resolveColumn(props, layerDef.districtNumField);
          const fpVal = String(props[fpKey] ?? '');
          if (layerDef.skipDistrictCodes.has(fpVal)) return;
        }
        actualCount++;
      });
      if (actualCount !== expected) {
        const err = new Error(
          `[FL MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 12 file is correct.`
        );
        err.name = 'MtfccAssertionError';
        throw err;
      }
      console.log(`  [${layer}] FL MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }
```

Also add `FL` to the state list in the `// ── Dry-run stops here` comment block, so the comment stays truthful.

- [ ] **Step 3: Dry-run the two legislative layers**

Run:
```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state FL --fips 12 --layers sldu,sldl --dry-run
```

Expected: `[sldu] FL MTFCC pre-flight assertion PASSED: 40 records (expected 40).` and `[sldl] FL MTFCC pre-flight assertion PASSED: 120 records (expected 120).` No DB write.

**If either count differs, STOP.** A different count means a legislative remap. Do not edit `EXPECTED_FL_MTFCC` to match — re-verify the map vintage first, and if it really moved, Task 2's `120` and `40` assertions are wrong too.

- [ ] **Step 4: Record the identity anchors before loading anything**

This is the step that catches a wrong map vintage. A correct record count proves nothing about *which* map you have.

For each of these three interior points, resolve the true House and Senate district from an **independent** authority — the county Supervisor of Elections' or county GIS district lookup for that county, which is what NC wave 1 used (Buncombe County's own GIS). Do **not** use the TIGER file you are about to load, and do **not** use Open States, which is a detector and not an oracle.

| Point | Coordinates (lon, lat) | County |
| --- | --- | --- |
| Tallahassee | -84.2522719, 30.4535287 | Leon |
| Bradenton | -82.5768045, 27.4897985 | Manatee |
| Miami | -80.2086152, 25.7751630 | Miami-Dade |

Write the three answers into `backend/scripts/verify-fl-tiger-import.sql` in Step 5, as the expected values in its `\echo` line and in a comment naming the source URL and the date you checked.

**If you cannot obtain an independent answer for all three, stop and report.** Do not load a map whose vintage you cannot confirm.

- [ ] **Step 5: Write the verification SQL**

Create `backend/scripts/verify-fl-tiger-import.sql`, matching the sibling `verify-*-tiger-import.sql` files. Replace `<HD-n>` / `<SD-n>` with the values recorded in Step 4, and fill in the source line:

```sql
-- verify-fl-tiger-import.sql — Knight program wave FL-1. Read-only.
-- Run after the sldu/sldl load, and again after the place load.
--
-- Identity anchors resolved independently on <DATE> from <SOURCE URL>:
--   Tallahassee -> <HD-n> / <SD-n>
--   Bradenton   -> <HD-n> / <SD-n>
--   Miami       -> <HD-n> / <SD-n>

\echo '== districts (expect STATE_LOWER 120, STATE_UPPER 40) =='
SELECT district_type, count(*)
FROM essentials.districts
WHERE lower(state) = 'fl' AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
GROUP BY 1 ORDER BY 1;

\echo '== geofence polygons (expect G5220 120, G5210 40) =='
SELECT mtfcc, count(*)
FROM essentials.geofence_boundaries
WHERE state = '12' AND mtfcc IN ('G5220', 'G5210')
GROUP BY 1 ORDER BY 1;

\echo '== every district has geometry (expect 0) =='
SELECT count(*) AS districts_without_geometry
FROM essentials.districts d
WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id);

\echo '== district numbering is complete and unduplicated (expect 0 rows) =='
WITH want AS (
  SELECT 'STATE_LOWER' AS dt, generate_series(1, 120) AS n
  UNION ALL
  SELECT 'STATE_UPPER' AS dt, generate_series(1, 40) AS n
)
SELECT w.dt, w.n, count(d.id) AS rows_found
FROM want w
LEFT JOIN essentials.districts d
  ON lower(d.state) = 'fl'
 AND d.district_type = w.dt
 AND d.geo_id = '12' || lpad(w.n::text, 3, '0')
GROUP BY w.dt, w.n
HAVING count(d.id) <> 1
ORDER BY w.dt, w.n;

\echo '== identity anchors (expect the values in the header comment) =='
-- 🔴 THE mtfcc PAIRING IN THIS JOIN IS LOAD-BEARING.
-- Florida's sldl and sldu GEOIDs BOTH start at 12001, so the collision is TOTAL for
-- districts 1-40: '12040' is both HD-40 and SD-40. Dropping the pairing silently
-- reports the wrong chamber, and nothing errors. This is the accepted collision class
-- that src/lib/geoIdGuard.ts exists to disambiguate.
WITH pts(label, lon, lat) AS (VALUES
  ('Tallahassee', -84.2522719, 30.4535287),
  ('Bradenton',   -82.5768045, 27.4897985),
  ('Miami',       -80.2086152, 25.7751630)
)
SELECT p.label, d.district_type, d.label AS district
FROM pts p
JOIN essentials.geofence_boundaries g
  ON g.state = '12' AND g.mtfcc IN ('G5220','G5210')
 AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(p.lon, p.lat), 4326))
JOIN essentials.districts d
  ON d.geo_id = g.geo_id
 AND ((g.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
   OR (g.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER'))
ORDER BY p.label, d.district_type;

\echo '== place polygons (expect 411; 0 until the place load runs) =='
SELECT count(*) AS fl_g4110_places
FROM essentials.geofence_boundaries
WHERE state = '12' AND mtfcc = 'G4110';

\echo '== the four Knight FL municipalities are present (expect 5 rows) =='
SELECT geo_id, name
FROM essentials.geofence_boundaries
WHERE state = '12' AND mtfcc = 'G4110'
  AND geo_id IN ('1207950', '1270600', '1245000', '1276600', '1254025')
ORDER BY geo_id;
```

- [ ] **Step 6: Load the two legislative layers**

Run:
```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state FL --fips 12 --layers sldu,sldl
```

Expected: both pre-flight assertions pass, then 40 + 120 districts and 40 + 120 polygons written.

- [ ] **Step 7: Run the verification against the legislative layers**

Run:
```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -f scripts/verify-fl-tiger-import.sql
```

Expected: `STATE_LOWER 120`, `STATE_UPPER 40`, `G5220 120`, `G5210 40`, `districts_without_geometry 0`, **zero rows** from the numbering-completeness query, and the three anchors resolving exactly to the values recorded in Step 4. `fl_g4110_places` is still `0` and the municipality query returns 0 rows — the place load has not run yet.

**Any anchor mismatch means the vintage assumption is wrong — stop and re-probe. Do not proceed to Task 2.**

- [ ] **Step 8: Load the place layer as a separate invocation**

Kept separate on purpose: a place problem must never force re-running the 160 legislative polygons.

Run:
```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state FL --fips 12 --layers place --dry-run
```

Expected: `[place] FL MTFCC pre-flight assertion PASSED: 411 records (expected 411).` plus the `STATE_CITY_ASSERTIONS` gate reporting all five Florida strings found.

Then run it live:
```bash
cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state FL --fips 12 --layers place
```

- [ ] **Step 9: Re-run the verification and confirm the place half**

Run:
```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -f scripts/verify-fl-tiger-import.sql
```

Expected: everything from Step 7 still passing, plus `fl_g4110_places 411` and **5 rows** from the municipality query — `1207950 Bradenton`, `1245000 Miami`, `1254025 Palm Beach`, `1270600 Tallahassee`, `1276600 West Palm Beach`.

- [ ] **Step 10: Confirm the reachability gate has no new bucket**

Run:
```bash
cd /c/EV-Accounts/backend && npm run check:reachability
```

Expected: PASS. Districts with geometry but no office are not a reachability violation, so loading polygons alone must not introduce a bucket. If `fl|STATE_LOWER` or `fl|STATE_UPPER` appears now, a district was written without geometry — fix that before Task 2 rather than baselining it.

- [ ] **Step 11: Commit**

```bash
cd /c/EV-Accounts/backend && git add scripts/load-state-tiger-boundaries.ts scripts/verify-fl-tiger-import.sql && git commit -F - -- scripts/load-state-tiger-boundaries.ts scripts/verify-fl-tiger-import.sql <<'EOF'
feat(knight-fl): load FL legislative and place polygons from TIGER 2024

120 sldl + 40 sldu + 411 G4110 places. Florida is single-member in both
chambers, so polygon count equals seat count. Pre-flight asserts all three
counts and aborts before any DB write.

Counts measured against raw TIGER 2024 FIPS 12 on 2026-08-28 by parsing the
.dbf directly: sldl 120 / sldu 40, zero ZZZ pseudo-districts, LSY=2024;
place 956 records = 411 G4110 + 545 G4210 CDPs.

FL sldl and sldu GEOIDs BOTH start at 12001, so the geo_id collision is total
for districts 1-40. Every join in verify-fl-tiger-import.sql pairs geo_id with
mtfcc for that reason.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: Roster builder — reconcile the 160 sitting members

Reads nothing from the DB and writes nothing to it. Pure fetch, reconcile and assert.

**Files:**
- Create: `backend/scripts/build-fl-legislature-roster.mjs`
- Create: `backend/scripts/build-fl-legislature-roster.test.ts`
- Output: `backend/data/fl-legislature-roster.json`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `data/fl-legislature-roster.json` shaped `{ retrievedAt: string, seats: Seat[] }` where
  `Seat = { chamber: 'upper' | 'lower', district: number, name: string, memberId: string, assumedOffice: string | null, assumedPrecision: 'day' | 'year' | 'unknown', howStarted: 'elected' | 'appointed' | 'unknown', portraitUrl: string | null, source: string }`.
  Task 3 reads exactly these field names.

  🔴 **`howStarted` is load-bearing.** `essentials.seat_officeholder` defaults `p_how_started` to `'elected'`. Any member who reached the seat by a special election or appointment must carry the true value, or the migration records an untrue claim about a named person. `office_terms.how_started` CHECKs `'elected'|'appointed'|'succeeded'|'redistricted'|'unknown'`. Use `'unknown'` rather than a guess.

**Why this needs its own unit test:** the sitting-member rule is pure logic over a known-tricky input — the House lists 127 members for 120 seats — and getting it wrong seats a departed member, which is a silent, voter-facing wrong answer. The rest of the script is I/O.

- [ ] **Step 1: Write the failing test**

Create `backend/scripts/build-fl-legislature-roster.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { pickSittingMember, normalizeForMatch, splitDistrict } from './build-fl-legislature-roster.mjs';

describe('normalizeForMatch', () => {
  it('NFD-strips diacritics by DELETING combining marks, not spacing them', () => {
    expect(normalizeForMatch('Ana María Rodríguez')).toBe('ana maria rodriguez');
    expect(normalizeForMatch('Berny Jacques')).toBe('berny jacques');
  });

  it('is case and whitespace insensitive', () => {
    expect(normalizeForMatch('  DANNY   Alvarez ')).toBe('danny alvarez');
  });
});

describe('splitDistrict', () => {
  it('parses the Senate session-scoped path', () => {
    expect(splitDistrict('/Senators/2024-2026/S40')).toBe(40);
    expect(splitDistrict('/Senators/2024-2026/S1')).toBe(1);
  });

  it('refuses a member-detail sub-path rather than returning the wrong number', () => {
    expect(() => splitDistrict('/Senators/2024-2026/S14/5523')).toThrow(/sub-path/i);
  });

  it('refuses the session segment itself', () => {
    expect(() => splitDistrict('/Senators/2024-2026/')).toThrow();
  });
});

describe('pickSittingMember', () => {
  it('returns the only row when a district is uncontested', () => {
    const rows = [{ name: 'Adam Anderson', assumedOn: '2022-11-08', departedOn: null }];
    expect(pickSittingMember('57', rows).name).toBe('Adam Anderson');
  });

  it('drops a row explicitly marked as departed', () => {
    const rows = [
      { name: 'Departed Member', assumedOn: '2022-11-08', departedOn: '2026-03-01' },
      { name: 'Sitting Member', assumedOn: '2026-06-02', departedOn: null },
    ];
    expect(pickSittingMember('12', rows).name).toBe('Sitting Member');
  });

  it('takes the LATEST assumed-office date when the predecessor is UNANNOTATED', () => {
    const rows = [
      { name: 'Old Member', assumedOn: '2022-11-08', departedOn: null },
      { name: 'New Member', assumedOn: '2026-06-02', departedOn: null },
    ];
    expect(pickSittingMember('55', rows).name).toBe('New Member');
  });

  it('ignores source ordering', () => {
    const rows = [
      { name: 'New Member', assumedOn: '2026-06-02', departedOn: null },
      { name: 'Old Member', assumedOn: '2022-11-08', departedOn: null },
    ];
    expect(pickSittingMember('78', rows).name).toBe('New Member');
  });

  it('returns the survivor when every other row is marked departed', () => {
    const rows = [
      { name: 'Gone A', assumedOn: '2022-11-08', departedOn: '2025-01-05' },
      { name: 'Gone B', assumedOn: '2025-02-01', departedOn: '2026-02-01' },
      { name: 'Here', assumedOn: '2026-03-01', departedOn: null },
    ];
    expect(pickSittingMember('113', rows).name).toBe('Here');
  });

  // Failing loudly is the point: a shape we have not seen must not be guessed.
  it('throws when a contested district has no date to arbitrate on', () => {
    const rows = [
      { name: 'Person A', assumedOn: null, departedOn: null },
      { name: 'Person B', assumedOn: null, departedOn: null },
    ];
    expect(() => pickSittingMember('116', rows)).toThrow(/district 116/i);
  });

  it('throws when two surviving rows tie on the same assumed-office date', () => {
    const rows = [
      { name: 'Person A', assumedOn: '2026-06-02', departedOn: null },
      { name: 'Person B', assumedOn: '2026-06-02', departedOn: null },
    ];
    expect(() => pickSittingMember('99', rows)).toThrow(/district 99/i);
  });

  it('throws when every row is marked departed — a vacancy is not a member', () => {
    const rows = [
      { name: 'Gone A', assumedOn: '2022-11-08', departedOn: '2026-02-01' },
    ];
    expect(() => pickSittingMember('7', rows)).toThrow(/district 7.*vacan/i);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /c/EV-Accounts/backend && npx vitest run scripts/build-fl-legislature-roster.test.ts`

Expected: FAIL — cannot resolve `./build-fl-legislature-roster.mjs`.

- [ ] **Step 3: Implement the three pure functions**

Create `backend/scripts/build-fl-legislature-roster.mjs`:

```javascript
#!/usr/bin/env node
/**
 * build-fl-legislature-roster.mjs
 *
 * Reconciles the Florida Legislature roster across THREE independent sources and
 * writes data/fl-legislature-roster.json. Reads nothing from the database and
 * writes nothing to it.
 *
 *   1. flhouse.gov/Representatives — the House's own roster. AUTHORITATIVE for
 *      identity, district and the canonical spelling of the name. Member links are
 *      /Sections/Representatives/contactmember.aspx?MemberId=<id>.
 *   2. flsenate.gov/Senators/ — the Senate's own roster. Member links are
 *      /Senators/2024-2026/S<district>. Measured 2026-08-28: exactly 40, districts
 *      1-40 complete.
 *   3. ballotpedia.org — the only source of "Date assumed office", which is what
 *      office_terms.term_start means: the day this person began holding THIS seat.
 *
 * ⚠ THE HOUSE LIST IS OVER-LONG. Measured 2026-08-28: 127 unique MemberId values
 * for 120 seats. This is the same shape NC had (125 for 120), and NC's lesson was
 * that the annotation is NOT reliable — in two NC districts the DEPARTED member
 * carried no annotation at all, and in a third the successor was listed FIRST.
 * The only rule that survived was: the sitting member is the one with the LATEST
 * assumed-office date, and a contested district with no date is a FATAL unseen
 * shape. That rule is implemented here. Do not weaken it to get a clean run.
 *
 * ⚠ THE SENATE PATH IS SESSION-SCOPED (/2024-2026/). A session roster is not a
 * statement about current occupancy — a senator who resigned mid-session can still
 * be listed under their session. This is the OLIS lesson. Every seat gets the
 * change-since-source check.
 *
 * ⚠ myfloridahouse.gov RETURNS HTTP 200 FOR PATHS THAT DO NOT EXIST. Measured
 * 2026-08-28: a .pdf path that cannot exist returned the same 74,830-byte roster
 * HTML as the roster itself. Never judge a Florida source by its status code.
 * flsenate.gov likewise returns the roster HTML for ?format=csv — there is no CSV
 * export.
 *
 * ⚠ DO NOT SUBSTITUTE WIKIPEDIA'S "Assumed office" COLUMN — it mixes election year
 * and appointment year in one column (the CO lesson).
 */

/**
 * Normalise a name for CROSS-SOURCE MATCHING ONLY. Never call this on a value
 * headed for politicians.full_name — that is a byte-for-byte pass of the source's
 * own spelling.
 *
 * 🔴 Combining marks are DELETED, not replaced with a space. Replacing them
 * spaces out every accented name and turns 'María' into 'mari a', which then
 * fails to match itself.
 */
export function normalizeForMatch(s) {
  return String(s)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}

/**
 * Extract the district number from a Senate roster href.
 * Accepts only the bare seat path; a member-detail sub-path is refused rather
 * than silently truncated to the seat.
 */
export function splitDistrict(href) {
  const m = String(href).match(/^\/Senators\/\d{4}-\d{4}\/S(\d{1,2})$/);
  if (m) return Number(m[1]);
  if (/^\/Senators\/\d{4}-\d{4}\/S\d{1,2}\/\d+$/.test(String(href))) {
    throw new Error(`Refusing a member-detail sub-path: ${JSON.stringify(href)}`);
  }
  throw new Error(`Unparseable Senate roster href: ${JSON.stringify(href)}`);
}

/**
 * Given every row a chamber lists for one district, return the sitting member.
 * Throws rather than guess on any shape not seen while planning.
 */
export function pickSittingMember(district, rows) {
  const surviving = rows.filter((r) => !r.departedOn);
  if (surviving.length === 0) {
    throw new Error(
      `district ${district}: every listed member is marked departed — this seat is vacant. ` +
      `A vacancy is a fact about a span, not a member; record it on the office, not here.`
    );
  }
  if (surviving.length === 1) return surviving[0];

  const dated = surviving.filter((r) => r.assumedOn);
  if (dated.length === 0) {
    throw new Error(
      `district ${district}: ${surviving.length} surviving rows and no assumed-office date ` +
      `to arbitrate on (${surviving.map((r) => r.name).join(', ')}). Unseen shape — refusing to guess.`
    );
  }
  const sorted = [...dated].sort((a, b) => b.assumedOn.localeCompare(a.assumedOn));
  if (sorted.length > 1 && sorted[0].assumedOn === sorted[1].assumedOn) {
    throw new Error(
      `district ${district}: ${sorted[0].name} and ${sorted[1].name} share assumed-office date ` +
      `${sorted[0].assumedOn}. Cannot arbitrate — refusing to guess.`
    );
  }
  return sorted[0];
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /c/EV-Accounts/backend && npx vitest run scripts/build-fl-legislature-roster.test.ts`

Expected: PASS, 12 tests.

- [ ] **Step 5: Implement fetch and reconcile, and produce the roster**

Append to the same file. Fetch both chamber rosters to disk first, so the evidence stays inspectable:

```bash
cd /c/EV-Accounts/backend && mkdir -p data/seed-fl-legislature-2026 && \
curl -sL -m 60 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' \
  -o data/seed-fl-legislature-2026/_house.html "https://www.flhouse.gov/Representatives" && \
curl -sL -m 60 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' \
  -o data/seed-fl-legislature-2026/_senate.html "https://www.flsenate.gov/Senators/" && \
ls -l data/seed-fl-legislature-2026/
```

Expected sizes are near 266,835 and 84,387 bytes. **A file materially smaller than that is the catch-all page, not the roster** — check the content, not the exit code.

Then, in the script: read both files as **UTF-8** (a Latin-1 read corrupts `Ana María Rodríguez` and every other accented name); parse each member block for the member id, name and district; group by district; apply `pickSittingMember`; cross-check every surviving name against Ballotpedia; take `assumedOffice` from Ballotpedia's "Date assumed office" with `assumedPrecision: 'day'` where a full date is published, `'year'` where only a year is (stored as `YYYY-01-01`), and `'unknown'` where neither is.

Name-form variance between sources is expected and is **not** a mismatch — compare through `normalizeForMatch` on first plus last token. A genuine first-name mismatch is a **refusal**, not a warning: skip and report, never guess. The refusal class here is high-precision false-negative.

End the script with hard assertions:

```javascript
const lower = seats.filter((s) => s.chamber === 'lower');
const upper = seats.filter((s) => s.chamber === 'upper');
if (lower.length !== 120) throw new Error(`FATAL: expected 120 FL House seats, got ${lower.length}`);
if (upper.length !== 40) throw new Error(`FATAL: expected 40 FL Senate seats, got ${upper.length}`);
for (const [chamber, list, max] of [['lower', lower, 120], ['upper', upper, 40]]) {
  const ds = new Set(list.map((s) => s.district));
  if (ds.size !== list.length) throw new Error(`FATAL: duplicate district in ${chamber}`);
  for (let n = 1; n <= max; n++) {
    if (!ds.has(n)) throw new Error(`FATAL: ${chamber} district ${n} missing from roster`);
  }
}
const bad = seats.filter((s) => !['elected', 'appointed', 'unknown'].includes(s.howStarted));
if (bad.length) throw new Error(`FATAL: ${bad.length} seat(s) with an invalid howStarted`);
console.log(`OK: 120 House + 40 Senate, every district 1..N present exactly once.`);
console.log(`  precision: day ${seats.filter(s => s.assumedPrecision === 'day').length}, ` +
            `year ${seats.filter(s => s.assumedPrecision === 'year').length}, ` +
            `unknown ${seats.filter(s => s.assumedPrecision === 'unknown').length}`);
console.log(`  howStarted: elected ${seats.filter(s => s.howStarted === 'elected').length}, ` +
            `appointed ${seats.filter(s => s.howStarted === 'appointed').length}, ` +
            `unknown ${seats.filter(s => s.howStarted === 'unknown').length}`);
```

- [ ] **Step 6: Check every seat for a change since the sources were last edited**

Neither roster can report a change that postdates it, and the Senate path is session-scoped. A resignation is exactly what silently seats the wrong person.

For each of the 160 seats, open the member's own page — `https://www.flhouse.gov/Sections/Representatives/contactmember.aspx?MemberId=<id>` or `https://www.flsenate.gov/Senators/2024-2026/S<n>` — and confirm the name matches the roster. Where a seat changed hands, find the special election or appointment and record it, setting `howStarted` accordingly.

Record in `backend/data/seed-fl-legislature-2026/ROSTERS.md`, under `## 🔴 Source defects found`: the count of seats checked, the count that changed, the count found vacant, and the date of the check. A vacant seat is **not** a roster row — it is recorded on the office in Task 4 and reported here.

- [ ] **Step 7: Build the roster and commit**

Run:
```bash
cd /c/EV-Accounts/backend && node scripts/build-fl-legislature-roster.mjs && node -e "const r=require('./data/fl-legislature-roster.json');console.log(r.seats.length,'seats, retrieved',r.retrievedAt)"
```

Expected: `OK: 120 House + 40 Senate…` then `160 seats, retrieved <ISO timestamp>`.

```bash
cd /c/EV-Accounts/backend && git add scripts/build-fl-legislature-roster.mjs scripts/build-fl-legislature-roster.test.ts data/fl-legislature-roster.json data/seed-fl-legislature-2026/ROSTERS.md && git commit -F - -- scripts/build-fl-legislature-roster.mjs scripts/build-fl-legislature-roster.test.ts data/fl-legislature-roster.json data/seed-fl-legislature-2026/ROSTERS.md <<'EOF'
feat(knight-fl): reconcile the 160-member Florida Legislature roster

The House lists 127 MemberIds for 120 seats. pickSittingMember resolves each
contested district by latest assumed-office date and THROWS on any shape it has
not seen, rather than seating a departed member silently. 12 unit tests cover
the unannotated-predecessor, reversed-order, tie and all-departed shapes.

The Senate roster path is session-scoped (/Senators/2024-2026/S<n>), so it
cannot report a mid-session resignation. Every one of the 160 seats was checked
against the member's own page; findings are in
data/seed-fl-legislature-2026/ROSTERS.md.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: Migration generator — emit structure and occupancy

**Files:**
- Create: `backend/scripts/gen-fl-legislature-migrations.mjs`
- Output: `backend/migrations/CC_wip_fl_legislature_structure.sql`
- Output: `backend/migrations/CC_wip_fl_legislature_incumbents.sql`

**Interfaces:**
- Consumes: `data/fl-legislature-roster.json` from Task 2, exactly the `Seat` field names listed there.
- Produces: two `_wip_` SQL files. Task 4 renames, dry-runs and applies them. This script **never** touches the database.

- [ ] **Step 1: Write the generator header and the shared helpers**

Create `backend/scripts/gen-fl-legislature-migrations.mjs`:

```javascript
#!/usr/bin/env node
/**
 * gen-fl-legislature-migrations.mjs
 *
 * Emits the two Florida Legislature seeding migrations from
 * data/fl-legislature-roster.json (160 seats: 120 House + 40 Senate).
 *
 *   migrations/CC_wip_fl_legislature_structure.sql   2 chambers + 160 offices
 *   migrations/CC_wip_fl_legislature_incumbents.sql  160 politicians + 160 terms
 *
 * Split in two to match the WA (1742/1743), CO (1843/1844) and NC (CA_0004/0005)
 * precedent: structure is stable, occupancy churns with every vacancy, and keeping
 * them apart means a re-seat never has to re-run office creation.
 *
 * Files are emitted as `CC_wip_` on purpose. MIGRATION NUMBERS ARE TAKEN LAST,
 * immediately before applying, in Chris Cantrell's CC_ namespace. This script does
 * NOT apply anything and does NOT touch the database.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/gen-fl-legislature-migrations.mjs
 */

import fs from 'node:fs';

const ROSTER = JSON.parse(fs.readFileSync('data/fl-legislature-roster.json', 'utf8'));
const SEATS = ROSTER.seats;
const RETRIEVED = ROSTER.retrievedAt;

if (SEATS.length !== 160) {
  console.error(`FATAL: expected 160 seats, roster has ${SEATS.length}. Re-run build-fl-legislature-roster.mjs.`);
  process.exit(1);
}

const GOV_ID = '623ac987-c7bc-4da1-8112-68adaec10cb2'; // State of Florida — ALREADY EXISTS

const HOUSE_NAME = 'Florida House of Representatives';
const SENATE_NAME = 'Florida Senate';

// SQL string literal. Escapes single quotes only -- the sole SQL-meaningful
// character inside a single-quoted literal. Double quotes and non-ASCII
// (Ana María Rodríguez) pass through untouched: this is a byte-for-byte pass of
// the name into the literal, never a normalization. The NFD-stripping helper in
// build-fl-legislature-roster.mjs is for cross-source MATCHING and must never run
// on a value headed into full_name.
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

/**
 * external_id band.
 *
 * 🔴 THE OBVIOUS BAND IS TAKEN. FL FIPS is 12, so the NC/CO scheme would give
 * -(1210000+n) for the Senate -- but -1212802..-1210101 already holds 166 rows,
 * the 2026 US House candidates keyed -12<district><candidate> (measured against
 * prod 2026-08-28). Seating a senator there would overwrite a real person.
 *
 * House -> -(1220000+n), Senate -> -(1230000+n). BOTH ranges measured completely
 * empty on 2026-08-28. The generator re-asserts this against prod in Task 4 before
 * anything is applied.
 */
const extId = (s) => (s.chamber === 'upper' ? -(1230000 + s.district) : -(1220000 + s.district));

/** TIGER GEOID: FIPS 12 plus the zero-padded 3-digit district. Both chambers. */
const geoIdFor = (s) => '12' + String(s.district).padStart(3, '0');
```

Then copy the `SURNAME_PARTICLES` set and the `splitName` function verbatim from `scripts/gen-nc-legislature-migrations.mjs` (lines 71–160). They are name-shape logic, not state-specific, and Florida's roster carries the same three shapes plus accented names.

- [ ] **Step 2: Emit the structure migration**

Append:

```javascript
const structure = `-- CC_wip_fl_legislature_structure.sql
-- Knight program, wave FL-2 (structure half).
--
-- Creates the two Florida legislative chambers under the existing
-- 'State of Florida' government, and one office per district: 120
-- Representatives + 40 Senators. Creates NO people and NO terms -- the
-- incumbents migration does that, and an office with no office_terms row is
-- invisible until it runs, so the two are applied back to back.
--
-- Districts and geometry come from scripts/load-state-tiger-boundaries.ts
-- (wave FL-1), not from this migration.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT ${q(GOV_ID)}, ${q(HOUSE_NAME)}, ${q(HOUSE_NAME)}, 120
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = ${q(GOV_ID)} AND name = ${q(HOUSE_NAME)}
);

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT ${q(GOV_ID)}, ${q(SENATE_NAME)}, ${q(SENATE_NAME)}, 40
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = ${q(GOV_ID)} AND name = ${q(SENATE_NAME)}
);

-- ─── House offices: 120, one per STATE_LOWER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Representative', 'FL', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = ${q(GOV_ID)} AND ch.name = ${q(HOUSE_NAME)}
) c
WHERE d.district_type = 'STATE_LOWER'
  AND lower(d.state) = 'fl'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Representative'
  );

-- ─── Senate offices: 40, one per STATE_UPPER district ───────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Senator', 'FL', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = ${q(GOV_ID)} AND ch.name = ${q(SENATE_NAME)}
) c
WHERE d.district_type = 'STATE_UPPER'
  AND lower(d.state) = 'fl'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Senator'
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE n_ch int; n_off int; n_orphan int;
BEGIN
  SELECT count(*) INTO n_ch FROM essentials.chambers c
   WHERE c.government_id = ${q(GOV_ID)}
     AND c.name IN (${q(HOUSE_NAME)}, ${q(SENATE_NAME)});
  IF n_ch <> 2 THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected 2 FL legislative chambers, found %', n_ch; END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 160 THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected 160 FL legislative offices, found %', n_off; END IF;

  -- Every office must hang off a district that actually has geometry, or the
  -- seat is unreachable by address and nothing will error.
  SELECT count(*) INTO n_orphan FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND (d.geo_id IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id));
  IF n_orphan <> 0 THEN RAISE EXCEPTION 'CC_wip_fl_structure: % FL legislative offices lack district geometry', n_orphan; END IF;
END $$;

-- Second gate: per-chamber shape + no cross-wiring. Catches exactly the failure
-- mode where a bare geo_id join fans a House office onto a Senate district while
-- still producing a plausible 160 total. FL's sldl and sldu GEOIDs BOTH start at
-- 12001, so this collision is total for districts 1-40 and this gate is not
-- theoretical.
DO $$
DECLARE n_lower int; n_upper int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_lower FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='fl' AND d.district_type='STATE_LOWER';
  IF n_lower <> 120 THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected 120 FL House offices, found %', n_lower; END IF;

  SELECT count(*) INTO n_upper FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='fl' AND d.district_type='STATE_UPPER';
  IF n_upper <> 40 THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected 40 FL Senate offices, found %', n_upper; END IF;

  SELECT count(*) INTO n_dupe FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state)='fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     GROUP BY o.district_id HAVING count(*) > 1
  ) x;
  IF n_dupe <> 0 THEN RAISE EXCEPTION 'CC_wip_fl_structure: % FL districts carry more than one office — geo_id join fanned across chambers', n_dupe; END IF;
END $$;

COMMIT;
`;
```

- [ ] **Step 3: Emit the incumbents migration**

Append. The payload table, the politicians insert, the `seat_officeholder` loop and the unknown-start direct insert follow `gen-nc-legislature-migrations.mjs` exactly; the differences are the counts, the state, the band and the chamber names.

```javascript
const rows = SEATS
  .slice()
  .sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? 1 : -1))
  .map((s) => {
    const { first, last, middle, suffix, preferred } = splitName(s.name);
    const districtType = s.chamber === 'upper' ? 'STATE_UPPER' : 'STATE_LOWER';
    const title = s.chamber === 'upper' ? 'Senator' : 'Representative';
    const aliases = preferred ? `ARRAY[${q(preferred)}]::text[]` : `'{}'::text[]`;
    const termStartSql = s.assumedOffice === null ? 'NULL' : `DATE ${q(s.assumedOffice)}`;
    return (
      `    (${q(geoIdFor(s))}, ${q(districtType)}, ${q(title)}, ${extId(s)}, ${q(s.name)}, ` +
      `${q(first)}, ${q(last)}, ${q(middle)}, ${q(suffix)}, ${aliases}, ${q(s.portraitUrl ?? null)}, ` +
      `${termStartSql}, ${q(s.assumedPrecision)}, ${q(s.howStarted)}, ${q(s.source)})`
    );
  })
  .join(',\n');

const nDay = SEATS.filter((s) => s.assumedPrecision === 'day').length;
const nYear = SEATS.filter((s) => s.assumedPrecision === 'year').length;
const nUnknown = SEATS.filter((s) => s.assumedPrecision === 'unknown').length;
const nAppointed = SEATS.filter((s) => s.howStarted === 'appointed').length;
const nElected = SEATS.filter((s) => s.howStarted === 'elected').length;
const nUnknownStarted = SEATS.filter((s) => s.howStarted === 'unknown').length;
const nDated = SEATS.filter((s) => s.assumedOffice !== null).length;
const nNullDate = SEATS.length - nDated;

const incumbents = `-- CC_wip_fl_legislature_incumbents.sql
-- Knight program, wave FL-2 (occupancy half).
--
-- Seats all 160 Florida Legislature members (120 Representatives + 40 Senators).
--
-- SOURCE: flhouse.gov/Representatives and flsenate.gov/Senators/ per seat
-- (identity, district, chamber), cross-checked against Ballotpedia for the
-- assumed-office date (data/fl-legislature-roster.json, built by
-- build-fl-legislature-roster.mjs). Retrieved ${RETRIEVED}.
--
-- DATE PRECISION is recorded, never fabricated: ${nDay} seats carry a full
-- assumed-office date (start_precision='day'); ${nYear} carry only a year
-- (stored as YYYY-01-01 with start_precision='year' so month and day are
-- explicitly NOT being claimed); ${nUnknown} are genuinely unknown.
--
-- HOW STARTED: elected ${nElected}, appointed ${nAppointed}, unknown ${nUnknownStarted}.
-- seat_officeholder() DEFAULTS p_how_started to 'elected', so every non-elected
-- seat must pass its true value or the migration asserts something untrue about a
-- named person.
--
-- ${nNullDate} seat(s) carry a NULL term_start and are inserted DIRECTLY into
-- essentials.office_terms: seat_officeholder() RAISE EXCEPTIONs on a NULL
-- p_term_start by design. This is the identical shape migration 1459's phase-2
-- backfill and its corrections (1465, 1546, 1635, 1798, 1814) use for a genuinely
-- unknown start. Such a member is still seated: essentials.current_office_holders
-- treats term_start IS NULL / term_end IS NULL as "currently holds".
--
-- 🔴 external_id band: House -(1220000+n), Senate -(1230000+n). NOT -(1210000+n),
-- which holds 166 FL US House candidate rows (-1212802..-1210101). Both bands used
-- here were measured empty against prod on 2026-08-28 and are re-asserted below
-- BEFORE any insert.

BEGIN;

-- ─── Refuse to run if the external_id bands are not empty ───────────────────
-- A collision here does not error on insert -- ON CONFLICT DO NOTHING would
-- silently skip the row and the seat would end up held by whoever already owned
-- that id. Check first.
DO $$
DECLARE v_house int; v_senate int;
BEGIN
  SELECT count(*) INTO v_house FROM essentials.politicians
   WHERE external_id BETWEEN -1220120 AND -1220001;
  SELECT count(*) INTO v_senate FROM essentials.politicians
   WHERE external_id BETWEEN -1230040 AND -1230001;
  IF v_house NOT IN (0, 120) THEN
    RAISE EXCEPTION 'CC_wip_fl_incumbents: FL House external_id band holds % rows (expected 0 on first run, 120 on a re-run)', v_house;
  END IF;
  IF v_senate NOT IN (0, 40) THEN
    RAISE EXCEPTION 'CC_wip_fl_incumbents: FL Senate external_id band holds % rows (expected 0 on first run, 40 on a re-run)', v_senate;
  END IF;
END $$;

CREATE TEMP TABLE fl_leg_seed (
  geo_id          text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_name     text,
  name_suffix     text,
  aliases         text[],
  photo_url       text,
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO fl_leg_seed VALUES
${rows};

-- Guard the payload itself before it touches anything.
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM fl_leg_seed;
  IF v_n <> 160 THEN RAISE EXCEPTION 'seed payload: expected 160 rows, got %', v_n; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM fl_leg_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT geo_id, district_type FROM fl_leg_seed GROUP BY geo_id, district_type HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate (geo_id, district_type) key(s)', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, photo_origin_url, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_name, s.name_suffix,
       s.aliases, s.photo_url, true, true, s.source
FROM fl_leg_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy: dated seats, via the helper ──────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before inserting,
-- which is the whole reason it exists.
--
-- 🔴 The districts join pairs geo_id WITH district_type. Dropping the pairing
-- would match HD-n against SD-n for every n <= 40.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
    FROM fl_leg_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id
     AND d.district_type = s.district_type
     AND lower(d.state) = 'fl'
    JOIN essentials.offices o
      ON o.district_id = d.id AND o.title = s.office_title
    WHERE s.term_start IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
      )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      r.source,
      r.how_started,
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % FL legislator(s) with a known start date', v_seated;
END $$;

-- ─── Occupancy: unknown-start seats, direct insert ──────────────────────────

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, s.start_precision, s.how_started, s.source
FROM fl_leg_seed s
JOIN essentials.politicians p ON p.external_id = s.ext_id
JOIN essentials.districts d
  ON d.geo_id = s.geo_id
 AND d.district_type = s.district_type
 AND lower(d.state) = 'fl'
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = s.office_title
WHERE s.term_start IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE v_pol int; v_seated int; v_lower int; v_upper int;
BEGIN
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id BETWEEN -1220120 AND -1220001
      OR external_id BETWEEN -1230040 AND -1230001;
  IF v_pol <> 160 THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: FL legislators inserted: expected 160, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs from
  -- offices, so a vacancy is a NULL politician_id, never an absent row. count(*)
  -- would pass vacuously with every seat empty.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 160 THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: expected 160 seated FL legislators, found %', v_seated; END IF;

  SELECT count(och.politician_id) INTO v_lower
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type = 'STATE_LOWER';
  IF v_lower <> 120 THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: expected 120 seated FL Representatives, found %', v_lower; END IF;

  SELECT count(och.politician_id) INTO v_upper
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type = 'STATE_UPPER';
  IF v_upper <> 40 THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: expected 40 seated FL Senators, found %', v_upper; END IF;
END $$;

COMMIT;
`;

fs.writeFileSync('migrations/CC_wip_fl_legislature_structure.sql', structure, { encoding: 'utf8' });
fs.writeFileSync('migrations/CC_wip_fl_legislature_incumbents.sql', incumbents, { encoding: 'utf8' });

// Verify the emitted bytes round-trip non-ASCII names and carry no BOM.
const emitted = fs.readFileSync('migrations/CC_wip_fl_legislature_incumbents.sql', 'utf8');
const hasBOM = fs.readFileSync('migrations/CC_wip_fl_legislature_incumbents.sql').slice(0, 3)
  .equals(Buffer.from([0xef, 0xbb, 0xbf]));
if (hasBOM) {
  console.error('FATAL: emitted incumbents file carries a UTF-8 BOM.');
  process.exit(1);
}
const accented = SEATS.filter((s) => /[^\x00-\x7F]/.test(s.name));
const missing = accented.filter((s) => !emitted.includes(s.name));
if (missing.length) {
  console.error(`FATAL: ${missing.length} non-ASCII name(s) failed to round-trip: ${missing.map((s) => s.name).join(', ')}`);
  process.exit(1);
}

console.log('wrote migrations/CC_wip_fl_legislature_structure.sql');
console.log('wrote migrations/CC_wip_fl_legislature_incumbents.sql');
console.log(`  ${SEATS.length} seats | House ${SEATS.filter((s) => s.chamber === 'lower').length}, Senate ${SEATS.filter((s) => s.chamber === 'upper').length}`);
console.log(`  precision: day ${nDay}, year ${nYear}, unknown ${nUnknown}`);
console.log(`  how_started: elected ${nElected}, appointed ${nAppointed}, unknown ${nUnknownStarted}`);
console.log(`  BOM check: none found`);
console.log(`  non-ASCII names round-tripped: ${accented.length} of ${accented.length}`);
```

- [ ] **Step 4: Run the generator**

Run:
```bash
cd /c/EV-Accounts/backend && node scripts/gen-fl-legislature-migrations.mjs
```

Expected: both files written, `160 seats | House 120, Senate 40`, `BOM check: none found`, and every non-ASCII name round-tripped.

- [ ] **Step 5: Read the two emitted files before trusting them**

Run:
```bash
cd /c/EV-Accounts/backend && grep -c "^    ('12" migrations/CC_wip_fl_legislature_incumbents.sql && grep -n "district_type = s.district_type" migrations/CC_wip_fl_legislature_incumbents.sql | wc -l && head -40 migrations/CC_wip_fl_legislature_structure.sql
```

Expected: `160` payload rows; **2** occurrences of the `district_type` pairing (one in the helper loop, one in the unknown-start insert) — if either is missing, the geo_id collision is live; and a structure header naming the Florida government UUID.

- [ ] **Step 6: Commit the generator, not the migrations**

The `_wip_` files are renamed in Task 4 and committed there with their final numbers.

```bash
cd /c/EV-Accounts/backend && git add scripts/gen-fl-legislature-migrations.mjs && git commit -F - -- scripts/gen-fl-legislature-migrations.mjs <<'EOF'
feat(knight-fl): generator for the Florida Legislature migrations

Emits structure (2 chambers + 160 offices) and incumbents (160 politicians +
160 terms) from data/fl-legislature-roster.json. Never touches the database.

The external_id band is -(1220000+n) House / -(1230000+n) Senate, NOT the
-(1210000+n) scheme NC and CO used: that range already holds 166 FL US House
candidate rows and a collision would be silently absorbed by ON CONFLICT DO
NOTHING. The incumbents migration re-asserts both bands are empty before
inserting anything.

Every districts join pairs geo_id with district_type. FL sldl and sldu GEOIDs
both start at 12001, so an unpaired join matches HD-n against SD-n for n <= 40.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Dry-run, apply, gate, commit

**Files:**
- Rename: `backend/migrations/CC_wip_fl_legislature_structure.sql` → `backend/migrations/CC_0006_fl_legislature_structure.sql`
- Rename: `backend/migrations/CC_wip_fl_legislature_incumbents.sql` → `backend/migrations/CC_0007_fl_legislature_incumbents.sql`

**Interfaces:**
- Consumes: the two `_wip_` files from Task 3, and the districts and polygons from Task 1.
- Produces: 160 seated Florida legislators in production. Later Florida waves (FL-3 onward) rely on `essentials.districts` rows for `fl|STATE_LOWER` and `fl|STATE_UPPER` carrying exactly one office each.

- [ ] **Step 1: Re-verify the free migration numbers**

Run:
```bash
cd /c/EV-Accounts && git fetch origin && ls backend/migrations/ | grep -E '^CC_' | sort | tail -3 && npm run check:migrations --prefix backend
```

Expected: highest applied `CC_` slot is `CC_0005`, so `CC_0006` and `CC_0007` are free. **If another session has taken them, use the next two free slots and update every reference in both files' comments and gate messages.**

- [ ] **Step 2: Dry-run the structure migration against production**

Run:
```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && \
  { echo "BEGIN;"; sed -e '/^BEGIN;$/d' -e '/^COMMIT;$/d' migrations/CC_wip_fl_legislature_structure.sql; echo "ROLLBACK;"; } | psql "$DATABASE_URL" -v ON_ERROR_STOP=1
```

Expected: no exception, then `ROLLBACK`. Every post-verify gate must pass **inside** the transaction — that is the point of the dry-run.

- [ ] **Step 3: Confirm the rollback actually reverted**

Run:
```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -c "
select count(*) as fl_leg_offices from essentials.offices o
  join essentials.districts d on d.id = o.district_id
 where lower(d.state)='fl' and d.district_type in ('STATE_LOWER','STATE_UPPER');"
```

Expected: `0`. **A non-zero count means the rollback did not revert and the dry-run gave you a false negative.** Stop and investigate.

- [ ] **Step 4: Apply the structure migration**

Run:
```bash
cd /c/EV-Accounts/backend && git mv migrations/CC_wip_fl_legislature_structure.sql migrations/CC_0006_fl_legislature_structure.sql && \
  sed -i 's/CC_wip_fl_structure/CC_0006/g; s/CC_wip_fl_legislature_structure\.sql/CC_0006_fl_legislature_structure.sql/g' migrations/CC_0006_fl_legislature_structure.sql && \
  set -a && . ./.env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CC_0006_fl_legislature_structure.sql
```

Expected: `COMMIT`, no exception.

- [ ] **Step 5: Dry-run the incumbents migration against production**

Run:
```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && \
  { echo "BEGIN;"; sed -e '/^BEGIN;$/d' -e '/^COMMIT;$/d' migrations/CC_wip_fl_legislature_incumbents.sql; echo "ROLLBACK;"; } | psql "$DATABASE_URL" -v ON_ERROR_STOP=1
```

Expected: `NOTICE: seated 160 FL legislator(s) with a known start date` (or 160 minus the unknown-start count), every gate passing, then `ROLLBACK`.

Note: the temp table is declared `ON COMMIT DROP`, so a `ROLLBACK` drops it too. That is correct and not a failure.

- [ ] **Step 6: Confirm the rollback actually reverted**

Run:
```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -c "
select count(*) as fl_leg_politicians from essentials.politicians
 where external_id between -1220120 and -1220001 or external_id between -1230040 and -1230001;"
```

Expected: `0`.

- [ ] **Step 7: Apply the incumbents migration**

Run:
```bash
cd /c/EV-Accounts/backend && git mv migrations/CC_wip_fl_legislature_incumbents.sql migrations/CC_0007_fl_legislature_incumbents.sql && \
  sed -i 's/CC_wip_fl_incumbents/CC_0007/g; s/CC_wip_fl_legislature_incumbents\.sql/CC_0007_fl_legislature_incumbents.sql/g' migrations/CC_0007_fl_legislature_incumbents.sql && \
  set -a && . ./.env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CC_0007_fl_legislature_incumbents.sql
```

Expected: `COMMIT`, no exception.

- [ ] **Step 8: Run the acceptance test**

Run:
```bash
cd /c/EV-Accounts/backend && npm run check:reachability && npm run check:occupancy && npm run check:migrations
```

Expected: all three PASS, with **no new bucket** in the reachability output. A new `fl|STATE_LOWER` or `fl|STATE_UPPER` bucket means a seat is unreachable by address — fix the cause. **Do not add it to `data/address-reachability-baseline.json` to get a green run.**

- [ ] **Step 9: Prove the four-answer probe end to end**

This is the definition of done from the spec. Two of the four answers land in this wave; the council and commission answers arrive in FL-3 onward.

Run:
```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -c "
with pts(label, lon, lat) as (values
  ('Tallahassee', -84.2522719, 30.4535287),
  ('Bradenton',   -82.5768045, 27.4897985),
  ('Miami',       -80.2086152, 25.7751630))
select p.label, d.district_type, d.label as district, pol.full_name
  from pts p
  join essentials.geofence_boundaries g
    on g.state = '12' and g.mtfcc in ('G5220','G5210')
   and public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(p.lon, p.lat), 4326))
  join essentials.districts d
    on d.geo_id = g.geo_id
   and ((g.mtfcc = 'G5210' and d.district_type = 'STATE_UPPER')
     or (g.mtfcc = 'G5220' and d.district_type = 'STATE_LOWER'))
  join essentials.offices o on o.district_id = d.id
  join essentials.office_current_holder och on och.office_id = o.id
  join essentials.politicians pol on pol.id = och.politician_id
 order by p.label, d.district_type;"
```

Expected: **exactly 6 rows** — one `STATE_LOWER` and one `STATE_UPPER` per point, each naming a real person, and each district matching the anchors recorded in Task 1 Step 4.

- [ ] **Step 10: Commit both migrations**

```bash
cd /c/EV-Accounts/backend && git add migrations/CC_0006_fl_legislature_structure.sql migrations/CC_0007_fl_legislature_incumbents.sql && git commit -F - -- migrations/CC_0006_fl_legislature_structure.sql migrations/CC_0007_fl_legislature_incumbents.sql <<'EOF'
feat(knight-fl): seat the 160-member Florida Legislature (CC_0006, CC_0007)

CC_0006 creates 2 chambers + 160 offices under the existing State of Florida
government. CC_0007 inserts 160 politicians and seats each through
essentials.seat_officeholder().

Both dry-run against prod with BEGIN/ROLLBACK first, and the rollback was
confirmed to have reverted before each apply. check:reachability introduced no
new bucket, so every one of the 160 seats is reachable by address.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: Update the program ledger

Without this the next session cannot tell what landed. The spec makes it a per-session obligation.

**Files:**
- Modify: `.planning/knight-foundation/PROGRAM.md`
- Create: `.planning/knight-foundation/fl.md`

**Interfaces:**
- Consumes: the measured outcomes of Tasks 1–4.
- Produces: the state of record that the FL-3 plan reads.

- [ ] **Step 1: Write the Florida slice notes**

Create `.planning/knight-foundation/fl.md` recording, with the date measured:

- The verified TIGER counts actually loaded: `sldl` 120, `sldu` 40, `place` 411 `G4110`.
- The three identity anchors from Task 1 Step 4, with their independent source URL.
- The `external_id` bands used and why the obvious one was refused.
- The Florida constitutional county officer set, once confirmed per county in FL-3.
- Every defect found in the roster sources, copied from `ROSTERS.md`.
- Any seat found vacant, with the office it belongs to, for FL-3 to resolve.

- [ ] **Step 2: Update the tracker**

In `.planning/knight-foundation/PROGRAM.md`:

- Set slice 1 (FL) stage 1 and stage 2 to `✅`.
- Update the FL row of the "Legislature seats owed" table to `120/120` and `40/40`.
- Update the FL row of the "Geofence polygons present" table to `sldl 120, sldu 40, place 411`.
- Add both applied migrations to the migration ledger table, and set the next free slot to `CC_0008`.
- Append a session log row naming what landed and the next action (`Write the FL-3 plan: Bradenton + Manatee County`).

- [ ] **Step 3: Commit the ledger**

```bash
cd /c/EV-Accounts && git add .planning/knight-foundation/PROGRAM.md .planning/knight-foundation/fl.md && git commit -F - -- .planning/knight-foundation/PROGRAM.md .planning/knight-foundation/fl.md <<'EOF'
docs(knight): record FL-1 and FL-2 in the program ledger

Florida stages 1 and 2 complete: 160 polygons + 411 places loaded, 160
legislators seated. Next free migration slot is CC_0008. Next action is the
FL-3 plan (Bradenton + Manatee County).

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

## Plan self-review

**Spec coverage.** FL-1 (spec §12 row 1) is Task 1. FL-2 (row 2) is Tasks 2–4. The ledger obligation (spec §6) is Task 5. The wave anatomy's seven steps (spec §4) map onto Task 2 steps 1–7 and Task 4 steps 1–7. The four gates (spec §5) all run in Task 4 Step 8. The `CC_` namespace and take-the-number-last rule (spec §4.1) are Task 4 steps 1, 4 and 7.

**Deliberately out of scope for this plan**, and named so nobody thinks it was forgotten:

- **Headshots for the 160 legislators.** Spec §7 puts them in stage 5 (wave FL-7), after every Florida jurisdiction is seated, so one contact-sheet review covers the whole slice. `photo_origin_url` is carried through from the roster where a chamber publishes a portrait, but no image is downloaded, cropped or uploaded in this plan.
- **Banners.** Also stage 5.
- **Florida's `cousub` layer.** Not loaded. Florida is not a strong-MCD state, so its county subdivisions are statistical, like CA/WA/CO. Do not add FL to `COUSUB_FUNCSTAT_STATES`.
- **The 67 FL county districts.** They already exist. Task 1's allowlist deliberately excludes `county` so they are not disturbed.
- **`DEAD_GEOGRAPHY: fl|NATIONAL_LOWER: 1`.** Pre-existing, unrelated to the legislature, and left exactly as it is.

**One deviation from the spec, decided while planning.** The spec's FL-1 row reads "TIGER `place` + `sldu` + `sldl`" as one wave. Task 1 loads them as **two separate invocations** with a verification pass after each (steps 6–7, then 8–9). Same wave, same commit; the split exists so a `place` problem never forces re-running the 160 legislative polygons. This follows the NC precedent, where `place` was declared in the allowlist in wave 1 but run in waves 2 and 3.

**Type consistency.** The `Seat` field names in Task 2's Interfaces block (`chamber`, `district`, `name`, `memberId`, `assumedOffice`, `assumedPrecision`, `howStarted`, `portraitUrl`, `source`) are the exact names Task 3 Step 3 reads. `geoIdFor` and `extId` are defined in Task 3 Step 1 and used in Step 3. `splitName`'s return shape (`first`, `last`, `middle`, `suffix`, `preferred`) is consumed in Step 3 and comes from the NC generator copied in Step 1. The temp table column list matches the payload tuple order position for position, 15 columns each.
