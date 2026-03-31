# Phase 98: Election Data Import - Research

**Researched:** 2026-03-29
**Domain:** Election data ingestion, TypeScript CLI scripts, HTML scraping, PostgreSQL upsert patterns
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Evolve the existing `sample-indiana-candidates.ts` into the real import script — preserves validated parsing logic and column mappings.
- **D-02:** Dry-run by default. Script runs in preview mode showing parsed records, match results, and warnings. Actual DB writes require `--commit` flag.
- **D-03:** Upsert by `external_id` for idempotency. Re-running updates existing records and adds new ones. Withdrawn candidates updated via status change. Manual edits (photos, bios) preserved.
- **D-04:** Single CLI with source flags: `--source indiana-sos` for Indiana SoS Excel, `--source la-roster` for LA County Public Officials Roster scraping. All election import logic in one script.
- **D-05:** Two-pass matching strategy:
  - Pass 1 — Office-based match: For each race, look up the `essentials.offices` record and find the current politician holding that seat. If a filed candidate's name matches the current officeholder → `is_incumbent = true` + `politician_id` set.
  - Pass 2 — Name-based match: For remaining unmatched candidates, check against all `essentials.politicians` records. If match found → `is_incumbent = false` + `politician_id` set.
- **D-06:** Ambiguous matches (near but not exact) flagged as "POSSIBLE MATCH — needs verification" in dry-run output. No auto-linking on fuzzy matches.
- **D-07:** Cross-office filers get `politician_id` linked but `is_incumbent = false`.
- **D-08:** LA County: incumbents only via scraper from Public Officials Roster. Auto-link incumbents via existing `essentials.politicians` records.
- **D-09:** Challengers for LA County entered manually via existing staging/data-entry tool (`/api/staging/*`).
- **D-10:** Import everything scrapable from the Public Officials Roster — Board of Supervisors, LA City Council, school boards, community college boards.
- **D-11:** Indiana SoS import filtered to Bloomington/Monroe County coverage areas only — IN-9 (US House), State Senate districts overlapping Monroe County, State Rep districts overlapping Monroe County.
- **D-12:** LA County: all available races from the Public Officials Roster.
- **D-13:** Basic query endpoint this phase: `GET /api/essentials/elections?lat=X&lng=Y`. Minimal — just enough to verify data with test addresses. Phase 99 builds the full Election Central page on top.
- **Antipartisan:** Party affiliation excluded at ingestion layer with antipartisan rationale comments in script source. Party lives on `races.primary_party` (for primaries only), never on candidates.
- **Schema:** `essentials.race_candidates` (separate table). Candidates must NEVER appear in `getRepresentativesByAddress` path.

### Claude's Discretion

- Indiana district filtering logic (how to determine which districts overlap Monroe County)
- LA County HTML scraping library choice and parsing approach
- Election query endpoint implementation (geofence-based vs district matching)
- Error handling and logging format in import script output
- Test address selection for verification

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-06 | Candidate records populated in database for upcoming races in coverage areas | Import script (Indiana SoS Excel + LA County scraper) populates `essentials.race_candidates` with candidates for Monroe County/Bloomington IN and LA County CA races. Freshness fields (`last_verified_at`, `candidate_status`) and API verification endpoint confirm data is queryable. |
</phase_requirements>

---

## Summary

Phase 98 is a data ingestion phase with three deliverables: (1) a TypeScript CLI import script that handles both the Indiana SoS Excel source and the LA County Public Officials PDF/web source, (2) populated `essentials.elections`, `essentials.races`, and `essentials.race_candidates` rows for the two coverage areas, and (3) a minimal `GET /api/essentials/elections` endpoint to verify the data against test addresses. The schema (migrations 042 + 043) is already applied from Phase 97. All code patterns (dry-run CLI, Excel parsing, geofence-based lookup) have direct analogues in the existing codebase.

The Indiana SoS Excel pipeline is well-understood — Phase 97 validated the column structure and produced a working parser scaffold (`sample-indiana-candidates.ts`). Monroe County is covered by IN-9 (US House), Senate District 40, and House Districts 60, 61, and 62. The SoS General candidate list also exists for the November 3, 2026 general election. Local Bloomington races (city council, mayor, county offices) are not in the SoS Excel — they require manual staging entry.

