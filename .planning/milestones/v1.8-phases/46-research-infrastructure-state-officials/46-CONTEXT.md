# Phase 46: Research Infrastructure & State Officials - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the stance research CSV schema and populate it with sourced stance data for CA and IN governors and lt. governors across all 21 compass topics. The CSV is the input format for Phase 50's import scripts.

</domain>

<decisions>
## Implementation Decisions

### CSV Schema Design
- Columns: `full_name`, `external_id`, `topic_key`, `value`, `source_url_1`, `source_url_2`, `source_url_3`
- `full_name` is human-readable for researchers; `external_id` is the BallotReady integer ID for exact database matching during import (Phase 50)
- `topic_key` matches `compass.topics.topic_key` (e.g., "healthcare", "abortion", "tariffs")
- `value` is an integer 1-5 matching the existing compass stance definitions
- 3 source URL columns — empty columns are fine when fewer sources exist
- No confidence or notes columns — keep the CSV minimal
- Mirrors the `staging.stances` pattern: `politician_external_id` + `politician_name` + `topic_key`

### Stance Scoring Method
- Match politician positions to the existing 5 stance descriptions per topic (from the compass CSV)
- Integers only (1-5) — no half-values or decimals, avoids false precision
- When evidence conflicts, use the most recent position — people's positions evolve
- Only assign stances based on the individual politician's documented positions — no party platform fallbacks

### Source Standards
- Valid source types: voting records & legislation, official statements & speeches, news reporting from major outlets
- Advocacy group ratings are NOT valid sources
- Voting records should be used with caution — omnibus bills and riders mean a vote against a bill doesn't necessarily mean opposition to every provision
- Minimum 1 source URL per stance value (required)
- Sources should point to specific articles, vote records, or speeches — general "Issues" pages are acceptable as fallback only
- When sources conflict across time, use the most recent position and source it

### Missing Positions
- Omit the row entirely when no documented position exists — no row = no stance in the database
- All 21 compass topics are fair game for governors and lt. governors
- No minimum coverage threshold — best effort research, whatever is found is valuable
- Equal research effort for governors and lt. governors, but accept that lt. governors will naturally have fewer documented positions

</decisions>

<specifics>
## Specific Ideas

- The existing `compass.answers` table stores stance values as float64, but research values should be integers mapped to the 5 defined stance descriptions
- The `compass.contexts` table stores `reasoning` (string) and `sources` (text[]) — the import script (Phase 50) can populate these from the CSV source columns
- Target politicians for this phase: Gov. Gavin Newsom (CA), Lt. Gov. Eleni Kounalakis (CA), Gov. Mike Braun (IN), Lt. Gov. Micah Beckwith (IN)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 46-research-infrastructure-state-officials*
*Context gathered: 2026-02-26*
