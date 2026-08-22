# NC General Assembly (Wave 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat all 170 members of the North Carolina General Assembly — 120 House, 50 Senate — on address-reachable district geometry.

**Architecture:** Four stages, each independently verifiable. TIGER 2024 `sldl`/`sldu` polygons load straight to the DB via the existing generalized loader (a script, not a migration). A roster builder reconciles the 170 sitting members across three independent sources and writes a JSON file, reading nothing from the DB. A generator turns that JSON into two migrations — structure (chambers + offices) and occupancy (politicians + terms) — split so a re-seat never re-runs office creation. Acceptance is an end-to-end address probe, because every cheaper check passes vacuously when a term row is missing.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, TIGER shapefiles via `shapefile` + `adm-zip`.

**Spec:** [`.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md`](../../../.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md)

## Global Constraints

- **`cwd` resets between Bash calls.** Every command below must be prefixed `cd /c/EV-Accounts/backend &&` in the *same* compound command.
- **Migrations are `CA_NNNN_snake_case.sql`** — Chris's namespace. **`CA_0004` and `CA_0005` are the slots** (`CA_0001`–`CA_0003` exist; `check:migrations` green 2026-08-21). Unlike the shared sequence, `CA_` numbers do **not** have to be taken last. Always cite the full slot, never "migration 4".
- **Every migration is idempotent** (`IF NOT EXISTS` / `NOT EXISTS` guards / guarded `UPDATE`) and ends with a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count. This is house style; match it.
- **Dry-run against prod first** by wrapping the body `BEGIN; ... ROLLBACK;`, and confirm the rollback actually reverted before trusting it.
- `psql "$DATABASE_URL"` (pooler creds in `backend/.env`) runs as `ev_api`. All writes here are **DML into existing tables**, so `psql` works and gives real `BEGIN`/`ROLLBACK`. No new objects are created, so the Supabase MCP (= PRODUCTION) is not needed.
- **Never cache "current" in a column.** Occupancy is `essentials.office_terms`, resolved at read time via `essentials.office_current_holder`.
- **Seat people with `essentials.seat_officeholder(office_id, politician_id, term_start, source)`** — do not hand-roll the two-step.
- **Don't invent dates.** Year-only evidence gets `start_precision => 'year'`; genuinely unknown gets `'unknown'`. A wrong year is not excused by `start_precision`.
- **`external_id` band:** Senate `-(3710000 + district)`, House `-(3720000 + district)`. Verified free 2026-08-21 — 0 rows in `-3729999..-3710001`. Re-verify before Task 5.
- Party affiliation is antipartisan: it lives on `races.primary_party`, never on a candidate or officeholder row. Wave 1 writes **no party data**.
- **Commit with a pathspec** — `git commit -F msg -- <path>`. Parallel sessions sweep each other's staged files in both directions.
- This work belongs on its own branch, not on `feat/scope-04-derivation`.

---

### Task 1: NC TIGER layers — allowlist, pre-flight assertion, load, verify

Delivers 170 rows in `essentials.districts` and 170 polygons in `essentials.geofence_boundaries`.

**Files:**
- Modify: `backend/scripts/load-state-tiger-boundaries.ts` (`STATE_LAYER_ALLOWLIST` ~line 35; new pre-flight block beside the existing `EXPECTED_*_MTFCC` blocks ~line 757+)
- Create: `backend/scripts/verify-nc-tiger-import.sql`

**Interfaces:**
- Consumes: nothing.
- Produces: `essentials.districts` rows with `district_type IN ('STATE_LOWER','STATE_UPPER')`, `state='nc'`, `geo_id` = TIGER `GEOID` (5-char, e.g. `37116` for HD-116). Tasks 4 and 6 join on these.

- [ ] **Step 1: Add the pre-flight assertion with DELIBERATELY WRONG counts**

This is the red half of the test. Add beside the other `EXPECTED_*_MTFCC` blocks:

```typescript
  // ── NC MTFCC pre-flight assertion (Wave 1) ──────────────────────────────────
  // NC is single-member in BOTH chambers, so polygon count EQUALS seat count —
  // unlike AZ/WA where SLDL polygons cover two seats each. Verified against raw
  // TIGER 2024 FIPS 37 on 2026-08-21: sldl 120 / sldu 50, zero ZZZ pseudo-districts.
  if (state === 'NC') {
    const EXPECTED_NC_MTFCC: Record<string, number> = {
      sldl: 999,  // TEMPORARILY WRONG — proves the gate aborts. Set to 120 in Step 3.
      sldu: 50,
    };
    if (layer in EXPECTED_NC_MTFCC) {
      const expected = EXPECTED_NC_MTFCC[layer];
      if (actualCount !== expected) {
        throw new Error(
          `[NC MTFCC assertion] layer=${layer}: expected ${expected} records, got ${actualCount}. ` +
          `TIGER file: ${url}. Aborting before any DB write — verify TIGER 2024 FIPS 37 file is correct.`
        );
      }
      console.log(`  [${layer}] NC MTFCC pre-flight assertion PASSED: ${actualCount} records (expected ${expected}).`);
    }
  }
```

- [ ] **Step 2: Add the allowlist entry and run the dry-run to watch it FAIL**

