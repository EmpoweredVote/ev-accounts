# Phase 97: Schema Foundation & Data Audit - Research

**Researched:** 2026-03-29
**Domain:** PostgreSQL schema design (essentials schema), Indiana/California election data sources, is_appointed data audit, judicial retention modeling
**Confidence:** HIGH

## Summary

Phase 97 has a clear scope: create three new DB tables (elections, races, race_candidates), confirm free data sources for Monroe County IN and LA County CA, audit is_appointed data quality, and add faces_retention_vote to essentials.offices. All four areas are well-understood from live code inspection, and the data source picture is now resolved.

The key discovery is that `essentials.election_records` already exists with a flat historical-record structure. The new `elections`, `races`, and `race_candidates` tables are distinct — they model upcoming/current election events, not historical career records. The planner must be aware of this naming overlap and ensure the new tables are explicitly differentiated in comments.

For Indiana, the Secretary of State publishes Excel candidate lists for both primary and general elections with a direct URL pattern. For Monroe County local races, the county clerk's candidate filings page exists but is only a SharePoint-linked web page (no structured download), so those require scraping or manual entry. LA County publishes a scheduled elections PDF and a 2026 Candidate Handbook but no free structured API; data entry via the existing staging tool is the confirmed approach for local races.

Indiana judicial retention applies exclusively to the Supreme Court, Court of Appeals, and Tax Court (appellate level). Circuit and superior court judges are NOT subject to retention votes — they run in partisan elections. The `faces_retention_vote` column must go on `essentials.offices` per D-10 decision, which is also where `is_appointed_position` already lives.

**Primary recommendation:** Design the three new tables with explicit antipartisan rationale comments, FK to essentials.offices (not directly to politicians) where possible for races, and use the existing migration numbering starting at 042. The audit queries can run against the live production DB before any schema changes land.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** CivicEngine API is off the table — no paid API dependency. Google Civic API is also unavailable (no longer supported).
- **D-02:** Hybrid approach: scrape structured public sources (Secretary of State candidate filings, county clerk websites) and manually fill gaps via existing staging/data-entry tool for local races, bios, and photos.
- **D-03:** Phase 97 must identify sources AND pull sample records to validate the schema design fits real data. Full import pipeline is Phase 98.
- **D-04:** Three new tables in essentials schema: `elections`, `races`, `race_candidates`. No party affiliation fields in any table — antipartisan exclusion enforced at schema layer with rationale comments in migration.
- **D-05:** `race_candidates` has optional `politician_id` FK to `essentials.politicians`. Incumbents link to existing records (photos, bio, legislative data). Challengers have `politician_id = NULL` and carry their own name/photo fields.
- **D-06:** Candidate status uses three values: `active` / `withdrawn` / `filed`. Only `active` candidates returned by default search. `filed` for early-stage unconfirmed candidates. `withdrawn` hidden from search.
- **D-07:** `elections` table has a `scope` / `jurisdiction_level` field (federal/state/county/city/district) for geographic flexibility. A single election can span multiple race levels.
- **D-08:** Audit at both levels — offices first (batch fix for all politicians in that office), then spot-check individual politicians for edge cases (interim appointments to normally-elected seats).
- **D-09:** Generate a report of suspected misclassifications for user review before applying any fixes. No auto-fix — report then fix approach.
- **D-10:** `faces_retention_vote` boolean goes on `essentials.offices` (not politicians). All judges in a retention-vote office inherit the flag automatically. Deviates from roadmap's suggestion of politician-level — offices is more normalized and handles new appointments automatically.
- **D-11:** Research Indiana judicial retention rules during Phase 97 to determine exactly which courts/offices have retention votes. Don't assume — verify.