LA County is the more complex deliverable. The Public Officials Roster is a PDF at a known URL (`content.lavote.gov/docs/rrcc/documents/current-por-02-26-2026.pdf`) — the web page at `apps1.lavote.net` is a navigation portal that links to the PDF, not a structured HTML table. The scraper must therefore fetch and parse the PDF (using `pdfjs-dist` or a fetch-then-parse approach), or alternatively use the structured HTML page at `lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/county-offices` which WebFetch confirmed lists all 5 supervisors cleanly. LA County's primary is June 2, 2026 with a November 3, 2026 general.

**Primary recommendation:** Build the import script by evolving `sample-indiana-candidates.ts` — add `--source` flag routing, implement the two-pass incumbent matcher, add the LA County HTML scraper as a separate source handler. Geofence-based matching in the elections endpoint mirrors the `getRepresentativesByAddress` pattern exactly using `ST_Covers` + existing `geofence_boundaries`.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| xlsx | 0.18.5 | Parse Indiana SoS `.xlsx` files | Already installed, validated in Phase 97 sample script |
| pg (pool) | ^8.13.0 | Direct PostgreSQL queries for upserts and geofence lookups | Project standard — all service files use `pool.query()` |
| tsx | ^4.19.0 | Run TypeScript scripts directly | Project standard for all `scripts/` files |
| dotenv | ^16.4.0 | Load `.env` for DATABASE_URL | Project standard — all scripts use this pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| node-html-parser | 7.1.0 | Parse LA County HTML pages | Lightweight, no external process, TypeScript-native, sufficient for simple DOM traversal |
| cheerio | 1.2.0 | jQuery-style HTML parsing | Alternative if LA County page structure is deeply nested; heavier than node-html-parser |
| https (stdlib) | built-in | HTTP(S) fetching for downloads | Already used in sample-indiana-candidates.ts; no extra dep needed for simple GETs |

**Recommendation on LA County parsing:** The `lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/county-offices` HTML page returns clean structured data (confirmed: 5 supervisors with names and districts clearly listed). `node-html-parser` is sufficient and avoids adding a new dependency. If the PDF must be parsed, `pdfjs-dist` would be required — but the HTML page approach is strongly preferred.

**Installation (if needed):**
```bash
cd ev-accounts/backend && npm install --save-dev node-html-parser
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| node-html-parser | cheerio | Cheerio has jQuery-style API familiar to more devs but adds ~500KB; node-html-parser is faster and smaller |
| node-html-parser | puppeteer/playwright | Not needed — LA County page does not require JavaScript execution |
| https (stdlib) | axios / node-fetch | No new dep needed; existing download helper in sample-indiana-candidates.ts covers simple redirects |

---

## Architecture Patterns

### Recommended Script Structure
```
ev-accounts/backend/scripts/
└── importElectionData.ts      # Main CLI — evolve from sample-indiana-candidates.ts

ev-accounts/backend/src/lib/
└── electionService.ts         # New: getElectionsByCoordinate() for the query endpoint

ev-accounts/backend/src/routes/
└── essentials.ts              # Add: GET /api/essentials/elections route handler
```

### Pattern 1: Dry-Run CLI with --commit Flag
**What:** Script parses source data and prints full preview of what would be written (matching results, upsert targets, warnings). No DB writes without `--commit`.
**When to use:** All import scripts — standard in this codebase (`importBudgetHierarchy.ts` uses `--dry-run` flag; this script should use `--commit` for the same effect per D-02).

**Example (from importBudgetHierarchy.ts):**
```typescript
// Source: ev-accounts/backend/scripts/importBudgetHierarchy.ts
const isDryRun = !args.includes('--commit');

if (isDryRun) {
  console.log('[DRY RUN] No changes written to DB.');
  console.log('Rerun with --commit to apply.');
} else {
  await client.query('BEGIN');
  // ... writes ...
  await client.query('COMMIT');
}
```

### Pattern 2: Upsert by external_id
**What:** INSERT ... ON CONFLICT (external_id) DO UPDATE — idempotent re-runs that update existing records without clobbering manual edits to excluded fields.
**When to use:** All race_candidate writes per D-03.

```typescript
// Source: 042_election_schema.sql — external_id has UNIQUE partial index
// WHERE external_id IS NOT NULL