```typescript
  // NC. sldu/sldl: SL 2023-146 (Senate) and SL 2023-149 (House), both enacted
  // 2023-10-25 and STILL the operative maps for 2026 — only the CONGRESSIONAL
  // map was redrawn for 2026 (SL 2025-95), and it is already loaded as G5200V26.
  // TIGER 2024 carries LSY=2024 on both layers, i.e. the 2023 Acts. Verified by
  // identity anchors against Buncombe County's own GIS: Asheville -> HD-116
  // (Turner) / SD-49 (Mayfield), Weaverville -> HD-115 (Prather), Black Mountain
  // -> HD-114 (Ager) / SD-46 (Daniel).
  // 120 sldl and 50 sldu polygons = 120 and 50 seats; single-member both chambers.
  // county is EXCLUDED: all 100 NC counties already exist with geo_id and carry
  // offices in later waves — do not disturb them.
  // place is declared here but is NOT run in wave 1; waves 2 and 3 run it alone
  // so a city mistake never forces a re-run of 170 seats.
  NC: new Set(['sldu', 'sldl', 'place']),
```

Run: `cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state NC --fips 37 --layers sldu,sldl --dry-run`

Expected: **FAILS** on `sldl` with `[NC MTFCC assertion] layer=sldl: expected 999 records, got 120`. If it does not fail, the gate is not wired into the code path — fix that before continuing. `sldu` must print `PASSED: 50`.

- [ ] **Step 3: Correct the expected count and re-run the dry-run**

Change `sldl: 999` to `sldl: 120` and delete the `TEMPORARILY WRONG` comment.

Run: `cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state NC --fips 37 --layers sldu,sldl --dry-run`

Expected: PASS for both — `sldl ... PASSED: 120`, `sldu ... PASSED: 50`, and no DB writes.

- [ ] **Step 4: Load for real**

Run: `cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state NC --fips 37 --layers sldu,sldl`

- [ ] **Step 5: Write the verification SQL**

Create `backend/scripts/verify-nc-tiger-import.sql`, matching the sibling `verify-*-tiger-import.sql` files:

```sql
-- verify-nc-tiger-import.sql — NC wave 1. Read-only; run after the sldu/sldl load.
\echo '== district counts (expect STATE_LOWER 120, STATE_UPPER 50) =='
SELECT district_type, count(*)
FROM essentials.districts
WHERE lower(state) = 'nc' AND district_type IN ('STATE_LOWER', 'STATE_UPPER')
GROUP BY 1 ORDER BY 1;

\echo '== geofence polygons (expect G5220 120, G5210 50) =='
SELECT mtfcc, count(*)
FROM essentials.geofence_boundaries
WHERE state = '37' AND mtfcc IN ('G5220', 'G5210')
GROUP BY 1 ORDER BY 1;

\echo '== every district has geometry (expect 0) =='
SELECT count(*) AS districts_without_geometry
FROM essentials.districts d
WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id);

\echo '== identity anchors (expect HD-116/SD-49, HD-115, HD-114/SD-46, HD-30/SD-22) =='
-- 🔴 THE mtfcc PAIRING IN THIS JOIN IS LOAD-BEARING — see "The geo_id collision" below.
WITH pts(label, lon, lat) AS (VALUES
  ('Asheville',      -82.555413969974, 35.596748465412),
  ('Weaverville',    -82.560275346056, 35.695581782572),
  ('Black Mountain', -82.320007628946, 35.619686277732),
  ('Durham City Hall', -78.8996816092, 35.996066837243)
)
SELECT p.label, d.district_type, d.label AS district
FROM pts p
JOIN essentials.geofence_boundaries g
  ON g.state = '37' AND g.mtfcc IN ('G5220','G5210')
 AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(p.lon, p.lat), 4326))
JOIN essentials.districts d
  ON d.geo_id = g.geo_id
 AND ((g.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
   OR (g.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER'))
ORDER BY p.label, d.district_type;
```

**🔴 The `geo_id` collision — do not drop the `mtfcc` pairing from any of these joins.**

TIGER's GEOID is `STATEFP || district`, and it is **not unique across layers**. For NC, districts
1–50 will carry the same `geo_id` in both chambers: `37040` is *both* HD-40 and SD-40. This is the
known, accepted collision class that `src/lib/geoIdGuard.ts` exists to disambiguate (lines 61–62),
and it is normal — 13 states already carry ~1,159 of these.

Measured on Colorado (which is already loaded), a Denver point joined on `geo_id` **alone** returns
**five** rows:

```
G5210|COUNTY|Denver County          <- 08031 is ALSO Denver County's FIPS
G5210|STATE_LOWER|State House District 31
G5210|STATE_UPPER|State Senate District 31
G5220|STATE_LOWER|State House District 6
G5220|STATE_UPPER|State Senate District 6
```

The correct answer is two rows — HD-6 and SD-31. Pairing `G5220→STATE_LOWER` and
`G5210→STATE_UPPER` yields exactly those. **A bare `d.geo_id = g.geo_id` join silently reports the
wrong chamber and an unrelated county, and nothing errors.**

- [ ] **Step 6: Run the verification**

Run: `cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -f scripts/verify-nc-tiger-import.sql`

Expected: `STATE_LOWER 120`, `STATE_UPPER 50`, `G5220 120`, `G5210 50`, `districts_without_geometry 0`, and the four anchors resolving exactly as listed. **Any anchor mismatch means the vintage assumption is wrong — stop and re-probe, do not proceed to Task 2.**

