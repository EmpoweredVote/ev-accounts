# Phase 48: Mayors Research - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Research Bloomington IN Mayor Kerry Thomson and Los Angeles CA Mayor Karen Bass to populate the existing stance CSV with sourced stance values across all 21 compass topics. CSV schema, scoring method, source standards, and missing-position handling are inherited from Phase 46.

</domain>

<decisions>
## Implementation Decisions

### Mayor Scope
- Bloomington IN: Mayor Kerry Thomson (took office January 2024, Democrat)
- Los Angeles CA: Mayor Karen Bass (took office December 2022, Democrat)
- Both are the current sitting mayors as of February 2026

### Research Structure
- Split into 2 plans: one per mayor
- Append all results to the existing stance CSV from Phases 46-47 (one file for all politicians)
- Both mayors are local executives with different source profiles than federal officials
- Bass has extensive congressional record (2011-2022) providing rich source material
- Thomson is newer to office with a thinner public record — accept lower coverage

### Source Standards (inherited from Phase 46, with additions for local officials)
- Valid source types: voting records, official statements, city council actions, press conferences, news from major outlets, campaign websites
- Mayor-specific sources: city budget proposals, executive orders, press releases from mayor's office, local news coverage
- Thomson sources likely: Herald-Times, Indiana Daily Student, City of Bloomington official site, WFIU/WTIU
- Bass sources likely: LA Times, official mayor.lacity.org pages, LA Daily News, city council records
- Advocacy group ratings are NOT valid sources
- Minimum 1 source URL per stance value (required)

### URL Authenticity (CRITICAL — lessons from Phase 47)
- Phase 47 generated ~723 fabricated URLs that required 6 cleanup plans to fix
- DO NOT fabricate URLs — if a URL cannot be verified, use a general official page as fallback
- Prefer verifiable URL patterns: city official sites, major newspaper articles with real slugs, congress.gov for Bass's House record
- For Bass: congress.gov member page (https://www.congress.gov/member/karen-bass/B001270) is a verified fallback
- For Thomson: City of Bloomington official site (bloomington.in.gov) pages are acceptable fallbacks
- When in doubt about a URL, use the politician's official page rather than guessing a news article slug

### Topic Applicability
- Research all 21 compass topics for both mayors — no topics skipped
- Some topics (e.g., ukraine-support, tariffs) may lack documented positions for local mayors — omit those rows
- Accept natural variation in coverage; mayors may have fewer documented stances than senators/governors
- Thomson likely has fewer documented positions than Bass due to shorter time in office and smaller city

### Claude's Discretion
- Exact order of topic research within each plan
- Source selection between multiple valid sources for the same stance
- Whether to use Bass's congressional record (2011-2022) or mayoral record (2022+) — prefer most recent, but congressional votes are valid

</decisions>

<specifics>
## Specific Ideas

- Phase 46 established the CSV schema: `full_name`, `external_id`, `topic_key`, `value`, `source_url_1`, `source_url_2`, `source_url_3`
- The CSV currently has 422 data rows for 21 politicians after Phase 47 completion
- Karen Bass has a congressional bioguide ID: B001270 (served in US House 2011-2022, CA-37 then CA-33)
- Bass's congressional record provides rich sourcing for federal-level topics
- Thomson's positions will come primarily from local governance, campaign platform, and local news

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 48-mayors-research*
*Context gathered: 2026-02-26*