await pool.query(`
  INSERT INTO essentials.race_candidates
    (race_id, full_name, first_name, last_name,
     is_incumbent, candidate_status, source, external_id, last_verified_at, politician_id)
  VALUES ($1,$2,$3,$4,$5,$6,$7,$8,now(),$9)
  ON CONFLICT (external_id) WHERE external_id IS NOT NULL
  DO UPDATE SET
    full_name        = EXCLUDED.full_name,
    is_incumbent     = EXCLUDED.is_incumbent,
    candidate_status = EXCLUDED.candidate_status,
    last_verified_at = now()
    -- NOTE: photo_url, politician_id NOT updated on conflict to preserve manual edits
`, [raceId, fullName, firstName, lastName, isIncumbent, status, source, externalId, politicianId]);
```

### Pattern 3: Two-Pass Incumbent Matching
**What:** Pass 1 queries `essentials.offices` for the politician currently holding the seat being contested. Pass 2 falls back to full-name search across `essentials.politicians`.
**When to use:** For every candidate record during import.

```typescript
// Pass 1: office-based match — find current occupant of this race's office
const officeMatch = await pool.query(`
  SELECT p.id, p.full_name
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE o.id = $1
    AND p.is_active = true
`, [raceOfficeId]);

if (officeMatch.rows[0]?.full_name === candidateFullName) {
  // Exact name match → incumbent confirmed
  return { politicianId: officeMatch.rows[0].id, isIncumbent: true };
}

// Pass 2: name-based match — cross-office filer or challenger with existing profile
const nameMatch = await pool.query(`
  SELECT id, full_name
  FROM essentials.politicians
  WHERE full_name ILIKE $1 AND is_active = true
  LIMIT 2
`, [candidateFullName]);