### Claude's Discretion
- Specific column types, indexes, and constraints for the three new tables
- Migration file structure and sequencing
- Sample data extraction approach (curl, script, manual download)
- Audit query design and report format

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Election data source researched and integrated for Bloomington/Monroe County IN + LA County CA | Sources identified: IN SoS Excel downloads for state/federal races; Monroe County clerk page for local (HTML scrape or manual entry); LA County lavote.gov scheduled elections PDF; staging tool for local gaps |
| DATA-02 | Elections table created with election_date, election_type (primary/general/retention/special), and geographic scope | Schema design documented below; migration 042 pattern established |
| DATA-03 | Races table created linking offices to elections with position-level granularity | FK design to essentials.offices (existing) and essentials.elections (new) documented |
| DATA-04 | Candidate-race linkage established connecting candidates to specific races with incumbent flag | race_candidates table design with optional politician_id FK and is_incumbent bool documented |
| DATA-05 | is_appointed data audited and backfilled for all officials added post-BallotReady (v1.6+) | Audit query targets essentials.politicians.is_appointed and essentials.offices.is_appointed_position; report-then-fix approach confirmed |
</phase_requirements>

---

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| PostgreSQL (Supabase) | 17.x | Tables, FK constraints, indexes | Existing DB; essentials schema is home to all politician data |
| TypeScript SQL migrations | Sequential `.sql` files | Schema changes | Established pattern: `042_...sql`, `043_...sql` |
| pool.query() | pg (existing) | Audit query execution | Already used in all essentials service files |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| Indiana SoS Excel downloads | Primary candidate data for state/federal races | Phase 97 sample pull; full import in Phase 98 |
| Monroe County clerk HTML page | Local Bloomington candidate filings | Manual review; scrape or manual staging entry |
| LA County lavote.gov | LA County candidate/election data | Scheduled elections PDF + Public Officials Roster |
| Existing staging/data-entry tool (`/api/staging/*`) | Manual candidate entry for local races | When structured download unavailable |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| IN SoS Excel | Ballotpedia API | Ballotpedia is paid; SoS is free and authoritative |
| Manual staging entry | Google Civic API | Google Civic is deprecated (confirmed D-01) |
| Manual staging entry | CivicEngine API | Paid, no access (confirmed D-01) |

---

## Architecture Patterns

### Existing Schema Context (CRITICAL)

The `essentials.election_records` table already exists with a flat structure for historical career records (past races a politician ran in, linked to BallotReady external IDs). The three new tables are for **upcoming/current election event modeling** — fundamentally different purpose. Comments in migration files must distinguish these clearly.

Existing relevant tables the new tables will FK against:

- `essentials.offices` — where `faces_retention_vote` lands (D-10); already has `is_appointed_position`
- `essentials.politicians` — FK target for `race_candidates.politician_id` (D-05)
- `essentials.districts` — already has a `retention boolean` column (pre-existing; relates to geofence district characteristics)
- `essentials.chambers` — has `election_frequency`

### Recommended Project Structure

```
ev-accounts/backend/migrations/
├── 042_election_schema.sql     # elections, races, race_candidates tables
├── 043_faces_retention_vote.sql  # ADD COLUMN to essentials.offices
```

Migration sequencing: schema-first (042), then column addition (043). Keeps them independent and revertible.

### Pattern 1: Three-Table Election Model

**What:** Elections → Races → Candidates as a three-level hierarchy.
- `essentials.elections` — the event (date, type, scope)
- `essentials.races` — a position within that election (FK to election + FK to offices)
- `essentials.race_candidates` — a person in a race (FK to race + optional FK to politicians)

**When to use:** Any time an election event needs modeling with multiple positions and multiple candidates per position.

**Proposed schema (based on code context + D-04 through D-07):**