- [ ] **Step 7: Commit**

```bash
cd /c/EV-Accounts/backend && git add scripts/load-state-tiger-boundaries.ts scripts/verify-nc-tiger-import.sql && git commit -F - -- scripts/load-state-tiger-boundaries.ts scripts/verify-nc-tiger-import.sql <<'EOF'
feat(nc): load NC state legislative districts from TIGER 2024

120 sldl + 50 sldu, single-member both chambers so polygons == seats.
Pre-flight asserts the counts and aborts before any DB write.

TIGER 2024 is the CORRECT vintage: only the congressional map moved for
2026 (SL 2025-95, already loaded as G5200V26). The House and Senate plans
are still SL 2023-149 / SL 2023-146. Anchors verified against Buncombe
County's own GIS.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: Roster builder — reconcile 170 sitting members

Reads nothing from the DB and writes nothing to it. Pure fetch + reconcile + assert.

**Files:**
- Create: `backend/scripts/build-nc-legislature-roster.mjs`
- Create: `backend/scripts/build-nc-legislature-roster.test.ts`
- Output: `backend/data/nc-legislature-roster.json`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `data/nc-legislature-roster.json` shaped `{ retrievedAt: string, seats: Seat[] }` where
  `Seat = { chamber: 'upper' | 'lower', district: number, name: string, memberId: string, assumedOffice: string | null, assumedPrecision: 'day' | 'year' | 'unknown', howStarted: 'elected' | 'appointed' | 'unknown', portraitUrl: string | null, source: string }`.
  Task 3 reads exactly these field names.

  🔴 **`howStarted` is load-bearing.** `essentials.seat_officeholder` takes `p_how_started` and
  **defaults it to `'elected'`**. The eight contested-district survivors reached their seats by
  *appointment*, so without this field the migration records an untrue claim about eight named
  people. `office_terms.how_started` CHECKs `'elected'|'appointed'|'succeeded'|'redistricted'|'unknown'`
  (`'appointed'` already appears on 61 existing rows). Populate `'appointed'` for exactly the eight
  — House 40, 47, 60, 90, 119 and Senate 18, 23, 34 — `'elected'` otherwise, and `'unknown'` rather
  than a guess. Assert the count is exactly 8.

**Why this needs its own unit test:** the sitting-member rule is pure logic over a known-tricky input, and getting it wrong seats a resigned member — a silent, voter-facing wrong answer. The rest of the script is I/O.

- [ ] **Step 1: Write the failing test**

Create `backend/scripts/build-nc-legislature-roster.test.ts`. These fixtures are the **real** contested districts, measured from ncleg.gov on 2026-08-21:

```typescript
import { describe, it, expect } from 'vitest';
import { pickSittingMember, parseNcgaDate } from './build-nc-legislature-roster.mjs';

describe('parseNcgaDate', () => {
  it('converts NCGA M/D/YY to ISO', () => {
    expect(parseNcgaDate('1/29/25')).toBe('2025-01-29');
    expect(parseNcgaDate('11/18/25')).toBe('2025-11-18');
    expect(parseNcgaDate('6/23/26')).toBe('2026-06-23');
  });
});

