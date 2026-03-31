# Phase 97: Schema Foundation & Data Audit - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Design three election-related DB tables (elections, races, race_candidates) with correct structure, confirm free/open data sources for election and candidate data in Bloomington/Monroe County IN and LA County CA, audit is_appointed data quality at both office and politician levels, and model retention judges accurately on the offices table — establishing the verified foundation every subsequent phase depends on.

</domain>

<decisions>
## Implementation Decisions

### Data Source Strategy
- **D-01:** CivicEngine API is off the table — no paid API dependency. Google Civic API is also unavailable (no longer supported).
- **D-02:** Hybrid approach: scrape structured public sources (Secretary of State candidate filings, county clerk websites) and manually fill gaps via existing staging/data-entry tool for local races, bios, and photos.
- **D-03:** Phase 97 must identify sources AND pull sample records to validate the schema design fits real data. Full import pipeline is Phase 98.

### Election Schema Design
- **D-04:** Three new tables in essentials schema: `elections`, `races`, `race_candidates`. No party affiliation fields in any table — antipartisan exclusion enforced at schema layer with rationale comments in migration.
- **D-05:** `race_candidates` has optional `politician_id` FK to `essentials.politicians`. Incumbents link to existing records (photos, bio, legislative data). Challengers have `politician_id = NULL` and carry their own name/photo fields.
- **D-06:** Candidate status uses three values: `active` / `withdrawn` / `filed`. Only `active` candidates returned by default search. `filed` for early-stage unconfirmed candidates. `withdrawn` hidden from search.
- **D-07:** `elections` table has a `scope` / `jurisdiction_level` field (federal/state/county/city/district) for geographic flexibility. A single election can span multiple race levels.

### is_appointed Audit
- **D-08:** Audit at both levels — offices first (batch fix for all politicians in that office), then spot-check individual politicians for edge cases (interim appointments to normally-elected seats).
- **D-09:** Generate a report of suspected misclassifications for user review before applying any fixes. No auto-fix — report then fix approach.

### Retention Judge Modeling
- **D-10:** `faces_retention_vote` boolean goes on `essentials.offices` (not politicians). All judges in a retention-vote office inherit the flag automatically. Deviates from roadmap's suggestion of politician-level — offices is more normalized and handles new appointments automatically.
- **D-11:** Research Indiana judicial retention rules during Phase 97 to determine exactly which courts/offices have retention votes. Don't assume — verify.

### Claude's Discretion
- Specific column types, indexes, and constraints for the three new tables
- Migration file structure and sequencing
- Sample data extraction approach (curl, script, manual download)
- Audit query design and report format

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Schema & Services
- `ev-accounts/backend/src/lib/essentialsService.ts` — Current politician lookup queries, is_elected derivation from `offices.is_appointed_position`
- `ev-accounts/backend/src/lib/candidateService.ts` — Existing "Empowered candidate" service (different concept from election candidates)
- `ev-accounts/backend/src/lib/stagingService.ts` — Staging promote flow, is_appointed field usage
- `ev-accounts/backend/migrations/` — Migration file naming convention (sequential numbered SQL)

### Data Source Documentation
- `CivicEngine GraphQL API Documentation.md` — Reference only (API access unavailable). Do NOT build against this.

### Project Context
- `.planning/REQUIREMENTS.md` — DATA-01 through DATA-05 requirements for this phase
- `.planning/ROADMAP.md` — Phase 97 success criteria (5 items)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Migration system**: Sequential SQL files in `ev-accounts/backend/migrations/` (currently up to 041)
- **Staging/data-entry tool**: Existing volunteer data entry workflow (`/api/staging/*`) can be used for manual candidate data entry
- **is_appointed_position on offices**: Already drives `is_elected` derivation in essentialsService — audit can leverage this existing field

### Established Patterns
- **essentials schema**: All politician-related tables use the `essentials.` schema prefix
- **FK constraints**: Politicians link to offices, offices link to districts, districts link to chambers/governments
- **Derived fields**: `is_elected` is computed as `!is_appointed_position` at query time, not stored
- **Geofence isolation**: Politicians are returned via geofence ST_Intersects queries — race_candidates must NOT be included in these queries

### Integration Points
- `essentials.offices` — `faces_retention_vote` column added here
- `essentials.politicians` — FK target for race_candidates.politician_id (incumbents)
- `ev-accounts/backend/src/routes/essentials.ts` — Future election endpoints will be wired here
- Migration numbering continues from 041

</code_context>

<specifics>
## Specific Ideas

- Data sources must be free/open — no paid APIs, no deprecated APIs
- Sample records pulled during Phase 97 should inform column types and constraints (don't design schema in a vacuum)
- The hybrid approach means the schema must support both scraped imports and manual staging entry
- Antipartisan enforcement: even if upstream data sources include party fields, they must be explicitly excluded at the ingestion layer

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 97-schema-foundation-data-audit*
*Context gathered: 2026-03-29*