```sql
-- Migration 042: Election schema foundation
-- NO party affiliation fields in any table — antipartisan exclusion enforced at schema layer.
-- Rationale: Empowered Vote derives political alignment from compass answers, legislative votes,
-- and sourced quotes. Party labels are partisan signals that undermine voter independence.
-- Even if upstream data sources (SoS filings, county clerk data) include party fields,
-- they are explicitly excluded at ingestion. See REQUIREMENTS.md Out of Scope section.

CREATE TABLE IF NOT EXISTS essentials.elections (
  id          uuid NOT NULL DEFAULT uuid_generate_v4(),
  name        text NOT NULL,                        -- e.g. "2026 Indiana Primary"
  election_date date NOT NULL,
  election_type text NOT NULL                       -- primary | general | retention | special
                CHECK (election_type IN ('primary','general','retention','special')),
  jurisdiction_level text NOT NULL                  -- federal | state | county | city | district
                CHECK (jurisdiction_level IN ('federal','state','county','city','district')),
  state       character(2),                         -- IN, CA, etc.
  description text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS essentials.races (
  id           uuid NOT NULL DEFAULT uuid_generate_v4(),
  election_id  uuid NOT NULL REFERENCES essentials.elections(id) ON DELETE CASCADE,
  office_id    uuid REFERENCES essentials.offices(id),          -- nullable: some races predate offices
  position_name text NOT NULL,                                  -- display name, e.g. "City Council District 3"
  seats        int NOT NULL DEFAULT 1,
  description  text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS essentials.race_candidates (
  id            uuid NOT NULL DEFAULT uuid_generate_v4(),
  race_id       uuid NOT NULL REFERENCES essentials.races(id) ON DELETE CASCADE,
  politician_id uuid REFERENCES essentials.politicians(id),     -- NULL for challengers (D-05)
  full_name     text NOT NULL,                                  -- denormalized for challengers
  first_name    text,
  last_name     text,
  photo_url     text,                                           -- for challengers without politician record
  is_incumbent  boolean NOT NULL DEFAULT false,
  candidate_status text NOT NULL DEFAULT 'active'              -- active | withdrawn | filed (D-06)
                CHECK (candidate_status IN ('active','withdrawn','filed')),
  last_verified_at timestamptz,                                 -- data freshness tracking
  source        text,                                           -- data origin: sos_excel | county_clerk | manual
  external_id   text,                                           -- SoS filing ID if available
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
-- NOTE: NO party_name, party_affiliation, or partisan fields. See antipartisan comment above.
```

**Indexes to include:**

```sql
CREATE INDEX idx_elections_election_date ON essentials.elections(election_date);
CREATE INDEX idx_elections_state ON essentials.elections(state);
CREATE INDEX idx_races_election_id ON essentials.races(election_id);
CREATE INDEX idx_races_office_id ON essentials.races(office_id);
CREATE INDEX idx_race_candidates_race_id ON essentials.race_candidates(race_id);
CREATE INDEX idx_race_candidates_politician_id ON essentials.race_candidates(politician_id)
  WHERE politician_id IS NOT NULL;
CREATE INDEX idx_race_candidates_status ON essentials.race_candidates(candidate_status);
CREATE UNIQUE INDEX idx_race_candidates_external_id ON essentials.race_candidates(external_id)
  WHERE external_id IS NOT NULL;
```

### Pattern 2: faces_retention_vote on offices

**What:** Add `faces_retention_vote boolean NOT NULL DEFAULT false` to `essentials.offices`.

**Why offices not politicians:** Retention vote is a property of the seat/position, not the individual. When a judge leaves and a replacement is appointed, the new judge automatically inherits the retention-vote characteristic without any data entry. This is more normalized and correct (D-10).

**Existing overlap to know:** `essentials.districts` already has a `retention boolean` column. That column tracks district-level boundary data from BallotReady. The new `offices.faces_retention_vote` is conceptually different — it flags whether the current officeholder will face a retention ballot. The names are different enough that no naming conflict exists.

```sql
-- Migration 043: Retention vote flag on offices
ALTER TABLE essentials.offices
  ADD COLUMN IF NOT EXISTS faces_retention_vote boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN essentials.offices.faces_retention_vote IS
  'True for offices where the incumbent faces a retention vote rather than a contested election.
   In Indiana, this applies to Supreme Court, Court of Appeals, and Tax Court judges.
   Enables dual-filter behavior: retention judges appear under both Elected and Appointed filters
   in the Phase 100 representatives filter UI.';
```

### Pattern 3: is_appointed Audit Query

**What:** Two-tier audit — offices level first (batch classification), then politicians level (individual edge cases).

