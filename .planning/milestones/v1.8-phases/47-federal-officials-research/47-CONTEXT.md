# Phase 47: Federal Officials Research - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Research US senators and House representatives for CA and IN to populate the existing stance CSV with sourced stance values across all 21 compass topics. CSV schema, scoring method, source standards, and missing-position handling are inherited from Phase 46.

</domain>

<decisions>
## Implementation Decisions

### Representative Scope
- Senators: Padilla, Schiff (CA) and Young, Banks (IN) — locked in
- LA County: all House representatives whose districts overlap LA County (potentially 15+)
- Monroe County, IN: researcher confirms current rep(s) during research — likely 1 (IN-9)
- Rep identification happens alongside research, not as a separate upfront step

### Research Structure
- Split into sub-plans by group (e.g., CA senators, IN senators, LA County reps, Monroe County rep)
- Equal research effort for all politicians — senators and House reps treated the same
- Best effort coverage: if positions aren't documented after reasonable search, omit the row and move on
- Append all results to the existing stance CSV from Phase 46 (one file for all politicians)

### Federal Voting Records
- Prefer public statements and speeches over roll call votes as primary sources
- When citing votes, prefer standalone bills over omnibus/bundled legislation
- Any official government source is valid: congress.gov, GovTrack, senate.gov, house.gov
- Campaign issue pages remain acceptable as fallback sources (same rule as Phase 46)

### Topic Applicability
- Research all 21 compass topics for every federal official — no topics skipped
- Any documented position counts regardless of jurisdictional level (the compass measures beliefs, not authority)
- Accept natural variation in coverage between states and between politicians
- Always require at least 1 source URL per stance value — no exceptions, even for well-known positions

### Claude's Discretion
- Exact order of politician research within each sub-plan
- How to identify which House districts overlap LA County and Monroe County
- Source selection between multiple valid sources for the same stance

</decisions>

<specifics>
## Specific Ideas

- Phase 46 established the CSV schema: `full_name`, `external_id`, `topic_key`, `value`, `source_url_1`, `source_url_2`, `source_url_3`
- Phase 46 context has full details on scoring method (1-5 integers, most recent position, no party platform fallbacks) and source standards
- Federal officials likely have more documented positions than state officials — coverage should be richer

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 47-federal-officials-research*
*Context gathered: 2026-02-26*
