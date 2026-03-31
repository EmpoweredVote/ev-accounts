# Phase 98: Election Data Import - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Populate candidate records for upcoming races in Bloomington/Monroe County IN and LA County CA via import scripts, with freshness fields and test address verification. Deliver a basic election query API endpoint to verify imported data against test addresses.

</domain>

<decisions>
## Implementation Decisions

### Import Script Design
- **D-01:** Evolve the existing `sample-indiana-candidates.ts` into the real import script — preserves validated parsing logic and column mappings.
- **D-02:** Dry-run by default. Script runs in preview mode showing parsed records, match results, and warnings. Actual DB writes require `--commit` flag.
- **D-03:** Upsert by `external_id` for idempotency. Re-running updates existing records and adds new ones. Withdrawn candidates updated via status change. Manual edits (photos, bios) preserved.
- **D-04:** Single CLI with source flags: `--source indiana-sos` for Indiana SoS Excel, `--source la-roster` for LA County Public Officials Roster scraping. All election import logic in one script.

### Incumbent Matching
- **D-05:** Two-pass matching strategy:
  - **Pass 1 — Office-based match:** For each race, look up the `essentials.offices` record and find the current politician holding that seat. If a filed candidate's name matches the current officeholder → `is_incumbent = true` + `politician_id` set.
  - **Pass 2 — Name-based match:** For remaining unmatched candidates, check against all `essentials.politicians` records. If match found → `is_incumbent = false` + `politician_id` set (existing profile data flows through but they're marked as challenger for this race).
- **D-06:** Ambiguous matches (near but not exact name matches) flagged for manual review in dry-run output as "POSSIBLE MATCH — needs verification". No auto-linking on fuzzy matches.
- **D-07:** Cross-office filers (e.g., state rep running for US Congress) get `politician_id` linked but `is_incumbent = false`. This ensures their existing photo, bio, compass, and legislative data carries over to Election Central while correctly identifying them as challengers for the new race.

### LA County Approach
- **D-08:** Incumbents only via scraper for this phase. Scrape the Public Officials Roster HTML at `apps1.lavote.net/Voter/Public_Officials.cfm` → create election/race records + auto-link incumbents via existing `essentials.politicians` records.
- **D-09:** Challengers for LA County entered manually via existing staging/data-entry tool (`/api/staging/*`).
- **D-10:** Import everything scrapable from the Public Officials Roster — Board of Supervisors, LA City Council, school boards, community college boards.

### Scope & Coverage
- **D-11:** Indiana SoS import filtered to Bloomington/Monroe County coverage areas only — IN-9 (US House), State Senate districts overlapping Monroe County, State Rep districts overlapping Monroe County. ~50-100 candidates instead of 12K rows.
- **D-12:** LA County: all available races from the Public Officials Roster (Supervisors, City Council, school boards, community college boards).
- **D-13:** Basic query endpoint this phase: `GET /api/essentials/elections?lat=X&lng=Y` returning elections/races/candidates for a coordinate. Minimal — just enough to verify data with test addresses. Phase 99 builds the full Election Central page on top.

### Claude's Discretion
- Indiana district filtering logic (how to determine which districts overlap Monroe County)
- LA County HTML scraping library choice and parsing approach
- Election query endpoint implementation (geofence-based vs district matching)
- Error handling and logging format in import script output
- Test address selection for verification

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Election Schema
- `ev-accounts/backend/migrations/042_election_schema.sql` — Elections/races/race_candidates table definitions, antipartisan rationale comments, isolation warning
- `ev-accounts/backend/migrations/043_faces_retention_vote.sql` — Retention vote boolean on offices

### Data Source Documentation
- `.planning/phases/97-schema-foundation-data-audit/DATA_SOURCES.md` — Complete source URLs, column mappings, schema fit assessment, import pipeline recommendations, coverage gaps
- `.planning/phases/97-schema-foundation-data-audit/97-CONTEXT.md` — Phase 97 decisions (D-01 through D-11) that constrain this phase

### Existing Import Code
- `ev-accounts/backend/scripts/sample-indiana-candidates.ts` — Validated Indiana SoS Excel parser with column mapping, mock fallback, schema fit assessment. This is the starting point for the real import script (D-01).

### Existing Services & Patterns
- `ev-accounts/backend/src/lib/essentialsService.ts` — Politician lookup queries, geofence matching pattern
- `ev-accounts/backend/src/lib/stagingService.ts` — Staging promote flow for manual data entry
- `ev-accounts/backend/src/routes/essentials.ts` — Route wiring pattern for new endpoints
- `ev-accounts/backend/migrations/` — Migration file naming convention (sequential numbered SQL)

### Project Context
- `.planning/REQUIREMENTS.md` — DATA-06 requirement for this phase
- `.planning/ROADMAP.md` — Phase 98 success criteria (4 items)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **sample-indiana-candidates.ts**: Validated Excel parsing with column mapping, SoS URL handling, mock fallback — direct starting point for import script
- **Staging/data-entry tool**: `/api/staging/*` routes for manual candidate entry (challenger data for LA County)
- **essentials.politicians records**: Existing politician data for incumbent matching (names, office linkages)
- **importBudgetHierarchy.ts pattern**: Existing CLI import script in scripts/ — similar dry-run + commit pattern can be followed

### Established Patterns
- **essentials schema**: All election tables already use `essentials.` prefix
- **Sequential migrations**: Currently at 043 — any new migrations start at 044
- **Geofence queries**: ST_Intersects in essentialsService.ts — election endpoint can reuse this pattern for address-based race lookup
- **Supabase client**: Existing DB client setup in services for direct table operations

### Integration Points
- `essentials.offices` — Office-based incumbent matching (Pass 1) queries current officeholders
- `essentials.politicians` — Name-based matching (Pass 2) for cross-office filers
- `essentials.races.office_id` FK — Links races to offices for incumbent lookup
- `ev-accounts/backend/src/routes/essentials.ts` — New election query endpoint wired here
- `ev-accounts/backend/src/index.ts` — Route registration

</code_context>

<specifics>
## Specific Ideas

- Cross-office filer handling is critical: politicians running for a different office than they currently hold must get `politician_id` linked (profile data flows through) but `is_incumbent = false` (correctly identified as challenger for that race)
- Two-pass matching ensures both incumbent identification and cross-office profile linkage happen correctly
- Dry-run output should clearly show: matched incumbents, cross-office matches, ambiguous near-matches flagged for review, and unmatched new challengers

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 98-election-data-import*
*Context gathered: 2026-03-29*