**Tier 1 — offices audit:**
```sql
-- Find offices where is_appointed_position is NULL (unset) or potentially misclassified
SELECT
  o.id AS office_id,
  o.title,
  o.is_appointed_position,
  d.district_type,
  ch.name AS chamber_name,
  g.name AS government_name,
  g.state,
  COUNT(p.id) AS politician_count
FROM essentials.offices o
LEFT JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
LEFT JOIN essentials.governments g ON g.id = ch.government_id
LEFT JOIN essentials.politicians p ON p.office_id = o.id AND p.is_active = true
WHERE o.is_appointed_position IS NULL
   OR (o.is_appointed_position = false AND d.district_type IN ('LOCAL_EXEC','LOCAL','COUNTY'))
GROUP BY o.id, o.title, o.is_appointed_position, d.district_type, ch.name, g.name, g.state
ORDER BY g.state, g.name, o.title;
```

**Tier 2 — politicians individual audit:**
```sql
-- Find politicians where is_appointed on politicians table may conflict with office classification
SELECT
  p.id AS politician_id,
  p.full_name,
  p.is_appointed AS politician_is_appointed,
  o.is_appointed_position AS office_is_appointed,
  p.data_source,
  p.last_synced
FROM essentials.politicians p
LEFT JOIN essentials.offices o ON o.politician_id = p.id
WHERE p.is_active = true
  AND (
    -- Politician says appointed but office says elected
    (p.is_appointed = true AND o.is_appointed_position = false)
    OR
    -- Politician says not appointed but office says appointed
    (p.is_appointed = false AND o.is_appointed_position = true)
    OR
    -- Office classification is NULL
    o.is_appointed_position IS NULL
  )
ORDER BY p.data_source, p.full_name;
```

**Important:** `is_elected` in service code is derived as `NOT COALESCE(o.is_appointed_position, false)`. A NULL `is_appointed_position` defaults to `false`, meaning NULL-valued offices are currently treated as "elected" — this may cause silent misclassification.

### Anti-Patterns to Avoid

- **Don't add race_candidates to the geofence search path:** The `getRepresentativesByAddress` query joins `essentials.politicians` via PostGIS. `race_candidates` must never be joined into this query. Phase 98's import pipeline must not populate `race_candidates.politician_id` in a way that leaks candidates into the officials query.
- **Don't store party affiliation, even temporarily:** Even a "staging" party field creates risk of future leakage. Exclusion is enforced at the schema layer with a CHECK constraint omission (no column exists to store it).
- **Don't rely on election_records for the new election model:** `essentials.election_records` is a legacy table for BallotReady historical career data. The new tables serve a fundamentally different purpose (upcoming elections for voter-facing display).
- **Don't use text fields for election_date without a date type:** Use PostgreSQL `date` type for election_date (not `text` as used in `election_records`). Enables date arithmetic for countdown displays in Phase 99.
- **Don't confuse offices.faces_retention_vote with districts.retention:** These are different concepts. `districts.retention` comes from BallotReady geofence data; `offices.faces_retention_vote` is the operational flag for filter UI behavior.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Geofence-based election lookup | Custom geofence queries for race_candidates | Existing `getRepresentativesByAddress` + join to races via offices.id | ST_Intersects pattern already optimized with PostGIS indexes |
| Candidate status filtering | Custom WHERE clause in each query | Consistent `WHERE candidate_status = 'active'` default in service layer | D-06 requires `filed` and `withdrawn` to be hidden by default; enforce once in service, not per-route |
| Migration idempotency | Manual DROP/CREATE dance | `ADD COLUMN IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS` | Established pattern across all 042 existing migrations |

---

## Data Source Findings

### Indiana — State and Federal Races (HIGH confidence)

Indiana Secretary of State publishes Excel files with direct download URLs:
- Primary: `https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx`
- General: `https://www.in.gov/sos/elections/files/General-Candidate-List-February-25,-2026.xlsx`

Columns confirmed in the General Election file (from Indiana Citizen HTML table): Office, Candidate Name, Last Name, Political Party, District, Date Filed, Incumbent status. Party column is present in the source and MUST be excluded at ingestion per D-04.

Indiana primary date: May 5, 2026. General election: November 2026.

**Coverage for Phase 97 sample pull:** Download both Excel files. Validate columns map to race_candidates schema. Note: these cover US House, Indiana State Senate, Indiana State Representative — confirmed. Local Bloomington races (city council, etc.) are NOT in the SoS Excel file.