if (nameMatch.rows.length === 1) {
  return { politicianId: nameMatch.rows[0].id, isIncumbent: false };
} else if (nameMatch.rows.length > 1) {
  // Ambiguous — flag for review, do not auto-link
  dryRunWarnings.push(`POSSIBLE MATCH — needs verification: "${candidateFullName}" matches ${nameMatch.rows.length} politicians`);
  return { politicianId: null, isIncumbent: false };
}
```

### Pattern 4: Elections Query Endpoint via Coordinate Lookup
**What:** `GET /api/essentials/elections?lat=X&lng=Y` joins races to elections using the same PostGIS `ST_Covers` pattern as `getRepresentativesByAddress`. Races are linked to `essentials.offices` via `office_id`, and offices are linked to districts which have geofence boundaries.
**When to use:** New endpoint for Phase 98 verification; Phase 99 will build the full UI on top.

```typescript
// Source: pattern mirrors essentialsService.ts getRepresentativesByAddress
// $1 = lng, $2 = lat (PostGIS convention: longitude first)
const { rows } = await pool.query(`
  SELECT DISTINCT
    e.id AS election_id, e.name AS election_name,
    e.election_date, e.election_type,
    r.id AS race_id, r.position_name, r.primary_party, r.seats,
    rc.id AS candidate_id, rc.full_name, rc.is_incumbent,
    rc.candidate_status, rc.photo_url, rc.politician_id
  FROM essentials.elections e
  JOIN essentials.races r ON r.election_id = e.id
  JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.offices o ON o.id = r.office_id
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
  WHERE (
    gb.geometry IS NOT NULL
    AND public.ST_Covers(
      gb.geometry,
      public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
    )
  )
  AND rc.candidate_status != 'withdrawn'
  AND e.election_date >= CURRENT_DATE
  ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
`, [lng, lat]);
```

**Alternative for races without geofence match (statewide + at-large):** A secondary query using `elections.state` + district type coverage analogous to the statewide query in `getRepresentativesByAddress`.

### Pattern 5: Excel Row Parsing with Date Serial Conversion
**What:** Indiana SoS uses Excel serial date format for `DATE FILED`. Must convert to ISO date string.
**When to use:** When parsing `DATE FILED` for provenance metadata.

```typescript
// Excel serial date conversion (already documented in DATA_SOURCES.md)
function excelSerialToISO(serial: number): string {
  const date = new Date(Date.UTC(1900, 0, serial - 1));
  return date.toISOString().split('T')[0]; // YYYY-MM-DD
}
```

### Anti-Patterns to Avoid
- **Joining race_candidates into getRepresentativesByAddress:** The `politician_id` FK is for incumbent linking only. The ISOLATION WARNING in migration 042 is explicit — candidates must never appear in the address search path.
- **Storing party on candidate records:** Party belongs only on `races.primary_party` for primary elections. Never on `race_candidates`. The schema enforces this — there is no party column on `race_candidates`.
- **Auto-linking fuzzy name matches:** Two candidates with similar names (e.g., "John Smith" vs "John T. Smith") must be flagged for manual review, not auto-linked.
- **Hard-coding election records:** Run import against the live SoS URL — the sample script already handles mock fallback when the URL is unavailable.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Excel parsing | Custom binary parser | `xlsx` (already installed) | Handles XLSX format, sheet selection, row iteration, serial date values |
| PostgreSQL upsert | Custom UPDATE/INSERT pair | `ON CONFLICT DO UPDATE` | Atomic, handles race conditions, simpler than two-query patterns |
| HTML DOM traversal | Regex on raw HTML | `node-html-parser` or `cheerio` | Handles malformed HTML, proper attribute extraction |
| Geofence lookup | Custom lat/lng bounding box | `ST_Covers` (PostGIS, already used) | Handles complex polygon geometries; exact match, not approximation |
| TypeScript ESM script | Custom module setup | `tsx` (already installed) | Handles ESM + TypeScript without compile step |

---

## Runtime State Inventory

This is not a rename/refactor phase — no runtime state migration required.

The schema tables (`essentials.elections`, `essentials.races`, `essentials.race_candidates`) were created by migration 042 in Phase 97. They are currently empty. This phase populates them for the first time — pure INSERT/upsert work.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `essentials.elections`, `essentials.races`, `essentials.race_candidates` — empty tables from migration 042 | Populate via import script |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | `DATABASE_URL` — already set in `.env` and Render env vars | None — reuse existing |
| Build artifacts | None | None |

---

## Common Pitfalls

### Pitfall 1: Monroe County District Filtering
**What goes wrong:** The Indiana SoS Excel has 12,289 rows covering all 9 congressional districts, all state senate districts, and all state house districts statewide. Without filtering, the import creates thousands of irrelevant races.
**Why it happens:** The DISTRICT column uses full text descriptions like "United States Representative, Ninth District" and "State Senate District 40" — not numeric codes. Simple substring matching works but must be exhaustive.
**How to avoid:** Allowlist the specific districts confirmed to cover Monroe County/Bloomington:
  - Congressional: District 9 ("Ninth District")
  - State Senate: District 40
  - State House: Districts 60, 61, 62
**Warning signs:** Import shows hundreds of races; check district filter allowlist.

### Pitfall 2: LA County Public Officials Page Is a PDF, Not HTML Table
**What goes wrong:** The URL `apps1.lavote.net/Voter/Public_Officials.cfm` links to a PDF, not a structured HTML table. An HTML scraper against that page will find navigation links, not official roster data.
**Why it happens:** WebFetch and direct inspection confirmed the page is a navigation portal that links to `content.lavote.gov/docs/rrcc/documents/current-por-02-26-2026.pdf`.
**How to avoid:** Scrape the structured HTML page at `lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/county-offices` instead — WebFetch confirmed this page returns clean structured data (all 5 supervisors with names and districts). For school boards and other positions, use the data already gathered from the schedule-of-elections PDF or manually stage them.
**Warning signs:** HTML parse yields zero rows or only navigation anchor tags.

### Pitfall 3: Election/Race Deduplication on Re-Run
**What goes wrong:** Re-running the script creates duplicate `essentials.elections` and `essentials.races` rows because these tables have no `external_id` column — only `race_candidates` has a unique index on `external_id`.
**Why it happens:** Elections and races are inserted by name/date/type, not by an external filing ID. The schema does not have a unique constraint on election+race identity.
**How to avoid:** Use `INSERT ... ON CONFLICT DO NOTHING` with a composite unique check, OR SELECT-first then INSERT-if-not-exists for elections and races. Recommend: add a `UNIQUE(name, election_date, state)` constraint on `essentials.elections` OR do a SELECT before INSERT and reuse the existing `id` if found.
**Warning signs:** Duplicate race names in the DB after two dry-run + commit sequences.

### Pitfall 4: Antipartisan Field Leakage
**What goes wrong:** Party column from SoS Excel gets stored on `race_candidates` instead of (or in addition to) `races.primary_party`.
**Why it happens:** Easy to accidentally pass the party value to the candidate insert.
**How to avoid:** The `race_candidates` table has no `party` column — any attempt to insert a party field will fail at the DB level. However, the dry-run output must explicitly log "Skipping party column — antipartisan policy" for each source row. The antipartisan comment must appear in the script source (required per success criterion 4).

### Pitfall 5: Excel Serial Date Rows Mixed with Header Rows
**What goes wrong:** The SoS Excel file has a 3-row header structure (metadata row, blank row, column header row) before data starts. If `range` is set incorrectly, the parser may treat header rows as data.
**Why it happens:** `xlsx.utils.sheet_to_json` defaults to the first row as header. The SoS file uses `range: 2` (0-indexed row 2) to skip the metadata and blank rows.
**How to avoid:** The `sample-indiana-candidates.ts` already sets `{ range: 2, defval: '' }` — preserve this in the evolved script.

### Pitfall 6: ST_Covers vs ST_Intersects for the Election Endpoint
**What goes wrong:** Using `ST_Intersects` instead of `ST_Covers` can return races for boundary-adjacent districts.
**Why it happens:** `ST_Intersects` returns true if geometries share any point including edges; `ST_Covers` requires the point to be fully inside the polygon.
**How to avoid:** Use `ST_Covers` consistent with `getRepresentativesByAddress`. The existing geofence queries all use `ST_Covers`.

---

## Code Examples

### Excel Source Handler (evolve from sample-indiana-candidates.ts)
```typescript
// Source: ev-accounts/backend/scripts/sample-indiana-candidates.ts (Phase 97 scaffold)
// Key: range: 2 skips the 3-row SoS header structure
const rows: Record<string, unknown>[] = xlsx.utils.sheet_to_json(worksheet, {
  range: 2,   // Row 2 = header row (0-indexed); rows 0-1 are metadata/blank
  defval: '',
});