describe('pickSittingMember', () => {
  it('returns the only row when a district is uncontested', () => {
    const rows = [{ name: 'Jay Adams', appointedOn: null, resignedOn: null }];
    expect(pickSittingMember('96', rows).name).toBe('Jay Adams');
  });

  // HD-47: BOTH rows annotated — the easy shape.
  it('prefers the appointed successor over an annotated resignation', () => {
    const rows = [
      { name: 'Jarrod Lowery', appointedOn: null, resignedOn: '2025-10-07' },
      { name: 'John L. Lowery', appointedOn: '2025-10-13', resignedOn: null },
    ];
    expect(pickSittingMember('47', rows).name).toBe('John L. Lowery');
  });

  // HD-40: the DEPARTED member carries NO annotation. Filtering on "Resigned"
  // alone keeps both rows and seats two people in one seat.
  it('prefers the appointed successor when the predecessor is UNANNOTATED', () => {
    const rows = [
      { name: 'Joe John', appointedOn: null, resignedOn: null },
      { name: 'Phil Rubin', appointedOn: '2025-01-29', resignedOn: null },
    ];
    expect(pickSittingMember('40', rows).name).toBe('Phil Rubin');
  });

  // HD-119: same unannotated shape, different district.
  it('handles the second unannotated-predecessor district', () => {
    const rows = [
      { name: 'Mike Clampitt', appointedOn: null, resignedOn: null },
      { name: 'Anna Ferguson', appointedOn: '2026-04-16', resignedOn: null },
    ];
    expect(pickSittingMember('119', rows).name).toBe('Anna Ferguson');
  });

  // HD-90: the appointee is listed FIRST, so source order proves nothing.
  it('ignores source ordering', () => {
    const rows = [
      { name: 'Dan Kiger', appointedOn: '2026-06-23', resignedOn: null },
      { name: 'Sarah Stevens', appointedOn: null, resignedOn: '2026-06-16' },
    ];
    expect(pickSittingMember('90', rows).name).toBe('Dan Kiger');
  });

  it('takes the LATEST appointment when a seat turned over twice', () => {
    const rows = [
      { name: 'First Appointee', appointedOn: '2025-03-01', resignedOn: '2025-09-01' },
      { name: 'Second Appointee', appointedOn: '2025-09-15', resignedOn: null },
    ];
    expect(pickSittingMember('99', rows).name).toBe('Second Appointee');
  });

  // Failing loudly is the point: a shape we have not seen must not be guessed.
  it('throws when a contested district has no appointment date to arbitrate on', () => {
    const rows = [
      { name: 'Person A', appointedOn: null, resignedOn: null },
      { name: 'Person B', appointedOn: null, resignedOn: null },
    ];
    expect(() => pickSittingMember('7', rows)).toThrow(/district 7/i);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /c/EV-Accounts/backend && npx vitest run scripts/build-nc-legislature-roster.test.ts`

Expected: FAIL — cannot resolve `./build-nc-legislature-roster.mjs`.

- [ ] **Step 3: Implement the two pure functions**

Create `backend/scripts/build-nc-legislature-roster.mjs` starting with the exported logic:

```javascript
#!/usr/bin/env node
/**
 * build-nc-legislature-roster.mjs
 *
 * Reconciles the North Carolina General Assembly roster across THREE independent
 * sources and writes data/nc-legislature-roster.json. Reads nothing from the
 * database and writes nothing to it.
 *
 *   1. ncleg.gov/Members/MemberList/{H,S} — the chamber's own table. AUTHORITATIVE
 *      for identity, district and the canonical spelling of the name. It is ALSO
 *      the only source carrying the appointment date for mid-term successors.
 *   2. data.openstates.org — independent cross-check, and the portrait URL used
 *      by the later headshot pass.
 *   3. ballotpedia.org — the only source of "Date assumed office" for members who
 *      were ELECTED rather than appointed, which is what office_terms.term_start
 *      means: the day this person began holding THIS seat.
 *
 * ⚠ THE CHAMBER'S OWN LISTS ARE OVER-LONG. Measured 2026-08-21: the House list
 * carries 125 rows for 120 seats and the Senate 53 for 50. Eight districts list a
 * departed member alongside their appointed successor.
 *
 * ⚠ AND THE ANNOTATION IS NOT RELIABLE. In HD-40 (Joe John / Phil Rubin) and
 * HD-119 (Mike Clampitt / Anna Ferguson) the DEPARTED member carries no annotation
 * at all — only the successor is marked "Appointed". Filtering on "Resigned" keeps
 * both rows and seats two people in one seat. In HD-90 the appointee is listed
 * FIRST, so source order proves nothing either. The only rule that survives all
 * eight is: the sitting member is the one with the LATEST appointment date, and a
 * contested district with no appointment date at all is a FATAL unseen shape.
 *
 * ⚠ DO NOT SUBSTITUTE WIKIPEDIA'S "Start" COLUMN for the assumed-office date — it
 * mixes election year and appointment year in one column (the CO lesson).
 */

/** NCGA renders dates as M/D/YY. Returns ISO yyyy-mm-dd. */
export function parseNcgaDate(raw) {
  const m = String(raw).trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{2})$/);
  if (!m) throw new Error(`Unparseable NCGA date: ${JSON.stringify(raw)}`);
  const [, mo, da, yy] = m;
  return `20${yy}-${mo.padStart(2, '0')}-${da.padStart(2, '0')}`;
}

/**
 * Given every row the chamber lists for one district, return the sitting member.
 * Throws rather than guess on any shape not seen on 2026-08-21.
 */
export function pickSittingMember(district, rows) {
  if (rows.length === 1) return rows[0];
  const appointed = rows.filter((r) => r.appointedOn);
  if (appointed.length === 0) {
    throw new Error(
      `district ${district}: ${rows.length} rows and no appointment date to arbitrate on ` +
      `(${rows.map((r) => r.name).join(', ')}). Unseen shape — refusing to guess.`
    );
  }
  return [...appointed].sort((a, b) => b.appointedOn.localeCompare(a.appointedOn))[0];
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /c/EV-Accounts/backend && npx vitest run scripts/build-nc-legislature-roster.test.ts`

Expected: PASS, 8 tests.

- [ ] **Step 5: Implement fetch + reconcile and produce the roster**

Append to the same file: fetch both `ncleg.gov` lists, parse each member block for the biography id, name, `District N`, and any `(Appointed M/D/YY)` / `(Resigned M/D/YY)` annotation; group by district; apply `pickSittingMember`; cross-check every surviving name against Open States and Ballotpedia; take `assumedOffice` from the NCGA appointment date where present (`assumedPrecision: 'day'`) and otherwise from Ballotpedia's "Date assumed office". Emit a seat only when all three sources name the same person for that district.

Name-form variance between sources is expected and is **not** a mismatch (e.g. `John L. Lowery` vs `John Lowery`) — normalise by NFD-stripping diacritics, lowercasing, and comparing first + last token. **Combining marks must be DELETED, not replaced with spaces.** A genuine first-name mismatch is a refusal, not a warning: skip and report, never guess.

End the script with hard assertions:

```javascript
const lower = seats.filter((s) => s.chamber === 'lower');
const upper = seats.filter((s) => s.chamber === 'upper');
if (lower.length !== 120) throw new Error(`FATAL: expected 120 House seats, got ${lower.length}`);
if (upper.length !== 50) throw new Error(`FATAL: expected 50 Senate seats, got ${upper.length}`);
for (const [chamber, list, max] of [['lower', lower, 120], ['upper', upper, 50]]) {
  const ds = new Set(list.map((s) => s.district));
  if (ds.size !== list.length) throw new Error(`FATAL: duplicate district in ${chamber}`);
  for (let n = 1; n <= max; n++) {
    if (!ds.has(n)) throw new Error(`FATAL: ${chamber} district ${n} missing from roster`);
  }
}
console.log(`OK: 120 House + 50 Senate, every district 1..N present exactly once.`);
```

- [ ] **Step 6: Run it and inspect the eight contested districts by hand**

Run: `cd /c/EV-Accounts/backend && node scripts/build-nc-legislature-roster.mjs`

Expected: the `OK:` line. Then read the eight contested seats out of the JSON and confirm each names the **successor**, not the departed member:

```bash
cd /c/EV-Accounts/backend && node -e "
const r=require('./data/nc-legislature-roster.json');
const want={lower:{40:'Rubin',47:'John L. Lowery',60:'Cook',90:'Kiger',119:'Ferguson'},upper:{18:'Fatmi',23:'Garson',34:'Measmer'}};
for(const ch of ['lower','upper']) for(const [d,frag] of Object.entries(want[ch])){
  const s=r.seats.find(x=>x.chamber===ch&&x.district===+d);
  console.log(ch,d,s?.name, s&&s.name.includes(frag)?'OK':'*** MISMATCH ***');
}"
```

Expected: eight `OK` lines. **Any `MISMATCH` means the dedupe rule broke against live data — stop.**

- [ ] **Step 7: Commit**

```bash
cd /c/EV-Accounts/backend && git add scripts/build-nc-legislature-roster.mjs scripts/build-nc-legislature-roster.test.ts data/nc-legislature-roster.json && git commit -F - -- scripts/build-nc-legislature-roster.mjs scripts/build-nc-legislature-roster.test.ts data/nc-legislature-roster.json <<'EOF'
feat(nc): reconcile the 170-seat NC General Assembly roster

The chamber's own lists are over-long: 125 House rows for 120 seats, 53
Senate rows for 50. Eight districts list a departed member beside their
appointed successor.

The annotation cannot be trusted. In HD-40 and HD-119 the DEPARTED member
carries no annotation at all, so filtering on "Resigned" seats two people
in one seat; in HD-90 the appointee is listed first, so order proves
nothing. Latest appointment date is the only rule that survives all eight,
and an unseen shape is fatal rather than guessed.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: Migration generator — emit the two `_wip_` migrations

**Files:**
- Create: `backend/scripts/gen-nc-legislature-migrations.mjs`
- Output: `backend/migrations/_wip_nc_legislature_structure.sql`, `backend/migrations/_wip_nc_legislature_incumbents.sql`

**Interfaces:**
- Consumes: `data/nc-legislature-roster.json` from Task 2 — fields `chamber`, `district`, `name`, `assumedOffice`, `assumedPrecision`, `source`.
- Produces: two SQL files. Task 4 renames the first to `CA_0004_nc_legislature_structure.sql`, Task 5 the second to `CA_0005_nc_legislature_incumbents.sql`.

**Why two migrations:** structure is stable, occupancy churns with every vacancy. Keeping them apart means a re-seat never re-runs office creation. This matches the WA (1742/1743) and CO (1843/1844) precedent.

- [ ] **Step 1: Write the generator**

Mirror `scripts/gen-co-legislature-migrations.mjs`. Key differences for NC:

```javascript
const ROSTER = JSON.parse(fs.readFileSync('data/nc-legislature-roster.json', 'utf8'));
const SEATS = ROSTER.seats;
if (SEATS.length !== 170) {
  console.error(`FATAL: expected 170 seats, roster has ${SEATS.length}. Re-run build-nc-legislature-roster.mjs.`);
  process.exit(1);
}

// NC FIPS is 37, so Senate -> -(3710000+n), House -> -(3720000+n), mirroring
// WA's -(5310000+n)/-(5320000+n) and CO's -(810000+n)/-(820000+n).
// Verified free against prod 2026-08-21: zero rows in -3729999..-3710001.
const extId = (s) => (s.chamber === 'upper' ? -(3710000 + s.district) : -(3720000 + s.district));

const GOV_ID = '3a09655d-0d33-45c5-a33a-7a863bd653a1'; // State of North Carolina — ALREADY EXISTS
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
```

The **structure** migration must:
- Insert exactly two chambers on `GOV_ID` — `North Carolina House of Representatives` (`official_count` 120) and `North Carolina Senate` (50), guarded `WHERE NOT EXISTS`.
  🔴 **One chamber per chamber, not one per district.** Indiana has 100+ rows named `Indiana House of Representatives - District 45`, each with its own `government_id` and `official_count = 0`. That shape is the bug, not the pattern.
- Insert 170 offices, with `title` `Representative` / `Senator`, `representing_state` `NC`, `seats` 1.
  🔴 **The office→district join must match on `geo_id` AND `district_type` together.** `geo_id` alone
  is ambiguous — `37040` is both HD-40 and SD-40 — so a bare join either attaches a House office to a
  Senate district or fans out to two rows per seat, while still producing a plausible-looking count.
  `(geo_id, district_type)` is unique (verified on already-loaded Colorado: zero groups with more
  than one row). Per chamber:

```sql
  -- House seats
  JOIN essentials.districts d
    ON d.geo_id = '37' || lpad(:district::text, 3, '0')
   AND d.district_type = 'STATE_LOWER'
   AND lower(d.state) = 'nc'
  -- Senate seats: identical, but district_type = 'STATE_UPPER'
```
- End with a post-verify gate:

```sql
DO $$
DECLARE n_ch int; n_off int; n_orphan int;
BEGIN
  SELECT count(*) INTO n_ch FROM essentials.chambers c
   WHERE c.government_id = '3a09655d-0d33-45c5-a33a-7a863bd653a1'
     AND c.name IN ('North Carolina House of Representatives', 'North Carolina Senate');
  IF n_ch <> 2 THEN RAISE EXCEPTION 'CA_0004: expected 2 NC legislative chambers, found %', n_ch; END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 170 THEN RAISE EXCEPTION 'CA_0004: expected 170 NC legislative offices, found %', n_off; END IF;

  -- Every office must hang off a district that actually has geometry, or the
  -- seat is unreachable by address and nothing will error.
  SELECT count(*) INTO n_orphan FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND (d.geo_id IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id));
  IF n_orphan <> 0 THEN RAISE EXCEPTION 'CA_0004: % NC legislative offices lack district geometry', n_orphan; END IF;
END $$;
```

Plus a fourth assertion in the same gate — every seat maps to exactly one district, and each chamber
has the right shape. This is what catches a cross-wired `geo_id` join, which the 170-count alone
does not:

```sql
DO $$
DECLARE n_lower int; n_upper int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_lower FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='nc' AND d.district_type='STATE_LOWER';
  IF n_lower <> 120 THEN RAISE EXCEPTION 'CA_0004: expected 120 NC House offices, found %', n_lower; END IF;

  SELECT count(*) INTO n_upper FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='nc' AND d.district_type='STATE_UPPER';
  IF n_upper <> 50 THEN RAISE EXCEPTION 'CA_0004: expected 50 NC Senate offices, found %', n_upper; END IF;

  -- Two offices on one district means the geo_id join fanned across chambers.
  SELECT count(*) INTO n_dupe FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state)='nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     GROUP BY o.district_id HAVING count(*) > 1
  ) x;
  IF n_dupe <> 0 THEN RAISE EXCEPTION 'CA_0004: % NC districts carry more than one office — geo_id join fanned across chambers', n_dupe; END IF;
END $$;
```

The **incumbents** migration must insert 170 politicians (guarded on `external_id`) and then call `essentials.seat_officeholder` once per seat. The full signature is:

```
essentials.seat_officeholder(p_office_id uuid, p_politician_id uuid, p_term_start date,
                             p_source text,
                             p_how_started text DEFAULT 'elected',
                             p_start_precision text DEFAULT 'day',
                             p_how_ended_prev text DEFAULT 'term_expired')
```

Pass `assumedOffice` → `p_term_start`, `assumedPrecision` → `p_start_precision`, and
**`howStarted` → `p_how_started`**. Do not let `p_how_started` fall through to its `'elected'`
default — eight of these members were appointed. Add a gate assertion that exactly 8 NC legislative
terms carry `how_started = 'appointed'`.

It ends with its own gate asserting 170 seated:

```sql
DO $$
DECLARE n_seated int;
BEGIN
  SELECT count(och.politician_id) INTO n_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs from
  -- offices, so a vacancy is a NULL politician_id, never an absent row. count(*)
  -- would pass vacuously with every seat empty.
  IF n_seated <> 170 THEN RAISE EXCEPTION 'CA_0005: expected 170 seated NC legislators, found %', n_seated; END IF;
END $$;
```

- [ ] **Step 2: Generate and eyeball**

Run: `cd /c/EV-Accounts/backend && node scripts/gen-nc-legislature-migrations.mjs`

Expected: both `_wip_` files written. Confirm the office count and that no `politician_id` column is written to `essentials.offices` — **that column was dropped** (ADR 0002 phase 5):

```bash
cd /c/EV-Accounts/backend && grep -c "INSERT INTO essentials.offices" migrations/_wip_nc_legislature_structure.sql && grep -n "offices.*politician_id\|politician_id.*offices" migrations/_wip_nc_legislature_*.sql | head
```

Expected: a nonzero insert count and **no** match for `offices.politician_id`.

- [ ] **Step 3: Run the occupancy guard**

Run: `cd /c/EV-Accounts/backend && npm run check:occupancy`

Expected: green. It catches references to the dropped column.

- [ ] **Step 4: Commit the generator**

```bash
cd /c/EV-Accounts/backend && git add scripts/gen-nc-legislature-migrations.mjs && git commit -F - -- scripts/gen-nc-legislature-migrations.mjs <<'EOF'
feat(nc): generate the NC General Assembly seeding migrations

Structure and occupancy are split so a re-seat never re-runs office
creation, matching the WA (1742/1743) and CO (1843/1844) precedent.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Apply `CA_0004` — chambers and 170 offices

**Files:**
- Rename: `backend/migrations/_wip_nc_legislature_structure.sql` → `backend/migrations/CA_0004_nc_legislature_structure.sql`

**Interfaces:**
- Consumes: districts from Task 1, generator output from Task 3.
- Produces: 2 chamber rows and 170 `essentials.offices` rows. Task 5 seats people into them.

- [ ] **Step 1: Confirm the slot is still free**

Run: `cd /c/EV-Accounts && git fetch origin --quiet && cd backend && npm run check:migrations && ls migrations/ | grep '^CA_'`

Expected: `Migration numbering OK`, and `CA_0004` absent from the listing.

- [ ] **Step 2: Rename into the slot**

```bash
cd /c/EV-Accounts/backend && git mv migrations/_wip_nc_legislature_structure.sql migrations/CA_0004_nc_legislature_structure.sql 2>/dev/null || mv migrations/_wip_nc_legislature_structure.sql migrations/CA_0004_nc_legislature_structure.sql
```

Then update any `_wip_` self-reference inside the file to `CA_0004`.

- [ ] **Step 3: Dry-run against prod and confirm the rollback reverted**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
BEGIN;
\i migrations/CA_0004_nc_legislature_structure.sql
SELECT count(*) AS offices_in_txn FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state)='nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
ROLLBACK;
SQL
```

Expected: `offices_in_txn = 170`, the post-verify gate passing, then `ROLLBACK`.

- [ ] **Step 4: Confirm the rollback actually reverted**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -c "SELECT count(*) FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id WHERE lower(d.state)='nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');"
```

Expected: `0`. **If this is not 0, the dry-run committed — stop and investigate before applying anything.**

- [ ] **Step 5: Apply for real**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CA_0004_nc_legislature_structure.sql
```

Expected: the gate passes silently; no exception.

- [ ] **Step 6: Re-run the count and confirm idempotency**

Re-run the Step 5 command a second time. Expected: still succeeds, still 170 offices — the guards make it a no-op.

- [ ] **Step 7: Commit**

```bash
cd /c/EV-Accounts/backend && git add migrations/CA_0004_nc_legislature_structure.sql && git commit -F - -- migrations/CA_0004_nc_legislature_structure.sql <<'EOF'
feat(nc): CA_0004 — NC General Assembly chambers and 170 offices

Two chambers on the existing State of North Carolina government, one per
CHAMBER (the Colorado/Massachusetts shape), not one per district (the
Indiana shape). Gate asserts 2 chambers, 170 offices, and zero offices
hanging off a district without geometry.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: Apply `CA_0005` — 170 politicians and their terms

**Files:**
- Rename: `backend/migrations/_wip_nc_legislature_incumbents.sql` → `backend/migrations/CA_0005_nc_legislature_incumbents.sql`

**Interfaces:**
- Consumes: offices from Task 4.
- Produces: 170 `essentials.politicians` rows in the `-3710000`/`-3720000` `external_id` bands and 170 `essentials.office_terms` rows. Task 6 probes them.

- [ ] **Step 1: Re-verify the `external_id` band is still free**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -c "SELECT count(*) FROM essentials.politicians WHERE external_id::bigint BETWEEN -3729999 AND -3710001;"
```

Expected: `0`. A nonzero result means another wave claimed the band — **stop**, an `external_id` collision seats the wrong person silently.

- [ ] **Step 2: Rename into the slot and dry-run**

```bash
cd /c/EV-Accounts/backend && mv migrations/_wip_nc_legislature_incumbents.sql migrations/CA_0005_nc_legislature_incumbents.sql && set -a && . ./.env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<SQL
BEGIN;
\i migrations/CA_0005_nc_legislature_incumbents.sql
SELECT count(och.politician_id) AS seated_in_txn
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
 WHERE lower(d.state)='nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
ROLLBACK;
SQL
```

Expected: `seated_in_txn = 170`, gate passes, then `ROLLBACK`. Confirm reversion with the Step 1 band query returning `0` again.

- [ ] **Step 3: Apply for real**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/CA_0005_nc_legislature_incumbents.sql
```

- [ ] **Step 4: Verify the eight contested seats hold the SUCCESSOR**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -F'|' -c "
SELECT d.district_type, d.label, p.full_name
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE lower(d.state)='nc'
  AND ((d.district_type='STATE_LOWER' AND d.geo_id IN ('37040','37047','37060','37090','37119'))
    OR (d.district_type='STATE_UPPER' AND d.geo_id IN ('37018','37023','37034')))
ORDER BY 1,2;"
```

Expected: Rubin, John L. Lowery, Cook, Kiger, Ferguson, Fatmi, Garson, Measmer. **No departed member — no Joe John, no Mike Clampitt, no Sarah Stevens, no Graig Meyer.**

- [ ] **Step 5: Confirm no occupancy drift**

```bash
cd /c/EV-Accounts/backend && npm run check:occupancy && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -c "SELECT count(*) FROM essentials.offices_missing_terms WHERE NOT is_vacant;"
```

Expected: `check:occupancy` green, and the unflagged count **still 655** — the pre-existing baseline. 170 new offices that all received terms must not move it. Any increase means seats were created without occupancy, which is the one failure mode CI cannot catch.

- [ ] **Step 6: Commit**

```bash
cd /c/EV-Accounts/backend && git add migrations/CA_0005_nc_legislature_incumbents.sql && git commit -F - -- migrations/CA_0005_nc_legislature_incumbents.sql <<'EOF'
feat(nc): CA_0005 — seat all 170 NC General Assembly members

Seated via essentials.seat_officeholder. The gate counts
och.politician_id rather than *, because office_current_holder LEFT JOINs
from offices — count(*) would pass vacuously with every seat empty.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: End-to-end acceptance and gates

The only reliable detector is an address probe. Everything above can be green with the seats unreachable.

**Files:**
- Modify: `.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md` (mark wave 1 done, record slots)

**Interfaces:**
- Consumes: everything from Tasks 1–5.
- Produces: nothing code-facing; this is the wave's gate.

- [ ] **Step 1: Probe the four anchors end to end**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -F'|' -c "
WITH pts(label, lon, lat) AS (VALUES
  ('Durham City Hall', -78.8996816092, 35.996066837243),
  ('Asheville',        -82.555413969974, 35.596748465412),
  ('Black Mountain',   -82.320007628946, 35.619686277732),
  ('Raleigh Leg Bldg', -78.639166804605, 35.78261009718)
)
SELECT p.label, d.district_type, d.label, p2.full_name
FROM pts p
JOIN essentials.geofence_boundaries g
  ON g.state='37' AND g.mtfcc IN ('G5220','G5210')
 AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(p.lon,p.lat),4326))
JOIN essentials.districts d
  ON d.geo_id = g.geo_id
 AND ((g.mtfcc='G5210' AND d.district_type='STATE_UPPER')
   OR (g.mtfcc='G5220' AND d.district_type='STATE_LOWER'))
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p2 ON p2.id = och.politician_id
ORDER BY p.label, d.district_type;"
```

The `mtfcc` pairing is mandatory here — without it `37040` matches both chambers and the probe
reports a Senate member under a House polygon.

Expected — **exactly two rows per anchor**, one `STATE_LOWER` and one `STATE_UPPER`:

| Anchor | House | Senate |
|---|---|---|
| Asheville | HD-116 Brian Turner | SD-49 Julie Mayfield |
| Black Mountain | HD-114 J. Eric Ager | SD-46 Warren Daniel |
| Durham City Hall | HD-30 | SD-22 |
| Raleigh Leg Bldg | HD-38 | SD-14 |

More than two rows for an anchor means a duplicate seat. Fewer means a missing term row.

- [ ] **Step 2: Run the negative control**

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && psql "$DATABASE_URL" -At -c "
SELECT count(*) FROM essentials.geofence_boundaries g
WHERE g.state='37'
  AND public.ST_Covers(g.geometry, public.ST_SetSRID(public.ST_MakePoint(-82.555413969974, 35.596748465412),4326))
  AND ((g.mtfcc='G5220' AND g.geo_id IN ('37114','37115'))
    OR (g.mtfcc='G5210' AND g.geo_id = '37046'));"
```

Expected: `0`. The Asheville point must **not** fall in HD-114, HD-115 or SD-46. A uniform
"everything found" answer is a broken detector until a negative control fails as expected.

⚠️ Note the `mtfcc` pairing again: a bare `geo_id IN ('37114','37115','37046')` would also match
**HD-46**, which is a different district from SD-46 and is nowhere near Asheville — the control would
then be testing something other than what it claims.

- [ ] **Step 3: Run the full gate suite**

```bash
cd /c/EV-Accounts/backend && npm run check:migrations && npm run check:occupancy && npm run check:reachability && npm run typecheck && npm test
```

Expected: all green. `check:reachability` is the one that matters — it fails on a district with geometry that returns nobody.

- [ ] **Step 4: Update the program doc**

Mark wave 1 done in `.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md`: record `CA_0004` / `CA_0005`, the measured counts, and the anchor results. Note that wave 3 can now derive Buncombe's commission districts from `sldl` 114/115/116.

- [ ] **Step 5: Commit and open the PR**

```bash
cd /c/EV-Accounts && git add .planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md && git commit -F - -- .planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md <<'EOF'
docs(planning): NC wave 1 landed — 170 General Assembly seats

CA_0004 (chambers + offices) and CA_0005 (people + terms). All four
address anchors return exactly one House and one Senate member; negative
control passes; offices_missing_terms unflagged still 655.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

## Self-Review

**Spec coverage.** Wave 1's four spec bullets map to tasks: allowlist + pre-flight → Task 1; two chambers on the existing government with the Indiana warning → Tasks 3–4; 170 offices/politicians/terms → Tasks 3–5; `external_id` band → Tasks 3 and 5 (asserted twice, at generation and immediately before apply). The spec's acceptance table rows for wave 1 are Task 6 Step 1. Waves 2–4 are deliberately out of scope.

**Placeholder scan.** No TBD/TODO. Every code step carries real code; every command is runnable as written; expected outputs are exact values, not "should look right".

**Type consistency.** `pickSittingMember(district, rows)` and `parseNcgaDate(raw)` are defined in Task 2 Step 3 and imported with those exact names in Task 2 Step 1. The `Seat` field names in Task 2's Interfaces block (`chamber`, `district`, `name`, `assumedOffice`, `assumedPrecision`) are the ones Task 3's generator reads. `extId` matches the band asserted in Tasks 3 and 5.

**One known gap, stated rather than hidden.** Task 2 Step 5 describes the fetch-and-reconcile in prose rather than full code, because the exact HTML shape of the Open States and Ballotpedia pages was not probed — only ncleg.gov was. The parsing of ncleg.gov *is* pinned down (measured row counts, the annotation shapes, and the eight contested districts). An executor should expect to iterate on the other two sources' selectors, and must not weaken the three-source rule to avoid that work: **Open States is a detector, not an oracle.**