### Indiana — Monroe County Local Races (MEDIUM confidence)

Monroe County clerk maintains a candidate filings page at `https://www.in.gov/counties/monroe/community2/voter-registration/candidate-filings/`. The data is an HTML page with candidate names linking to SharePoint folders containing PDF filing documents. No structured download.

**Gap confirmed:** Local Bloomington/Monroe County races require either HTML scraping (names only, no structured data) or manual entry via staging tool. This is the "known coverage gap" referenced in the roadmap blockers.

**Sample pull approach for Phase 97:** Screenshot/HTML scrape the candidate names list to validate schema handles the data. Full entry is Phase 98.

### LA County — Elections and Candidates (MEDIUM confidence)

LA County Registrar-Recorder publishes:
- Scheduled elections (PDF): `https://content.lavote.gov/docs/rrcc/documents/2026-scheduled-elections-10-25-2025-v-2.pdf`
- Public Officials Roster (web app): `https://apps1.lavote.net/Voter/Public_Officials.cfm`
- 2026 Candidate Handbook: `https://content.lavote.gov/docs/rrcc/documents/2026-candidate-handbook-and-resource-guide--new-v-5.pdf`

**No free structured API confirmed.** Purchasing election information requires calling `(800) 815-2666 option 4`. Free data access is limited to PDFs and the Public Officials Roster web app (scrapable HTML).

**Coverage approach:** Download scheduled elections PDF to enumerate races. Scrape Public Officials Roster for incumbent-level data. Manual staging for challenger candidates. This is appropriate for Phase 97's scope (identify sources + validate schema).

### Indiana Judicial Retention — Verified Courts (HIGH confidence)

**Retention vote applies to (confirmed from official Indiana Courts website):**
- Indiana Supreme Court
- Indiana Court of Appeals (judges represent regions — only on ballot in their region)
- Indiana Tax Court

**Retention vote does NOT apply to:**
- Circuit courts
- Superior courts
- These judges run in partisan elections (different mechanism entirely)

**Key operational rule (D-11 answered):** Once appointed, a justice/judge stands for retention at the first statewide general election after serving two full years, then every 10 years thereafter. Indiana Court of Appeals judges appear only in their geographic region's ballot.

**Implication for offices data:** Query for offices with `is_appointed_position = true` in Indiana where the chamber/government corresponds to Supreme Court, Court of Appeals, or Tax Court. These are the offices to set `faces_retention_vote = true`.

---

## Common Pitfalls

### Pitfall 1: party_name Leakage from Source Data
**What goes wrong:** Indiana SoS Excel and Monroe County filings both include party affiliation columns. An import script that does a naïve column mapping will accidentally include party data.
**Why it happens:** Party is a standard column in all election filing systems.
**How to avoid:** Define explicit column allowlist in Phase 98 import script. In Phase 97, document the excluded columns in the migration comment. Add a `-- NO party_name` comment directly in the migration.
**Warning signs:** Any INSERT statement that references `party`, `party_name`, `party_affiliation`, or similar.

### Pitfall 2: Confusing election_records (legacy) with elections (new)
**What goes wrong:** Developer queries `essentials.election_records` expecting current election data, or adds columns to the wrong table.
**Why it happens:** Both table names contain "election." The legacy table is undocumented as legacy.
**How to avoid:** Add a SQL comment to the 042 migration explicitly noting that `election_records` is a separate legacy table. Prefix the new table's purpose in comments.
**Warning signs:** Any service code that joins `election_records` to `races` or `race_candidates`.

### Pitfall 3: NULL is_appointed_position Defaulting to "Elected"
**What goes wrong:** `is_elected` is derived as `NOT COALESCE(o.is_appointed_position, false)`. NULL defaults to `false`, so NULL = treated as elected. Post-BallotReady officials whose offices were never explicitly classified default to `is_elected = true` incorrectly.
**Why it happens:** The data import from BallotReady set is_appointed_position on offices. Officials added via staging tool after v1.5 may have NULL if not explicitly set.
**How to avoid:** Audit query must include `WHERE o.is_appointed_position IS NULL` as a high-priority finding. Backfill plan must address these before Phase 100 filter ships.
**Warning signs:** Audit query returns a significant number of NULL rows for post-BallotReady officials.