// District filter — Monroe County coverage only (D-11)
const MONROE_COUNTY_DISTRICTS = [
  'ninth district',    // IN-09 US House (contains Bloomington)
  'district 40',       // State Senate District 40
  'district 60',       // State House District 60
  'district 61',       // State House District 61
  'district 62',       // State House District 62
];

const filteredRows = rows.filter(row => {
  const district = String(row['DISTRICT'] ?? '').toLowerCase();
  return MONROE_COUNTY_DISTRICTS.some(d => district.includes(d));
});
```

### Election Upsert Pattern (SELECT-first for elections/races)
```typescript
// SELECT-first to avoid duplicate elections on re-run
async function upsertElection(pool: Pool, election: ElectionRecord): Promise<string> {
  const existing = await pool.query(
    `SELECT id FROM essentials.elections
     WHERE name = $1 AND election_date = $2 AND state = $3`,
    [election.name, election.election_date, election.state]
  );
  if (existing.rows.length > 0) return existing.rows[0].id;

  const inserted = await pool.query(
    `INSERT INTO essentials.elections
       (name, election_date, election_type, jurisdiction_level, state)
     VALUES ($1,$2,$3,$4,$5) RETURNING id`,
    [election.name, election.election_date, election.election_type,
     election.jurisdiction_level, election.state]
  );
  return inserted.rows[0].id;
}
```

### Antipartisan Comment Pattern (required in script source)
```typescript
// ANTIPARTISAN POLICY: Party column present in source data but NEVER stored on candidates.
// Empowered Vote derives political alignment from compass answers, legislative votes,
// and sourced quotes. Party labels on individual candidates are partisan signals that
// undermine voter independence. See 042_election_schema.sql for full rationale.
//
// For PRIMARY elections: party is stored on races.primary_party (the structural
// container for the race), not on race_candidates. This is required for closed/
// semi-closed primary states where voters need to know which primary they can vote in.
// For GENERAL elections: primary_party is NULL.
const rawParty = String(row['POLITICAL PARTY'] ?? '').trim();
const primaryParty = electionType === 'primary' && rawParty ? rawParty : null;
// DO NOT pass rawParty to the candidate record.
```

---

## Data Coverage: What to Import

### Indiana — Monroe County Scope (D-11)

| Race | District | Election Date | Election Type | Source |
|------|----------|---------------|---------------|--------|
| U.S. House IN-9 | "United States Representative, Ninth District" | 2026-05-05 | primary | Indiana SoS Excel |
| U.S. House IN-9 | "United States Representative, Ninth District" | 2026-11-03 | general | Indiana SoS Excel |
| State Senate District 40 | "State Senate District 40" | 2026-05-05 | primary | Indiana SoS Excel |
| State House District 60 | "State Representative District 60" | 2026-05-05 | primary | Indiana SoS Excel |
| State House District 61 | "State Representative District 61" | 2026-05-05 | primary | Indiana SoS Excel |
| State House District 62 | "State Representative District 62" | 2026-05-05 | primary | Indiana SoS Excel |
| Monroe County Commissioner Dist 1 | Monroe County | 2026-05-05 | primary | Manual staging |
| Monroe County Council (multiple) | Monroe County | 2026-05-05 | primary | Manual staging |
| Bloomington City Council | City of Bloomington | 2026-05-05 | primary | Manual staging |

**Monroe County primary candidates confirmed (from Ballotpedia 2026-03-29):**
- County Assessor: Bob Nyquist (D), Judith A. Sharp (D)
- County Commissioner District 1: Trent Deckard (D), David G. Henry (D)
- County Council District 1-4: one candidate each (D or R)
- Circuit Court races: Krothe (D), Bradley (D)
- Sheriff: Ruben Marte' (D)

**IN-9 congressional primary candidates confirmed:**
- Democratic: Jim Graham, Brad Meyer, Timothy Peck, Keil Roark
- Republican: Erin Houchin (incumbent)
- General (Nov 3): Tonya Hudson (Libertarian), Floyd Taylor (Independent)

**Test address for Bloomington:** Any address in Bloomington, IN 47401 (e.g., 401 N Morton St, Bloomington, IN 47404 — Monroe County Courthouse).

### LA County — Scope (D-10, D-12)

| Race | Notes | Election Date | Source |
|------|-------|---------------|--------|
| Board of Supervisors Districts 1 + 3 | Dist 1 open (Solis term-limited); Dist 3 Horvath incumbent | 2026-06-02 primary, 2026-11-03 general | HTML scraper + manual staging |
| LA County Sheriff | Incumbent Luna + 8 challengers | 2026-06-02 primary | Manual staging |
| LA County Assessor | Incumbent Prang | 2026-06-02 primary | Manual staging |
| LA City Council open seats (Dist 3, 9, 11, 13) | Dist 3 + 9 open; Dist 11 (Park), Dist 13 (Soto-Martinez) | 2026-06-02 primary | Manual staging |
| LA County Superior Court judges | Multiple races | 2026-06-02 | Manual staging |

**LA County primary date:** June 2, 2026 (confirmed).
**LA County general date:** November 3, 2026 (confirmed).
**Incumbents on the structured HTML page** (`lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/county-offices`): Solis (D1), Mitchell (D2), Horvath (D3), Hahn (D4), Barger (D5), Sheriff Luna, DA Hochman, Assessor Prang.

**Test address for LA County:** Any address in unincorporated LA County or City of LA, e.g., 500 W Temple St, Los Angeles, CA 90012 (LA County Hall of Administration).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CivicEngine API (paid) | Direct source scraping + manual staging | Phase 97 decision | No API cost; requires manual work for challengers |
| Google Civic API | Unavailable (discontinued) | 2024-2025 | Reinforces direct-source approach |
| Store candidates in essentials.politicians | Separate `essentials.race_candidates` table | Migration 042 (Phase 97) | Prevents candidates from appearing in address search results |

---

## Open Questions

1. **LA County school board races**
   - What we know: School board elections are included in the June 2026 election cycle. LAUSD and LA Community College District boards are scrapable.
   - What's unclear: Whether LA County `lavote.gov` HTML pages list school board members, or if only the PDF roster covers them. D-10 says "import everything scrapable."
   - Recommendation: Check `lavote.gov` HTML pages for each body type. If not available in HTML, use manual staging for school board races. Do not block the phase on this.

2. **Race deduplication constraint**
   - What we know: `essentials.elections` and `essentials.races` have no unique constraint — only `race_candidates.external_id` has a unique partial index.
   - What's unclear: Whether a new migration (044) adding a composite unique constraint on elections is needed, or if SELECT-first logic is sufficient.
   - Recommendation: The planner should include a Wave 0 task to add `UNIQUE(name, election_date, state)` to `essentials.elections` as migration 044. This is safer than relying on application-level SELECT-first logic.

3. **office_id matching for races**
   - What we know: `essentials.races.office_id` links to `essentials.offices`. The elections endpoint uses this FK to join races to geofence boundaries. If `office_id` is NULL (races without a corresponding offices record), those races won't appear in geofence-based query results.
   - What's unclear: How many existing `essentials.offices` records map to Monroe County and LA County races. The two-pass matching in D-05 depends on finding the office record.
   - Recommendation: The import script's dry-run output should report unmatched offices explicitly. This is an acceptable gap for Phase 98 — the endpoint is verification-only. Phase 99 can handle display of races without geofence linkage.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Import script runtime | Yes | Per system (confirmed tsx runs) | — |
| `xlsx` | Indiana SoS Excel parsing | Yes | 0.18.5 | — |
| `pg` (Pool) | DB upserts | Yes | ^8.13.0 | — |
| `tsx` | Run TypeScript scripts | Yes | ^4.19.0 | — |
| `dotenv` | DATABASE_URL loading | Yes | ^16.4.0 | — |
| `node-html-parser` | LA County HTML scraping | Not installed | — | Add as devDependency: `npm install --save-dev node-html-parser` |
| Indiana SoS Excel URL | Source data | Yes | Live (confirmed 2026-03-29) | Mock data in sample-indiana-candidates.ts |
| LA County HTML page | Incumbent roster | Yes | Live (confirmed 2026-03-29) | Manual staging for all LA County records |
| DATABASE_URL | DB connection | Yes (in .env + Render) | — | — |

**Missing dependencies with no fallback:**
- None that block execution.

**Missing dependencies with fallback:**
- `node-html-parser` — not installed; can be added as devDependency OR use `node-html-parser` npm package. Alternative: fall back to `node fetch + regex` for the simple county page structure (not recommended but workable for a simple list).

---

## Validation Architecture

`workflow.nyquist_validation` is not set to false in `.planning/config.json` — validation section is included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest ^2.1.0 |
| Config file | None found — Vitest runs via `npm test` script |
| Quick run command | `cd ev-accounts/backend && npm test` |
| Full suite command | `cd ev-accounts/backend && npm test` |

**Note:** No existing test files found in `backend/tests/` or `backend/test/`. The existing test suite runs via `vitest run`. Phase 98 is a data ingestion phase with a single new API endpoint — the primary verification is manual test address queries, not automated unit tests.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-06 (criterion 1) | Bloomington test address returns election results from API | smoke/manual | `curl "http://localhost:3000/api/essentials/elections?lat=39.165&lng=-86.526"` | N/A — manual |
| DATA-06 (criterion 2) | LA County test address returns election results from API | smoke/manual | `curl "http://localhost:3000/api/essentials/elections?lat=34.053&lng=-118.243"` | N/A — manual |
| DATA-06 (criterion 3) | candidate_status field present; no withdrawn candidates returned | smoke/manual | Query + curl verification | N/A — manual |
| DATA-06 (criterion 4) | Script source contains antipartisan rationale comments + party exclusion | code review | `grep -n "ANTIPARTISAN" ev-accounts/backend/scripts/importElectionData.ts` | Wave 0 |

### Sampling Rate
- **Per task commit:** `cd ev-accounts/backend && npm run typecheck` (no test files for this phase — type checking is the gate)
- **Per wave merge:** `cd ev-accounts/backend && npm test && npm run typecheck`
- **Phase gate:** All 4 success criteria verified manually before `/gsd:verify-work`

### Wave 0 Gaps
- No test files to create — DATA-06 verification is manual (test address queries against live DB)
- The `antipartisan comments` check (criterion 4) is a code review item, not an automated test

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 98 |
|-----------|-------------------|
| `ev-accounts/backend` is the primary backend | All import script and endpoint work goes here |
| Service pattern: create `lib/<feature>Service.ts` for business logic | New `electionService.ts` for `getElectionsByCoordinate()` |
| Route pattern: create `routes/<feature>.ts`, wire in `index.ts` | New route added to `routes/essentials.ts` OR new `routes/elections.ts` |
| Migrations in `backend/migrations/` — sequential numbered SQL | Next migration is 044 (after 043_faces_retention_vote.sql) |
| `requireAuth` / `optionalAuth` middleware for all routes | Election query endpoint uses `optionalAuth` (public data) |
| Secrets — `.env` locally, Render env vars for production | `DATABASE_URL` already configured; no new secrets needed |
| NEVER commit `.env` files | Import script reads from `.env` via dotenv — must not commit |
| Use `chrisandrewsedu` GitHub account | Applies to all git operations |
| Antipartisan principle | Party NEVER on candidates; stored on races.primary_party for primaries only; import script must have explicit antipartisan comments |

---

## Sources

### Primary (HIGH confidence)
- `ev-accounts/backend/migrations/042_election_schema.sql` — Schema tables, column names, constraints, antipartisan rationale
- `ev-accounts/backend/scripts/sample-indiana-candidates.ts` — Validated parser scaffold, confirmed SoS Excel column structure
- `.planning/phases/97-schema-foundation-data-audit/DATA_SOURCES.md` — Confirmed source URLs, column mappings, coverage gaps
- `ev-accounts/backend/src/lib/essentialsService.ts` — ST_Covers geofence pattern (lines 487-600)
- `ev-accounts/backend/package.json` — Installed dependencies: xlsx@0.18.5, pg, tsx, dotenv
- WebFetch `lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/county-offices` — Confirmed 5 supervisors listed in structured HTML

### Secondary (MEDIUM confidence)
- [Ballotpedia: Monroe County Indiana elections 2026](https://ballotpedia.org/Monroe_County,_Indiana,_elections,_2026) — Confirmed candidate names for county primaries
- [LA County politics site: June 2026 ballot](https://losangelescountypolitics.com/who-is-on-the-ballot-la-county-june-2026-primary/) — Confirmed Board of Supervisors races, sheriff, city council races
- WebSearch + [Indiana's 9th Congressional District election 2026](https://ballotpedia.org/Indiana's_9th_Congressional_District_election,_2026) — Confirmed IN-9 candidates
- [npm: cheerio 1.2.0](https://www.npmjs.com/package/cheerio) — Confirmed current version
- [npm: node-html-parser 7.1.0](https://www.npmjs.com/package/node-html-parser) — Confirmed current version

### Tertiary (LOW confidence)
- WebSearch result that LA County primary is June 2, 2026 — confirmed by multiple sources (HIGH)
- Specific candidate lists for LA County school boards — not yet confirmed from official source

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages confirmed installed or confirmed current from npm registry
- Architecture patterns: HIGH — all patterns sourced from existing codebase files
- Data coverage (Indiana): HIGH — SoS Excel confirmed accessible; Monroe County districts confirmed from Ballotpedia
- Data coverage (LA County): MEDIUM — HTML page confirmed for incumbents; full school board/community college coverage unverified
- Pitfalls: HIGH — all based on confirmed schema + codebase inspection

**Research date:** 2026-03-29
**Valid until:** 2026-04-28 (LA County election filing may change; SoS Excel URL may rotate after deadline)