### Pitfall 4: race_candidates Contaminating Geofence Search
**What goes wrong:** A future developer adds a join in `getRepresentativesByAddress` to include candidates, accidentally returning challenger records on the officials page.
**Why it happens:** The politician_id FK on race_candidates makes it look joinable to the politicians query.
**How to avoid:** Document the isolation requirement in the migration comment. The geofence search should only ever join to `essentials.politicians` directly.
**Warning signs:** Any ST_Intersects query that touches `race_candidates` or `races`.

### Pitfall 5: election_date as text vs date type
**What goes wrong:** Phase 99 election countdown UI requires date arithmetic. A `text` date field makes this painful and error-prone.
**Why it happens:** The legacy `election_records` table stores `election_date` as `text`. Copying that pattern into new tables would be wrong.
**How to avoid:** Use PostgreSQL `date` type for all election_date columns in the new tables.
**Warning signs:** Any migration that defines `election_date text`.

---

## Code Examples

### Correct pool.query() Pattern (from essentialsService.ts)

```typescript
// Source: ev-accounts/backend/src/lib/essentialsService.ts line 821+
const baseQuery = `
  SELECT p.id, p.full_name, ...
  FROM essentials.politicians p
  LEFT JOIN essentials.offices o ON o.politician_id = p.id
  WHERE p.id = $1
`;
const { rows } = await pool.query(baseQuery, [id]);
```

All new election service queries should follow this `pool.query()` pattern (not supabase client) because essentials schema is not exposed via PostgREST.

### Migration File Template (from 033_politician_schema.sql)

```sql
-- =============================================================================
-- Migration NNN: [Description]
--
-- [What this migration does, and why]
-- =============================================================================

BEGIN;

-- Step 1: [description]
...

-- Step 2: [description]
...

COMMIT;
```

All migrations use `BEGIN;` / `COMMIT;` wrapping for transactional safety.

### is_elected Derivation (canonical)

```typescript
// Source: ev-accounts/backend/src/lib/essentialsService.ts line 449
is_elected: !row.is_appointed_position,
// NOTE: is_appointed_position comes from essentials.offices, not essentials.politicians
// The politicians table has its own is_appointed column but is_elected is derived from OFFICES
```

The audit must check both `essentials.politicians.is_appointed` AND `essentials.offices.is_appointed_position` — they can disagree (see Pitfall 3).

---

## Runtime State Inventory

> This is a schema addition + data audit phase, not a rename/refactor. No runtime state rename is involved.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `essentials.election_records` — existing legacy table (BallotReady historical records) | None — untouched by this phase; document in migration comment to avoid confusion |
| Stored data | `essentials.districts.retention` — pre-existing boolean column from BallotReady | None — different semantics from new `offices.faces_retention_vote`; document distinction |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (Supabase) | All migrations and audit queries | Yes | 17.x (Supabase managed) | None needed |
| Node.js / tsx | Running audit script | Yes | 20.x (from CLAUDE.md) | — |
| curl / wget | Downloading IN SoS Excel files | Yes (macOS built-in) | — | Browser download |
| IN SoS Excel file | DATA-01 sample pull | Yes (public URL confirmed) | 2026-03-25 dated file | — |
| Monroe County clerk page | DATA-01 local race gaps | Yes (HTML scrape) | — | Manual staging entry |
| LA County lavote.gov | DATA-01 LA County | Yes (PDF + HTML) | — | Manual staging entry |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

> workflow.nyquist_validation is not explicitly set to false in config.json — validation section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest (from CLAUDE.md: `npm test` runs Vitest integration tests) |
| Config file | ev-accounts/backend (check for vitest.config.ts) |
| Quick run command | `cd ev-accounts/backend && npm test` |
| Full suite command | `cd ev-accounts/backend && npm test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Sources identified and sample records pulled | manual | n/a — output is documentation artifact | N/A |
| DATA-02 | elections table exists with correct columns and constraints | integration | `cd ev-accounts/backend && npm test` (migration verify) | Wave 0 gap |
| DATA-03 | races table FK to elections, offices works correctly | integration | `cd ev-accounts/backend && npm test` | Wave 0 gap |
| DATA-04 | race_candidates table: status enum, politician_id nullable, is_incumbent | integration | `cd ev-accounts/backend && npm test` | Wave 0 gap |
| DATA-05 | Audit query runs and produces report; no auto-fix | manual verification | Audit SQL output reviewed by human | N/A |

### Sampling Rate

- **Per task commit:** `cd ev-accounts/backend && npm run typecheck`
- **Per wave merge:** `cd ev-accounts/backend && npm test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] Migration test coverage for 042 and 043 — confirm tables exist with expected columns after migration runs
- [ ] Verify existing tests still pass after new column added to essentials.offices (faces_retention_vote)

---

## Open Questions

1. **How many officials are post-BallotReady with NULL or potentially wrong is_appointed_position?**
   - What we know: BallotReady import set is_appointed_position on offices. Officials added via staging tool may not have had it set.
   - What's unclear: Volume. If predominantly NULL, Phase 100 is blocked.
   - Recommendation: Run audit query as Task 1 before any schema work. The count determines urgency of backfill work.

2. **Do offices in essentials have a 1:1 or 1:many relationship with politicians?**
   - What we know: `idx_essentials_offices_politician_id` is a UNIQUE index on `offices.politician_id` — suggesting 1:1 currently. But the schema allows `politician_id` to be nullable.
   - What's unclear: For races, should `races.office_id` FK to the office record of the current incumbent, or should there be a separate "position" concept?
   - Recommendation: Use `races.office_id` as optional (nullable) FK to the closest matching office. New positions (no incumbent yet) will have NULL office_id. Document this in migration comment.

3. **Are the new elections/races/race_candidates tables exposed via PostgREST or pool.query only?**
   - What we know: The essentials schema is not currently in PostgREST exposed list — all queries use `pool.query()`.
   - What's unclear: Whether new election endpoints will be added to essentials.ts routes or a new election.ts route.
   - Recommendation: Follow existing pattern — pool.query() only, new service file `electionService.ts` planned for Phase 99. Phase 97 is schema-only, no new service code needed.

---

## Sources

### Primary (HIGH confidence)
- Live codebase inspection: `ev-accounts/backend/src/lib/essentialsService.ts` — is_appointed derivation, pool.query() patterns
- Live codebase inspection: `ev-schema-export.sql` — confirmed existing tables: essentials.election_records (legacy), essentials.offices.is_appointed_position, essentials.districts.retention
- Live codebase inspection: `ev-accounts/backend/migrations/033_politician_schema.sql` — migration file pattern, BEGIN/COMMIT, ADD COLUMN IF NOT EXISTS
- Indiana Courts official site: `https://www.in.gov/courts/about/retention/` — Supreme Court, Court of Appeals, Tax Court confirmed retention courts; circuit/superior excluded
- Indiana SoS official site: `https://www.in.gov/sos/elections/` — Excel download URLs confirmed

### Secondary (MEDIUM confidence)
- Monroe County clerk: `https://www.in.gov/counties/monroe/community2/voter-registration/candidate-filings/` — HTML SharePoint page confirmed, no structured download
- LA County lavote.gov search results — scheduled elections PDF confirmed, no free structured API
- Indiana Citizen 2026 candidate list: `https://indianacitizen.org/2026-indiana-primary-candidate-list/` — HTML DataTable format confirmed scrapable, party column present (must exclude)

### Tertiary (LOW confidence)
- General PostgreSQL election schema patterns — informed column type recommendations (date vs text); no authoritative external source needed, conventional PostgreSQL patterns

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all based on live code inspection
- Schema design: HIGH — based on existing migration patterns and CONTEXT.md decisions
- Data sources: HIGH (IN SoS), MEDIUM (Monroe County local, LA County) — confirmed from official sites
- Indiana judicial retention rules: HIGH — from official Indiana Courts website
- Pitfalls: HIGH — derived from direct code inspection of is_elected derivation and existing table structure

**Research date:** 2026-03-29
**Valid until:** 2026-04-29 (stable domain; election filing data URLs may change after filing deadline)
